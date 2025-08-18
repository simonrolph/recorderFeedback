# This function computes objects from the provided data.
# It could be applied to the background data or focal data or both, depending on what is specified in the config.yml for computation_script_bg and compuation_script_focal.
#
# This script MUST define a function named `compute_objects`.
# The function's first argument MUST be the argument `data`, which will be be a the focal or background data.
# The function MUST return a named list of computed objects.
# Otherwise do whatever you want in this script.
# There is no constraints on what the computed objects are:
# they can be any R objects, such as data frames, vectors, lists, plots, etc.
#
# For customisation you can either edit this script or create a new one in the in the R/scripts directory and specify it as the computation_script_bg/focal in configuration.
#
# Included is a very simple example of a computation function that counts the number of rows in the data:
compute_objects <- function(data){
  # example computation: count the number of rows in the data
  # This is just a placeholder; you can replace it with your actual computation logic.
  list(nrows = nrow(data))
}
