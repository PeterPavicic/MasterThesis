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

print("Performing Instant causality test (rolling-window shares)")
# ------ Actual granger causality test (Method 1: rolling-window share of rejections) ------

# Output containers
PM_cause_ZQ_share_blockwise <- list()
# ZQ_cause_PM_share_blockwise <- list()

# Optional: keep per-window p-values for plots/tables
rolling_gc_windows_blockwise <- list()

# Settings (tune as needed)
alpha        <- 0.05
window_size  <- 1440   # number of observations per window
step_size    <- 60    # stride between windows

{
  timeseries_df <- vectorised_timeseries[, -1] # not actually differenced
  assetNames     <- colnames(timeseries_df)
  unique_assets  <- unique(substring(assetNames, 1, nchar(assetNames) - 3))


  ## ------------------------
  ## Blockwise (3 vs 3) share
  ## ------------------------
  PM_assets <- assetNames[!startsWith(assetNames, "noChange") & endsWith(assetNames, "PM")]
  ZQ_assets <- assetNames[!startsWith(assetNames, "noChange") & endsWith(assetNames, "ZQ")]

  # Exclude noChange.* and build aligned matrix as in your code
  nb_df <- timeseries_df[, c(PM_assets, ZQ_assets), drop = FALSE]
  if (nrow(nb_df) >= window_size) {

    p_blk <- VARselect(nb_df, lag.max = 24)$selection["SC(n)"]
    ends  <- seq.int(window_size, nrow(nb_df), by = step_size)

    get_pvals_blk <- function() {
      rows <- lapply(ends, function(ei) {
        si  <- ei - window_size + 1L
        Yw  <- nb_df[si:ei, , drop = FALSE]

        vfit <- try(VAR(Yw, p = p_blk, type = "const"), silent = TRUE)
        if (inherits(vfit, "try-error")) {
          return(tibble::tibble(
            a_to_b_p = NA_real_,
            # b_to_a_p = NA_real_,
            start = si,
            end = ei
          ))
        }

        a_to_b <- try(causality(vfit, cause = PM_assets)$Instant$p.value, silent = TRUE)
        # b_to_a <- try(causality(vfit, cause = ZQ_assets)$Instant$p.value, silent = TRUE)

        tibble::tibble(
          a_to_b_p = if (inherits(a_to_b, "try-error")) NA_real_ else a_to_b,
          # b_to_a_p = if (inherits(b_to_a, "try-error")) NA_real_ else b_to_a,
          start    = si,
          end      = ei
        )
      })

      dplyr::bind_rows(rows)
    }

    roll_eigen <- get_pvals_blk()

    PM_cause_ZQ_share_blockwise <- list(
      eigen = mean(roll_eigen$a_to_b_p < alpha, na.rm = TRUE)
    )
    # ZQ_cause_PM_share_blockwise <- list(
    #   eigen = mean(roll_eigen$b_to_a_p < alpha, na.rm = TRUE)
    # )

    rolling_gc_windows_blockwise <- list(
      eigen = roll_eigen
    )
  }

  rm(
    roll_eigen,
    nb_df,
    ECT_eigen_full,
    nb_df
  )

  invisible(gc())

}

print("Finished rolling-window Instant causality (shares)")
# -----------------------------------------------------------------------------------------

# Optional: compact meeting-level summary tables you can write out:
# gc_summary_block <- tibble::tibble(
#   meeting         = names(PM_cause_ZQ_share_blockwise),
#   PM_to_ZQ_eigen  = sapply(PM_cause_ZQ_share_blockwise, `[[`, "eigen"),
#   ZQ_to_PM_eigen  = sapply(ZQ_cause_PM_share_blockwise, `[[`, "eigen")
# )
# readr::write_csv(gc_summary_block, file.path(ROOT_DIR, "outputs/fomc/granger_rolling_shares_blockwise.csv"))
save(PM_cause_ZQ_share_blockwise,
  # ZQ_cause_PM_share_blockwise,
  # meetingMonths,
  # gc_summary_block,
  file = "./FOMC_POOLED_which_lags_which_INSTANTANEOUS_results_1_min.RData")
# file = "./FOMC_granger_results_5_min.RData")
# file = "./FOMC_granger_results_1_min_no_monday.RData")
# file = "./FOMC_granger_results_5_min_no_monday.RData")
