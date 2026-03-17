#' Perform computations on data
#'
#' Runs user-defined computations on the raw data prior to rendering.
#'
#' @param computation_script Character. Path to computation script
#' @param records_data Data frame of data
#' @return Computed data object.
#' @export
rf_do_computations <- function(computation_script,records_data){

  source(computation_script)
  if (!exists("compute_objects", mode = "function", inherits = TRUE)) {
    stop("Function 'compute_objects' not found after sourcing computation script: ", computation_script)
  }
  compute_objects_fn <- get("compute_objects", mode = "function", inherits = TRUE)
  computed_objects <- compute_objects_fn(records_data)

  computed_objects
}
