if (!require(dplyr)) install.packages("dplyr")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(lubridate)) install.packages("lubridate")
if (!require(readr)) install.packages("readr")
# if (!require(svglite)) install.packages("svglite")
if (!require(tibble)) install.packages("tibble")
if (!require(tidyr)) install.packages("tidyr")
if (!require(viridis)) install.packages("viridis")

library(dplyr)
library(ggplot2)
library(lubridate)
library(readr)
# library(svglite)
library(tibble)
library(tidyr)
library(viridis)


# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 

load("./FOMC_preprocesed.RData")

# head(meetings)
# head(tokens)
# head(PM_data)
# head(ZQ_data)


# Assumes ZQ_list comes in correct chronological order
# Takes list of 2 and performs full_join on time.  
# Resulting tibble has columns time, rateBps.1, rateBps.2
unify_ZQ <- function(ZQ1, ZQ2) {
  if (any(is.na(ZQ1)) || any(is.na(ZQ2))) stop("ZQ tibbles missing in input")

  # First joining
  unified <- ZQ1 |>
    full_join(
      ZQ2,
      by = "time",
      suffix = c(".1", ".2")
    ) |>
    select(
      time,
      rateBps.1,
      rateBps.2,
    ) |>
    arrange(time) |>
    fill(
      rateBps.1,
      rateBps.2,
      .direction = "downup")

  unified
}


# ------- Calculating the intramonth price-implied rates -------
# We want to calculate the implied EFFR at the beginning and the end of the month
# (so we can compute the risk-neutral expected change in the EFFR, thereby estimating the Fed decision)
# ------ Formulas ------
# N: number of days in current month before meeting (incl. both meeting days)
# M: number of days in current month after meeting
# startRate: implied EFFR at beginning of the month
# endRate: implied EFFR at end of the current month
# avgRate: implied average EFFR for the month

# FedWatch assumption:
# Only meeting changes EFFR ==> avgRate is day-weighted average of startRate and endRate

# avgRate:
# avgRate = [M / (N + M)] * endRate + [N / (N + M)] * startRate 
# avgRate = [ weightEnd ]   * endRate + [weightStart] * startRate

# startRate:
# [weightEnd] * endRate + [weightStart] * startRate = avgRate
# [weightStart] * startRate = avgRate - [weightEnd] * endRate
# startRate = [1 / weightStart] * avgRate - [weightEnd / weightStart] * endRate

# endRate:
# [weightEnd] * endRate + [weightStart] * startRate = avgRate
# [weightEnd] * endRate = avgRate - [weightStart] * startRate 
# endRate = [1 / weightEnd] * avgRate - [weightStart / weightEnd] * startRate 

