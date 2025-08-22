# run_pipeline.R
# A script to run the recorderFeedback pipeline
# This script is used to run the entire recorderFeedback pipeline, from getting recipients and data to dispatching emails.
# Source this script to run the pipeline, or run each step individually as needed.
# Use Rscript run_pipeline.R to run this script from the command line.
# CRON jobs could also be set up to run this script at regular intervals.

#load the recorderFeedback package
library(recorderFeedback)

#get the configuration
config <- config::get()

#get recipients
rf_get_recipients()

#get data
rf_get_data()

#verify the data is all good
rf_verify_data(T)

# run the pipeline
batch_id <- paste0("batch-",Sys.Date())
rf_render_all(batch_id)

#verify the batch
rf_verify_batch(batch_id)

#view content
#rf_view_content(batch_id = batch_id,recipient_id = 3)

#send the emails
rf_dispatch_smtp(batch_id)
