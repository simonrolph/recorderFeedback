#' Render feedback for a single recipient
#'
#' Generates feedback for one recipient using their data.
#'
#' @param recipient_id Integer or character. ID of the recipient.
#' @param view Logical. Whether to show the content in the viewer.
#' @return Path to rendered file.
#' @export
rf_render_single <- function(recipient_id,view = F){

  config <- config::get()
  batch_id <- "singles"
  dir.create("renders/singles",showWarnings = F)
  source("templates/email_format.R")
  source("scripts/focal_filter.R")

  if (!exists("email_format", mode = "function", inherits = TRUE)) {
    stop("Function 'email_format' not found after sourcing templates/email_format.R")
  }
  email_format_fn <- get("email_format", mode = "function", inherits = TRUE)

  if (!exists("focal_filter", mode = "function", inherits = TRUE)) {
    stop("Function 'focal_filter' not found after sourcing scripts/focal_filter.R")
  }
  focal_filter_fn <- get("focal_filter", mode = "function", inherits = TRUE)

  recipients <- read.csv(config$recipients_file)
  recipient <- recipients[recipients$recipient_id==recipient_id,]

  bg_data <- read.csv(config$data_file)
  bg_computed_objects = rf_do_computations(computation_script = config$computation_script_bg, bg_data)

  focal_data = focal_filter_fn(bg_data,recipient_id)
  focal_computed_objects = rf_do_computations(computation_script = config$computation_script_focal, focal_data)
  content_key = paste0(batch_id,paste0(sample(c(1:9,letters),16,replace = T),collapse=""))


  params <- list(recipient_name = recipient$name,
       recipient_email = recipient$email,
       focal_data = focal_data,
       focal_computed_objects = focal_computed_objects,
       bg_data = bg_data,
       bg_computed_objects = bg_computed_objects,
       content_key = content_key,
       config = config,
      extra_params = recipient[, setdiff(names(recipient), c("name", "email")), drop = FALSE])

  rendered_file <- rf_render_content(
    template_file = config$content_template_file,
    params,
    recipient_id = recipient_id,
    batch_id = batch_id,
    email_format = email_format_fn,
    template_html = file.path(getwd(),config$html_template_file)
  )

  # Open in default browser or RStudio viewer
  if(view==T){
    utils::browseURL(rendered_file)
  }


  rendered_file
}
