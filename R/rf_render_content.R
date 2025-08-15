#' Render feedback content for all recipients
#'
#' Generates personalized feedback documents for each recipient.
#'
#' @param template_file Character. RMarkdown file for template
#' @param recipient_params List. Parameters for the recipient
#' @param recipient_id Character. Identifier for the batch.
#' @param batch_id Character. Identifier for the batch.
#' @param template_html Character. Template file for template
#' @return Path to rendered file.
#' @export
rf_render_content <- function(template_file,recipient_params,recipient_id,batch_id,template_html){

  # build a unique file name
  filename <- basename(template_file) # Use basename to get the filename with extension
  filename <- sub("\\.\\w+$", "", filename) # Use regex to extract filename without extension
  out_file <- paste0(filename,"_",recipient_id,"_",Sys.Date(),".html")

  #check that all required computed objects are provided within recipient_params
  required_objects <- rf_look_for_computed_objects(template_file)
  #background
  if(!is.null(required_objects$bg_computed_objects) & any(!(required_objects$bg_computed_objects %in% (names(recipient_params$bg_computed_objects))))){
    stop(
      paste0(
        "You have specified background precomputed objects in ",
        template_file,
        " but not all required prcomputed objects have been provided in recipient_params$bg_computed_objects. You have provided: \n",
        paste0(names(recipient_params$bg_computed_objects),collapse=", "),
        "\nbut the template requires: \n",
        paste0(required_objects$bg_computed_objects,collapse=", ")
      )
    )
  }

  #user
  if(!is.null(required_objects$focal_computed_objects) & any(!(required_objects$focal_computed_objects %in% (names(recipient_params$focal_computed_objects))))){
    stop(
      paste0(
        "You have specified user precomputed objects in ",
        template_file,
        " but not all required prcomputed objects have been provided in recipient_params$focal_computed_objects. You have provided: \n",
        paste0(names(recipient_params$focal_computed_objects),collapse=", "),
        "\nbut the template requires: \n",
        paste0(required_objects$focal_computed_objects,collapse=", ")
      )
    )
  }

  #set a temp directory for intermediate files in rendering
  temporary_directory <- tempdir() #per session temp directory

  #render the content
  rmarkdown::render(template_file,
         output_file = out_file,
         output_dir = paste0("renders/",batch_id),
         output_format = email_format(template_html=template_html),
         params = recipient_params,
         quiet=T,
         intermediates_dir = temporary_directory,
         knit_root_dir = temporary_directory,
         envir = new.env()
  )

  #delete the temporary director
  unlink(temporary_directory, recursive = TRUE)

  #return the file name as in targets we're using format="file"
  paste0("renders/",batch_id,"/",out_file)
}
