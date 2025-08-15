# TODO: Move this into data_processing
library(dplyr)
library(tibble)
library(tidyr)
library(lubridate)

# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 
load("./FOMC_Granger_Causality.RData")


