if (!require(dplyr)) install.packages("dplyr")
if (!require(lubridate)) install.packages("lubridate")
if (!require(tibble)) install.packages("tibble")
if (!require(tidyr)) install.packages("tidyr")
if (!require(tseries)) install.packages("tseries")
if (!require(urca)) install.packages("urca")
if (!require(vars)) install.packages("vars")

library(dplyr)
library(lubridate)
library(tibble)
library(tidyr)
library(tseries)
library(urca)
library(vars)

ROOT_DIR <- dirname(dirname(dirname(getwd()))) 
# load("./FOMC_granger_results_1_min.RData")
load("./FOMC_preprocesed.RData")
load("./FOMC_Granger_Causality.RData")

# # handpicked:
# "2023-02" = c(up25, up50)
# "2023-03" = c(noChange, up25)
# "2023-05" = c(noChange, up25)
# "2023-06" = c(down25, noChange)
# "2023-07" = c(noChange, up25)
# "2023-09" = c(noChange, up25)
# "2023-11" = c(noChange, up25)
# "2023-12" = c(noChange, up25)
# "2024-01" = c(down25, noChange)
# "2024-03" = c(down25, noChange)
# "2024-05" = c(down25, noChange)
# "2024-06" = c(noChange, up25)
# "2024-07" = c(down25, noChange)
# "2024-09" = c(down50, down25)
# "2024-11" = c(down25, noChange)
# "2024-12" = c(down25, noChange)
# "2025-01" = c(down25, noChange)
# "2025-03" = c(down25, noChange)
# "2025-05" = c(down25, noChange)
# "2025-06" = c(noChange, up25)
# "2025-07" = c(down25, noChange)

vec2var


running_filter <- meetings |>
  dplyr::select(meetingMonth, meetingTime, data_end) |>
  mutate(
    previousMeeting = lag(meetingTime)
  ) |>
  dplyr::select(meetingMonth, meetingTime, previousMeeting)
  

ZQ_IP_filtered_time <- list()
PM_data_unscaled_filtered_time <- list()
for (meetingName in meetingMonths) {
  meetingTime <- running_filter |>
    filter(meetingMonth == meetingName) |>
    pull(meetingTime)

  if (meetingName == "2023-02") {
    ZQ_IP_filtered_time[[meetingName]] <- ZQ_Implied_Probs[[meetingName]] |>
      filter(time <= meetingTime)
    PM_data_unscaled_filtered_time[[meetingName]] <- PM_data_unscaled[[meetingName]] |>
      filter(time <= meetingTime)
    next
  }

  previous_meetingTime <- running_filter |>
    filter(meetingMonth == meetingName) |>
    pull(previousMeeting)
  
  ZQ_IP_filtered_time[[meetingName]] <- ZQ_Implied_Probs[[meetingName]] |>
    filter(previous_meetingTime < time & time <= meetingTime)

  PM_data_unscaled_filtered_time[[meetingName]] <- PM_data_unscaled[[meetingName]] |>
    filter(previous_meetingTime < time & time <= meetingTime)
}


highest_means <- list()
# highest mean in ZQ IP after previous meeting
for (meetingName in meetingMonths) {
  ZQ_df <- ZQ_IP_filtered_time[[meetingName]]

  sorted_assets <- ZQ_df |>
    select_if(is.numeric)  |> 
    # Apply the max function to each column
    sapply(mean) |>
    sort(decreasing = TRUE) |> 
    names()

  highest_means[[meetingName]] <- sorted_assets[1:2]

  # cat("\nMeeting:", meetingName, "highest mean:", sorted_assets[1:2])

  # print(meetingName)
  # print(highest_means)
}

highest_means

ZQ_IP_filtered <- list()
PM_data_unscaled_filtered <- list()
for (meetingName in meetingMonths) {
  ZQ_IP_df <- ZQ_IP_filtered_time[[meetingName]]
  PM_df <- PM_data_unscaled_filtered_time[[meetingName]]

  ZQ_filtered <- ZQ_IP_df |>
    dplyr::select(time, highest_means[[meetingName]])

  PM_filtered <- PM_df |>
    dplyr::select(time, highest_means[[meetingName]])

  colnames(ZQ_filtered) <- c("time", "asset1", "asset2")
  colnames(PM_filtered) <- c("time", "asset1", "asset2")

  ZQ_IP_filtered[[meetingName]] <- ZQ_filtered
  PM_data_unscaled_filtered[[meetingName]] <- PM_filtered
}

ZQ_running <- do.call(bind_rows, ZQ_IP_filtered)
PM_running <- do.call(bind_rows, PM_data_unscaled_filtered)

rm(
  PM_data,
  PM_data_scaled,
  PM_data_unscaled,
  PM_data_unscaled_filtered,
  PM_data_unscaled_filtered_time,
  PM_df,
  PM_filtered,
  ZQ_IP_df,
  ZQ_IP_filtered,
  ZQ_IP_filtered_time,
  ZQ_Implied_Probs,
  ZQ_data,
  ZQ_df,
  ZQ_filtered,
  highest_means,
  meetingName,
  meetings,
  previous_meetingTime,
  running_filter,
  sorted_assets,
  tokens
)

