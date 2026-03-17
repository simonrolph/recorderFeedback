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
#' @param preview_n Integer. If > 0, only process the first `preview_n` recipients.
#' @param preview_recipient_ids Optional vector of recipient IDs to process.
#' @param preview_only Logical. If TRUE, write preview HTML files and do not send.
#' @param preview_dir Optional output directory for preview HTML files.
#' @return Invisible named list with `log_file`, `summary_file`, and `summary`.
#' @export
rf_dispatch_smtp <- function(
    batch_id,
    dry_run = FALSE,
    resume = TRUE,
    confirm_live_send = FALSE,
    max_retries = NULL,
    retry_backoff_sec = NULL,
  rate_per_minute = NULL,
  preview_n = 0,
  preview_recipient_ids = NULL,
  preview_only = FALSE,
  preview_dir = NULL) {

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

  rf_dispatch_render_template <- function(template, context) {
    if (is.null(template) || !nzchar(template)) {
      return("")
    }

    out <- template
    matches <- gregexpr("\\{\\{\\s*([A-Za-z0-9_.-]+)\\s*\\}\\}", out, perl = TRUE)
    tokens <- regmatches(out, matches)[[1]]

    if (length(tokens) == 0 || identical(tokens, "")) {
      return(out)
    }

    for (token in unique(tokens)) {
      key <- gsub("^\\{\\{\\s*|\\s*\\}\\}$", "", token)
      value <- context[[key]]
      if (is.null(value) || length(value) == 0 || is.na(value[1])) {
        value <- ""
      }
      out <- gsub(token, as.character(value[1]), out, fixed = TRUE)
    }

    out
  }

  rf_dispatch_parse_paths <- function(value) {
    if (is.null(value) || length(value) == 0 || is.na(value[1]) || !nzchar(as.character(value[1]))) {
      return(character(0))
    }

    parts <- unlist(strsplit(as.character(value[1]), "[;,|]"))
    parts <- trimws(parts)
    parts <- parts[nzchar(parts)]
    parts
  }

  rf_dispatch_build_context <- function(row, config, batch_id) {
    context <- as.list(row)
    context <- lapply(context, function(x) {
      if (length(x) == 0 || is.na(x[1])) "" else as.character(x[1])
    })

    context$batch_id <- batch_id
    context$campaign_batch_id <- batch_id
    context$campaign_name <- if (!is.null(config$campaign_name) && nzchar(config$campaign_name)) {
      as.character(config$campaign_name)
    } else {
      batch_id
    }
    context$campaign_date <- as.character(Sys.Date())
    context$dispatch_timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
    context$mail_subject <- if (!is.null(config$mail_subject)) as.character(config$mail_subject) else ""

    if (!is.null(config$campaign_metadata) && is.list(config$campaign_metadata)) {
      meta_names <- names(config$campaign_metadata)
      if (!is.null(meta_names) && any(nzchar(meta_names))) {
        for (nm in meta_names[nzchar(meta_names)]) {
          context[[paste0("campaign_", nm)]] <- as.character(config$campaign_metadata[[nm]])
        }
      }
    }

    context
  }

  rf_dispatch_apply_body_templates <- function(html, prefix_html, suffix_html, inline_images) {
    inline_block <- ""
    if (length(inline_images) > 0) {
      image_tags <- vapply(
        inline_images,
        function(img) {
          src <- gsub("\\\\", "/", img)
          paste0('<p><img src="', src, '" style="max-width:100%;height:auto;" /></p>')
        },
        character(1)
      )
      inline_block <- paste0(image_tags, collapse = "")
    }

    prefix_html <- if (is.null(prefix_html)) "" else prefix_html
    suffix_html <- paste0(if (is.null(suffix_html)) "" else suffix_html, inline_block)

    out <- html

    if (nzchar(prefix_html)) {
      if (grepl("<body[^>]*>", out, ignore.case = TRUE, perl = TRUE)) {
        out <- sub("<body[^>]*>", paste0("\\0", prefix_html), out, ignore.case = TRUE, perl = TRUE)
      } else {
        out <- paste0(prefix_html, out)
      }
    }

    if (nzchar(suffix_html)) {
      if (grepl("</body>", out, ignore.case = TRUE, perl = TRUE)) {
        out <- sub("</body>", paste0(suffix_html, "</body>"), out, ignore.case = TRUE, perl = TRUE)
      } else {
        out <- paste0(out, suffix_html)
      }
    }

    out
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

  preview_n <- as.integer(preview_n)
  if (is.na(preview_n) || preview_n < 0) {
    stop("preview_n must be a non-negative integer")
  }

  preview_ids <- NULL
  if (!is.null(preview_recipient_ids)) {
    preview_ids <- as.character(preview_recipient_ids)
  }

  preview_enabled <- isTRUE(preview_only) || preview_n > 0 || !is.null(preview_ids)
  if (isTRUE(preview_only)) {
    dry_run <- TRUE
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

  if (!is.null(preview_ids)) {
    dispatch_rows <- dispatch_rows[as.character(dispatch_rows$recipient_id) %in% preview_ids, , drop = FALSE]
  }

  if (preview_n > 0) {
    dispatch_rows <- utils::head(dispatch_rows, preview_n)
  }

  log_file <- file.path("renders", batch_id, "dispatch_log.csv")
  summary_file <- file.path("renders", batch_id, "dispatch_summary.csv")
  dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)

  if (is.null(preview_dir) || !nzchar(preview_dir)) {
    preview_dir <- file.path("renders", batch_id, "dispatch_preview")
  }
  if (preview_enabled) {
    dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
  }

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

  subject_template <- if (!is.null(config$mail_subject_template) && nzchar(config$mail_subject_template)) {
    as.character(config$mail_subject_template)
  } else {
    "{{mail_subject}}"
  }

  body_prefix_template <- if (!is.null(config$mail_body_prefix_template)) {
    as.character(config$mail_body_prefix_template)
  } else {
    ""
  }

  body_suffix_template <- if (!is.null(config$mail_body_suffix_template)) {
    as.character(config$mail_body_suffix_template)
  } else {
    ""
  }

  attachments_col <- if (!is.null(config$mail_attachments_col) && nzchar(config$mail_attachments_col)) {
    as.character(config$mail_attachments_col)
  } else {
    "attachment_paths"
  }

  inline_images_col <- if (!is.null(config$mail_inline_images_col) && nzchar(config$mail_inline_images_col)) {
    as.character(config$mail_inline_images_col)
  } else {
    "inline_image_paths"
  }

  preview_index <- data.frame(
    recipient_id = character(),
    email = character(),
    subject = character(),
    preview_file = character(),
    stringsAsFactors = FALSE
  )

  for (i in seq_len(nrow(valid_rows))) {
    row <- valid_rows[i, , drop = FALSE]

    elapsed <- as.numeric(Sys.time()) - last_attempt_time
    if (elapsed < min_interval) {
      Sys.sleep(min_interval - elapsed)
    }
    last_attempt_time <- as.numeric(Sys.time())

    recipient_id <- as.character(row$recipient_id)
    recipient_email <- as.character(row$email)

    context <- rf_dispatch_build_context(row, config, batch_id)
    subject <- rf_dispatch_render_template(subject_template, context)
    if (!nzchar(subject)) {
      subject <- as.character(config$mail_subject)
    }

    body_prefix <- rf_dispatch_render_template(body_prefix_template, context)
    body_suffix <- rf_dispatch_render_template(body_suffix_template, context)

    attachment_paths <- character(0)
    if (attachments_col %in% names(row)) {
      attachment_paths <- rf_dispatch_parse_paths(row[[attachments_col]])
    }
    if (length(attachment_paths) > 0) {
      attachment_paths <- vapply(attachment_paths, function(x) normalizePath(x, winslash = "/", mustWork = FALSE), character(1))
    }

    inline_image_paths <- character(0)
    if (inline_images_col %in% names(row)) {
      inline_image_paths <- rf_dispatch_parse_paths(row[[inline_images_col]])
    }
    if (length(inline_image_paths) > 0) {
      inline_image_paths <- vapply(inline_image_paths, function(x) normalizePath(x, winslash = "/", mustWork = FALSE), character(1))
    }

    missing_attachments <- attachment_paths[!file.exists(attachment_paths)]
    missing_inline_images <- inline_image_paths[!file.exists(inline_image_paths)]

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
    } else if (length(missing_attachments) > 0) {
      send_result <- list(
        status = "Failed",
        attempt = 0L,
        error_type = "content",
        message = paste0("Missing attachment file(s): ", paste(missing_attachments, collapse = ", "))
      )
    } else if (length(missing_inline_images) > 0) {
      send_result <- list(
        status = "Failed",
        attempt = 0L,
        error_type = "content",
        message = paste0("Missing inline image file(s): ", paste(missing_inline_images, collapse = ", "))
      )
    } else if (dry_run) {
      base_html <- paste0(readLines(row$file, warn = FALSE), collapse = "")
      final_html <- rf_dispatch_apply_body_templates(
        html = base_html,
        prefix_html = body_prefix,
        suffix_html = body_suffix,
        inline_images = inline_image_paths
      )

      if (preview_enabled) {
        preview_file <- file.path(preview_dir, paste0("preview_", recipient_id, ".html"))
        writeLines(final_html, preview_file, useBytes = TRUE)
        preview_index <- rbind(
          preview_index,
          data.frame(
            recipient_id = recipient_id,
            email = recipient_email,
            subject = subject,
            preview_file = preview_file,
            stringsAsFactors = FALSE
          )
        )
      }

      send_result <- list(
        status = if (isTRUE(preview_only)) "Preview" else "DryRun",
        attempt = 0L,
        error_type = NA_character_,
        message = paste0(
          if (isTRUE(preview_only)) {
            "Preview generated; email not sent"
          } else {
            "Preflight passed; email not sent (dry_run = TRUE)"
          },
          "; subject=", subject
        )
      )
    } else {
      destination_email <- if (isTRUE(config$test_mode)) {
        as.character(config$mail_test_recipient)
      } else {
        recipient_email
      }

      base_html <- paste0(readLines(row$file, warn = FALSE), collapse = "")
      final_html <- rf_dispatch_apply_body_templates(
        html = base_html,
        prefix_html = body_prefix,
        suffix_html = body_suffix,
        inline_images = inline_image_paths
      )

      temp_file <- tempfile(pattern = "rf_dispatch_", fileext = ".html")
      writeLines(final_html, temp_file, useBytes = TRUE)

      if (preview_enabled) {
        preview_file <- file.path(preview_dir, paste0("preview_", recipient_id, ".html"))
        writeLines(final_html, preview_file, useBytes = TRUE)
        preview_index <- rbind(
          preview_index,
          data.frame(
            recipient_id = recipient_id,
            email = destination_email,
            subject = subject,
            preview_file = preview_file,
            stringsAsFactors = FALSE
          )
        )
      }

      send_call <- function() {
        cid_images_fn <- getFromNamespace("cid_images", "blastula")
        email_obj <- cid_images_fn(temp_file)
        blastula::smtp_send(
          email = email_obj,
          from = sender,
          to = destination_email,
          subject = subject,
          credentials = creds,
          attachments = if (length(attachment_paths) > 0) attachment_paths else NULL,
          verbose = FALSE
        )
      }

      send_result <- rf_dispatch_send_with_retry(
        send_call = send_call,
        max_retries = max_retries,
        retry_backoff_sec = retry_backoff_sec
      )

      recipient_email <- destination_email
      unlink(temp_file, force = TRUE)
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

  if (preview_enabled && nrow(preview_index) > 0) {
    write.csv(preview_index, file.path(preview_dir, "preview_index.csv"), row.names = FALSE)
  }

  total_attempted <- nrow(run_log)
  total_success <- sum(run_log$status == "Success")
  total_failed <- sum(run_log$status == "Failed")
  total_dry_run <- sum(run_log$status == "DryRun")
  total_preview <- sum(run_log$status == "Preview")

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
    preview_this_run = total_preview,
    stringsAsFactors = FALSE
  )

  write.csv(summary, summary_file, row.names = FALSE)

  invisible(list(
    log_file = log_file,
    summary_file = summary_file,
    summary = summary
  ))
}
