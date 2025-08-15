library(dplyr)
library(tibble)
library(tidyr)

# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 
load("./FOMC_Granger_Causality.RData")

# TODO: 
# Match ZQ estimates with PM estimates
# Figure out how to perform Granger causality test


ZQ_IP_unfiltered <- ZQ_Implied_Probs
rm(ZQ_Implied_Probs)

# TODO: Make both IP vars contain data that is also filtered for time 
# (match time, PM_data should have reasonable unscaled_sum)
# PM_IP should not contain unscaled_sum anymore
# Also move this part to FOMC_ZQ_PM_comparison.R

for (meetingName in meetings$meetingMonth) { 

  ZQ_df_unfiltered <- ZQ_IP_unfiltered[[meetingName]]
  ZQ_df_filtered <- ZQ_df_unfiltered |>
    select(time, all_of(assetNames))

  ZQ_IP_filtered
}

range(ZQ_data$`2024-09`$time)
range(PM_data_unscaled$`2024-09`$time)
range(ZQ_Implied_Probs$`2024-09`$time)




