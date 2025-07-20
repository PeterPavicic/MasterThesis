library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)


# Load all RData from specified directory into varList list
aggregateRDataVars <- function(directoryPath) {
  rdata_files <- list.files(path = directoryPath,
    pattern = "\\.RData$", full.names = TRUE)

  if (length(rdata_files) == 0) {
    stop("No RData files found in the specified directory.")
  }

  # Loop through each RData file
  for (file_path in rdata_files) {
    # Create new environment to load RData into
    load_env <- new.env()

    loaded_vars <- load(file_path, envir = load_env)

    # Loop through the names of variables that were loaded
    for (var_name in loaded_vars) {
      list_name <- paste0(var_name, "List")

      # Create list if it doesn't already exist in global environment
      if (!exists(list_name, envir = .GlobalEnv)) {
        assign(list_name, list(), envir = .GlobalEnv)
      }

      # Update list global environment with RData (local env) contents
      existing_list <- get(list_name, envir = .GlobalEnv)
      var_content <- get(var_name, envir = load_env)
      updated_list <- c(existing_list, list(var_content))
      assign(list_name, updated_list, envir = .GlobalEnv)
    }
  }
  # return(invisible(NULL))
}


tokens_data <- read_csv("./FOMC Tokens.csv",
  col_types = cols(
    Yes = col_character(),
    No = col_character()
  ))

tokens_outcomes <- tokens_data |>
  select(
    tokenId = Yes,
    tokenOutcome = outcomeYes
  ) |>
  bind_rows(
    tokens_data |> 
      select(
        tokenId = No,
        tokenOutcome = outcomeNo
      )
  )

aggregateRDataVars("./UserPnLs/")   # contains users' PnL, returns, real users
aggregateRDataVars("./EventDatas/") # contains transactions, timeseries data

# unique(timeSeriesData$asset)
# 
# yesTokens <- c("88244443360063235221444316604590968694314258311386447899087521723508440858841",
#                "106191328358576540351439267765925450329859429577455659884974413809922495874408",
#                "89262722133387845193166560202808972424089924545438804960915341631492994906283",
#                "95823178650727331613915203831778682038645976746731326695569990405131199144192")
# 
# 
# asd <- timeSeriesData |> 
#   filter(asset %in% yesTokens)
# 
# 
# library(ggplot2)
# library(patchwork)
# 
# # price panel
# p_price <- ggplot(asd, aes(timestamp, price, colour = asset)) +
#   geom_line(size = 1) +
#   theme_minimal() +
#   theme(legend.position = "bottom") +
#   labs(title = "Price over Time", y = "Price", x = NULL)
# 
# # volume panel
# p_vol <- ggplot(asd, aes(timestamp, tokenVolume, fill = asset)) +
#   geom_col(position = position_dodge()) + 
#   scale_x_datetime(date_labels = "%Y-%m-%d\n%H:%M") +
#   theme_minimal() +
#   theme(legend.position = "none") +
#   labs(title = "Token Volume", y = "Volume", x = "Timestamp")
# 
# # stack them
# (p_price / p_vol) + plot_layout(heights = c(2, 1))
# 
# 
# png(
#   filename = paste0("./Plots/", event_name, "returnHist.png"),
#   width = 800,
#   heigh = 600,
#   res = 100
# )


# Contains per-user
# maker order count, token volume, usdcvolume
# taker order count, token volume, usdcvolume
# total returns
user_statsList = list()

