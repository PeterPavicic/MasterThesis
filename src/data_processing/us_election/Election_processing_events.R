if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")

library(dplyr)
library(readr)
# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 


# WARNING: Unfinished
# Rewrite for election markets processing

perform_analysis <- function(event_tibble, event_name) {
  event_tibble |>
    arrange(timestamp)

  scaled_events <- event_tibble |>
    mutate(
      timestamp = as.POSIXct(timestamp, tz = "Europe/Vienna")
    ) |>
    mutate(
      type = if_else(makerAssetId == 0,
        "makerBuy",
        "makerSell")
    ) |>
    mutate(
      usdcVolume = if_else(type == "makerBuy",
        makerAmountFilled / 10^6,
        takerAmountFilled / 10^6),
      tokenVolume = if_else(type == "makerBuy",
        takerAmountFilled / 10^6,
        makerAmountFilled / 10^6),
      asset = if_else(type == "makerBuy",
        takerAssetId,
        makerAssetId)
    ) |>
    mutate(
      price = usdcVolume / tokenVolume
    ) |>
    select(
      timestamp,
      asset,
      price,
      usdcVolume,
      tokenVolume,
      type,
      maker,
      taker,
      transactionHash,
      orderHash
    )

  timeSeriesData <- scaled_events |>
    select(
      timestamp,
      asset,
      price,
      tokenVolume
    )

  write.csv(timeSeriesData,
    file.path(
      ROOT_DIR,
      "data/processed/",
      sprintf("TimeSeries/%s.csv", event_name)
    ),
    row.names = FALSE
  )

  save(
    event_name,
    scaled_events,
    timeSeriesData,
    file = file.path(
      ROOT_DIR,
      "data/processed/",
      sprintf("./EventDatas/%s.RData", event_name)
    )
  )
}


# WARNING: Unfinished
# Write root dir stuff
dirs <- list.dirs(
  path = file.path(
    ROOT_DIR,
    "data/raw/polymarket/transactions/fomc_transactions"
  ),
  recursive = FALSE
)

# Write users to users.txt for each event
# For each event perform analysis
for (dir in dirs) {
  event_name <- last(strsplit(dir, "/")[[1]])
  csv_files <- file.path(dir, list.files(path = dir, pattern = "orderFilledEvents.*\\.csv$"))

  all_markets_for_event <- bind_rows(sapply(csv_files, function(x) {
    read_csv(x,
      col_types = cols(
        maker = col_character(),
        taker = col_character(),
        makerAssetId = col_character(),
        takerAssetId = col_character()
      )) |>
      as_tibble()
  }, simplify = FALSE))

  perform_analysis(all_markets_for_event, event_name)
}