# wrapper to be called inside of `apply` in main loop
# which takes rows containing meetings & applies relevant calculations to get
# outcomes and their associated probabilities
# which will be saved to a list where each entry will be a meeting
meeting_implied_rates <- function(meetingRow) {
  # Parsing all datatypes correctly
  meetingTime <- as.POSIXct(meetingRow[["meetingTime"]], tz = "America/New_York")
  meetingMonth <- meetingRow[["meetingMonth"]]
  previousMonthIsAnchor <- as.logical(meetingRow[["previousMonthIsAnchor"]])
  nextMonthIsAnchor <- as.logical(meetingRow[["nextMonthIsAnchor"]])
  nextNextMonthIsAnchor <- as.logical(meetingRow[["nextNextMonthIsAnchor"]])
  PM_data_start <- as.POSIXct(meetingRow[["data_start"]], tz = "America/New_York")
  PM_data_end <- as.POSIXct(meetingRow[["data_end"]], tz = "America/New_York")


  # for current month:
  # days before meeting (incl. meeting days)
  N <- day(meetingTime)
  # days after meeting (excl. meeting days)
  M <- days_in_month(meetingTime) - day(meetingTime)

  ZQ_current <- ZQ_data[[meetingMonth]] |>
    filter(
      PM_data_start <= time,
      time <= PM_data_end
    )

  if (meetingRow[["previousMonthIsAnchor"]]) {
    previous_month_name <- format(as.Date(paste0(meetingMonth, "-01")) - months(1), "%Y-%m") 

    ZQ_previous <- ZQ_data[[previous_month_name]] |>
      filter(
        PM_data_start <= time,
        time <= PM_data_end
      )

    intraMonthRates <- IRPreviousMonthAnchor(N, M, ZQ_previous, ZQ_current)

  } else if (meetingRow[["nextMonthIsAnchor"]]) {
    next_month_name <- format(as.Date(paste0(meetingMonth, "-01")) + months(1), "%Y-%m") 

    ZQ_next <- ZQ_data[[next_month_name]] |>
      filter(
        PM_data_start <= time,
        time <= PM_data_end
      )


    intraMonthRates <- IRNextMonthAnchor(N, M, ZQ_current, ZQ_next)

  } else if (meetingRow[["nextNextMonthIsAnchor"]]) {
    next_month_name <- format(as.Date(paste0(meetingMonth, "-01")) + months(1), "%Y-%m") 

    ZQ_next <- ZQ_data[[next_month_name]] |> 
      filter(
        PM_data_start <= time,
        time <= PM_data_end
      )

    next_next_month_name <- format(as.Date(paste0(meetingMonth, "-01")) + months(2), "%Y-%m") 

    ZQ_next_next <- ZQ_data[[next_next_month_name]] |> 
      filter(
        PM_data_start <= time,
        time <= PM_data_end
      )

    nextMonthMeetingDate <- meetings |>
      filter(meetingMonth == next_month_name) |>
      pull(meetingTime)

    nextMonthMeeting_N <- day(nextMonthMeetingDate)
    nextMonthMeeting_M <- days_in_month(meetingTime) - day(meetingTime)

    intraMonthRates <- IRNextNextMonthAnchor(
      N, M,
      nextMonthMeeting_N, nextMonthMeeting_M,
      ZQ_current, ZQ_next, ZQ_next_next
    )
  } else {
    stop("Neither previous or next 2 months are anchor months")
  }

  implied_probabilities <- get_probabilities(intraMonthRates$changeBps)

  tibble(
    time = intraMonthRates$time,
    implied_probabilities
  )
}

IRPreviousMonthAnchor <- function(N, M, ZQ1, ZQ2) {
  # ZQ1 is ZQ data for previous month
  # ZQ2 is ZQ data for current month
  # N: number of days in current month before meeting (incl. both meeting days)
  # M: number of days in current month after meeting (incl. both meeting days)

  unified_df <- unify_ZQ(ZQ1, ZQ2)

  previousMonth <- unified_df |>
    select(
      time,
      rateBps = rateBps.1
    )

  currentMonth <- unified_df |>
    select(
      time,
      rateBps = rateBps.2
    )

  weightStart <- N / (N + M)
  weightEnd <- M / (N + M) # = 1 - weightStart

  # in Bps
  startRate <- previousMonth$rateBps 
  avgRate <- currentMonth$rateBps 

  endRate <- (1 / weightEnd) * avgRate - (weightStart / weightEnd) * startRate 
  changeBps <- endRate - startRate

  # NOTE: Should this function only return the implied rate change instead?
  tibble(
    time = unified_df$time,
    startRate,
    avgRate,
    endRate,
    changeBps
  )
}

