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

  errors <- targets::tar_meta(fields = error, complete_only = TRUE)

  if(nrow(errors)>0){
    for (i in 1:nrow(errors)){
      warning("Target ",errors$name[i]," errored with message: ",errors$error[i])
    }
  }


  invisible(TRUE)
}