# Calculate order counts, volume for maker & taker side
# Save it to user_statsList
for (i in seq_along(event_nameList)) {
  # Grab event-specific variables
  scaled_events <- scaled_eventsList[[i]]
  realUsers <- realUsersList[[i]]
  userReturns <- userReturnsList[[i]]
  userMarketCount <- userMarketCountList[[i]]

  ###### Order counts ######
  maker_order_counts <- scaled_events |>
    filter(maker %in% realUsers) |> # only rows where maker is in realUsers
    distinct(maker, transactionHash) |> # one row per unique maker+orderHash
    count(user = maker, # group by maker
      name = "makerCount")

  # Count unique orders per taker for realUsers
  taker_order_counts <- scaled_events |> 
    filter(taker %in% realUsers) |> # only rows where taker is in realUsers
    distinct(taker, transactionHash) |>  # one row per unique taker+orderHash
    count(user = taker, name = "takerCount") # group by taker

  # Merge maker and taker counts, filling missing with 0
  order_counts <- full_join(maker_order_counts,
    taker_order_counts,
    by = "user") |>
    replace_na(list(makerCount = 0,
      takerCount = 0)) |>
    mutate(totalTradeCount = makerCount + takerCount)

  ###### Order volume ######
  maker_order_volume <- scaled_events |>
    filter(maker %in% realUsers) |> # only rows where maker is in realUsers
    group_by(maker) |>
    summarise(
      makerTokenVolume = sum(tokenVolume),
      makerUsdcVolume = sum(usdcVolume)
    ) |>
    ungroup() |>
    select(
      user = maker,
      makerTokenVolume,
      makerUsdcVolume
    )

  # Count unique orders per taker for realUsers
  taker_order_volume <- scaled_events |> 
    filter(taker %in% realUsers) |> # only rows where taker is in realUsers
    group_by(taker) |>
    summarise(
      takerTokenVolume = sum(tokenVolume),
      takerUsdcVolume = sum(usdcVolume)
    ) |> 
    ungroup() |>
    select(
      user = taker,
      takerTokenVolume,
      takerUsdcVolume
    )

  # Merge maker and taker counts, filling missing with 0
  order_volume <- full_join(maker_order_volume,
    taker_order_volume,
    by = "user") |>
    replace_na(
      list(
        makerTokenVolume = 0,
        makerUsdcVolume = 0,
        takerTokenVolume = 0,
        takerUsdcVolume = 0
      )
    ) |>
    mutate(
      totalTokenVolume = makerTokenVolume + takerTokenVolume,
      totalUsdcVolume = makerUsdcVolume + takerUsdcVolume
    )

  # Merge order counts & volume
  order_stats <- order_counts |> 
    left_join(order_volume,
      by = "user")

  user_event_stats <- userReturns |> left_join(
    userMarketCount, by = "user")

  # Merge with user returns
  # TODO: Also add other metrics described above
  user_stats <- order_stats |> 
    left_join(user_event_stats,
      by = "user")

  user_statsList[[i]] <- user_stats
  rm(scaled_events)
  rm(realUsers)
  rm(userReturns)
  rm(maker_order_counts)
  rm(maker_order_volume)
  rm(taker_order_counts)
  rm(taker_order_volume)
  rm(order_counts)
  rm(order_volume)
  rm(user_stats)
  rm(order_stats)
  rm(userMarketCount)
  rm(i)
}


