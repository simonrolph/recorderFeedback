#' Render feedback content for all recipients
#'
#' Generates personalized feedback documents for each recipient.
#'
#' @param batch_id Character. Identifier for the batch.
#' @return Invisible
#' @export
rf_render_all <- function(batch_id){

  Sys.setenv(BATCH_ID = batch_id) # Set an environment variable in R for the batch code
  targets::tar_make() # run the pipeline
  Sys.unsetenv("BATCH_ID") #and unset the variable

  invisible(TRUE)
}