invisible(gc())

# --------- regular analysis start ---------
# Creating common timegrid
fidelity <- "1 minutes"

fidelity_count <- as.numeric(strsplit(fidelity, " ")[[1]][1])
fidelity_unit <- strsplit(fidelity, " ")[[1]][2]

fidelity_seconds <- fidelity_count * ifelse(
  fidelity_unit == "hours", 3600,
  ifelse(fidelity_unit == "minutes", 60,
    # seconds
    1
  )
)

rm(fidelity_unit, fidelity_count)


# unifying to common timegrid
# vectorised_timeseries
{
  time_grid_start <- max(
    floor_date(min(PM_running$time), fidelity),
    floor_date(min(ZQ_running$time), fidelity)
  )

  time_grid_end <- min(
    ceiling_date(max(PM_running$time), fidelity),
    ceiling_date(max(ZQ_running$time), fidelity)
  )

  time_grid <- tibble(
    timestamp = seq(time_grid_start, time_grid_end, by = fidelity_seconds)
  ) |>
    mutate(
      day_of_week = weekdays(timestamp)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  assetNames <- colnames(PM_running)[!(colnames(PM_running) == "time")]

  PM_aligned <- PM_running |> 
    mutate(
      # rounding "up" (to nearest upper) `fidelity`
      nextBin = ceiling_date(time, fidelity)
    ) |>
    mutate(
      next_grid_point = case_when(
        # if earlier than grid start, use grid start
        nextBin < time_grid_start ~ time_grid_start,
        # if later than grid start, use timepoint
        nextBin >= time_grid_start ~ nextBin
      )
    ) |>
    dplyr::select(!nextBin) |>
    group_by(next_grid_point) |>
    # choose last observation in bin
    slice_tail(n = 1) |>
    ungroup()

  ZQ_aligned <- ZQ_running |> 
    mutate(
      # rounding "up" (to nearest upper) `fidelity`
      nextBin = ceiling_date(time, fidelity)
    ) |>
    mutate(
      next_grid_point = case_when(
        # if earlier than grid start, use grid start
        nextBin < time_grid_start ~ time_grid_start,
        # if later than grid start, use timepoint
        nextBin >= time_grid_start ~ nextBin
      )
    ) |>
    dplyr::select(!nextBin) |>
    group_by(next_grid_point) |>
    slice_tail(n = 1) |>
    ungroup()

  all_aligned <- time_grid |>
    left_join(PM_aligned, by = join_by(timestamp == next_grid_point)) |>
    dplyr::select(
      timestamp,
      all_of(assetNames)
    ) |>
    left_join(ZQ_aligned, by = join_by(timestamp == next_grid_point),
      suffix = c(".PM", ".ZQ")) |>
    dplyr::select(!time) |>
    fill(
      !timestamp,
      .direction = "down")

  if (any(is.na(all_aligned[1, ]))) all_aligned <- all_aligned[-1, ]
  vectorised_timeseries <- all_aligned
}

rm(
  PM_aligned,
  PM_running,
  ZQ_aligned,
  ZQ_running,
  all_aligned,
  assetNames,
  fidelity,
  fidelity_seconds,
  time_grid,
  time_grid_end,
  time_grid_start
)


print("Done")
ls()


vectorised_timeseries


png(
  filename = file.path(ROOT_DIR,
    "outputs/fomc/plots/ZQ_PM_comparison",
    paste0("ZQ_PM_FOMC_meeting_", 
      sub("-", "_", meetingName), ".png")
  ),
  width = 1600,
  height = 600,
  res = 100,
  type = "cairo-png",
  antialias = "subpixel"
)

assetNames <- c(
  "asset1.PM",
  "asset2.PM",
  "asset1.ZQ",
  "asset2.ZQ"
)

PM_asset <- "asset1.PM"
ZQ_asset <- "asset1.ZQ"
timestamps <- vectorised_timeseries$timestamp
PM_asset <- vectorised_timeseries[[assetName]]

# Initialise plotting area
plot(timestamps, PM_asset, type = 'n', ylim = c(0, 1),
  main = "Pooled dataset",
  ylab = "Implied probability",
  xlab = "Time", lty = "solid",
  yaxt = "n",
  cex.main = 1,
  cex.lab = 1,
  cex.axis = 1
)
# y-axis
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
grid()

# Polymarket probabilities

lines(timestamps, PM_asset, type = 'l', col = "#2D9CDB")
# ZQ implied probabilities
lines(ZQ_time, ZQ_probs, type = 'l', col = "#FF5952")
legend("right", legend = c("Polymarket", "ZQ-implied"),
  col = c("#2D9CDB", "#FF5952"), lwd = 2)


  dev.off()
}







