#' Dispatch feedback via SMTP email
#'
#' Sends rendered feedback files to recipients via SMTP with preflight checks,
#' retries, rate limiting, and dispatch logging.
#'
#' @param batch_id Character. Identifier for the batch.
#' @param dry_run Logical. If TRUE, do not send mail; only validate and write logs.
#' @param resume Logical. If TRUE, skip recipients already marked `Success` in
#'   `renders/<batch_id>/dispatch_log.csv`.
#' @param confirm_live_send Logical. Must be TRUE to send to real recipients when
#'   `test_mode` is FALSE.
#' @param max_retries Integer. Number of retries after the first failed attempt.
#'   Defaults to `config$mail_retry_max`.
#' @param retry_backoff_sec Numeric. Base seconds for exponential backoff.
#'   Defaults to `config$mail_retry_backoff_sec`.
#' @param rate_per_minute Numeric. Maximum send attempts per minute.
#'   Defaults to `config$mail_rate_per_minute`.
#' @return Invisible named list with `log_file`, `summary_file`, and `summary`.
#' @export
rf_dispatch_smtp <- function(
    batch_id,
    dry_run = FALSE,
    resume = TRUE,
    confirm_live_send = FALSE,
    max_retries = NULL,
    retry_backoff_sec = NULL,
    rate_per_minute = NULL) {

  rf_dispatch_error_type <- function(message) {
    msg <- tolower(as.character(message))

    if (grepl("auth|login|credential|535|authentication", msg)) {
      return("auth")
    }
    if (grepl("timeout|timed out|connection|network|tls|ssl|handshake", msg)) {
      return("connection")
    }
    if (grepl("recipient|mailbox|invalid address|550|551|552|553|554", msg)) {
      return("recipient")
    }
    if (grepl("meta_table|required columns|footer|rendered file|cannot read", msg)) {
      return("content")
    }

    "unknown"
  }

  rf_dispatch_append_log <- function(log_path, entries) {
    if (nrow(entries) == 0) {
      return(invisible(log_path))
    }

    write_header <- !file.exists(log_path)
    write.table(
      entries,
      file = log_path,
      sep = ",",
      row.names = FALSE,
      col.names = write_header,
      append = !write_header,
      qmethod = "double"
    )

    invisible(log_path)
  }

  rf_dispatch_validate_rows <- function(rows) {
    valid <- rows

    if (nrow(valid) == 0) {
      return(list(valid = valid, invalid = valid))
    }

    is_invalid <-
      is.na(valid$recipient_id) |
      is.na(valid$email) |
      valid$email == "" |
      !grepl("@", valid$email) |
      is.na(valid$file) |
      valid$file == "" |
      !file.exists(valid$file)

    invalid <- valid[is_invalid, , drop = FALSE]
    valid <- valid[!is_invalid, , drop = FALSE]

    if (nrow(invalid) > 0) {
      invalid$validation_message <- "Invalid dispatch row: missing/invalid email or missing file"
    }

    list(valid = valid, invalid = invalid)
  }

  rf_dispatch_build_creds <- function(config) {
    if (identical(config$mail_creds, "envvar")) {
      Sys.setenv(SMTP_PASSWORD = config$mail_password)
      return(blastula::creds_envvar(
        user = config$mail_username,
        pass_envvar = "SMTP_PASSWORD",
        host = config$mail_server,
        port = config$mail_port,
        use_ssl = config$mail_use_ssl
      ))
    }

    if (identical(config$mail_creds, "anonymous")) {
      return(blastula::creds_anonymous(
        host = config$mail_server,
        port = config$mail_port,
        use_ssl = config$mail_use_ssl
      ))
    }

    stop("Unsupported mail_creds value: ", config$mail_creds)
  }

  rf_dispatch_send_with_retry <- function(send_call, max_retries, retry_backoff_sec) {
    attempt <- 1

    repeat {
      result <- tryCatch({
        send_call()
        list(ok = TRUE, message = "Email sent")
      }, error = function(e) {
        list(ok = FALSE, message = as.character(e$message))
      })

      if (result$ok) {
        return(list(
          status = "Success",
          attempt = attempt,
          error_type = NA_character_,
          message = result$message
        ))
      }

      if (attempt > max_retries) {
        return(list(
          status = "Failed",
          attempt = attempt,
          error_type = rf_dispatch_error_type(result$message),
          message = result$message
        ))
      }

      wait_for <- retry_backoff_sec * (2 ^ (attempt - 1))
      Sys.sleep(wait_for)
      attempt <- attempt + 1
    }
  }

  config <- config::get()

  if (is.null(max_retries)) {
    max_retries <- if (!is.null(config$mail_retry_max)) config$mail_retry_max else 3
  }
  if (is.null(retry_backoff_sec)) {
    retry_backoff_sec <- if (!is.null(config$mail_retry_backoff_sec)) config$mail_retry_backoff_sec else 2
  }
  if (is.null(rate_per_minute)) {
    rate_per_minute <- if (!is.null(config$mail_rate_per_minute)) config$mail_rate_per_minute else 60
  }

  max_retries <- as.integer(max_retries)
  retry_backoff_sec <- as.numeric(retry_backoff_sec)
  rate_per_minute <- as.numeric(rate_per_minute)

  if (is.na(max_retries) || max_retries < 0) {
    stop("max_retries must be a non-negative integer")
  }
  if (is.na(retry_backoff_sec) || retry_backoff_sec < 0) {
    stop("retry_backoff_sec must be >= 0")
  }
  if (is.na(rate_per_minute) || rate_per_minute <= 0) {
    stop("rate_per_minute must be > 0")
  }

  if (!dry_run && !isTRUE(config$test_mode) && !isTRUE(confirm_live_send)) {
    stop(
      "Live dispatch blocked: set confirm_live_send = TRUE to send when test_mode is FALSE."
    )
  }

  meta_file <- file.path("renders", batch_id, "meta_table.csv")
  if (!file.exists(meta_file)) {
    stop("Meta table not found: ", meta_file)
  }

  meta_table <- read.csv(meta_file, stringsAsFactors = FALSE)
  required_cols <- c("recipient_id", "file", "email")
  missing_cols <- setdiff(required_cols, names(meta_table))
  if (length(missing_cols) > 0) {
    stop("meta_table is missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  if ("render_status" %in% names(meta_table)) {
    dispatch_rows <- meta_table[meta_table$render_status == "rendered", , drop = FALSE]
    skipped_before_dispatch <- sum(meta_table$render_status == "skipped")
  } else {
    dispatch_rows <- meta_table[!is.na(meta_table$file), , drop = FALSE]
    skipped_before_dispatch <- 0
  }

  log_file <- file.path("renders", batch_id, "dispatch_log.csv")
  summary_file <- file.path("renders", batch_id, "dispatch_summary.csv")
  dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)

  prior_log <- data.frame()
  if (file.exists(log_file)) {
    prior_log <- read.csv(log_file, stringsAsFactors = FALSE)
  }

  if (resume && nrow(prior_log) > 0 && "status" %in% names(prior_log)) {
    successful_ids <- unique(prior_log$recipient_id[prior_log$status == "Success"])
    dispatch_rows <- dispatch_rows[!(dispatch_rows$recipient_id %in% successful_ids), , drop = FALSE]
  }

  validated <- rf_dispatch_validate_rows(dispatch_rows)
  valid_rows <- validated$valid
  invalid_rows <- validated$invalid

  run_log <- data.frame(
    timestamp = character(),
    batch_id = character(),
    recipient_id = character(),
    email = character(),
    status = character(),
    attempt = integer(),
    error_type = character(),
    message = character(),
    dry_run = logical(),
    stringsAsFactors = FALSE
  )

  if (nrow(invalid_rows) > 0) {
    invalid_entries <- data.frame(
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
      batch_id = batch_id,
      recipient_id = as.character(invalid_rows$recipient_id),
      email = as.character(invalid_rows$email),
      status = "Failed",
      attempt = 0L,
      error_type = "content",
      message = as.character(invalid_rows$validation_message),
      dry_run = dry_run,
      stringsAsFactors = FALSE
    )
    run_log <- rbind(run_log, invalid_entries)
  }

  sender <- config$mail_sender
  names(sender) <- config$mail_name
  creds <- NULL
  if (!dry_run && nrow(valid_rows) > 0) {
    creds <- rf_dispatch_build_creds(config)
  }

  min_interval <- 60 / rate_per_minute
  last_attempt_time <- as.numeric(Sys.time()) - min_interval

  for (i in seq_len(nrow(valid_rows))) {
    row <- valid_rows[i, , drop = FALSE]

    elapsed <- as.numeric(Sys.time()) - last_attempt_time
    if (elapsed < min_interval) {
      Sys.sleep(min_interval - elapsed)
    }
    last_attempt_time <- as.numeric(Sys.time())

    recipient_id <- as.character(row$recipient_id)
    recipient_email <- as.character(row$email)

    footer_check <- tryCatch({
      lines_read <- paste0(readLines(row$file, warn = FALSE), collapse = "")
      grepl(recipient_email, lines_read, fixed = TRUE)
    }, error = function(e) {
      stop("Cannot read rendered file for recipient_id ", recipient_id, ": ", e$message)
    })

    if (!isTRUE(footer_check)) {
      send_result <- list(
        status = "Failed",
        attempt = 0L,
        error_type = "content",
        message = "Target email address is different to email listed in footer"
      )
    } else if (dry_run) {
      send_result <- list(
        status = "DryRun",
        attempt = 0L,
        error_type = NA_character_,
        message = "Preflight passed; email not sent (dry_run = TRUE)"
      )
    } else {
      destination_email <- if (isTRUE(config$test_mode)) {
        as.character(config$mail_test_recipient)
      } else {
        recipient_email
      }

      send_call <- function() {
        email_obj <- blastula:::cid_images(row$file)
        blastula::smtp_send(
          email = email_obj,
          from = sender,
          to = destination_email,
          subject = config$mail_subject,
          credentials = creds,
          verbose = FALSE
        )
      }

      send_result <- rf_dispatch_send_with_retry(
        send_call = send_call,
        max_retries = max_retries,
        retry_backoff_sec = retry_backoff_sec
      )

      recipient_email <- destination_email
    }

    run_log <- rbind(
      run_log,
      data.frame(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
        batch_id = batch_id,
        recipient_id = recipient_id,
        email = recipient_email,
        status = send_result$status,
        attempt = as.integer(send_result$attempt),
        error_type = send_result$error_type,
        message = send_result$message,
        dry_run = dry_run,
        stringsAsFactors = FALSE
      )
    )
  }

  rf_dispatch_append_log(log_file, run_log)

  total_attempted <- nrow(run_log)
  total_success <- sum(run_log$status == "Success")
  total_failed <- sum(run_log$status == "Failed")
  total_dry_run <- sum(run_log$status == "DryRun")

  summary <- data.frame(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    batch_id = batch_id,
    dry_run = dry_run,
    resume = resume,
    total_rendered_candidates = nrow(dispatch_rows),
    skipped_before_dispatch = skipped_before_dispatch,
    attempted_this_run = total_attempted,
    success_this_run = total_success,
    failed_this_run = total_failed,
    dry_run_this_run = total_dry_run,
    stringsAsFactors = FALSE
  )

  write.csv(summary, summary_file, row.names = FALSE)

  invisible(list(
    log_file = log_file,
    summary_file = summary_file,
    summary = summary
  ))
}
