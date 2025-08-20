#' Verify a render batch
#'
#' Checks that the rendered items match the recipient data and meta table.
#'
#' @param verbose Logical, if TRUE prints summary info.
#' @return Invisible TRUE if all checks pass, otherwise stops or warns.
#' @export
rf_verify_batch <- function(batch_id,verbose = FALSE) {
  config <- config::get()

  # --- Load Recipient Data ---
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


  meta_table_file <- file.path("renders",batch_id,"meta_table.csv")
  # --- Load Meta Table ---
  if (!file.exists(meta_table_file)) {
    stop("Meta table file not found: ", meta_table_file)
  }

  meta_table <- tryCatch(
    read.csv(meta_table_file, stringsAsFactors = FALSE),
    error = function(e) stop("Unable to read meta table file: ", e$message)
  )

  required_meta_cols <- c("recipient_id", "file")
  missing_meta_cols <- setdiff(required_meta_cols, colnames(meta_table))
  if (length(missing_meta_cols) > 0) {
    stop("Meta table is missing required columns: ", paste(missing_meta_cols, collapse = ", "))
  }

  # check for failed renders
  failed_renders <- meta_table[is.na(meta_table$file),]
  if (nrow(failed_renders)>0){
    stop("These recipient_ids have failed renders: ", paste(failed_renders$recipient_id, collapse = ", "))
  }

  # --- Check Recipient IDs Match Meta Table ---
  missing_in_meta <- setdiff(recipients$recipient_id, meta_table$recipient_id)
  if (length(missing_in_meta) > 0) {
    warning("These recipient_ids are missing in meta_table: ", paste(missing_in_meta, collapse = ", "))
  }

  missing_in_recip <- setdiff(meta_table$recipient_id, recipients$recipient_id)
  if (length(missing_in_recip) > 0) {
    warning("These recipient_ids are in meta_table but not in recipients: ", paste(missing_in_recip, collapse = ", "))
  }

  # --- Check Rendered Files Exist ---
  missing_files <- meta_table$file[!file.exists(meta_table$file)]
  if (length(missing_files) > 0) {
    warning("The following rendered files are missing: ", paste(missing_files, collapse = ", "))
  }

  # --- Verbose Output ---
  if (verbose) {
    message("Number of recipients: ", nrow(recipients))
    message("Number of entries in meta_table: ", nrow(meta_table))
    message("Number of missing render files: ", length(missing_files))
  }

  message("Batch verification complete: no blocking errors found.")
  invisible(TRUE)
}
