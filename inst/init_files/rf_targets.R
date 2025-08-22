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

tar_option_set(packages = c("dplyr", "ggplot2","rmarkdown","tidyr","lubridate"))



#read in data files
#get configuration from config.yml
config <- config::get()
recipients <- read.csv(config$recipients_file) #recipients data
data_file <- read.csv(config$data_file) #raw species data

#load the filtering script to load in focal_filter()
tar_source(config$focal_filter_script)
#load the email_format() used in rf_render_content() into environment
tar_source(config$email_format.R)

#assertions to ensure the data is all there
library(assertr)
recipients |> verify(has_all_names("recipient_id", "name", "email"))
data_file |> verify(has_all_names("recipient_id"))

#set up static branching by user
names(recipients) <- paste0(names(recipients),"_") #apply an underscore to after the name to differentiate it
values <- recipients #values for static branching

# mapping for static branching
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
                                  extra_params = recipients_target %>% filter(recipient_id == recipient_id_) %>% select(-name,-email)),
               recipient_id = recipient_id_,
               batch_id = batch_id,
               email_format = email_format,
               template_html = html_template_file
             ),
             format="file",
             error = "null"), # create the content as html

  tar_target(meta_data,list(recipient_id = recipient_id_,file = data_story_content,content_key = recipient_objects$content_key))
)

# construct pipeline
list(
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

  #carry out the computations on the whole dataset
  tar_target(bg_computed_objects,rf_do_computations(computation = computation_file, records_data=raw_data)),

  #do jobs across all recipients
  mapping,

  #create a dataframe of recipients and their email files
  tar_combine(meta_table,
              mapping$meta_data,
              command = rf_make_meta_table(list(!!!.x),batch_id,recipients_target),
              use_names = T,
              format="file"
  )
)


