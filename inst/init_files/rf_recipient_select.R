# This script is called by rf_render_all() if it is the recipient_select_script
# specified in config.yml.
#
# Define recipient_select(recipients, data, config) to choose which recipients
# are rendered in a batch. The function can return:
# - NULL to select all recipients
# - a logical vector the same length as recipients
# - a vector of recipient_id values to include
# - a data.frame with recipient_id, selected, and optional skip_reason columns

recipient_select <- function(recipients, data, config) {
  data.frame(
    recipient_id = recipients$recipient_id,
    selected = TRUE,
    skip_reason = NA_character_,
    stringsAsFactors = FALSE
  )
}