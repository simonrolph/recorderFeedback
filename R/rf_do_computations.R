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
  computed_objects <- compute_objects(records_data)

  computed_objects
}
