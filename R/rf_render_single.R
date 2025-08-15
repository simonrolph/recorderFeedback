#' Render feedback for a single recipient
#'
#' Generates feedback for one recipient using their data.
#'
#' @param recipient_id Integer or character. ID of the recipient.
#' @return Path to rendered file.
#' @export
rf_render_single <- function(recipient_id){

  config <- config::get()
  batch_id <- "singles"
  dir.create("renders/singles",showWarnings = F)
  source("templates/email_format.R")

  recipients <- read.csv(config$recipients_file)
  recipient <- recipients[recipients$recipient_id==recipient_id,]

  bg_data <- read.csv(config$data_file)
  bg_computed_objects = rf_do_computations(computation = config$computation_script_bg,bg_data)

  r_id<- recipient_id
  focal_data = dplyr::filter(bg_data,recipient_id == r_id)
  focal_computed_objects = rf_do_computations(computation = config$computation_script_focal,focal_data)
  content_key = paste0(batch_id,paste0(sample(c(1:9,letters),16,replace = T),collapse=""))

  params <- list(recipient_name = recipient$name,
       recipient_email = recipient$email,
       focal_data = focal_data,
       focal_computed_objects = focal_computed_objects,
       bg_data = bg_data,
       bg_computed_objects = bg_computed_objects,
       content_key = content_key,
       config = config,
       extra_params = dplyr::select(recipient,-name,-email))

  rf_render_content(
    template_file = config$content_template_file,
    params,
    recipient_id = recipient_id,
    batch_id = batch_id,
    template_html = file.path(getwd(),config$html_template_file)
  )
}