meeting_dates <- c(
  as.POSIXct("2023-02-01 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_02_February"
  as.POSIXct("2023-03-22 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_03_March"
  as.POSIXct("2023-05-03 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_05_May"
  as.POSIXct("2023-06-14 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_06_June"
  as.POSIXct("2023-07-26 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_07_July"
  as.POSIXct("2023-09-20 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_09_September"
  as.POSIXct("2023-11-01 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_11_November"
  as.POSIXct("2023-12-13 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2023_12_December"
  as.POSIXct("2024-01-31 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_01_January"
  as.POSIXct("2024-03-20 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_03_March"
  # as.POSIXct("2024-05-01 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_06_June"
  as.POSIXct("2024-06-12 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_06_June"
  as.POSIXct("2024-07-31 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_07_July"
  as.POSIXct("2024-09-18 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_09_September"
  as.POSIXct("2024-11-07 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_11_November"
  as.POSIXct("2024-12-18 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2024_12_December"
  as.POSIXct("2025-01-29 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2025_01_January"
  as.POSIXct("2025-03-19 14:00:00", tz = "America/New_York"), # "Fed_Interest_Rates_2025_03_March"
  as.POSIXct("2025-05-07 14:00:00", tz = "America/New_York") # "Fed_Interest_Rates_2025_05_May"
)

# 3 times checking thing
# for (i in seq_along(event_nameList)) {
#   print(event_nameList[[i]])
#   print(sum(user_statsList[[i]]$totalTokenVolume) / 3)
#   # NOTE: Why is this 3 times what it should be and not twice?
# }
# intermediaries <- user_statsList[[15]]$makerUsdcVolume == user_statsList[[15]]$takerUsdcVolume
# hist(user_statsList[[15]]$eventReturn[intermediaries])
# summary(user_statsList[[15]]$totalUsdcVolume[intermediaries])
# summary(user_statsList[[15]]$totalTradeCount[intermediaries])
# user_statsList[[1]]
# rm(i)

master_table <- bind_rows(user_statsList, .id = "market_id")

winning_stats <- master_table |>
  mutate(
    winner = if_else(
      eventReturn > 0,
      TRUE,
      FALSE
    )
  ) |> 
  group_by(user) |>
  summarise(numberWon = sum(winner),
  numberLost = sum(1 - winner)) |>
  mutate(percentWon = numberWon / sum(numberWon, numberLost))


userSpending <- bind_rows(scaled_PnLList, .id = "market_id") |>
  filter(investmentSize != 0) |> 
  group_by(user) |>
  summarise(
    totalSpent = sum(investmentSize),
    totalPnL = sum(payoff),
    marketsParticipated = n()
  ) |>
  mutate(totalReturn = totalPnL / totalSpent)


sum(userSpending$totalReturn < -1, na.rm = TRUE)

hist(userSpending$totalReturn)

plot(userSpending$marketsParticipated,
userSpending$totalReturn)

# dev.new()

# ------- Descriptive statistics -------
png(
  filename = paste0("./Plots/", "returnHistSept.png"),
  width = 800,
  heigh = 600,
  res = 100
)
 
# Winners or Losers

# 29 percent win, 71% lose
sum(user_statsList[[13]]$eventReturn > 0) / length(user_statsList[[13]]$user)

toPlot <- user_statsList[[13]]$eventReturn
toPlotMean <- round(mean(toPlot), 4)
toPlotMedian <- round(median(toPlot), 4)

# event_nameList[[13]]
hist(toPlot, breaks = "Scott",
  main = "User returns for 2024 September market",
  xlab = "Return",
  xaxt = 'n'
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)

new_ticks <- seq(-1, 12, by = 1)
axis(side = 1, at = new_ticks)

dev.off()



# USDC Volume
png(
  filename = paste0("./Plots/", "USDCVolumeHistSept.png"),
  width = 800,
  heigh = 600,
  res = 100
)

# USDC volume lognormally distributed with mean: 
logvol <- log(user_statsList[[13]]$totalUsdcVolume[user_statsList[[13]]$totalUsdcVolume > 0])
summary(logvol)

toPlot <- logvol
toPlotMean <- round(exp(mean(toPlot)), 4)
toPlotMedian <- round(exp(median(toPlot)), 4)

event_nameList[[13]]
hist(toPlot, breaks = "Scott",
  main = "Total USDC volume for 2024 September market (log)",
  xlab = "Volume in $",
  xaxt = 'n'
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)
new_ticks <- seq(range(as.integer(summary(logvol)))[1], 
  range(as.integer(summary(logvol)))[2],
  by = 2)
axis(side = 1, at = new_ticks, labels = round(exp(new_ticks), 1))

dev.off()




# Token Volume
png(
  filename = paste0("./Plots/", "USDCTokenHistSept.png"),
  width = 800,
  heigh = 600,
  res = 100
)

# USDC volume lognormally distributed with mean: 
logvol <- log(user_statsList[[13]]$totalTokenVolume[user_statsList[[13]]$totalTokenVolume > 0])
summary(logvol)

toPlot <- logvol
toPlotMean <- round(exp(mean(toPlot)), 4)
toPlotMedian <- round(exp(median(toPlot)), 4)

event_nameList[[13]]
hist(toPlot, breaks = "Scott",
  main = "Total securities volume for 2024 September market (log)",
  xlab = "Asset Volume",
  xaxt = 'n'
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)

new_ticks <- seq(range(as.integer(summary(logvol)))[1], 
  range(as.integer(summary(logvol)))[2],
  by = 2)
axis(side = 1, at = new_ticks, labels = round(exp(new_ticks), 1))

dev.off()





# P&L Histogram
png(
  filename = paste0("./Plots/", "PnLHistSept.png"),
  width = 800,
  heigh = 600,
  res = 100
)

a <- user_statsList[[13]]$eventReturn * user_statsList[[13]]$totalUsdcVolume
# USDC volume lognormally distributed with mean: 
logvol <- log(abs(a[a != 0])) * sign(a[a != 0])
summary(logvol)


toPlot <- logvol
toPlotMean <- round(exp(mean(toPlot)), 4)
toPlotMedian <- round(exp(median(toPlot)), 4)

event_nameList[[13]]
hist(toPlot, breaks = "Scott",
  main = "log per-user PnL for 2024 September market",
  xlab = "PnL",
  xaxt = 'n'
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)

new_ticks <- seq(range(as.integer(summary(logvol)))[1], 
  range(as.integer(summary(logvol)))[2],
  by = 2)
axis(side = 1, at = new_ticks, labels = round(exp(new_ticks), 1))

dev.off()



# maker/taker
png(
  filename = paste0("./Plots/", "makerUsdcProportion.png"),
  width = 800,
  heigh = 600,
  res = 100
)

a <- user_statsList[[13]]$makerUsdcVolume / user_statsList[[13]]$totalUsdcVolume

toPlot <- a
toPlotMean <- round(mean(toPlot), 4)
toPlotMedian <- round(median(toPlot), 4)

# event_nameList[[13]]
hist(toPlot, breaks = "Sturges",
  main = "Per-user $ volume proportion of maker orders for 2024 September market",
  xlab = "USDC volume proportion",
  xaxt = 'n',
  xlim = c(0, 1)
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)

new_ticks <- seq(0, 1, by = .2)
axis(side = 1, at = new_ticks)

dev.off()


# maker/taker
png(
  filename = paste0("./Plots/", "takerUsdcProportion.png"),
  width = 800,
  heigh = 600,
  res = 100
)

a <- user_statsList[[13]]$takerUsdcVolume / user_statsList[[13]]$totalUsdcVolume


toPlot <- a
toPlotMean <- round(mean(toPlot), 4)
toPlotMedian <- round(median(toPlot), 4)

# event_nameList[[13]]
hist(toPlot, breaks = "Sturges",
  main = "Per-user $ volume proportion of taker orders for 2024 September market",
  xlab = "USDC volume proportion",
  xaxt = 'n',
  xlim = c(0, 1)
)
abline(v = toPlotMean, col = "#440154", lwd = 3)
abline(v = toPlotMedian, col = "#73D055", lwd = 3)
legend("topright",
  c(paste("Mean:", toPlotMean),
    paste("Median:", toPlotMedian)
  ),
  col = c("#440154", "#73D055"),
  lwd = 5
)

new_ticks <- seq(0, 1, by = .2)
axis(side = 1, at = new_ticks)

dev.off()



# Stuff from before
plot(user_order_counts$makerCount, user_order_counts$takerCount, log = 'xy',
  main = "Number of Maker and Taker orders",
  xlab = "Number of Maker orders",
  ylab = "Number of Taker orders")


abline(a = 0, b = 1, col = "red", lwd = 2)

hist(user_order_counts$makerCount / user_order_counts$totalTrades, freq = TRUE)


plot(user_order_counts$makerCount,
  user_order_counts$takerCount, log = "xy")


plot(sort(user_order_counts$makerCount), log = "y")

hist(user_order_counts$makerCount)
hist(user_order_counts$takerCount)




hist(user_statsList[[13]]$totalTradeCount)
hist(user_statsList[[13]]$makerUsdcVolume)
hist(user_statsList[[13]]$takerUsdcVolume)
hist(user_statsList[[13]]$takerCount)


min(scaled_eventsList[[13]]$timestamp)
max(scaled_eventsList[[13]]$timestamp)



# Above certain amounts, etc.
user_statsList[[13]]$totalUsdcVolume[user_statsList[[13]]$totalTradeCount > 2000]
event_nameList[[13]]
user_statsList[[13]]

?quantile((user_statsList[[13]]$totalUsdcVolume), .90)

user_statsList[[13]]$totalUsdcVolume[user_statsList[[13]]$totalTradeCount > 2000]
user_statsList[[13]]$eventReturn[user_statsList[[13]]$totalTradeCount > 2000]



# HFT stuff
HFT_class <- user_statsList[[13]] |> 
  mutate(
    tradesPerDay = totalTradeCount / 55
  ) |> 
  mutate(
    HFTType = if_else(
      tradesPerDay > 5,
      "HFT",
      "NotHFT"
    )
  )

# LPs
HFT_liquidity_class <- HFT_class |> 
  mutate(
    makerRatio = makerCount / totalTradeCount 
  ) |> 
  mutate(
    traderType = if_else(
      makerRatio > 0.8,
      "LP",
      if_else(
        makerRatio > 0.2,
        "Neither",
        "LT"
      )
    )
  )

HFT_liquidity_class

asd <- HFT_liquidity_class |> 
  mutate(
    winner = if_else(
      eventReturn > 1,
      "Profit",
      "Loss"
    )
  )

spineplot(asd)


lm()


sum(asd$winner == "Profit")
sum(asd$winner == "Loss")


# older things
ggplot(HFT_liquidity_class, aes(x = eventReturn)) +
  geom_histogram(bins = 30, colour = "black", fill = "grey80") +
  facet_grid(HFTType ~ traderType) +
  labs(
    title = "Histogram of Returns by HFT Status and Liquidity Role",
    x     = "Return",
    y     = "Count"
  ) +
  theme_bw()


all_data <- df_vol |> 
  left_join(
    asd,
    by = "user"
  )

colnames(all_data)

aaa <- lm(eventReturn ~ totalVol + totalTrades + HFTType + traderType, data = all_data)

summary(aaa)  

all_data


df_lorenz <- df_vol %>%
  arrange(desc(totalVol)) %>%
  mutate(userRank      = row_number(),
    cumVol        = cumsum(totalVol),
    totalVolume   = sum(totalVol),
    cumVolPct     = cumVol / totalVolume,
    totalUsers    = n(),
    cumUsersPct   = userRank / totalUsers)

library(ggplot2)
library(scales)

ggplot(df_lorenz, aes(x = cumUsersPct, y = cumVolPct)) +
  geom_line(size = 1) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Lorenz Curve: Cumulative % of Users vs. % of Token Volume",
    x = "Cumulative % of Users",
    y = "Cumulative % of Volume"
  ) +
  theme_minimal()