IRNextMonthAnchor <- function(N, M, ZQ1, ZQ2) {
  # ZQ1 is ZQ data for current month
  # ZQ2 is ZQ data for next month
  # N: number of days in current month before meeting (incl. both meeting days)
  # M: number of days in current month after meeting (incl. both meeting days)

  unified_df <- unify_ZQ(ZQ1, ZQ2)

  currentMonth <- unified_df |>
    select(
      time,
      rateBps = rateBps.1
    )

  nextMonth <- unified_df |>
    select(
      time,
      rateBps = rateBps.2
    )
  
  # and in Bps
  endRate <- nextMonth$rateBps 
  avgRate <- currentMonth$rateBps 

  weightStart <- N / (N + M)
  weightEnd <- M / (N + M) # = 1 - weightStart

  startRate <- (1 / weightStart) * avgRate - (weightEnd / weightStart) * endRate
  
  changeBps <- endRate - startRate

  # NOTE: Should this function only return the implied rate change instead?
  tibble(
    time = unified_df$time,
    startRate,
    avgRate,
    endRate,
    changeBps
  )
}

IRNextNextMonthAnchor <- function(N1_2, M1_2, N2_3, M2_3, ZQ1, ZQ2, ZQ3) {
  nextMonth <- IRNextMonthAnchor(N2_3, M2_3, ZQ2, ZQ3)

  nextMonth_renamed <- nextMonth |>
    as_tibble() |>
    select(time, rateBps = startRate)

  IRNextMonthAnchor(N1_2, M1_2, ZQ1, nextMonth_renamed)
}


# ------- Calculating price-implied risk-neutral probabilities -------
get_probabilities <- function(changeBps) {
  # NOTE: Here we get outcomes and probabilities for lower and higher rates (increments of 25 bps) for 
  # possible changes to the interest rates
  
  # Division of changeBps by 25 bps yields the number of implied IR cuts which can be decomposed into:
  # characteristic: characteristic (integer part)
  # mantissa: mantissa (decimal points part)
  characteristic <- (abs(changeBps / 25) %/% 1) * sign(changeBps)
  mantissa <- (abs(changeBps / 25) %% 1) * sign(changeBps)
  
  # The characteristic determines the lower bound of potential rate hikes or cuts
  # (step #7 from FedWatch Methodology)
  lower <- (characteristic + floor(mantissa)) * 25
  upper <- lower + 25
  
  
  # The mantissa determines the probability of hikes or cuts of the size of the lower bound
  # (step #8 from FedWatch Methodology)
  # if mantissa < 0:
  # lowerProb = - mantissa
  #
  # if mantissa > 0:
  # lowerProb = 1 - mantissa
  # 
  # if mantissa = 0:
  # lowerProb = 1
  #
  # combined:
  # lowerProb = I_{0 <= mantissa} - mantissa 
  
  lowerProb <- (0 <= mantissa) - mantissa
  upperProb <- 1 - lowerProb
  
  rates_implied_prob <- tibble(
    lower,
    lowerProb,
    upper,
    upperProb,
  ) |>
    mutate(
      # Initialise all possible change probabilities
      down100 = 0,
      down75 = 0,
      down50 = 0,
      down25 = 0,
      noChange = 0,
      up25 = 0,
      up50 = 0,
      up75 = 0,
      up100 = 0,
      # get named changes
      lowerName = case_when(
        lower == 0 ~ "noChange",
        lower < 0 ~ paste0("down", abs(lower)),
        lower > 0 ~ paste0("up", abs(lower))
      ),
      upperName = case_when(
        upper == 0 ~ "noChange",
        upper < 0 ~ paste0("down", abs(upper)),
        upper > 0 ~ paste0("up", abs(upper))
      )
    )
  
  # fill grid for down100, down75, etc.
  for (rowIndex in seq_len(nrow(rates_implied_prob))) {
    lowerRate <- rates_implied_prob[[rowIndex, "lowerName"]]
    rates_implied_prob[rowIndex, lowerRate] <- rates_implied_prob[rowIndex, "lowerProb"]
    upperRate <- rates_implied_prob[[rowIndex, "upperName"]]
    rates_implied_prob[rowIndex, upperRate] <- rates_implied_prob[rowIndex, "upperProb"]
  }

  rates_implied_prob |>
    select(
      down100,
      down75,
      down50,
      down25,
      noChange,
      up25,
      up50,
      up75,
      up100
    )
}

