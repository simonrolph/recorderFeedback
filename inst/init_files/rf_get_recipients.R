# get_recipients.R
# A script for getting recipients

# Script function: This script is used to load recipients and save it to the `recipients_file` location specified in config.yml 
# This basic example reads a CSV file from the data attached to recorderFeedback and writes it to the recipients_file location specified in config.yml.
# This script is called by rf_get_recipients() function in the package if it is the recipients_script specificed in config.yml
# For customisation you can either edit this script or create a new one in the in the R/scripts directory and specify it as the recipients_script in config.yml

# You can use the 'extras' folder for supplementary files such as SQL files. By default the extras folder will be git ignored, on the basis that you might use it to contain information about connections to databases

#Here is a minimal example script which loads example data stored within the package. It has the following steps:
# 1. Load the configuration from the package. 
#    If you are getting data from a database with authentication you can either add variables to the config or use an .Renviron file to store the credentials.
#
# 2. Get the data from a CSV file included in the package. Here you can replace this with any data retrieval method, such as querying a database or reading from an API.
#    You can also use the `extras` folder to store SQL files or other scripts that you might need to run to get the data.
#    For example, if you are using a database, you can use the `DBI` package to connect to the database and retrieve the data.
#    For example, if you are using an API, you can use the `httr` package to make API calls and retrieve the data.
#
# 3. Write the data to the location specified in the configuration

# 1. Load the configuration
config <- config::get()

# 2. Get the data
path <- system.file("extdata", "example_recipients.csv", package = "recorderFeedback")
df <- read.csv(path)

# 3. Write the data
write.csv(df,config$recipients_file,row.names = F)
