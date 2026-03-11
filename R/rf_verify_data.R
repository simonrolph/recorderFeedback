#' Verify data and recipient files
#'
#' Checks that the raw data file and recipient file exist, are readable,
#' contain required columns, validates recipient IDs and emails,
#' and can optionally check recorder-analytics schema columns.
#'
#' @param verbose Logical, if TRUE prints number of records and recipients.
#' @param check_recorder_schema Logical. If TRUE, validate recorder schema columns.
#' @param recorder_schema_cols Character vector of optional recorder schema columns.
#'   Defaults to c("date", "species", "site").
#' @param recorder_schema_required Logical. If TRUE, missing recorder schema columns
#'   are treated as errors. If FALSE, missing columns trigger warnings.
#' @return Invisible TRUE if all checks pass, otherwise stops with an error.
#' @export
rf_verify_data <- function(
    verbose = FALSE,
    check_recorder_schema = FALSE,
    recorder_schema_cols = c("date", "species", "site"),
    recorder_schema_required = FALSE) {
  config <- config::get()

  # --- Check Data File ---
  if (!file.exists(config$data_file)) {
    stop("Data file not found: ", config$data_file)
  }

  data <- tryCatch(
    read.csv(config$data_file, stringsAsFactors = FALSE),
    error = function(e) stop("Unable to read data file: ", e$message)
  )

  required_data_cols <- c("recipient_id") # add more if needed
  missing_data_cols <- setdiff(required_data_cols, colnames(data))
  if (length(missing_data_cols) > 0) {
    stop("Data file is missing required columns: ", paste(missing_data_cols, collapse = ", "))
  }

  # --- Check Recipients File ---
  if (!file.exists(config$recipients_file)) {
    stop("Recipients file not found: ", config$recipients_file)
  }

  recipients <- tryCatch(
    read.csv(config$recipients_file, stringsAsFactors = FALSE),
    error = function(e) stop("Unable to read recipients file: ", e$message)
  )

  required_recip_cols <- c("recipient_id", "name", "email")
  missing_recip_cols <- setdiff(required_recip_cols, colnames(recipients))
  if (length(missing_recip_cols) > 0) {
    stop("Recipients file is missing required columns: ", paste(missing_recip_cols, collapse = ", "))
  }

  # --- Check Duplicate Recipient IDs ---
  duplicated_ids <- unique(recipients$recipient_id[duplicated(recipients$recipient_id)])
  if (length(duplicated_ids) > 0) {
    stop(
      "Duplicate recipient_id values found in recipients file: ",
      paste(duplicated_ids, collapse = ", ")
    )
  }

  # --- Check Email Quality ---
  email_values <- trimws(as.character(recipients$email))
  missing_email <- is.na(email_values) | email_values == ""
  if (any(missing_email)) {
    stop(
      "Missing email values found for recipient_id(s): ",
      paste(recipients$recipient_id[missing_email], collapse = ", ")
    )
  }

  email_pattern <- "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  invalid_email <- !grepl(email_pattern, email_values)
  if (any(invalid_email)) {
    stop(
      "Invalid email format for recipient_id(s): ",
      paste(recipients$recipient_id[invalid_email], collapse = ", ")
    )
  }

  # --- Optional recorder schema checks ---
  if (isTRUE(check_recorder_schema)) {
    missing_schema_cols <- setdiff(recorder_schema_cols, colnames(data))
    if (length(missing_schema_cols) > 0) {
      msg <- paste(
        "Data file is missing optional recorder schema columns:",
        paste(missing_schema_cols, collapse = ", ")
      )

      if (isTRUE(recorder_schema_required)) {
        stop(msg)
      } else {
        warning(msg)
      }
    }
  }

  # --- Check Matching IDs ---
  missing_in_data <- setdiff(recipients$recipient_id, data$recipient_id)
  if (length(missing_in_data) > 0) {
    warning("The following recipient_ids are in recipients file but not in data file: ",
            paste(missing_in_data, collapse = ", "))
  }

  missing_in_recip <- setdiff(data$recipient_id, recipients$recipient_id)
  if (length(missing_in_recip) > 0) {
    warning("The following recipient_ids are in data file but not in recipients file: ",
            paste(missing_in_recip, collapse = ", "))
  }

  # --- Verbose Output ---
  if (verbose) {
    message("Number of data records: ", nrow(data))
    message("Number of recipients: ", nrow(recipients))
  }

  message("Data and recipients verification complete: no blocking errors found.")
  invisible(TRUE)
}
