library(targets)
library(tarchetypes)
library(recorderFeedback)


#batch identifier
batch_id <- Sys.getenv("BATCH_ID")
if (batch_id == ""){
  batch_id <- "test"
}

# (Optional) Distributed computing set up:
# library(crew)
# tar_option_set(
#   controller = crew_controller_local(workers = 4),
# )

tar_option_set(packages = c("ggplot2","rmarkdown","tidyr","lubridate"))



#read in data files
#get configuration from config.yml
config <- config::get()
recipients <- read.csv(config$recipients_file, stringsAsFactors = FALSE) #recipients data
data_file <- read.csv(config$data_file, stringsAsFactors = FALSE) #raw species data

selection_info_file <- Sys.getenv("RECIPIENT_SELECTION_FILE")
if (selection_info_file != "" && file.exists(selection_info_file)) {
  selection_info <- read.csv(selection_info_file, stringsAsFactors = FALSE)
} else {
  selection_info <- recorderFeedback:::rf_default_recipient_selection(recipients)
  selection_info_file <- recorderFeedback:::rf_selection_file(batch_id)
  dir.create(dirname(selection_info_file), recursive = TRUE, showWarnings = FALSE)
  write.csv(selection_info, selection_info_file, row.names = FALSE)
}

selected_recipients <- recipients[
  recipients$recipient_id %in% selection_info$recipient_id[selection_info$selected],
  ,
  drop = FALSE
]

#load the filtering script to load in focal_filter()
tar_source(config$focal_filter_script)
#load the email_format() used in rf_render_content() into environment
tar_source(config$email_format)

#assertions to ensure the data is all there
library(assertr)
recipients |> verify(has_all_names("recipient_id", "name", "email"))
data_file |> verify(has_all_names("recipient_id"))
selection_info |> verify(has_all_names("recipient_id", "selected", "skip_reason"))

#set up static branching by user
names(selected_recipients) <- paste0(names(selected_recipients),"_") #apply an underscore to after the name to differentiate it
values <- selected_recipients #values for static branching

if (nrow(values) > 0) {
  mapping <- tar_map(
    values = values,
    names = recipient_id_,

    tar_target(
      recipient_objects,
      list(
        focal_data = focal_filter(raw_data,recipient_id = recipient_id_), #generate a df for the user's recording activity
        focal_computed_objects = rf_do_computations(computation = computation_file_focal, records_data=focal_filter(raw_data,recipient_id = recipient_id_)), #do any computations on the user data
        content_key = paste0(batch_id,paste0(sample(c(1:9,letters),16,replace = T),collapse="")) # generate a content_key
      )
    ),

    #render the content
    tar_target(data_story_content,
               rf_render_content(
                 template_file = template_file,
                 recipient_params = list(recipient_name = name_,
                                    recipient_email = email_,
                                    focal_data = recipient_objects$focal_data,
                                    focal_computed_objects = recipient_objects$focal_computed_objects,
                                    bg_data = raw_data,
                                    bg_computed_objects = bg_computed_objects,
                                    content_key = recipient_objects$content_key,
                                    config = config,
                                    extra_params = recipients_target[
                                      recipients_target$recipient_id == recipient_id_,
                                      setdiff(names(recipients_target), c("name", "email")),
                                      drop = FALSE
                                    ]),
                 recipient_id = recipient_id_,
                 batch_id = batch_id,
                 email_format = email_format,
                 template_html = html_template_file
               ),
               format="file",
               error = "null"), # create the content as html

    tar_target(
      meta_data,
      list(
        recipient_id = recipient_id_,
        file = if (length(data_story_content) == 0) NA_character_ else data_story_content,
        content_key = recipient_objects$content_key,
        render_status = if (length(data_story_content) == 0) "failed" else "rendered",
        skip_reason = NA_character_
      )
    )
  )
}

# construct pipeline
base_pipeline <- list(
  #this links to the full (all records) data file
  tar_target(raw_data_file, config$data_file, format = "file"),

  #this links to the email template file, an R markdown file
  tar_target(template_file,paste0(getwd(),"/",config$content_template_file), format = "file"),

  #this links to the html template file
  tar_target(html_template_file,paste0(getwd(),"/",config$html_template_file), format = "file"),

  #this links to the computation file applied to all data
  tar_target(computation_file,config$computation_script_bg, format = "file"),

  #this links to the computation script that is applied to the user (this might be the same as the script above)
  tar_target(computation_file_focal,config$computation_script_focal, format = "file"),

  #reading in the raw data to R object
  tar_target(raw_data, read.csv(raw_data_file)),

  #reading in the recipients data to R object
  tar_target(recipients_file, config$recipients_file,format = "file"),
  tar_target(recipients_target, read.csv(recipients_file)),
  tar_target(recipient_selection_info_file, selection_info_file, format = "file"),
  tar_target(recipient_selection_target, read.csv(recipient_selection_info_file)),

  #carry out the computations on the whole dataset
  tar_target(bg_computed_objects,rf_do_computations(computation = computation_file, records_data=raw_data))
)

if (nrow(values) > 0) {
  c(
    base_pipeline,
    mapping,
    list(
      tar_combine(meta_table,
                  mapping$meta_data,
                  command = rf_make_meta_table(list(!!!.x),batch_id,recipients_target,recipient_selection_target),
                  use_names = T,
                  format="file"
      )
    )
  )
} else {
  c(
    base_pipeline,
    list(
      tar_target(
        meta_table,
        rf_make_meta_table(list(), batch_id, recipients_target, recipient_selection_target),
        format = "file"
      )
    )
  )
}


