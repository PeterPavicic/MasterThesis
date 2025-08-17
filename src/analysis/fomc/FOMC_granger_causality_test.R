if (!require(dplyr)) install.packages("dplyr")
if (!require(tibble)) install.packages("tibble")
if (!require(tidyr)) install.packages("tidyr")
if (!require(vars)) install.packages("vars")

library(dplyr)
library(tibble)
library(tidyr)
library(vars)

# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 
load("./FOMC_Granger_Causality.RData")
ZQ_IP_unfiltered <- ZQ_Implied_Probs
rm(ZQ_Implied_Probs)


# TODO: Make both IP vars contain data that is also filtered for time 
# (match time, PM_data should have reasonable unscaled_sum)
# PM_IP should not contain unscaled_sum anymore



# meetingName <- "2023-02"

ZQ_minute_distances <- list()
PM_minute_distances <- list()

# NOTE: timeseries skips weekends ==> assumption of no weekend effect
# NOTE: Using unscaled Polymarket data ==> probabilities almost never add up to 1


# ------- Plotting pauses in trading -------
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_data_unscaled[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]

  # only select ones with bets on Polymarket
  ZQ_df <- ZQ_IP_unfiltered[[meetingName]] |>
    dplyr::select(time, all_of(assetNames))

  # difference in minutes
  ZQ_m_distance <- diff(as.numeric(ZQ_df$time) / 60)
  PM_m_distance <- diff(as.numeric(PM_df$time) / 60)

  ZQ_timeIndex <- ZQ_df$time
  ZQ_timeIndexToPlot <- (ZQ_timeIndex)[2:length(ZQ_timeIndex)]
  ZQ_toPlot <- log(ZQ_m_distance)

  PM_timeIndex <- PM_df$time
  PM_timeIndexToPlot <- (PM_timeIndex)[2:length(PM_timeIndex)]
  PM_toPlot <- log(PM_m_distance)

  # Where to save plot
  png(
    filename = file.path(ROOT_DIR,
      "outputs/fomc/plots/granger_causality/trading_pauses",
      paste0("FOMC_meeting_", 
        sub("-", "_", meetingName), ".png")
    ),
    width = 1600,
    height = 600,
    res = 100,
    type = "cairo-png",
    antialias = "subpixel"
  )

  par(mfrow = c(1, 2), oma = c(0, 0, 3, 0))
    

  plot(ZQ_timeIndexToPlot, ZQ_toPlot, type = 'l',
    main = paste("ZQ Minutes distance"),
    xlab = "time",
    yaxt = 'n'
  )
  ZQ_ticks <- seq(range(as.integer(summary(ZQ_toPlot)))[1], 
    range(as.integer(summary(ZQ_toPlot)))[2],
    by = 2)
  axis(side = 2, at = ZQ_ticks, labels = round(exp(ZQ_ticks), 1))

  plot(PM_timeIndexToPlot, PM_toPlot, type = 'l',
    main = paste("PM Minutes distance"),
    xlab = "time",
    yaxt = 'n'
  )
  PM_ticks <- seq(range(as.integer(summary(PM_toPlot)))[1], 
    range(as.integer(summary(PM_toPlot)))[2],
    by = 2)
  axis(side = 2, at = PM_ticks, labels = round(exp(PM_ticks), 1))

  # Large title for the entire plot
  title(
    paste(
      "FOMC meeting",
      format(as.Date(paste0(meetingName, "-01")), "%Y %B")
    ),
    cex.main = 1.5,
    # cex.adj = c(0, -2),
    line = -0.5,
    outer = TRUE
  )

  dev.off()

  ZQ_minute_distances[[meetingName]] <- ZQ_m_distance
  PM_minute_distances[[meetingName]] <- PM_m_distance
}


