#' Preflight validation before render or dispatch
#'
#' Runs early checks to fail fast before expensive render or email steps.
#'
#' @param stage Character. One of `"render"` or `"dispatch"`.
#' @param batch_id Character. Required when `stage = "dispatch"`.
#' @param verbose Logical. If TRUE, prints progress messages.
#' @param check_recorder_schema Logical. Passed to [rf_verify_data()].
#' @param recorder_schema_cols Character vector of recorder schema columns.
#' @param recorder_schema_required Logical. Passed to [rf_verify_data()].
#' @return Invisible TRUE if all checks pass, otherwise stops with an error.
#' @export
rf_preflight <- function(
    stage = c("render", "dispatch"),
    batch_id = NULL,
    verbose = TRUE,
    check_recorder_schema = TRUE,
    recorder_schema_cols = c("date", "species", "site"),
    recorder_schema_required = FALSE) {

  stage <- match.arg(stage)
  config <- config::get()

  resolve_path <- function(path) {
    if (is.null(path) || !nzchar(path)) {
      return(path)
    }

    if (file.exists(path)) {
      return(path)
    }

    candidate <- file.path(getwd(), path)
    if (file.exists(candidate)) {
      return(candidate)
    }

    path
  }

  assert_exists <- function(path, label) {
    resolved <- resolve_path(path)
    if (!file.exists(resolved)) {
      stop(label, " not found: ", path)
    }
    invisible(resolved)
  }

  do.call(
    rf_verify_data,
    list(
      verbose = verbose,
      check_recorder_schema = check_recorder_schema,
      recorder_schema_cols = recorder_schema_cols,
      recorder_schema_required = recorder_schema_required
    )
  )

  render_files <- list(
    recipients_script = config$recipients_script,
    data_script = config$data_script,
    focal_filter_script = config$focal_filter_script,
    recipient_select_script = config$recipient_select_script,
    computation_script_bg = config$computation_script_bg,
    computation_script_focal = config$computation_script_focal,
    content_template_file = config$content_template_file,
    html_template_file = config$html_template_file,
    email_format = config$email_format
  )

  for (nm in names(render_files)) {
    assert_exists(render_files[[nm]], nm)
  }

  if (identical(stage, "dispatch")) {
    if (is.null(batch_id) || !nzchar(batch_id)) {
      stop("batch_id is required for dispatch preflight")
    }

    rf_verify_batch(batch_id = batch_id, verbose = verbose)

    if (is.null(config$mail_port) || is.na(as.integer(config$mail_port))) {
      stop("mail_port must be a valid integer")
    }

    if (is.null(config$mail_sender) || !nzchar(as.character(config$mail_sender))) {
      stop("mail_sender must be configured")
    }

    if (is.null(config$mail_subject) || !nzchar(as.character(config$mail_subject))) {
      stop("mail_subject must be configured")
    }

    if (is.null(config$mail_test_recipient) || !nzchar(as.character(config$mail_test_recipient))) {
      stop("mail_test_recipient must be configured")
    }

    if (identical(config$mail_creds, "envvar")) {
      if (is.null(config$mail_username) || !nzchar(as.character(config$mail_username))) {
        stop("mail_username must be configured when mail_creds = 'envvar'")
      }
      if (is.null(config$mail_password) || !nzchar(as.character(config$mail_password))) {
        stop("mail_password must be configured when mail_creds = 'envvar'")
      }
    }

    if (is.null(config$mail_server) || !nzchar(as.character(config$mail_server))) {
      warning("mail_server is empty; dispatch may fail without a valid SMTP server")
    }
  }

  if (verbose) {
    message("Preflight complete for stage: ", stage)
  }

  invisible(TRUE)
}
