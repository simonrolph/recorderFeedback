#' Load recipient data
#'
#' Loads or updates the recipients file as specified in the config.
#'
#' @return Invisible
#' @export
rf_get_recipients <- function(){
  config <- config::get()
  source(config$recipients_script)

  # check that records have been updated
  if(difftime(file.info(config$recipients_file)$mtime,Sys.time(),units = "secs") < 5){
    message("Recipient file has been updated")
  } else {
    stop("Recipient file has not been updated, check for issue in gather script")
  }

  invisible(TRUE)
}