# ----- ADF test on original (non-constant) timeseries -----
adf_test_results <- list()
{
  timeseries_df <- vectorised_timeseries[, -1]

  for (assetName in colnames(timeseries_df)) {
    if (assetName == "timestamp") {
      next
    }
    else {
      adf_test_results[[assetName]] <- adf.test(timeseries_df[[assetName]])
    }
  }
}

# stationary --> no need to difference ts
# no need for Johansen procedure
# NOTE: Was original data non-stationary in regular GC testing file?

rm(timeseries_df, assetName)

invisible(gc())

print("Performing Granger causality test")
# ------ Actual granger causality test ------
# PM_cause_ZQ_bivariate <- list()
# ZQ_cause_PM_bivariate <- list()
PM_cause_ZQ_blockwise <- list()
ZQ_cause_PM_blockwise <- list()
{
  timeseries_df <- vectorised_timeseries[, -1]
  assetNames <- colnames(timeseries_df)
  unique_assets <- unique(substring(assetNames, 1, nchar(assetNames) - 3))

  rm(unique_asset, unique_assets)

  # blockwise granger test
  PM_filter <- endsWith(assetNames, "PM")
  ZQ_filter <- endsWith(assetNames, "ZQ")

  PM_assets <- assetNames[PM_filter]
  ZQ_assets <- assetNames[ZQ_filter]

  rm(PM_filter, ZQ_filter, assetNames)

  # var model
  var_select <- VARselect(timeseries_df, lag.max = 24)
  lag_choice <- var_select$selection["SC(n)"]
  VAR_model_trace <- VAR(timeseries_df, p = lag_choice, type = "const")

  rm(PM_filter, ZQ_filter, noBaseCase_df, ECT_trace, lag_from_ECT, var_select)

  # -- Trace methods --
  # PM --> ZQ, trace
  tryCatch(
    {
      PM_causing_trace <- causality(VAR_model_trace, cause = PM_assets)
      PM_cause_ZQ_blockwise[["trace"]] <- PM_causing_trace
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nin blockwise test", 
        "\nPerforming:", 
        "PM --> ZQ",
        "trace test",
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      PM_cause_ZQ_blockwise[["trace"]] <- NULL
    }
  )
  rm(PM_causing_trace)
  # invisible(gc())

  # ZQ --> PM, trace
  tryCatch(
    {
      ZQ_causing_trace <- causality(VAR_model_trace, cause = ZQ_assets)
      ZQ_cause_PM_blockwise[["trace"]] <- ZQ_causing_trace
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nin blockwise test", 
        "\nPerforming:", 
        "ZQ --> PM",
        "trace test",
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      ZQ_cause_PM_blockwise[["trace"]] <- NULL
    }
  )
  rm(ZQ_causing_trace, VAR_model_trace)
  invisible(gc())

  # -- Eigen methods --
  VAR_model_eigen <- VAR(timeseries_df, p = lag_choice, type = "const")
  rm(timeseries_df, lag_choice, ECT_eigen)

  # PM --> ZQ, eigen
  tryCatch(
    {
      PM_causing_eigen <- causality(VAR_model_eigen, cause = PM_assets)
      PM_cause_ZQ_blockwise[["eigen"]] <- PM_causing_eigen
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nin blockwise test", 
        "\nPerforming:", 
        "PM --> ZQ",
        "eigen test",
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      PM_cause_ZQ_blockwise[["eigen"]] <- NULL
    }
  )
  rm(PM_causing_eigen)
  # invisible(gc())

  # ZQ --> PM, eigen
  tryCatch(
    {
      ZQ_causing_eigen <- causality(VAR_model_eigen, cause = ZQ_assets)
      ZQ_cause_PM_blockwise[["eigen"]] <- ZQ_causing_eigen
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nin blockwise test", 
        "\nPerforming:", 
        "ZQ --> PM",
        "eigen test",
        "\nwith error message:", "\n",
        e$message, "\n"
      )

        ZQ_cause_PM_blockwise[["eigen"]] <- NULL
      }
  )
  rm(ZQ_causing_eigen, VAR_model_eigen)
  invisible(gc())
}
print("Finished performing Granger causality test")

rm(
  ECT_eigen,
  ECT_trace,
  PM_assets,
  PM_causing,
  PM_filter,
  VAR_model,
  ZQ_assets,
  ZQ_causing,
  ZQ_filter,
  assetNames,
  hasBoth,
  lag_choice,
  meetingName,
  testing_df,
  unique_asset,
  unique_assets,
  var_select,
  differenced_df
)
save(
  PM_cause_ZQ_blockwise,
  ZQ_cause_PM_blockwise,
  file = "./pooled_granger_causality_results.RData"
)

# PM_cause_ZQ_bivariate
# ZQ_cause_PM_bivariate
# PM_cause_ZQ_blockwise
# ZQ_cause_PM_blockwise
