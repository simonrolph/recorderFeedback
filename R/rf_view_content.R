#' View rendered feedback for a recipient
#'
#' Opens the rendered HTML file for a specific recipient and batch in the system's default browser.
#'
#' @param batch_id Character. The feedback batch identifier.
#' @param recipient_id Character or numeric. The recipient's ID.
#' @return Invisible TRUE if file is opened successfully, otherwise stops with an error.
#' @export
rf_view_content <- function(batch_id, recipient_id=NULL) {
  # Path to meta table
  meta_file <- file.path("renders", batch_id, "meta_table.csv")

  if (!file.exists(meta_file)) {
    stop("Meta table not found for batch: ", batch_id)
  }

  # Read meta table
  meta_table <- tryCatch(
    read.csv(meta_file, stringsAsFactors = FALSE),
    error = function(e) stop("Unable to read meta_table: ", e$message)
  )

  # Check required columns
  required_cols <- c("recipient_id", "file")
  missing_cols <- setdiff(required_cols, colnames(meta_table))
  if (length(missing_cols) > 0) {
    stop("meta_table is missing required columns: ", paste(missing_cols, collapse = ", "))
  }


  # Filter for this recipient
  if(!is.null(recipient_id)){
    matches <- meta_table[meta_table$recipient_id %in% recipient_id, ]
  } else {
    matches <- meta_table
  }


  if (nrow(matches) == 0) {
    stop("No rendered content found for recipient_id: ", recipient_id, " in batch: ", batch_id)
  }

  answer <- "Y"
  if(nrow(matches)>30){
    answer <- readline(prompt = paste0("This will open ",nrow(matches),"  webpages, continue? (Y/n): "))
  }

  if (answer == "Y") {
    for(i in 1:nrow(matches)){
      render_file <- matches$file[1]

      if (!file.exists(render_file)) {
        stop("Rendered file does not exist: ", render_file)
      }

      # Open in default browser or RStudio viewer
      utils::browseURL(render_file)
    }
  }

  invisible(TRUE)
}
