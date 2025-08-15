#' Verify data and recipient files
#'
#' Checks that the raw data file and recipient file exist, are readable,
#' contain the required columns, and optionally prints summary info.
#'
#' @param verbose Logical, if TRUE prints number of records and recipients.
#' @return Invisible TRUE if all checks pass, otherwise stops with an error.
#' @export
rf_verify_data <- function(verbose = FALSE) {
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