# Putting it all together
ZQ_Implied_Probs <- apply(meetings, 1, meeting_implied_rates)
names(ZQ_Implied_Probs) <- meetings$meetingMonth


PM_data_unscaled <- PM_data
rm(PM_data)


# scale each PM_data tibble so probabilities sum to 1
# but also store unscaled sum for reference
PM_data_scaled <- list()
for (i in seq_along(PM_data_unscaled)) {
  PM_df <- PM_data_unscaled[[i]]
  PM_data_scaled[[i]] <- PM_df |>
    rowwise() |>
    mutate(
      unscaled_sum = sum(c_across(-time))
    ) |> 
    mutate(
      across(-c(time, unscaled_sum), function(x) {x / unscaled_sum})
    ) |> 
    ungroup()
}

rm(i, PM_df)

names(PM_data_scaled) <- names(PM_data_unscaled)

meetingMonths <- meetings$meetingMonth


save(
  PM_data_scaled,
  PM_data_unscaled,
  ZQ_Implied_Probs,
  meetingMonths,
  file = "./FOMC_Granger_Causality.RData"
)

load("./FOMC_Granger_Causality.RData")
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 

# ------- Plotting every asset in every meeting -------
for (meetingName in meetings$meetingMonth) {
  # get asset names from current polymarket market
  PM_df <- PM_data_unscaled[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) == "time")]

  # only select ones with bets on Polymarket
  ZQ_IP_df_unfiltered <- ZQ_Implied_Probs[[meetingName]]
  ZQ_IP_df <- ZQ_IP_df_unfiltered |>
    dplyr::select(time, all_of(assetNames))


  # how many rows in plot such that there are always two plots in one row
  rowCountInPlot <- ceiling(length(assetNames) / 2)

  # Where to save plot
  png(
    filename = file.path(ROOT_DIR,
      "outputs/fomc/plots/ZQ_PM_comparison",
      paste0("ZQ_PM_FOMC_meeting_", 
        sub("-", "_", meetingName), ".png")
    ),
    width = 1600,
    height = 600 * rowCountInPlot,
    res = 100 * rowCountInPlot,
    type = "cairo-png",
    antialias = "subpixel"
  )

  # svglite(
  #   filename = file.path(ROOT_DIR,
  #     "outputs/fomc/plots/ZQ_PM_comparison",
  #     paste0("ZQ_PM_FOMC_meeting_", 
  #       sub("-", "_", meetingName), ".svg")
  #   ), 
  #   width = 7,
  #   height = 5
  # )

  # always have enough space for plots, 2 columns
  par(
    mfrow = c(
      rowCountInPlot,
      2
    ),
    oma = c(0, 0, 3, 0)
  )

  for (assetName in assetNames) {
    PM_time <- PM_df$time
    PM_probs <- PM_df[[assetName]]

    ZQ_time <- ZQ_IP_df$time
    ZQ_probs <- ZQ_IP_df[[assetName]]

    # Initialise plotting area
    plot(PM_time, PM_probs, type = 'n', ylim = c(0, 1),
      main = assetName,
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
    lines(PM_time, PM_probs, type = 'l', col = "#2D9CDB")
    # ZQ implied probabilities
    lines(ZQ_time, ZQ_probs, type = 'l', col = "#FF5952")
    # legend("right", legend = c("Polymarket", "ZQ-implied"),
    #   col = c("#2D9CDB", "#FF5952"), lwd = 2)
  }

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
}


ZQ_minute_distances <- list()
PM_minute_distances <- list()

