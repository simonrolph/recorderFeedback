#get_recipients.R

# you can use the 'extras' folder for supplementary files such as SQL files. By default the extras folder will be git ignored, on the basis that you might use it to contain information about connections to databases

#Here is a minimal example script which loads example recipients stored within the package
config <- config::get()
path <- system.file("extdata", "example_recipients.csv", package = "recorderFeedback")
df <- read.csv(path)
write.csv(df,config$recipients_file,row.names = F)
