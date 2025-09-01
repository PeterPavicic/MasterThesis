if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(tidyr)) install.packages("tidyr")
if (!require(ggplot2)) install.packages("ggplot2")

library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)

# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 

# loading data
SMART_CONTRACTS <- c(
  GNOSIS_CONTRACT = "0x4d97dcd97ec945f40cf65f87097ace5ea0476045",	# Conditional Tokens Framework (CTF)
  CTF_EXCHANGE = "0x4bfb41d5b3570defd03c39a9a4d8de6bd8b8982e",	# CTF Exchange
  NR_CTF_EXCHANGE = "0xc5d563a36ae78145c45a50134d48a1215220f80a",	# NegRisk_CTFExchange
  NR_ADAPTER = "0xd91e80cf2e7be2e162c6513ced06f1dd0da35296",	# NegRiskAdapter
  USDC.e = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",	# USDC.e (Collateral)
  UMA_V2 = "0x6a9d222616c90fca5754cd1333cfd9b7fb6a4f74",	# UMA Oracle (V2)
  GNOSIS_PROXY_WALLET_FACTORY = "0xaacfeea03eb1561c4e67d661e40682bd20e3541b",	# Gnosis Safe Proxy Factory
  POLYMARKET_PROXY_WALLET_FACTORY = "0xab45c5a4b0c941a2f231c04c3f49182e1a254052",	# Polymarket Proxy Factory
  NR_FEE_MODULE = "0x78769d50be1763ed1ca0d5e878d93f05aabff29e"	# Polymarket: Neg Risk Fee Module
)


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

meetingMonths <- c(
  "2023-02",
  "2023-03",
  "2023-05",
  "2023-06",
  "2023-07",
  "2023-09",
  "2023-11",
  "2023-12",
  "2024-01",
  "2024-03",
  "2024-05",
  "2024-06",
  "2024-07",
  "2024-09",
  "2024-11",
  "2024-12",
  "2025-01",
  "2025-03",
  "2025-05",
  "2025-06",
  "2025-07"
)

