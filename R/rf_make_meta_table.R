#' Create meta table for feedback batch
#'
#' Generates a summary table of feedback files and recipients, and writes it to disk.
#'
#' @param x A list or data frame of feedback results to summarize.
#' @param batch_id Character. Identifier for the feedback batch.
#' @param recipient_data Data frame. Recipient information to join.
#' @return Character. Path to the written meta table CSV file.
#' @export
rf_make_meta_table <- function(x,batch_id,recipient_data){
  file_name <- paste0("renders/",batch_id,"/meta_table.csv")

  x <- dplyr::bind_rows(x)
  x <- left_join(x,recipient_data,by = "recipient_id")
  x$batch_id <- batch_id
  write.csv(x, file_name,row.names = F)

  file_name
}
