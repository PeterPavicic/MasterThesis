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


# TODO: Make both IP vars contain data that is also filtered for time 
# (match time, PM_data should have reasonable unscaled_sum)
# PM_IP should not contain unscaled_sum anymore

# NOTE: We filter timeseries to skip weekends (due to ZQ unavailability) ==> assumption of no weekend effect since lags are worth the same as between workdays
# NOTE: Using unscaled Polymarket data ==> probabilities almost never add up to 1
# Logic for using this is that these are (price-implied risk-neutral) probabilities that two traders have agreed on -- if we used midpoints, that would avoid people actually agreeing on probabilities; as a matter of fact the (width of) the spread shows how much people *disagree* on probabilities.


# ------ Remove weekends ------
PM_data_unscaled_no_weekend <- list()
PM_data_scaled_no_weekend <- list()
for (meetingName in meetings$meetingMonth) {
  PM_df_unscaled <- PM_data_unscaled[[meetingName]] |>
    mutate(
      day_of_week = weekdays(time)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  PM_df_scaled <- PM_data_scaled[[meetingName]] |>
    mutate(
      day_of_week = weekdays(time)
    ) |>
    filter(
      !(day_of_week %in% c("Saturday", "Sunday"))
    ) |>
    dplyr::select(
      !day_of_week
    )

  PM_data_unscaled_no_weekend[[meetingName]] <- PM_df_unscaled
  PM_data_scaled_no_weekend[[meetingName]] <- PM_df_scaled
}

rm(PM_df_unscaled, PM_df_scaled, meetingName)

# decrease in number of trades
trades_num_with_weekend <- sapply(PM_data_unscaled, nrow)
trades_num_without_weekend <- sapply(PM_data_unscaled_no_weekend, nrow)


png(
  filename = file.path(ROOT_DIR,
    "outputs/fomc/plots/granger_causality/number_of_trades.png"
  ),
  width = 800,
  height = 600,
  res = 100,
  type = "cairo-png",
  antialias = "subpixel"
)

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


png(
  filename = file.path(ROOT_DIR,
    "outputs/fomc/plots/granger_causality/trades_excluded_PM.png"
  ),
  width = 800,
  height = 600,
  res = 100,
  type = "cairo-png",
  antialias = "subpixel"
)

PM_excluded_proportions <- (trades_num_with_weekend - trades_num_without_weekend) / trades_num_with_weekend

bp <- barplot(PM_excluded_proportions, ylim = c(0, max(PM_excluded_proportions + 0.1)), main = "Proportion of trades excluded")

text(x = bp,
     y = PM_excluded_proportions,
     labels = paste0(round(100 * PM_excluded_proportions), '%'),
     pos = 3,
     cex = 0.9,
     col = "black")


dev.off()

PM_whichLatestZero <- c()

# ------- Checking which is the last 0 priced asset -------
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_data_unscaled_no_weekend[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]
  
  PM_df <- PM_df |>
    mutate(
      containsZero = if_any(all_of(assetNames), ~ . == 0)
    )

  PM_whichLatestZero[meetingName] <- max(which(PM_df$containsZero))
}

rm(PM_df, meetingName)

# PM_whichLatestZero


