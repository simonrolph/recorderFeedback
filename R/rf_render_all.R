#' Render feedback content for all recipients
#'
#' Generates personalized feedback documents for each recipient.
#'
#' @param batch_id Character. Identifier for the batch.
#' @return Invisible
#' @export
rf_render_all <- function(batch_id){

  start_wd <- getwd()
  on.exit({
    Sys.unsetenv("BATCH_ID")
    setwd(start_wd)
  }, add = TRUE)

  Sys.setenv(BATCH_ID = batch_id) # Set an environment variable in R for the batch code
  # Use current session to ensure the active package code is used consistently.
  targets::tar_make(callr_function = NULL) # run the pipeline

  errors <- targets::tar_meta(fields = error, complete_only = TRUE)

  if(nrow(errors)>0){
    for (i in 1:nrow(errors)){
      warning("Target ",errors$name[i]," errored with message: ",errors$error[i])
    }
  }


  invisible(TRUE)
}
