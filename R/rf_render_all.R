#' Render feedback content for all recipients
#'
#' Generates personalized feedback documents for each recipient.
#'
#' @param batch_id Character. Identifier for the batch.
#'   Recipient selection can be customised in config.yml via recipient_select_script.
#' @return Invisible
#' @export
rf_render_all <- function(batch_id){

  start_wd <- getwd()
  on.exit({
    Sys.unsetenv("BATCH_ID")
    Sys.unsetenv("RECIPIENT_SELECTION_FILE")
    setwd(start_wd)
  }, add = TRUE)

  selection_file <- rf_prepare_recipient_selection(batch_id)

  Sys.setenv(BATCH_ID = batch_id) # Set an environment variable in R for the batch code
  Sys.setenv(RECIPIENT_SELECTION_FILE = selection_file)
  # Use current session to ensure the active package code is used consistently.
  targets::tar_make(callr_function = NULL) # run the pipeline

  errors <- targets::tar_meta(fields = "error", complete_only = TRUE)

  if(nrow(errors)>0){
    for (i in seq_len(nrow(errors))){
      warning("Target ",errors$name[i]," errored with message: ",errors$error[i])
    }
  }


  invisible(TRUE)
}
