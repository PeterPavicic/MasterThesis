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


# TODO: Check if following reasonable:
# TODO: Remove observations where not all assets are priced (a.k.a have an unscaled price of 0)





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

# Proportion of datapoints excluded
(trades_num_with_weekend - trades_num_without_weekend) / trades_num_with_weekend


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

PM_whichLatestZero


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

PM_latest_below_matrix

trades_num_without_weekend["2024-01"]


# The idea now is to remove the observations
# where the sum of the last-trade asset prices in the events 
# are less than 0.2

# However:

# 1) In the 2023-12, removing these observations would erase most of the datapoints
trades_num_without_weekend["2023-12"]
# 2) In the 2024-01 markets, it would erase 25% of the datapoints
trades_num_without_weekend["2024-01"]

# 3) This data reveals some insights: there is an abnormal period of trading in the March 2025 market:
(PM_data_scaled_no_weekend$`2025-03`[16510:16515, ])$unscaled_sum

# Removing these observations fixes this:
max(
  which(
    ((PM_data_scaled_no_weekend$`2025-03`[-(16510:16515), ])$unscaled_sum) < 0.2
  )
)

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



ZQ_avg_trading_freq_stats[, "Mean"]
PM_avg_trading_freq_stats[, "Mean"]

PM_df
test_timePoint <- PM_df$time[4]



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

  # TODO: Figure out why this can happen
  # remove first row if any observations are NA
  if (any(is.na(all_aligned[1, ]))) all_aligned <- all_aligned[-1, ]
  vectorised_timeseries[[meetingName]] <- all_aligned
}


logit <- function(p) log(p / (1 - p))
# HACK: arbitrarily chosen
replace_zero <- 1e-4
log_odds_timeseries <- list()
for (meetingName in meetings$meetingMonth) {
  timeseries_df <- vectorised_timeseries[[meetingName]]
  log_odds_df <- timeseries_df |>
    mutate(
      across(!c(timestamp), ~ if_else(. == 0, replace_zero, .))
    ) |> 
    mutate(
      across(!c(timestamp), ~ logit(.))
    )
  log_odds_timeseries[[meetingName]] <- log_odds_df
}



# ADF test
# WARNING: some reject stationarity --> what do?
adf_test_results <- list()
for (meetingName in meetings$meetingMonth) {
  timeseries_df <- log_odds_timeseries[[meetingName]]

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


for (df in vectorised_timeseries) {
  print(any(is.na(df)))
}

# TODO: Continue here
# TODO: rm() loop variables after every `for` loop

PM_grid <- list()
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_filtered[[meetingName]]

  PM_grid[[meetingName]]
}



View(PM_data_unscaled$`2024-11`)
