polymarket_biden <- read.csv("price_data/biden_full_minute_data.csv",
    header = TRUE)
polymarket_harris <- read.csv("price_data/harris_full_minute_data.csv",
    header = TRUE)
polymarket_trump <- read.csv("price_data/trump_full_minute_data.csv",
    header = TRUE)
polymarket_kanye <- read.csv("price_data/kanye_full_minute_data.csv",
    header = TRUE)
polymarket_rfkjr <- read.csv("price_data/rfkjr_full_minute_data.csv",
    header = TRUE)

polymarket_full_trump <- read.csv("trump_full_minute_data.csv",
    header = TRUE)

polymarket_full_harris <- read.csv("harris_full_minute_data.csv",
    header = TRUE)


polymarket_full <- data.frame("Timestamp" = as.POSIXct(polymarket_full_harris$timestamp, tz = "UTC"),
    "Harris" = polymarket_full_harris$price,
    "Trump" = polymarket_full_trump$price)

