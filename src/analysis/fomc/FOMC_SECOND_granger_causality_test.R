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


# Set Monday as start of week
options("lubridate.week.start" = 1)

# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 
load("./FOMC_Granger_Causality.RData")


# NOTE: We filter timeseries to skip weekends (due to ZQ unavailability) ==> assumption of no weekend effect since lags are worth the same as between workdays
# NOTE: Using unscaled Polymarket data ==> probabilities almost never add up to 1
# Logic for using this is that these are (price-implied risk-neutral) probabilities that two traders have agreed on -- if we used midpoints, that would avoid people actually agreeing on probabilities; as a matter of fact the (width of) the spread shows how much people *disagree* on probabilities.


# ------ Remove weekends ------
PM_data_unscaled_no_weekend <- list()
PM_data_scaled_no_weekend <- list()
for (meetingName in meetingMonths) {
  PM_df_unscaled <- PM_data_unscaled[[meetingName]] |>
    mutate(
      day_of_week = weekdays(time)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday", "Monday"))
      # !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  PM_df_scaled <- PM_data_scaled[[meetingName]] |>
    mutate(
      day_of_week = weekdays(time)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday", "Monday"))
      # !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  PM_data_unscaled_no_weekend[[meetingName]] <- PM_df_unscaled
  PM_data_scaled_no_weekend[[meetingName]] <- PM_df_scaled
}

rm(PM_df_unscaled, PM_df_scaled, meetingName, PM_data_scaled)

# decrease in number of trades
trades_num_with_weekend <- sapply(PM_data_unscaled, nrow)
trades_num_without_weekend <- sapply(PM_data_unscaled_no_weekend, nrow)


# png(
#   filename = file.path(ROOT_DIR,
#     "outputs/fomc/plots/granger_causality/number_of_trades.png"
#   ),
#   width = 800,
#   height = 600,
#   res = 100,
#   type = "cairo-png",
#   antialias = "subpixel"
# )

# FIX: Fix this
plot(trades_num_with_weekend, type = 'l',
  main = "Number of trades in Polymarket's markets",
  ylab = "No. of trades",
  xlab = "market",
  col = "black",
  log = 'y',
  las = 2,
  mar = c(9.1, 5.1, 4.1, 2.1)
)


lines(trades_num_without_weekend, type = 'l',
  main = "Number of trades",
  ylab = "# trades",
  xlab = "market",
  col = "red"
)
legend(
  "bottomright",
  legend = c("# of trades with weekends included")
)

dev.off()

# # Proportion of datapoints excluded
# (trades_num_with_weekend - trades_num_without_weekend) / trades_num_with_weekend


# png(
#   filename = file.path(ROOT_DIR,
#     "outputs/fomc/plots/granger_causality/trades_excluded_PM.png"
#   ),
#   width = 800,
#   height = 600,
#   res = 100,
#   type = "cairo-png",
#   antialias = "subpixel"
# )

PM_excluded_proportions <- (trades_num_with_weekend - trades_num_without_weekend) / trades_num_with_weekend

bp <- barplot(PM_excluded_proportions, ylim = c(0, max(PM_excluded_proportions + 0.1)), main = "Proportion of trades excluded")

text(x = bp,
     y = PM_excluded_proportions,
     labels = paste0(round(100 * PM_excluded_proportions), '%'),
     pos = 3,
     cex = 0.9,
     col = "black")


dev.off()


rm(bp, PM_excluded_proportions, PM_data_unscaled, trades_num_with_weekend)

PM_whichLatestZero <- c()

# ------- Checking which is the last 0 priced asset -------
for (meetingName in meetingMonths) {
  PM_df <- PM_data_unscaled_no_weekend[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]
  
  PM_df <- PM_df |>
    mutate(
      containsZero = if_any(all_of(assetNames), ~ . == 0)
    )

  PM_whichLatestZero[meetingName] <- max(which(PM_df$containsZero))
}

rm(PM_df, meetingName, assetNames)

# PM_whichLatestZero

rm(PM_whichLatestZero)


# ------- Checking where unscaled sum above certain threshold -------
PM_whichLatestBelowThresHold <- function(threshold) {
  PM_latestBelowThreshold <- c()
  for (meetingName in meetingMonths) {
    PM_df <- PM_data_scaled_no_weekend[[meetingName]]

    PM_latestBelowThreshold[meetingName] <- max(
      which(PM_df$unscaled_sum < threshold)
    )
  }

  PM_latestBelowThreshold
}

PM_latest_below_matrix <- sapply(c(0.2, 0.3, 0.4, 0.5, 0.6), PM_whichLatestBelowThresHold)
colnames(PM_latest_below_matrix) <- c(0.2, 0.3, 0.4, 0.5, 0.6)

# PM_latest_below_matrix

rm(PM_whichLatestBelowThresHold)

# trades_num_without_weekend["2024-01"]


# The idea now is to remove the observations
# where the sum of the last-trade asset prices in the events 
# are less than 0.2

# However:

# # 1) In the 2023-12, removing these observations would erase most of the datapoints
# trades_num_without_weekend["2023-12"]
# # 2) In the 2024-01 markets, it would erase 25% of the datapoints
# trades_num_without_weekend["2024-01"]

# # 3) This data reveals some insights: there is an abnormal period of trading in the March 2025 market:
# (PM_data_scaled_no_weekend$`2025-03`[16510:16515, ])$unscaled_sum

# # Removing these observations fixes this:
# max(
#   which(
#     ((PM_data_scaled_no_weekend$`2025-03`[-(16510:16515), ])$unscaled_sum) < 0.2
#   )
# )

# ----- Removing observations below threshold -----
# It is crucial for this to be executed atomically
{
  first_observations_filter <- PM_latest_below_matrix[!rownames(PM_latest_below_matrix) %in%  c("2023-12", "2024-01", "2025-03"), colnames(PM_latest_below_matrix) == 0.2]

  PM_filtered <- PM_data_unscaled_no_weekend
  PM_filtered$`2025-03` <- PM_filtered$`2025-03`[-(16510:16515), ]

  for (meetingName in meetingMonths) {
    PM_df <- PM_filtered[[meetingName]]
    filterBy <- first_observations_filter[meetingName]

    # skip if NA or -Inf (not found)
    if (is.na(filterBy) || is.infinite(filterBy)) {
      next
    } else {
      PM_filtered[[meetingName]] <- PM_df[-(1:filterBy), ]
    }
  }
}

# PM_filtered

# PM_latest_below_matrix



rm(
  PM_data_scaled_no_weekend,
  PM_data_unscaled_no_weekend,
  PM_latest_below_matrix,
  filterBy,
  first_observations_filter,
  trades_num_without_weekend
)


# ----- Deciding which timegrid to use (measuring breaks in trading) -----
PM_avg_trading_freq_stats <- c()
for (meetingName in meetingMonths) {
  PM_df <- PM_filtered[[meetingName]]

  minute_distances <- diff(as.numeric(PM_df$time)) / 60
  # exclude weekends
  minute_distances <- minute_distances[minute_distances < 48 * 60]

  PM_avg_trading_freq_stats <- rbind(PM_avg_trading_freq_stats, summary(minute_distances))
}

# PM_avg_trading_freq_stats

rm(PM_df, minute_distances, meetingName, PM_avg_trading_freq_stats)


ZQ_avg_trading_freq_stats <- c()
ZQ_filtered <- list()

for (meetingName in meetingMonths) {
  PM_df <- PM_filtered[[meetingName]]

  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]


  ZQ_df <- ZQ_Implied_Probs[[meetingName]] |>
    # filter for relevant assets
    dplyr::select(time, all_of(assetNames)) |> 
    mutate(
      day_of_week = weekdays(time)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  ZQ_filtered[[meetingName]] <- ZQ_df

  minute_distances <- diff(as.numeric(ZQ_df$time)) / 60
  # exclude weekends
  minute_distances <- minute_distances[minute_distances < 48 * 60]

  ZQ_avg_trading_freq_stats <- rbind(ZQ_avg_trading_freq_stats, summary(minute_distances))
}

# ZQ_avg_trading_freq_stats

rm(PM_df, ZQ_df, minute_distances, meetingName, ZQ_Implied_Probs, ZQ_avg_trading_freq_stats)


# Which one starts earlier and ends later?
for (meetingName in meetingMonths) {
  PM_df <- PM_filtered[[meetingName]]
  ZQ_df <- ZQ_filtered[[meetingName]]

  PM_range <- as.numeric(range(PM_df$time))
  ZQ_range <- as.numeric(range(ZQ_df$time))

  # cat("\n\n", meetingName, "\n")
  # cat("Earlier start:", ifelse(PM_range[1] < ZQ_range[1], "Polymarket", ifelse(PM_range[1] == ZQ_range[1], "equal", "ZQ_implied")), "\t\t", "by:", abs(PM_range[1] - ZQ_range[1]) / 60, "minutes", "\n")
  #
  # cat("Later end:", ifelse(PM_range[2] > ZQ_range[2], "Polymarket", ifelse(PM_range[2] == ZQ_range[2], "equal", "ZQ_implied")), "\t\t", "by:", abs(PM_range[2] - ZQ_range[2]) / 60, "minutes", "\n")
}

rm(PM_df, PM_range, ZQ_df, ZQ_range, meetingName)

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
vectorised_timeseries <- list()
for (meetingName in meetingMonths) {
  PM_df <- PM_filtered[[meetingName]]
  ZQ_df <- ZQ_filtered[[meetingName]]

  time_grid_start <- max(
    floor_date(min(PM_df$time), fidelity),
    floor_date(min(ZQ_df$time), fidelity)
  )

  time_grid_end <- min(
    ceiling_date(max(PM_df$time), fidelity),
    ceiling_date(max(ZQ_df$time), fidelity)
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

  assetNames <- colnames(PM_df)[!(colnames(PM_df) == "time")]

  PM_aligned <- PM_df |> 
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

  ZQ_aligned <- ZQ_df |> 
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
  vectorised_timeseries[[meetingName]] <- all_aligned
}

rm(
  PM_aligned,
  PM_df,
  PM_filtered,
  ZQ_aligned,
  ZQ_df,
  ZQ_filtered,
  all_aligned,
  assetNames,
  fidelity,
  fidelity_seconds,
  meetingName,
  time_grid,
  time_grid_end,
  time_grid_start
)



# ----- Removing constant timeseries -----
filtered_timeseries <- list()
for (meetingName in meetingMonths) {
  timeseries_df <- vectorised_timeseries[[meetingName]]
  df_assets_only <- timeseries_df[, -1]
  assetNames <- colnames(df_assets_only)

  hasOnlyZeroes <- df_assets_only |> 
    summarise(across(all_of(assetNames), ~all(.x == 0))) |>
    unlist()

  # select ones that don't only have zeroes
  filtered_timeseries[[meetingName]] <- df_assets_only |>
    dplyr::select(names(hasOnlyZeroes)[!hasOnlyZeroes])
}

# Additional manual filtering to prevent error due to singular matrices
filtered_timeseries[["2023-02"]] <- filtered_timeseries[["2023-02"]] |>
  dplyr::select(-up25.ZQ)

filtered_timeseries[["2025-07"]] <- filtered_timeseries[["2025-07"]] |>
  dplyr::select(-up25.ZQ)

# NOTE: I should check which columns included and which ones aren't included
# based on if findings significant or not


rm(
  timeseries_df,
  df_assets_only,
  assetNames,
  hasOnlyZeroes,
  meetingName,
  vectorised_timeseries
)


# ----- ADF test on original (non-constant) timeseries -----
adf_test_results <- list()
for (meetingName in meetingMonths) {
  timeseries_df <- filtered_timeseries[[meetingName]]

  adf_test_results_for_meeting <- list()

  for (assetName in colnames(timeseries_df)) {
    if (assetName == "timestamp") {
      next
    }
    else {
      adf_test_results_for_meeting[[assetName]] <- adf.test(timeseries_df[[assetName]])
    }
  }

  adf_test_results[[meetingName]] <- adf_test_results_for_meeting
}

rm(timeseries_df, adf_test_results_for_meeting, assetName, meetingName)


stationary_ts <- c()
for (meetingName in meetingMonths) {
  adf_results_list <- adf_test_results[[meetingName]]
  for (assetName in names(adf_results_list)) {
    if (adf_results_list[[assetName]]$p.value < 0.05) {
      stationary_ts <- rbind(
        stationary_ts,
        c(meetingName, assetName)
      )
    }
  }
}

rm(adf_results_list, meetingName, assetName)

# stationary_ts


# ----- Creating differenced timeseries -----
differenced_timeseries <- list()
for (meetingName in meetingMonths) {
  ts_df <- filtered_timeseries[[meetingName]]

  differenced_df <- ts_df |>
    dplyr::mutate(
      across(colnames(ts_df), ~ c(NA, diff(.)))
    ) |>
    filter(if_all(colnames(ts_df), ~ !is.na(.)))

  differenced_timeseries[[meetingName]] <- differenced_df
}

rm(ts_df, differenced_df, meetingName, stationary_ts)


# ----- ADF test on differenced timeseries -----
adf_test_results_differenced <- list()
for (meetingName in meetingMonths) {
  timeseries_df <- differenced_timeseries[[meetingName]]

  adf_test_results_for_meeting <- list()

  for (assetName in colnames(timeseries_df)) {
    adf_test_results_for_meeting[[assetName]] <- adf.test(timeseries_df[[assetName]])
  }

  adf_test_results_differenced[[meetingName]] <- adf_test_results_for_meeting
}

rm(
  timeseries_df,
  adf_test_results_for_meeting,
  assetName,
  meetingName
)


# ----- Evaluating ADF test on differenced timeseries -----
non_stationary_differenced_ts <- c()
for (meetingName in meetingMonths) {
  meeting_adf_results <- adf_test_results_differenced[[meetingName]] 
  assetNames <- names(meeting_adf_results)
  for (assetName in assetNames) {
    if (meeting_adf_results[[assetName]]$p.value >= 0.05) {
      non_stationary_differenced_ts <- rbind(
        non_stationary_differenced_ts,
        c(meetingName, assetName)
      )
    }
  }
}

rm(
  meeting_adf_results,
  adf_test_results_for_meeting,
  assetName,
  assetNames,
  meetingName
)



# non_stationary_differenced_ts
adf_test_results_differenced[["2024-12"]][["down50.ZQ"]]
filtered_timeseries[["2024-12"]][["down50.ZQ"]]


# adf_test_results_differenced

# all timeseries stationary except for this one


# testing whether there is a trend/drift in levels
# If there is, ca.jo would need to be reestimated with trend constant
for (meetingName in meetingMonths) {
  filtered_df <- filtered_timeseries[[meetingName]]

  cat("\nMeeting:", meetingName)

  for (assetName in colnames(filtered_df)) {
    t_test_res <- t.test(filtered_df[[assetName]])
    p_val_res <- ifelse(t_test_res$p.value < 0.05, "reject mean == 0", "cannot reject mean == 0")
    cat(
      "\nAsset:", assetName,
      "\nResult:", p_val_res
    )
  }

  cat("\n")
}

# Conclusion: We use ecdet = 'const' for a constant intercept
# in the Johansen procedure and test whether a linear trend is allowed
# in the deterministic term

# # to locate warnings
# options(warn = 1)

# ----- Johansen test (original timeseries) -----
print("Performing Johansen test")
bivariate_johansen_test <- list()
block_johansen_test <- list()
lag_choices_blockwise <- list()
lag_choices_bivariate <- list()
for (meetingName in meetingMonths) {
  filtered_df <- filtered_timeseries[[meetingName]]
  assetNames <- colnames(filtered_df)
  unique_assets <- unique(substring(assetNames, 1, nchar(assetNames) - 3))

  # pairwise (bivariate) case
  for (unique_asset in unique_assets) {
    # prob_spread <- testing_df[[paste0(unique_asset, ".PM")]] - testing_df[[paste0(unique_asset, ".ZQ")]]
    # class(prob_spread)
    #
    # adf.test(prob_spread, alternative = "stationary")

    hasBoth <- sum(startsWith(assetNames, unique_asset)) == 2
    if (!hasBoth) next

    testing_df <- filtered_df[, startsWith(assetNames, unique_asset)]

    # var model
    var_select <- VARselect(testing_df, lag.max = 24)
    lag_choice <- var_select$selection["SC(n)"]

    lag_choices_bivariate[[meetingName]][[unique_asset]] <- lag_choice

    # try trace test
    tryCatch(
      {
        # # to locate warnings
        # cat(
        #   "\nRunning",
        #   "\nbivariate test",
        #   "\ntrace test",
        #   "\nWhile processing:", meetingName,
        #   "\non assets:", unique_asset,
        #   "\nwith error message:", "\n"
        # )

        trace_test <- ca.jo(
          as.data.frame(testing_df), type = "trace",
          K = lag_choice, ecdet = "const",
          spec = "transitory" # Determines which formula Gamma is
        )

        bivariate_johansen_test[[meetingName]][[unique_asset]][["trace"]] <- trace_test

      },
      error = function(e) {
        cat(
          "\nAn error occured",
          "\nin bivariate test",
          "\nPerforming:", "trace", "test",
          "\nWhile processing:", meetingName,
          "\non assets:", unique_asset,
          "\nwith error message:", "\n",
          e$message, "\n"
        )

        bivariate_johansen_test[[meetingName]][[unique_asset]][["trace"]] <- NULL
      }
    )

    # try eigen test
    tryCatch(
      {
        # # to locate warnings
        # cat("\nRunning",
        #   "\nbivariate test",
        #   "\neigen test",
        #   "\nWhile processing:", meetingName,
        #   "\non assets:", unique_asset,
        #   "\nwith error message:", "\n"
        # )

        eigen_test <- ca.jo(
          as.data.frame(testing_df), type = "eigen",
          K = lag_choice, ecdet = "const",
          spec = "transitory" # Determines which formula Gamma is
        )

        bivariate_johansen_test[[meetingName]][[unique_asset]][["eigen"]] <- eigen_test
      },
      error = function(e) {

        cat(
          "\nAn error occured",
          "\nin bivariate test",
          "\nPerforming:", "eigen", "test",
          "\nWhile processing:", meetingName,
          "\non assets:", unique_asset,
          "\nwith error message:", "\n",
          e$message, "\n"
        )

        bivariate_johansen_test[[meetingName]][[unique_asset]][["eigen"]] <- NULL
      }
    )

    rm(hasBoth, testing_df, var_select, lag_choice, trace_test, eigen_test)
    invisible(gc())
  }

  # blockwise granger test
  PM_filter <- !startsWith(assetNames, "noChange") & endsWith(assetNames, "PM")
  ZQ_filter <- !startsWith(assetNames, "noChange") & endsWith(assetNames, "ZQ")

  PM_assets <- assetNames[PM_filter]
  ZQ_assets <- assetNames[ZQ_filter]

  # excludes noChange
  noBaseCase_df <- filtered_df[, c(PM_assets, ZQ_assets)]

  # var model
  var_select <- VARselect(noBaseCase_df, lag.max = 24)
  lag_choice <- var_select$selection["SC(n)"]

  lag_choices_blockwise[[meetingName]] <- lag_choice


  # try to perform blockwise causality test, save NULL if fails

  # try trace test
  tryCatch(
    {

      # # to locate warnings
      # cat("\nRunning",
      #   "\nblockwise test",
      #   "\ntrace test",
      #   "\nWhile processing:", meetingName,
      #   "\non assets:", unique_asset,
      #   "\nwith error message:", "\n"
      # )

      trace_test <- ca.jo(as.data.frame(noBaseCase_df), type = "trace",
        K = lag_choice, ecdet = "const",
        spec = "transitory" # Determines which formula Gamma is
      )

      block_johansen_test[[meetingName]][["trace"]] <- trace_test
    },
    error = function(e) {

      cat(
        "\nan error occured",
        "\nin blockwise test",
        "\nperforming:", "trace", "test",
        "\nwhile processing:", meetingName,
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      block_johansen_test[[meetingName]][["trace"]] <- NULL
    }
  )

  # try eigen test
  tryCatch(
    {
      # # to locate warnings
      # cat("\nRunning",
      #   "\nblockwise test",
      #   "\neigen test",
      #   "\nWhile processing:", meetingName,
      #   "\non assets:", unique_asset,
      #   "\nwith error message:", "\n"
      # )

      eigen_test <- ca.jo(as.data.frame(noBaseCase_df), type = "eigen",
        K = lag_choice, ecdet = "const",
        spec = "transitory" # Determines which formula Gamma is
      )

      block_johansen_test[[meetingName]][["eigen"]] <- eigen_test
    },
    error = function(e) {
      cat(
        "\nan error occured",
        "\nin blockwise test",
        "\nperforming:", "eigen", "test",
        "\nwhile processing:", meetingName,
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      block_johansen_test[[meetingName]][["eigen"]] <- NULL
    }
  )

  rm(filtered_df, noBaseCase_df, var_select, lag_choice, trace_test, eigen_test)
  invisible(gc())
}

print("Finished performing Johansen test")


rm(
  PM_assets,
  PM_filter,
  ZQ_assets,
  ZQ_filter,
  adf_test_results,
  adf_test_results_differenced,
  assetNames,
  eigen_test,
  filtered_df,
  hasBoth,
  lag_choice,
  noBaseCase_df,
  non_stationary_differenced_ts,
  testing_df,
  trace_test,
  trace_test_failed,
  unique_asset,
  unique_assets,
  var_select
)


# All 30 warnings happen on:
# Running bivariate eigen test 
# While processing: 2023-02 
# on assets: up50 

# # turn off after locating warnings
# options(warn = 0) # turn off after locating warnings


# bivariate_johansen_test
# block_johansen_test

count_cointegrating_rels <- function(jotest, alpha = 0.05) {
  # HACK: This should do something else or be checked for elsewhere
  if (is.null(jotest)) return(0)

  crit_col <- switch(
    as.character(alpha),
    "0.1" = 1,
    "0.05" = 2,
    "0.01" = 3,
    stop("Alpha must be 0.1, 0.05, or 0.01")
  )

  # test statistics and critical values
  test_stats <- jotest@teststat
  crit_vals <- jotest@cval[, crit_col]

  # number of rejected null hypotheses = number of cointegrating relationships
  num_relationships <- sum(test_stats > crit_vals)

  num_relationships
}

calculate_ECT <- function(cajo_obj, r) {
  # taken from cajorls function
  r <- count_cointegrating_rels(cajo_obj)
  # beta
  beta <- matrix(cajo_obj@V[, 1:r], ncol = r)
  C1 <- diag(r)
  C2 <- matrix(0, nrow = nrow(beta) - r, ncol = r)
  C <- rbind(C1, C2)
  betanorm <- beta %*% solve(t(C) %*% beta)
  # This is Y_{t-1}, lagged: cajo_obj@ZK
  # Y_{t-1} %*% beta (transpose of beta %*% Y_{t-1}, due to ts conventions in code)
  ECT <- cajo_obj@ZK %*% betanorm
  colnames(ECT) <- paste("ect", 1:r, sep = "")

  ECT
}


# ----- Evaluating Johansen test (original timeseries) -----
# Also testing whether linear trend should be included in deterministic term (H0: not included)
# If H0 rejected, redo Johansen procedure
# If H0 failed to be rejected, calculate ECT (error correction terms)

ECT_bivariate <- list()
ECT_blockwise <- list()
print("Evaluating Johansen test")
for (meetingName in meetingMonths) {
  bivariate_results <- bivariate_johansen_test[[meetingName]]
  block_results <- block_johansen_test[[meetingName]]

  # pairwise (bivariate) case
  for (assetName in names(bivariate_results)) {
    trace_results <- bivariate_results[[assetName]][["trace"]]
    eigen_results <- bivariate_results[[assetName]][["eigen"]]

    cointegration_count_trace <- count_cointegrating_rels(trace_results)
    cointegration_count_eigen <- count_cointegrating_rels(eigen_results)

    if (cointegration_count_trace == 0) {
      ECT_trace <- NULL
    } else {
      ECT_trace <- calculate_ECT(
        trace_results,
        cointegration_count_trace
      )
    }

    if (cointegration_count_eigen == 0) {
      ECT_eigen <- NULL
    } else {
      ECT_eigen <- calculate_ECT(
        eigen_results,
        cointegration_count_trace
      )
    }

    ECT_bivariate[[meetingName]][[assetName]][["trace"]] <- ECT_trace
    ECT_bivariate[[meetingName]][[assetName]][["eigen"]] <- ECT_eigen

    # suppress output by redirecting it to /dev/null
    sink("/dev/null")

    # Conducts a likelihood ratio test for no inclusion of a linear trend in a VAR.\
    # H0: is for not including a linear trend and is assigned as ’H2*(r)’. 
    tryCatch(
      {
        lt_trace <- lttest(trace_results, r = cointegration_count_trace)
        lt_eigen <- lttest(eigen_results, r = cointegration_count_eigen)
      },
      error = function(e) {
        cat("\nError occured", e$message)
        if (cointegration_count_trace == 0) {
          lt_trace <- matrix(1)
          colnames(lt_trace) <- c("p-value") # do not reject
        }
        if (cointegration_count_eigen == 0) { # do not reject
          lt_eigen <- matrix(1)
          colnames(lt_eigen) <- c("p-value")
        }
      }
    )

    # stop suppressing output
    sink()

    cat(
      "\nMeeting: ", meetingName,
      "\nbivariate case, asset:", assetName,
      "\ncointegration count:",
      "\ntrace:", cointegration_count_trace,
      "\neigen:", cointegration_count_eigen,
      "\nlttest trace:", ifelse(lt_trace[1, "p-value"] < 0.05, "reject", "do not reject"), 
      "NOT including linear ecdet",
      "\nlttest eigen:", ifelse(lt_eigen[1, "p-value"] < 0.05, "reject", "do not reject"), 
      "NOT including linear ecdet",
      "\n"
    )

    invisible(gc()) 
  }

  # blockwise granger test
  trace_results <- block_results[["trace"]]
  eigen_results <- block_results[["eigen"]]

  cointegration_count_trace <- count_cointegrating_rels(trace_results)
  cointegration_count_eigen <- count_cointegrating_rels(eigen_results)

  if (cointegration_count_trace == 0) {
    ECT_trace <- NULL
  } else {
    ECT_trace <- calculate_ECT(
      trace_results,
      cointegration_count_trace
    )
  }

  if (cointegration_count_eigen == 0) {
    ECT_eigen <- NULL
  } else {
    ECT_eigen <- calculate_ECT(
      eigen_results,
      cointegration_count_trace
    )
  }

  ECT_blockwise[[meetingName]][["trace"]] <- ECT_trace
  ECT_blockwise[[meetingName]][["eigen"]] <- ECT_eigen

  # suppress output by redirecting it to /dev/null
  sink("/dev/null")

  # Conducts a likelihood ratio test for no inclusion of a linear trend in a VAR.\
  # H0: is for not including a linear trend and is assigned as ’H2*(r)’. 
  tryCatch(
    {
      lt_trace <- lttest(trace_results, r = cointegration_count_trace)
      lt_eigen <- lttest(eigen_results, r = cointegration_count_eigen)
    },
    error = function(e) {
      cat("\nError occured", e$message)
      if (cointegration_count_trace == 0) {
        lt_trace <- matrix(1)
        colnames(lt_trace) <- c("p-value") # do not reject
      }
      if (cointegration_count_eigen == 0) { # do not reject
        lt_eigen <- matrix(1)
        colnames(lt_eigen) <- c("p-value")
      }
    }
  )

  # stop suppressing output
  sink()

  cat(
    "\nMeeting: ", meetingName,
    "\nblock case",
    "\ncointegration count:",
    "\ntrace:", cointegration_count_trace,
    "\neigen:", cointegration_count_eigen,
    "\nlttest trace:", ifelse(lt_trace[1, "p-value"] < 0.05, "reject", "do not reject"), 
    "NOT including linear ecdet",
    "\nlttest eigen:", ifelse(lt_eigen[1, "p-value"] < 0.05, "reject", "do not reject"), 
    "NOT including linear ecdet",
    "\n"
  )

  invisible(gc())
}
print("Finished evaluating Johansen test")

# Conclusion: not including linear ecdet anywhere


rm(
  bivariate_results,
  block_results,
  cointegration_count_eigen,
  cointegration_count_trace,
  eigen_results,
  lt_eigen,
  lt_trace,
  trace_results
)

# Findings:
# There is a lot of cointegration


# testing whether there is a trend/drift in differences:
for (meetingName in meetingMonths) {
  differenced_df <- differenced_timeseries[[meetingName]]

  cat("\nMeeting:", meetingName)

  for (assetName in colnames(differenced_df)) {
    t_test_res <- t.test(differenced_df[[assetName]])
    p_val_res <- ifelse(t_test_res$p.value < 0.05, "reject mean == 0", "cannot reject mean == 0")
    cat(
      "\nAsset:", assetName,
      "\nResult:", p_val_res
    )
  }

  cat("\n")
}

# Conclusion: We use restricted OLS to estimate VECM since
# null-hypothesis of 0-mean differences cannot be rejected
# for any timeseries

rm(meetingName, assetName, t_test_res, p_val_res)




# Output containers
PM_cause_ZQ_share_bivariate <- list()
ZQ_cause_PM_share_bivariate <- list()
PM_cause_ZQ_share_blockwise <- list()
ZQ_cause_PM_share_blockwise <- list()

# Optional: keep per-window p-values for plots/tables
rolling_gc_windows_bivariate <- list()
rolling_gc_windows_blockwise <- list()

# Settings (tune as needed)
alpha        <- 0.05
window_size  <- 1440   # number of observations per window
step_size    <- 60    # stride between windows

missingMonths <- c(
  "2023-03",
  "2023-06",
  "2024-01",
  "2024-03",
  "2024-11"
)


# differenced_timeseries[["2023-03"]] == 0
# differenced_timeseries[["2023-06"]] == 0
# differenced_timeseries[["2024-01"]] == 0
# differenced_timeseries[["2024-03"]] == 0
# differenced_timeseries[["2024-11"]] == 0



print("Performing Granger causality test MISSING (rolling-window shares)")

# load("tmp.RData")
gc()


# ------ Actual granger causality test (Method 1: rolling-window share of rejections) ------
# Blockwise only
for (meetingName in missingMonths) {
  differenced_df <- differenced_timeseries[[meetingName]]
  assetNames     <- colnames(differenced_df)

  PM_assets <- assetNames[!startsWith(assetNames, "noChange") & endsWith(assetNames, "PM")]
  ZQ_assets <- assetNames[!startsWith(assetNames, "noChange") & endsWith(assetNames, "ZQ")]

  nb_df <- differenced_df[, c(PM_assets, ZQ_assets), drop = FALSE]
  ECT_trace_full <- ECT_blockwise[[meetingName]][["trace"]]
  ECT_eigen_full <- ECT_blockwise[[meetingName]][["eigen"]]
  lag_from_ECT <- lag_choices_blockwise[[meetingName]]


  delta_Y_full <- nb_df[lag_from_ECT:nrow(nb_df), , drop = FALSE]


  if (nrow(delta_Y_full) >= window_size) {
    p_blk <- VARselect(delta_Y_full, lag.max = 24)$selection["SC(n)"]
    ends  <- seq.int(window_size, nrow(delta_Y_full), by = step_size)


    get_pvals_blk <- function(exog_full) {
      rows <- lapply(ends, function(ei) {
        si  <- ei - window_size + 1L
        Yw  <- delta_Y_full[si:ei, , drop = FALSE]
        Exw <- if (!is.null(exog_full)) exog_full[si:ei, , drop = FALSE] else NULL

        # Keep columns that are NOT all zeros in this window
        keep_cols <- apply(Yw, 2, function(x) any(x != 0, na.rm = TRUE))
        nonZeroMatrix <- Yw[, keep_cols, drop = FALSE]

        if (ncol(nonZeroMatrix) == 0L) {
          return(tibble::tibble(
            a_to_b_p = NA_real_, b_to_a_p = NA_real_, start = si, end = ei
          ))
        }

        # Cause sets that actually exist in this window
        PM_in <- intersect(PM_assets, colnames(nonZeroMatrix))
        ZQ_in <- intersect(ZQ_assets, colnames(nonZeroMatrix))
        if (length(PM_in) == 0L || length(ZQ_in) == 0L) {
          # Nothing to test blockwise → skip
          return(tibble::tibble(
            a_to_b_p = NA_real_, b_to_a_p = NA_real_, start = si, end = ei
          ))
        }

        # Optional: skip windows with zero variance in any remaining column
        if (any(apply(nonZeroMatrix, 2, function(x) var(x, na.rm = TRUE) == 0))) {
          return(tibble::tibble(
            a_to_b_p = NA_real_, b_to_a_p = NA_real_, start = si, end = ei
          ))
        }

        # Fit VAR; protect against bad p
        p_win <- p_blk
        if (is.na(p_win) || p_win < 1L) p_win <- 1L

        vfit <- try(VAR(nonZeroMatrix, p = p_win, type = "const", exogen = Exw), silent = TRUE)
        if (inherits(vfit, "try-error")) {
          return(tibble::tibble(
            a_to_b_p = NA_real_, b_to_a_p = NA_real_, start = si, end = ei
          ))
        }

        # Granger tests (blockwise)
        a_to_b <- tryCatch(
          causality(vfit, cause = PM_in)$Granger$p.value,
          error = function(e) NA_real_
        )
        b_to_a <- tryCatch(
          causality(vfit, cause = ZQ_in)$Granger$p.value,
          error = function(e) NA_real_
        )

        tibble::tibble(
          a_to_b_p = a_to_b,
          b_to_a_p = b_to_a,
          start    = si,
          end      = ei
        )
      })

      dplyr::bind_rows(rows)
    }
    roll_trace <- get_pvals_blk(ECT_trace_full)
    roll_eigen <- get_pvals_blk(ECT_eigen_full)

    # print(all(is.na(roll_trace$a_to_b_p)))
    # print(all(is.na(roll_trace$b_to_a_p)))
    # print(all(is.na(roll_eigen$a_to_b_p)))
    # print(all(is.na(roll_eigen$b_to_a_p)))

    PM_cause_ZQ_share_blockwise[[meetingName]] <- list(
      trace = mean(roll_trace$a_to_b_p < alpha, na.rm = TRUE),
      eigen = mean(roll_eigen$a_to_b_p < alpha, na.rm = TRUE)
    )
    ZQ_cause_PM_share_blockwise[[meetingName]] <- list(
      trace = mean(roll_trace$b_to_a_p < alpha, na.rm = TRUE),
      eigen = mean(roll_eigen$b_to_a_p < alpha, na.rm = TRUE)
    )

    rolling_gc_windows_blockwise[[meetingName]] <- list(
      trace = roll_trace,
      eigen = roll_eigen
    )
  }

  # rm(
  #   roll_trace,
  #   roll_eigen,
  #   delta_Y_full,
  #   ECT_eigen_full,
  #   ECT_trace_full,
  #   nb_df
  # )

  invisible(gc())

}

print("Finished rolling-window Granger causality (shares)")


# readr::write_csv(gc_summary_block, file.path(ROOT_DIR, "outputs/fomc/granger_rolling_shares_blockwise.csv"))
save(PM_cause_ZQ_share_blockwise,
  ZQ_cause_PM_share_blockwise,
  # meetingMonths,
  # gc_summary_block,
  file = "./FOMC_which_lags_which_MISSING_granger_results_1_min.RData")
# file = "./FOMC_granger_results_5_min.RData")
# file = "./FOMC_granger_results_1_min_no_monday.RData")
# file = "./FOMC_granger_results_5_min_no_monday.RData")