# ------- Plotting pauses in trading -------
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_data_unscaled[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]

  # only select ones with bets on Polymarket
  ZQ_df <- ZQ_Implied_Probs[[meetingName]] |>
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
      "outputs/fomc/plots/granger_causality/trading_pauses_with_weekends",
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


  plot(
    ZQ_timeIndexToPlot, ZQ_toPlot, type = 'l',
    main = paste("ZQ Minutes distance"),
    xlab = "time",
    yaxt = 'n'
  )
  ZQ_ticks <- seq(range(as.integer(summary(ZQ_toPlot)))[1], 
    range(as.integer(summary(ZQ_toPlot)))[2],
    by = 2)
  axis(side = 2, at = ZQ_ticks, labels = round(exp(ZQ_ticks), 1))

  plot(
    PM_timeIndexToPlot, PM_toPlot, type = 'l',
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

rbind(
  summary(ZQ_minute_distances[[1]]),
  summary(ZQ_minute_distances[[2]]),
  summary(ZQ_minute_distances[[3]]),
  summary(ZQ_minute_distances[[4]]),
  summary(ZQ_minute_distances[[5]]),
  summary(ZQ_minute_distances[[6]]),
  summary(ZQ_minute_distances[[7]]),
  summary(ZQ_minute_distances[[8]]),
  summary(ZQ_minute_distances[[9]]),
  summary(ZQ_minute_distances[[10]]),
  summary(ZQ_minute_distances[[11]]),
  summary(ZQ_minute_distances[[12]]),
  summary(ZQ_minute_distances[[13]]),
  summary(ZQ_minute_distances[[14]]),
  summary(ZQ_minute_distances[[15]]),
  summary(ZQ_minute_distances[[16]]),
  summary(ZQ_minute_distances[[17]]),
  summary(ZQ_minute_distances[[18]]),
  summary(ZQ_minute_distances[[19]]),
  summary(ZQ_minute_distances[[20]]),
  summary(ZQ_minute_distances[[21]])
)

rbind(
  summary(PM_minute_distances[[1]]),
  summary(PM_minute_distances[[2]]),
  summary(PM_minute_distances[[3]]),
  summary(PM_minute_distances[[4]]),
  summary(PM_minute_distances[[5]]),
  summary(PM_minute_distances[[6]]),
  summary(PM_minute_distances[[7]]),
  summary(PM_minute_distances[[8]]),
  summary(PM_minute_distances[[9]]),
  summary(PM_minute_distances[[10]]),
  summary(PM_minute_distances[[11]]),
  summary(PM_minute_distances[[12]]),
  summary(PM_minute_distances[[13]]),
  summary(PM_minute_distances[[14]]),
  summary(PM_minute_distances[[15]]),
  summary(PM_minute_distances[[16]]),
  summary(PM_minute_distances[[17]]),
  summary(PM_minute_distances[[18]]),
  summary(PM_minute_distances[[19]]),
  summary(PM_minute_distances[[20]]),
  summary(PM_minute_distances[[21]])
)


# Set Monday as start of week
options("lubridate.week.start" = 1)

# ------- Plotting trading by day of week -------
for (meetingName in meetings$meetingMonth) {
  PM_df <- PM_data_unscaled[[meetingName]]
  assetNames <- colnames(PM_df)[!(colnames(PM_df) %in% c("time"))]

  # only select ones with bets on Polymarket
  ZQ_df <- ZQ_Implied_Probs[[meetingName]] |>
    dplyr::select(time, all_of(assetNames))

  # difference in minutes
  ZQ_trading_day <- wday(ZQ_df$time)
  PM_trading_day <- wday(PM_df$time)

  # Where to save plot
  png(
    filename = file.path(ROOT_DIR,
      "outputs/fomc/plots/granger_causality/day_of_week_trading_freq",
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
    

  barplot(table(ZQ_trading_day),
    main = "ZQ trading frequency on days of week",
    xlab = "day of week",
  )

  barplot(table(PM_trading_day),
    main = paste("PM trading frequency on days of week"),
    xlab = "day of week"
  )

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
}
