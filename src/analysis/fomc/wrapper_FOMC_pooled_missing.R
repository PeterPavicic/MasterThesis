fidelity <- "5 minutes"
excluded_days <- c("Saturday", "Sunday")
output_file = "pooled_gc_5_mins.RData"

source("FOMC_pooled_missing.R")

rm(list = ls())
invisible(gc())

fidelity <- "1 minutes"
excluded_days <- c("Saturday", "Sunday", "Monday")
output_file = "pooled_gc_no_monday_1_min.RData"

source("FOMC_pooled_missing.R")

rm(list = ls())
invisible(gc())

print("Done getting missing data")
