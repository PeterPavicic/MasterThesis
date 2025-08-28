if (!require(knitr)) install.packages("knitr")
if (!require(kableExtra)) install.packages("kableExtra")
if (!require(modelsummary)) install.packages("modelsummary")

library(knitr)
library(kableExtra)
library(modelsummary)


# data missing from later load statement
load("FOMC_which_lags_which_MISSING_granger_results_1_min.RData")

PM_cause_ZQ_share_blockwise
ZQ_cause_PM_share_blockwise

eigen_df_missing <- cbind(
  "PM to ZQ" = sapply(PM_cause_ZQ_share_blockwise, function(listObj) listObj$eigen),
  "ZQ to PM" = sapply(ZQ_cause_PM_share_blockwise, function(listObj) listObj$eigen)
)

trace_df_missing <- cbind(
  "PM to ZQ" = sapply(PM_cause_ZQ_share_blockwise, function(listObj) listObj$trace),
  "ZQ to PM" = sapply(ZQ_cause_PM_share_blockwise, function(listObj) listObj$trace)
)

missingMonths <- rownames(eigen_df_missing) 


load("./FOMC_which_lags_which_granger_results_1_min.RData")
load("./FOMC_POOLED_which_lags_which_granger_results_1_min.RData")
# load("src/analysis/fomc/FOMC_granger_results_5_min_no_monday.RData")
# load("FOMC_granger_results_1_min.RData")
# load("FOMC_granger_results_5_min.RData")

options(scipen = 9999)

meetingMonthsFormatted <- format(as.Date(paste0(meetingMonths, "-01")), "%Y %B")

get_significance_stars <- function(p_value) {
  if (p_value == "None") "None"
  else {
    p_value <- as.numeric(p_value)

    stars <- ifelse(
      0.1 < p_value,
      " ",
      ifelse(
        0.05 < p_value,
        ".",
        ifelse(
          0.01 < p_value,
          "*",
          ifelse(
            0.001 < p_value,
            "**",
            "***"
          )
        )
      )
    )

    stars
  }
}

# --- Blockwise ---
PM_cause_ZQ_share_blockwise
ZQ_cause_PM_share_blockwise

eigen_df <- cbind(
  "PM to ZQ" = PM_cause_ZQ_share_blockwise$eigen,
  "ZQ to PM" = ZQ_cause_PM_share_blockwise$eigen
)

# trace_df <- cbind(
#   "PM to ZQ" = sapply(PM_cause_ZQ_share_blockwise, function(listObj) listObj$trace),
#   "ZQ to PM" = sapply(ZQ_cause_PM_share_blockwise, function(listObj) listObj$trace)
# )

eigen_df[missingMonths, ] <- eigen_df_missing
# trace_df[missingMonths, ] <- trace_df_missing


# rownames(eigen_df) <- meetingMonthsFormatted
# rownames(trace_df) <- meetingMonthsFormatted

# colnames(eigen_df) <- c("PM --> ZQ", "ZQ --> PM")
# colnames(trace_df) <- c("PM --> ZQ", "ZQ --> PM")

# eigen_df
# trace_df

first_df <- datasummary_df(
  data.frame(name = "Pooled dataset", eigen_df),
  output = "latex",
  align = "lll",
  title = "Which lags which eigen findings",
  fmt = 4
)

# # options("modelsummary_format_numeric_latex" = "plain")
# second_df <- datasummary_df(
#   data.frame(name = meetingMonthsFormatted, trace_df),
#   output = "latex",
#   align = "lll",
#   title = "Which lags which trace findings",
#   fmt = 4
# )

toCopy <- paste0(
  "\n\n% which lags which eigen\n",
  as.character(first_df)
  # "\n\n% which lags which trace\n",
  # as.character(second_df)
)

system2(
  "wl-copy",
  input = toCopy
)