# ------- Checking where unscaled sum above certain threshold -------
PM_whichLatestBelowThresHold <- function(threshold) {
  PM_latestBelowThreshold <- c()
  for (meetingName in meetings$meetingMonth) {
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

  for (meetingName in meetings$meetingMonth) {
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


# ----- Deciding which timegrid to use (measuring breaks in trading) -----
PM_avg_trading_freq_stats <- c()
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_filtered[[meetingName]]

  minute_distances <- diff(as.numeric(PM_df$time)) / 60
  # exclude weekends
  minute_distances <- minute_distances[minute_distances < 48 * 60]

  PM_avg_trading_freq_stats <- rbind(PM_avg_trading_freq_stats, summary(minute_distances))
}

rm(PM_df, minute_distances, meetingName)

# PM_avg_trading_freq_stats

ZQ_avg_trading_freq_stats <- c()
ZQ_filtered <- list()

for (meetingName in meetings$meetingMonth) {
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

rm(PM_df, ZQ_df, minute_distances, meetingName)


# Which one starts earlier and ends later?
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_filtered[[meetingName]]
  ZQ_df <- ZQ_filtered[[meetingName]]

  PM_range <- as.numeric(range(PM_df$time))
  ZQ_range <- as.numeric(range(ZQ_df$time))

  cat("\n\n", meetingName, "\n")
  cat("Earlier start:", ifelse(PM_range[1] < ZQ_range[1], "Polymarket", ifelse(PM_range[1] == ZQ_range[1], "equal", "ZQ_implied")), "\t\t", "by:", abs(PM_range[1] - ZQ_range[1]) / 60, "minutes", "\n")

  cat("Later end:", ifelse(PM_range[2] > ZQ_range[2], "Polymarket", ifelse(PM_range[2] == ZQ_range[2], "equal", "ZQ_implied")), "\t\t", "by:", abs(PM_range[2] - ZQ_range[2]) / 60, "minutes", "\n")
}

rm(PM_df, PM_range, ZQ_df, ZQ_range, meetingName)

# Creating common timegrid
# TODO: Turn this into function
# should be specified in `hours`, `minutes` or `seconds`
fidelity <- "5 minutes"

fidelity_count <- as.numeric(strsplit(fidelity, " ")[[1]][1])
fidelity_unit <- strsplit(fidelity, " ")[[1]][2]

fidelity_seconds <- fidelity_count * ifelse(
  fidelity_unit == "hours", 3600,
  ifelse(fidelity_unit == "minutes", 60,
    # seconds
    1
  )
)


# unifying to common timegrid
vectorised_timeseries <- list()
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_filtered[[meetingName]]
  ZQ_df <- ZQ_filtered[[meetingName]]

  # WARNING: Check if everything correct here
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
  PM_df,
  ZQ_df,
  time_grid_start,
  time_grid,
  time_grid_end,
  assetNames,
  PM_aligned,
  ZQ_aligned,
  all_aligned,
  PM_df,
  ZQ_df,
  meetingName
)



# ----- Removing constant timeseries -----
filtered_timeseries <- list()
for (meetingName in meetings$meetingMonth) {
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

rm(
  timeseries_df,
  df_assets_only,
  assetNames,
  hasOnlyZeroes,
  meetingName
)


# ----- ADF test on original (non-constant) timeseries -----
adf_test_results <- list()
for (meetingName in meetings$meetingMonth) {
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


# WARNING: some reject explosive --> what do?
stationary_ts <- c()
for (meetingName in meetings$meetingMonth) {
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
for (meetingName in meetings$meetingMonth) {
  ts_df <- filtered_timeseries[[meetingName]]

  differenced_df <- ts_df |>
    dplyr::mutate(
      across(colnames(ts_df), ~ c(NA, diff(.)))
    ) |>
    # WARNING: What is this?
    filter(if_all(colnames(ts_df), ~ !is.na(.)))

  differenced_timeseries[[meetingName]] <- differenced_df
}

rm(ts_df, differenced_df, meetingName)


# ----- ADF test on differenced timeseries -----
adf_test_results_differenced <- list()
for (meetingName in meetings$meetingMonth) {
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
for (meetingName in meetings$meetingMonth) {
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

# all timeseries stationary except for
# this one that is kinda stationary anyway



# testing whether there is a trend/drift in levels
# If there is, ca.jo
for (meetingName in meetings$meetingMonth) {
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
bivariate_johansen_test <- list()
block_johansen_test <- list()
for (meetingName in meetings$meetingMonth) {
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


        trace_test_failed <- TRUE

        trace_test <- ca.jo(
          as.data.frame(testing_df), type = "trace",
          K = lag_choice, ecdet = "const",
          spec = "transitory" # Determines which formula Gamma is
        )

        trace_test_failed <- FALSE

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
      },
      error = function(e) {
        cat(
          "\nAn error occured",
          "\nin bivariate test",
          "\nPerforming:", ifelse(trace_test_failed, "trace", "eigen"), "test",
          "\nWhile processing:", meetingName,
          "\non assets:", unique_asset,
          "\nwith error message:", "\n",
          e$message, "\n"
        )

        trace_test <- NULL
        eigen_test <- NULL
      },
      finally = {
        bivariate_johansen_test[[meetingName]][[unique_asset]][["trace"]] <- trace_test
        bivariate_johansen_test[[meetingName]][[unique_asset]][["eigen"]] <- eigen_test
      }
    )
  }

  # blockwise granger test
  # FIX: Why is noChange still present below?
  PM_filter <- !startsWith(assetNames, "noChange") & endsWith(assetNames, "PM")
  ZQ_filter <- !startsWith(assetNames, "noChange") & endsWith(assetNames, "ZQ")

  PM_assets <- assetNames[PM_filter]
  ZQ_assets <- assetNames[ZQ_filter]

  # excludes noChange
  noBaseCase_df <- filtered_df[, c(PM_assets, ZQ_assets)]

  # var model
  var_select <- VARselect(noBaseCase_df, lag.max = 24)
  lag_choice <- var_select$selection["SC(n)"]

  # try to perform blockwise causality test, save NULL if fails
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
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nin blockwise test",
        "\nPerforming:", ifelse(trace_test_failed, "trace", "eigen"), "test",
        "\nWhile processing:", meetingName,
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      trace_test <- NULL
      eigen_test <- NULL
    },
    finally = {
      block_johansen_test[[meetingName]][["trace"]] <- trace_test
      block_johansen_test[[meetingName]][["eigen"]] <- eigen_test
    }
  )
}


rm(
  PM_assets,
  PM_filter,
  ZQ_assets,
  ZQ_filter,
  assetNames,
  eigen_test,
  filtered_df,
  hasBoth,
  lag_choice,
  noBaseCase_df,
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


# ----- Evaluating Johansen test (original timeseries) -----
# also testing whether linear trend is allowed in deterministic term
# If there is, redo Johansen procedure
vecm_fits_bivariate <- list()
vecm_fits_blockwise <- list()
for (meetingName in meetings$meetingMonth) {
  bivariate_results <- bivariate_johansen_test[[meetingName]]
  block_results <- block_johansen_test[[meetingName]]

  # pairwise (bivariate) case
  for (assetName in names(bivariate_results)) {
    trace_results <- bivariate_results[[assetName]][["trace"]]
    eigen_results <- bivariate_results[[assetName]][["eigen"]]

    cointegration_count_trace <- count_cointegrating_rels(trace_results)
    cointegration_count_eigen <- count_cointegrating_rels(eigen_results)

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


    # # Fit VECM model
    # if (cointegration_count_trace != 0) {
    #   vecm_fits_bivariate[[meetingName]][[assetName]]
    # }
  }

  # blockwise granger test
  trace_results <- block_results[["trace"]]
  eigen_results <- block_results[["eigen"]]

  cointegration_count_trace <- count_cointegrating_rels(trace_results)
  cointegration_count_eigen <- count_cointegrating_rels(eigen_results)

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
}


# Conclusion: not including linear ecdet anywhere


is.null(cointegration_count_trace)

rm(
  bivariate_results,
  block_results,
  cointegration_count_eigen
  cointegration_count_trace,
  eigen_results,
  lt_eigen,
  lt_trace,
  trace_results,
)

# Findings:
# There is a lot of cointegration


# TODO: Continue here, build VECM

# NOTE: Using trace test results to build vecm (?)

# # 1. Re-run your Johansen test to get the object
# johansen_test <- ca.jo(prices_df, type = "trace", ecdet = "const", K = 3)
#
# # 2. Estimate the VECM using cajorls()
# # We set r=1 because a bivariate system can have at most one cointegrating relationship
# vecm_fit <- cajorls(johansen_test, r = 1)
#
# # Look at the summary to find the speed of adjustment coefficients (the alphas)
# summary(vecm_fit$rlm)

count_cointegrating_rels(block_johansen_test[["2023-05"]][["trace"]])


# testing whether there is a trend/drift in differences:
for (meetingName in meetings$meetingMonth) {
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




cajo_obj <- block_johansen_test[["2023-05"]][["trace"]]
cajorls_obj <- cajorls(cajo_obj, r = 2)

class(cajo_obj)
class(cajorls_obj) 

# NOTE: Should I plot these?
# plot(cajo_obj)

cajo_obj
summary(cajo_obj)
cajo_obj@V # Eigenvectors (cointegration relations)
# 5x5
# filtered ts
# t x 4


count_cointegrating_rels(cajo_obj)

cajorls

# taken from cajorls function
r <- count_cointegrating_rels(cajo_obj)

beta <- matrix(cajo_obj@V[, 1:r], ncol = r)
C1 <- diag(r)
C2 <- matrix(0, nrow = nrow(beta) - r, ncol = r)
C <- rbind(C1, C2)
betanorm <- beta %*% solve(t(C) %*% beta)
# This is Y
# cajo_obj@ZK
# Y %*% beta
ECT <- cajo_obj@ZK %*% betanorm
colnames(ECT) <- paste("ect", 1:r, sep = "")

head(ECT)

# supposedly error correction terms, i.e. beta' * Y
%*% cajo_obj@V[, 1:count_cointegrating_rels(cajo_obj)]

head(cajo_obj@ZK)

as.matrix()
class(cajo_obj@ZK)

head(cajo_obj@ZK[,1:4])
head(as.matrix(filtered_timeseries[["2023-05"]][,c(1, 2, 3, 5)]))

all(cajo_obj@ZK[,1:4] == as.matrix(filtered_timeseries[["2023-05"]][-c(1, 8613),c(1, 2, 3, 5)]))



as.matrix(filtered_timeseries[["2023-05"]][,c(1, 2, 3, 5)]) %*% cajo_obj@V

cajo_obj@V


cajorls_obj
cajorls_obj$rlm
cajorls_obj$beta

# restricted VECM
class(cajorls_obj$rlm)

# normalised cointegrating vectors
class(cajorls_obj$beta)

vars::VARselect()
vars::VAR()

urca::cajorls()
urca::cajools()


#  Estimate VECM and Extract the Error Correction Term (ECT) ---
# # This is a crucial new step.
# vecm_model <- cajorls(johansen_test, r = cointegrating_rank)
#
# # The residuals of the rank-restricted regression are the ECTs.
# # We need to lag it by one period.
# ect <- vecm_model$rlm$residuals


asd <- block_johansen_test[["2023-05"]][["trace"]]
asd@spec

showMethods(classes = "ca.jo")

VAR()


summary(block_johansen_test[["2023-05"]][["trace"]])

# https://www.rdocumentation.org/packages/urca/versions/1.3-4/topics/ca.jo-class


head(filtered_timeseries$`2023-05`)

cajorls(block_johansen_test[["2023-05"]][["trace"]], r = 2)

asd <- cajorls(block_johansen_test[["2023-05"]][["trace"]], r = 2)


class(asd$rlm)




asd$rlm$residuals


summary(cajorls(block_johansen_test[["2023-05"]][["trace"]], r = 2)$rlm)

cajorls(block_johansen_test[["2023-05"]][["trace"]], r = 2)$beta

vec2var(block_johansen_test[["2023-05"]][["trace"]], r = 2)

class(cajorls(block_johansen_test[["2023-05"]][["trace"]], r = 2)$rlm)


jo_obj <- block_johansen_test[["2023-05"]][["trace"]]

v2v <- vars::vec2var(jo_obj, r = 2)

sessionInfo()

vars:::causality.vec2var(
  v2v,
  cause = colnames(v2v$y)[endsWith(colnames(v2v$y), ".PM")]
)

vars::causality(
  asd,
  cause = colnames(v2v$y)[endsWith(colnames(v2v$y), ".PM")]
)

summary(block_johansen_test[["2023-05"]][["trace"]])


summary(block_johansen_test[["2023-02"]][["eigen"]])
summary(block_johansen_test[["2023-02"]][["trace"]])
summary(block_johansen_test[["2023-03"]][["eigen"]])
summary(block_johansen_test[["2023-03"]][["trace"]])
summary(block_johansen_test[["2023-05"]][["eigen"]])
summary(block_johansen_test[["2023-05"]][["trace"]])
summary(block_johansen_test[["2023-06"]][["eigen"]])
summary(block_johansen_test[["2023-06"]][["trace"]])
summary(block_johansen_test[["2023-07"]][["eigen"]])
summary(block_johansen_test[["2023-07"]][["trace"]])
summary(block_johansen_test[["2023-09"]][["eigen"]])
summary(block_johansen_test[["2023-09"]][["trace"]])
summary(block_johansen_test[["2023-11"]][["eigen"]])
summary(block_johansen_test[["2023-11"]][["trace"]])
summary(block_johansen_test[["2023-12"]][["eigen"]])
summary(block_johansen_test[["2023-12"]][["trace"]])
summary(block_johansen_test[["2024-01"]][["eigen"]])
summary(block_johansen_test[["2024-01"]][["trace"]])
summary(block_johansen_test[["2024-03"]][["eigen"]])
summary(block_johansen_test[["2024-03"]][["trace"]])
summary(block_johansen_test[["2024-05"]][["eigen"]])
summary(block_johansen_test[["2024-05"]][["trace"]])
summary(block_johansen_test[["2024-06"]][["eigen"]])
summary(block_johansen_test[["2024-06"]][["trace"]])
summary(block_johansen_test[["2024-07"]][["eigen"]])
summary(block_johansen_test[["2024-07"]][["trace"]])
summary(block_johansen_test[["2024-09"]][["eigen"]])
summary(block_johansen_test[["2024-09"]][["trace"]])
summary(block_johansen_test[["2024-11"]][["eigen"]])
summary(block_johansen_test[["2024-11"]][["trace"]])
summary(block_johansen_test[["2024-12"]][["eigen"]])
summary(block_johansen_test[["2024-12"]][["trace"]])
summary(block_johansen_test[["2025-01"]][["eigen"]])
summary(block_johansen_test[["2025-01"]][["trace"]])
summary(block_johansen_test[["2025-03"]][["eigen"]])
summary(block_johansen_test[["2025-03"]][["trace"]])
summary(block_johansen_test[["2025-05"]][["eigen"]])
summary(block_johansen_test[["2025-05"]][["trace"]])
summary(block_johansen_test[["2025-06"]][["eigen"]])
summary(block_johansen_test[["2025-06"]][["trace"]])
summary(block_johansen_test[["2025-07"]][["eigen"]])
summary(block_johansen_test[["2025-07"]][["trace"]])


summary()


# ------ Actual granger causality test ------
PM_cause_ZQ_pairwise <- list()
ZQ_cause_PM_pairwise <- list()
PM_cause_ZQ_blockwise <- list()
ZQ_cause_PM_blockwise <- list()
for (meetingName in meetings$meetingMonth) {
  filtered_df <- filtered_timeseries[[meetingName]]
  assetNames <- colnames(filtered_df)
  unique_assets <- unique(substring(assetNames, 1, nchar(assetNames) - 3))

  # pairwise (bivariate) granger test
  for (unique_asset in unique_assets) {
    hasBoth <- sum(startsWith(assetNames, unique_asset)) == 2
    if (!hasBoth) next

    testing_df <- filtered_df[, startsWith(assetNames, unique_asset)]

    # var model
    var_select <- VARselect(testing_df, lag.max = 24)
    lag_choice <- var_select$selection["SC(n)"]
    VAR_model <- VAR(testing_df, p = lag_choice, type = "const")
    
    PM_causing <- causality(VAR_model, cause = paste0(unique_asset, ".PM"))
    ZQ_causing <- causality(VAR_model, cause = paste0(unique_asset, ".ZQ"))

    PM_cause_ZQ_pairwise[[meetingName]][[unique_asset]] <- PM_causing
    ZQ_cause_PM_pairwise[[meetingName]][[unique_asset]] <- ZQ_causing
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
  VAR_model <- VAR(noBaseCase_df, p = lag_choice, type = "const")

  # FIX: exclude basecase in each
  # try to perform blockwise causality test, save NULL if fails
  tryCatch(
    {
      PM_causing <- causality(VAR_model, cause = PM_assets)
      ZQ_causing <- causality(VAR_model, cause = ZQ_assets)
    },
    error = function(e) {
      cat(
        "\nAn error occured",
        "\nWhile processing:", meetingName,
        "\nwith error message:", "\n",
        e$message, "\n"
      )

      PM_causing <- NULL
      ZQ_causing <- NULL
    },
    finally = {
      PM_cause_ZQ_blockwise[[meetingName]] <- PM_causing
      ZQ_cause_PM_blockwise[[meetingName]] <- ZQ_causing
    }
  )
}

rm(
  meetingName,
  assetNames,
  unique_assets,
  unique_asset,
  PM_assets,
  ZQ_assets,
  PM_causing,
  ZQ_causing,
  hasBoth,
  var_select,
  lag_choice,
  VAR_model,
  testing_df,
  PM_filter,
  ZQ_filter
)

PM_cause_ZQ_pairwise
ZQ_cause_PM_pairwise

PM_cause_ZQ_blockwise
ZQ_cause_PM_blockwise

length(meetings$meetingMonth)



filtered_timeseries$`2023-09`
