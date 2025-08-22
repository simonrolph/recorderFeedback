#' Filter focal data for a given recipient
#'
#' This function extracts a subset of the provided dataset (`all_data`) that
#' corresponds to a specific recipient, identified by `recipient_id`.
#'
#' The function first looks up the recipient information in a recipient
#' configuration file (defined in `config::get()$recipients_file`). By default,
#' the filtering is performed on `recipient_id`, but the logic can be easily
#' adapted to filter on another field that exists in both `all_data` and the
#' recipient configuration file (e.g., `activity_id`).
#'
#' @param all_data A `data.frame` or tibble containing the complete dataset,
#'   with at least one column named `recipient_id`.
#' @param recipient_id A scalar value (numeric, character, or factor) that
#'   uniquely identifies the recipient of interest.
#'
#' @return A `data.frame` (or tibble) containing only the rows from
#'   `all_data` that match the given recipient's identifier.
#'
#' @details
#' The function works as follows:
#' 1. Retrieves configuration values using `config::get()`.
#' 2. Reads the recipient metadata from the CSV file specified in
#'    `config$recipients_file`.
#' 3. Filters the metadata to isolate the row corresponding to the given
#'    `recipient_id`.
#' 4. Filters `all_data` to return only the rows matching the selected
#'    recipient.
#'
#' Alternative filtering criteria can be enabled by modifying the `dplyr::filter`
#' call (e.g., by `activity_id`).
#'
#'
focal_filter <- function(all_data, recipient_id) {
  # get the recipient

  r_id <- recipient_id
  config <- config::get()
  recipients <- read.csv(config$recipients_file)
  recipient <- recipients[recipients$recipient_id==r_id,]

  # default: filter by recipient_id
  focal_data <- dplyr::filter(all_data, recipient_id == recipient$recipient_id)

  # alternative: filter by another column such as activity_id
  # focal_data <- dplyr::filter(all_data, activity_id == recipient$activity_id)
  # or even you could do some spatial filtering at this stage

  focal_data
}
