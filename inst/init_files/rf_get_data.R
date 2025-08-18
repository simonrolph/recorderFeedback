# get_data.R
# A script for getting records data

# Script function: This script is used to load data and save it to the `data_file` location specified in the package's configuration. 
# This basic example reads a CSV file from the data attached to recorderFeedback and writes it to the data
# This script is called by rf_get_data() function in the package if it is the data_script specificed in the package configuration.
# For customisation you can either edit this script or create a new one in the in the R/scripts directory and specify it as the data_file in package configuration.

# You can use the 'extras' folder for supplementary files such as SQL files. By default the extras folder will be git ignored, on the basis that you might use it to contain information about connections to databases

#Here is a minimal example script which loads example data stored within the package. It has the following steps:
# 1. Load the configuration from the package. 
#    If you are getting data from a database with authentication you can either add variables to the config or use an .Renviron file to store the credentials.
#
# 2. Get the data from an external source (in this case a CSV file included in the package). 
#    Here you can replace this with any data retrieval method, such as querying a database or reading from an API.
#    You can also use the `extras` folder to store SQL files or other scripts that you might need to run to get the data.
#    For example, if you are using a database, you can use the `DBI` package to connect to the database and retrieve the data.
#    For example, if you are using an API, you can use the `httr` package to make API calls and retrieve the data.
#    You could also load the recipient data using config$recipients_file, for example if you want to query a database for the data of each recipients.
#
# 3. Write the data to the location specified in the configuration

# 1. Load the configuration
config <- config::get()

# 2. Get the data
path <- system.file("extdata", "example_data.csv", package = "recorderFeedback")
df <- read.csv(path)

# 3. Write the data
write.csv(df,config$data_file,row.names = F)
