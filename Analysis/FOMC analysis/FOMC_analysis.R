library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)

event_files <- list.files(file.path(getwd(), "EventDatas"), pattern = ".RData$")

tokens_data <- read_csv("./FOMC Tokens.csv",
  col_types = cols(
    Yes = col_character(),
    No = col_character()
  ))

tokens_outcomes <- tokens_data |>
  select(
    tokenId = Yes,
    tokenOutcome = outcomeYes
  )  |>
  bind_rows(
    tokens_data |> 
      select(
        tokenId = No,
        tokenOutcome = outcomeNo
      )
  )

fileName <- "Fed_Interest_Rates_September_2024.RData"

# Analyise individual events here
# Generate plots for all events
# for (fileName in event_files) {


load(file.path(getwd(), "EventDatas", fileName))
load(file.path(getwd(), "UserPnLs", fileName))


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


# down25 Yes
# "88244443360063235221444316604590968694314258311386447899087521723508440858841" 

# down50 Yes
# "106191328358576540351439267765925450329859429577455659884974413809922495874408"

# noChange Yes
# "89262722133387845193166560202808972424089924545438804960915341631492994906283" 

# up25 Yes
# "95823178650727331613915203831778682038645976746731326695569990405131199144192" 



# png(
#   filename = paste0("./Plots/", event_name, "returnHist.png"),
#   width = 800,
#   heigh = 600,
#   res = 100
# )


{
  maker_order_counts <- scaled_events |>
  filter(maker %in% realUsers) |>         # only rows where maker is in realUsers
  distinct(maker, orderHash) |>           # one row per unique maker+orderHash
  count(user = maker,                      # group by maker
    name = "makerCount")               # tally unique orders

  # 2) Count unique orders per taker **only** for realUsers
  taker_order_counts <- scaled_events %>%
    filter(taker %in% realUsers) %>%         # only rows where taker is in realUsers
    distinct(taker, orderHash) %>%           # one row per unique taker+orderHash
    count(user = taker,                      # group by taker
      name = "takerCount")               # tally unique orders

  # 3) Merge maker and taker counts, filling missing values with 0
  user_order_counts <- full_join(maker_order_counts,
    taker_order_counts,
    by = "user") |>
    replace_na(list(makerCount = 0,
      takerCount = 0))


  user_order_counts <- user_order_counts |> 
    left_join(userReturns,
      by = "user") |> 
    mutate(totalTrades = makerCount + takerCount)

  rm(maker_order_counts)
  rm(taker_order_counts)
}





HFT_class <- user_order_counts |> 
  mutate(
    tradesPerDay = totalTrades / 55
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
    makerRatio = makerCount / totalTrades
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




# user_liquidity_class |> 
#   filter(traderType == "LP") |> 




ggplot(HFT_liquidity_class, aes(x = eventReturn)) +
  geom_histogram(bins = 30, colour = "black", fill = "grey80") +
  facet_grid(HFTType ~ traderType) +
  labs(
    title = "Histogram of Returns by HFT Status and Liquidity Role",
    x     = "Return",
    y     = "Count"
  ) +
  theme_bw()





hist(userReturns$eventReturn,
  main = "Traders's Returns",
  xlab = "Returns")


summary(userReturns$eventReturn)



sum(user_order_counts$totalTrades > 100)


plot(sort(user_order_counts$totalTrades))


real_makers_events <- scaled_events |>
  filter(maker %in% realUsers) |> 
  group_by(maker) |> 
  summarise(
    makerVolume = sum()
  )


real_takers_events <- scaled_events %>%
  filter(taker %in% realUsers)


user_order_counts <- full_join(maker_order_counts,
  taker_order_counts,
  by = "user") |>
  replace_na(list(makerCount = 0,
    takerCount = 0))






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


# Log histogram maker orders
ggplot(user_order_counts, aes(x = makerCount + 1)) +
  geom_histogram(binwidth = 0.1) +
  scale_x_log10() +
  labs(title = "Log-Histogram of Maker Orders",
    x = "Maker Orders (log scale)",
    y = "Count of Users") +
  theme_minimal()


ggplot(user_order_counts, aes(x = takerCount + 1)) +
  geom_histogram(binwidth = 0.1) +
  scale_y_log10() +
  labs(title = "Log-Histogram of Taker Orders",
    x = "Maker Orders (log scale)",
    y = "Count of Users") +
  theme_minimal()


df_fills <- scaled_events

maker_vol <- df_fills |> 
  filter(maker %in% realUsers) |> 
  group_by(user = maker) |> 
  summarize(vol = sum(tokenVolume), .groups = "drop")

taker_vol  <- df_fills %>%
  filter(taker %in% realUsers) |> 
  group_by(user = taker) %>%
  summarize(vol = sum(tokenVolume), .groups = "drop")  

# NOTE: if you want collateral volume, replace makerAmountFilled with takerAmountFilled

df_vol <- bind_rows(maker_vol, taker_vol) %>%
  group_by(user) %>%
  summarize(totalVol = sum(vol), .groups = "drop")


hist(df_vol$totalVol)




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






as.Date(timeSeriesData$timestamp)

barplot(as.Date(timeSeriesData$timestamp))

plot(timeSeriesData$timestamp,
  timeSeriesData$tokenVolume)

# timeSeriesData$
# }
# View the result
# print(user_order_counts)
