library(dplyr)

# NOTE: This file assumes the working directory has been set to the directory this file is in.


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

  write.csv(timeSeriesData, sprintf("./TimeSeries/%s.csv", event_name))
  save.image(sprintf("./EventDatas/%s.RData", event_name))
}





dirs <- list.dirs(path = file.path(dirname(getwd()), "Data Transactions/All Fed Events"), recursive = FALSE)
file.path(dirs)
# Write users to users.txt for each event
# For each event perform analysis
for (dir in dirs) {
  event_name <- last(strsplit(dir, "/")[[1]])
  csv_files <- file.path(dir, list.files(path = dir, pattern = "orderFilledEvents.*\\.csv$"))
  all_markets_for_event <- bind_rows(sapply(csv_files, function(x) read.csv(x) |> as_tibble(), simplify = FALSE))

  perform_analysis(all_markets_for_event, event_name)


  # Unique tokens, excluding 0
  tokens <- sort(unique(
    c(all_markets_for_event$makerAssetId,
      all_markets_for_event$takerAssetId)))
  tokens_string <- sprintf("\"%s\"", as.character(tokens[tokens != 0]))

  # print(tokens)
  # users <- unique(all_markets_for_event$maker, all_markets_for_event$taker)

  # users_path <- file.path(dir, "users.txt")
  tokens_path <- file.path(dir, "tokens.txt")

  write(tokens_string, tokens_path, sep = "\n")
  cat("Succesfully saved tokens to", tokens_path, "\n")
}