tokens_data <- read_csv(
  file.path(ROOT_DIR, "data/processed/tokens/FOMC Tokens.csv"),
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

# contains users' PnL, returns, real users
aggregateRDataVars(
  file.path(ROOT_DIR, "data/processed/UserPnLs/")
) 

# contains transactions, timeseries data
aggregateRDataVars(
  file.path(ROOT_DIR, "data/processed/EventDatas/") 
) 

names(scaled_eventsList) <- meetingMonths
names(event_nameList) <- meetingMonths
names(realUsersList) <- meetingMonths
names(userReturnsList) <- meetingMonths
names(userMarketCountList) <- meetingMonths


# summary(userReturnsList[[1]]$eventReturn)
# summary(userReturnsList[[2]]$eventReturn)
# summary(userReturnsList[[3]]$eventReturn)
# summary(userReturnsList[[4]]$eventReturn)
# summary(userReturnsList[[5]]$eventReturn)
# summary(userReturnsList[[6]]$eventReturn)
# summary(userReturnsList[[7]]$eventReturn)
# summary(userReturnsList[[8]]$eventReturn)
# summary(userReturnsList[[9]]$eventReturn)
# summary(userReturnsList[[10]]$eventReturn)
# summary(userReturnsList[[11]]$eventReturn)
# summary(userReturnsList[[12]]$eventReturn)
# summary(userReturnsList[[13]]$eventReturn)
# summary(userReturnsList[[14]]$eventReturn)
# summary(userReturnsList[[15]]$eventReturn)
# summary(userReturnsList[[16]]$eventReturn)
# summary(userReturnsList[[17]]$eventReturn)
# summary(userReturnsList[[18]]$eventReturn)
# summary(userReturnsList[[19]]$eventReturn)
# summary(userReturnsList[[20]]$eventReturn)
# summary(userReturnsList[[21]]$eventReturn)

# How do some make a loss of more than 7x?
# TODO: Fix UserReturns calculation
# by investigating this user:
# 0x4d4517f51bc23420bcad5fa56f82226bb13997f4

# which.min(userReturnsList[[20]]$eventReturn)
#
# userReturnsList[[20]][6841, ]
#
# unique(tokens_data$event_slug)

# tokens_data |>
#   filter(event_slug == "fed-decision-in-june") |>
#   pull(Yes)

# test_df <- scaled_eventsList[["2024-09"]]

# NOTE: This is also weird
# which.max(scaled_df$fee)
# system2(
#   command = "wl-copy",
#   input = unlist(scaled_df[1267, "maker"])
# )

# rm(test_df)



# ------ Correcting events ------
corrected_eventsList <- list()
for (meetingMonth in meetingMonths) {
  scaled_df <- scaled_eventsList[[meetingMonth]]
  isNegRisk <- any(scaled_df$taker == SMART_CONTRACTS["NR_CTF_EXCHANGE"])
  if (isNegRisk) {
    ctfContract <- SMART_CONTRACTS["NR_CTF_EXCHANGE"]
  } else {
    ctfContract <- SMART_CONTRACTS["CTF_EXCHANGE"]
  }


  # actions of the true taker, the one interacting with Exchange contract
  takerActions <- scaled_df |>
    filter(taker == ctfContract) |>
    mutate(
      # is the taker buying or selling
      trueTakerBuys = (type == "makerBuy"),
      trueTakerAsset = asset
    ) |>
    select(
      transactionHash,
      trueTakerBuys,
      trueTakerAsset
    )

  noExchange_df <- scaled_df |>
    filter(taker != ctfContract) |>
    mutate(
      takerBuys = !(type == "makerBuy")
    ) |>
    select(
      transactionHash,
      timestamp,
      maker,
      taker,
      asset,
      price,
      usdcVolume,
      tokenVolume,
      takerBuys,
      fee
    ) |> 
    inner_join(
      takerActions,
      by = "transactionHash"
    )

  # Types of transactions:
  # transfers:
  # takerBuys == trueTakerBuys
  # one side selling, other side buying
  # cash is simply transferred
  # buyer receives `tokenVolume` of `asset`,
  # seller gets the usdcVolume in return

  # splits (minting new token):
  # takerBuys != trueTakerBuys
  # both sides are buying (complementary assets)
  # maker receives the asset
  # taker DOES NOT receive the cash
  # in reality
  # 1. maker interacts with Exchange
  # gives `usdcVolume`
  # gets `tokenVolume` of `asset`
  # 2. taker interacts with Exchange
  # gives `tokenVolume - usdcVolume`
  # gets `tokenVolume` of `trueTakerAsset` (which is the complementary asset of `asset`)

  # merges (a token is burned):
  # takerBuys != trueTakerBuys
  # both sides are selling (complementary assets)
  # maker receives the cash
  # taker DOES NOT receive the asset
  # in reality
  # 1. maker interacts with Exchange,
  # gives `tokenVolume` of `asset`
  # gets `usdcVolume`
  # 2. taker interacts with Exchange,
  # gives `tokenVolume` of `trueTakerAsset` (which is the complementary asset of `asset`)
  # gets `tokenVolume - usdcVolume`

  isTransfer <- (noExchange_df$takerBuys == noExchange_df$trueTakerBuys)
  isSplit <- noExchange_df$trueTakerBuys & (noExchange_df$takerBuys != noExchange_df$trueTakerBuys)
  isMerge <- !(noExchange_df$trueTakerBuys) & (noExchange_df$takerBuys != noExchange_df$trueTakerBuys)

  # NOTE: transfers are not corrected but maybe they should be
  transfers_df <- noExchange_df[isTransfer, ]
  splits_df <- noExchange_df[isSplit, ]
  merges_df <- noExchange_df[isMerge, ]


  # -------- correcting transfers --------
  # duplicate all rows
  corrected_transfers <- transfers_df |>
    mutate(count = 2) |>
    uncount(count)

  # legs of transactions: first for maker, second for taker
  maker_leg <- seq(1, nrow(corrected_transfers), by = 2)
  taker_leg <- seq(2, nrow(corrected_transfers), by = 2)

  # maker leg of transfer
  corrected_transfers[maker_leg, ] <- corrected_transfers[maker_leg, ] |>
    mutate(
      taker = "exchange"
    )

  # taker leg of transfer
  corrected_transfers[taker_leg, ] <- corrected_transfers[taker_leg, ] |>
    mutate(
      maker = "exchange",
    )

  # -------- correcting splits --------
  # duplicate all rows
  corrected_splits <- splits_df |>
    mutate(count = 2) |>
    uncount(count)


  # legs of transactions: first for maker, second for taker
  maker_leg <- seq(1, nrow(corrected_splits), by = 2)
  taker_leg <- seq(2, nrow(corrected_splits), by = 2)

  # maker leg of split
  corrected_splits[maker_leg, ] <- corrected_splits[maker_leg, ] |>
    mutate(
      taker = "exchange"
    )

  # taker leg of split
  corrected_splits[taker_leg, ] <- corrected_splits[taker_leg, ] |>
    mutate(
      maker = "exchange",
      takerBuys = TRUE,
      usdcVolume = tokenVolume - usdcVolume,
      asset = trueTakerAsset
    )

  # -------- correcting merges --------
  # duplicate all rows
  corrected_merges <- merges_df |>
    mutate(count = 2) |>
    uncount(count)

  # legs of transactions: first for maker, second for taker
  maker_leg <- seq(1, nrow(corrected_merges), by = 2)
  taker_leg <- seq(2, nrow(corrected_merges), by = 2)

  # maker leg of merge
  corrected_merges[maker_leg, ] <- corrected_merges[maker_leg, ] |>
    mutate(
      taker = "exchange"
    )

  # taker leg of merge
  corrected_merges[taker_leg, ] <- corrected_merges[taker_leg, ] |>
    mutate(
      maker = "exchange",
      takerBuys = FALSE,
      usdcVolume = tokenVolume - usdcVolume,
      asset = trueTakerAsset
    )

  corrected_df <- bind_rows(
    corrected_transfers,
    # transfers_df,
    corrected_splits,
    corrected_merges
  ) |> arrange(
      timestamp,
      asset
    ) |>
    select(
      transactionHash,
      timestamp, 
      maker, 
      taker, 
      asset, 
      price, 
      usdcVolume, 
      tokenVolume, 
      takerBuys, 
      fee
    )

  corrected_eventsList[[meetingMonth]] <- corrected_df

  rm(
    corrected_df,
    corrected_merges,
    corrected_splits,
    corrected_transfers,
    ctfContract,
    isMerge,
    isNegRisk,
    isSplit,
    isTransfer,
    maker_leg,
    merges_df,
    noExchange_df,
    scaled_df,
    splits_df,
    takerActions,
    taker_leg,
    transfers_df
  )
}


# Contains per-user
# maker order token volume, usdcvolume
# taker order token volume, usdcvolume
# total returns
user_statsList <- list()

# Calculate order counts, volume for maker & taker side
# Save it to user_statsList
for (meetingMonth in meetingMonths) {
  # Grab event-specific variables
  corrected_events <- corrected_eventsList[[meetingMonth]]
  # realUsers <- realUsersList[[meetingMonth]]
  userReturns <- userReturnsList[[meetingMonth]]
  userMarketCount <- userMarketCountList[[meetingMonth]]

  corrected_events

  ###### Order counts ######
  # maker_order_counts <- corrected_events |>
  #   filter(maker != "exchange") |> # only rows where maker is real
  #   distinct(maker, transactionHash) |> # one row per unique maker+orderHash
  #   count(user = maker, # group by maker
  #     name = "makerCount")
  #
  # # Count unique orders per taker for realUsers
  # taker_order_counts <- corrected_events |> 
  #   filter(taker != "exchange") |> # only rows where taker is real
  #   distinct(taker, transactionHash) |>  # one row per unique taker+orderHash
  #   count(user = taker, name = "takerCount") # group by taker
  #
  # Merge maker and taker counts, filling missing with 0
  # order_counts <- full_join(maker_order_counts,
  #   taker_order_counts,
  #   by = "user") |>
  #   replace_na(list(makerCount = 0,
  #     takerCount = 0)) |>
  #   mutate(totalTradeCount = makerCount + takerCount)

  ###### Order volume ######
  maker_order_volume <- corrected_events |>
    filter(maker != "exchange") |>
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
  taker_order_volume <- corrected_events |> 
    filter(taker != "exchange") |> # only rows where taker is in realUsers
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

  # # Merge order counts & volume
  # order_stats <- order_counts |> 
  #   left_join(order_volume,
  #     by = "user")

  user_event_stats <- userReturns |> left_join(
    userMarketCount, by = "user")

  # Merge with user returns
  # TODO: Also add other metrics described above
  user_stats <- order_volume |> 
    left_join(user_event_stats,
      by = "user")

  user_statsList[[meetingMonth]] <- user_stats

  rm(
    corrected_events,
    # maker_order_counts,
    maker_order_volume,
    meetingMonth,
    # order_counts,
    # order_stats,
    order_volume,
    # realUsers,
    # taker_order_counts,
    taker_order_volume,
    userMarketCount,
    userReturns,
    user_stats
  )
}


for (meetingMonth in meetingMonths) {
  scaled_df <- scaled_eventsList[[meetingMonth]]
  print(meetingMonth)
  print(
    (sum(scaled_df[scaled_df$taker == SMART_CONTRACTS["NR_CTF_EXCHANGE"], "tokenVolume"]) == 
      sum(scaled_df[scaled_df$taker != SMART_CONTRACTS["NR_CTF_EXCHANGE"], "tokenVolume"])) | 
    (sum(scaled_df[scaled_df$taker == SMART_CONTRACTS["CTF_EXCHANGE"], "tokenVolume"]) == 
      sum(scaled_df[scaled_df$taker != SMART_CONTRACTS["CTF_EXCHANGE"], "tokenVolume"]))
  )
}


user_statsList

# still not the exact numbers I am looking for
# TODO: Figure out what else is off, perhaps when dealing with transfers?
# or implementation faulty for many transactions
for (meetingMonth in meetingMonths) {
  print(event_nameList[[meetingMonth]])
  # print(sum(scaled_eventsList[[meetingMonth]]$usdcVolume))
  print(sum(corrected_eventsList[[meetingMonth]]$usdcVolume))
  # print(sum(scaled_eventsList[[meetingMonth]]$tokenVolume))
  print(sum(corrected_eventsList[[meetingMonth]]$tokenVolume) / 2)
}


for (meetingMonth in meetingMonths) {
  print(event_nameList[[meetingMonth]])
  # print(length(unique(corrected_eventsList[[meetingMonth]]$maker)))
  # print(length(unique(corrected_eventsList[[meetingMonth]]$taker)))
  # print(length(unique(scaled_eventsList[[meetingMonth]]$maker)))
  # print(length(unique(scaled_eventsList[[meetingMonth]]$taker)))

  print(length(unique(corrected_eventsList[[meetingMonth]]$transactionHash)))
  print(length(unique(corrected_eventsList[[meetingMonth]]$transactionHash)))
  print(length(unique(scaled_eventsList[[meetingMonth]]$transactionHash)))
  print(length(unique(scaled_eventsList[[meetingMonth]]$transactionHash)))
}

View(corrected_eventsList[[meetingMonth]])


# july 2024
2791944.06709
2791944

# november 2024
189537155.167586
189548857

# december 2024
58771668.63480185
58771704



sum(corrected_eventsList[["2024-12"]]$tokenVolume)


# 3 times checking thing
# for (meetingMonth in meetingMonths) {
#   print(event_nameList[[meetingMonth]])
#   print(sum(user_statsList[[meetingMonth]]$totalTokenVolume) / 3)
#   # NOTE: Why is this 3 times what it should be and not twice?
# }
# intermediaries <- user_statsList[[15]]$makerUsdcVolume == user_statsList[[15]]$takerUsdcVolume
# hist(user_statsList[[15]]$eventReturn[intermediaries])
# summary(user_statsList[[15]]$totalUsdcVolume[intermediaries])
# summary(user_statsList[[15]]$totalTradeCount[intermediaries])
# user_statsList[[1]]
# rm(meetingMonth)

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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "returnHistSept.png"),
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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "USDCVolumeHistSept.png"),
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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "USDCTokenHistSept.png"),
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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "PnLHistSept.png"),
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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "makerUsdcProportion.png"),
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
  filename = file.path(ROOT_DIR, "/outputs/fomc/plots", "takerUsdcProportion.png"),
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
