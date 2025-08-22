#' Load raw data
#'
#' Loads or updates the data file as specified in the config.
#'
#' @return Invisible
#' @export
rf_get_data <- function(){
  config <- config::get()
  source(config$data_script, local=attach(NULL))

  # check that records have been updated
  if(difftime(file.info(config$data_file)$mtime,Sys.time(),units = "secs") < 5){
    print("Data file has been updated")
  } else {
    stop("Data file has not been updated, check for issue in gather script")
  }

  invisible(TRUE)
}
