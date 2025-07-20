library(dplyr)
library(ggplot2)
library(readr)
library(tibble)
library(tidyr)
library(viridis)


# Data frame with fileName, event_slug, meeting time
meeting_dates <- tibble(
  fileName = c(
    "Fed_Interest_Rates_2023_02_February.csv",
    "Fed_Interest_Rates_2023_03_March.csv",
    "Fed_Interest_Rates_2023_05_May.csv",
    "Fed_Interest_Rates_2023_06_June.csv",
    "Fed_Interest_Rates_2023_07_July.csv",
    "Fed_Interest_Rates_2023_09_September.csv",
    "Fed_Interest_Rates_2023_11_November.csv",
    "Fed_Interest_Rates_2023_12_December.csv",
    "Fed_Interest_Rates_2024_01_January.csv",
    "Fed_Interest_Rates_2024_03_March.csv",
    "Fed_Interest_Rates_2024_05_May.csv",
    "Fed_Interest_Rates_2024_06_June.csv",
    "Fed_Interest_Rates_2024_07_July.csv",
    "Fed_Interest_Rates_2024_09_September.csv",
    "Fed_Interest_Rates_2024_11_November.csv",
    "Fed_Interest_Rates_2024_12_December.csv",
    "Fed_Interest_Rates_2025_01_January.csv",
    "Fed_Interest_Rates_2025_03_March.csv",
    "Fed_Interest_Rates_2025_05_May.csv",
    "Fed_Interest_Rates_2025_06_June.csv",
    "Fed_Interest_Rates_2025_07_July.csv",
    "Fed_Interest_Rates_2025_09_September.csv"
  ),
  event_slug = c(
    "fed-interest-rates-february-2023",
    "fed-interest-rates-march-2023",
    "fed-interest-rates-may-2023",
    "fed-interest-rates-june-2023",
    "fed-interest-rates-july-2023",
    "fed-interest-rates-september-2023",
    "fed-interest-rates-november-2023",
    "fed-interest-rates-december-2023",
    "fed-interest-rates-january-2024",
    "fed-interest-rates-march-2024",
    "fed-interest-rates-may-2024",
    "fed-interest-rates-june-2024",
    "fed-interest-rates-july-2024",
    "fed-interest-rates-september-2024",
    "fed-interest-rates-november-2024",
    "fed-interest-rates-december-2024",
    "fed-interest-rates-january-2025",
    "fed-decision-in-march",
    "fed-decision-in-may-2025",
    "fed-decision-in-june",
    "fed-decision-in-july",
    "fed-decision-in-september"
  ),
  meetingTime = c(
    as.POSIXct("2023-02-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-03-22 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-05-03 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-06-14 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-07-26 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-09-20 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-11-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-12-13 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-01-31 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-03-20 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-05-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-06-12 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-07-31 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-09-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-11-07 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-12-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-01-29 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-03-19 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-05-07 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-06-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-07-30 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-09-17 14:00:00", tz = "America/New_York")
  )
)

tokens_data <- read_csv(
  "./FOMC Tokens.csv",
  col_types = cols(
    Yes = col_character(),
    No = col_character()
  )) |>
  select(
    event_slug,
    assetName = marketTitle,
    Yes,
    No
  )


# TODO: write table/tibble for which meeting to use which ZQ data
head(meeting_dates)
head(tokens_data)


# TODO:Write calculation functions (3 types), 
# construct ZQ estimates
# construct PM estimates properly
# Figure out how to perform Granger causality test


PM_files <- file.path("./TimeSeries", 
  list.files(path = "./TimeSeries/", pattern = "\\.csv$")
)

ZQ_files <- file.path("./ZQ", 
  list.files(path = "./ZQ/", pattern = "\\.csv$")
)

PM_data <- list()
ZQ_data <- list()

# Loading Polymarket data
for (i in seq_along(PM_files)) {
  csv_fileName <- PM_files[i]

  PM_df <- read_csv(
    csv_fileName,
    col_types = cols(
      asset = col_character() 
    )
  ) |> 
    filter(asset %in% tokens_data$Yes) |>
    mutate(
      time = as.POSIXct(timestamp, tz = "America/New_York")
    ) |>
    left_join(
      tokens_data |>
        select(assetName, Yes),
      by = join_by(asset == Yes)
    ) |>
    select(
      time,
      asset = assetName,
      price
    )
  PM_df <- PM_df[!duplicated(PM_df[, 1:2]), ]

  PM_data[[i]] <- PM_df
}

for (i in seq_along(ZQ_files)) {
  csv_fileName <- ZQ_files[i]

  ZQ_df <- read_csv(
    csv_fileName,
    col_types = cols(
      open = col_double(),
      high = col_double(),
      low = col_double(),
      close = col_double()
    )
  ) |>
    select(time, close) |>
    mutate(
      time = as.POSIXct(time, tz = "America/New_York"),
      rateBps = (100 - close) * 100,
      # TODO: Here only load data, perform change calculation later
      changeBps = rateBps - 525
    )

  ZQ_data[[i]] <- ZQ_df
}

rm(i, PM_df, ZQ_df, csv_fileName)

PM_data
PM_files


# TODO: For each PM market calculated implied RN probs
ZQU2024 <- read_csv(
  "./ZQ/ZQU2024.csv",
  col_types = cols(
    # time = col_datetime(),
    open = col_double(),
    high = col_double(),
    low = col_double(),
    close = col_double()
  )
) |>
  select(time, close) |>
  mutate(
    time = as.POSIXct(time, tz = "America/New_York"),
    rateBps = (100 - close) * 100,
    changeBps = rateBps - 525
  ) |>
  filter(
    time > as.POSIXct("2024-08-01 00:00:00", tz = "America/New_York"),
    time < as.POSIXct("2024-09-30 23:59:59", tz = "America/New_York")
  )

ZQV2024 <- read_csv(
  "./ZQ/ZQV2024.csv",
  col_types = cols(
    # time = col_datetime(),
    open = col_double(),
    high = col_double(),
    low = col_double(),
    close = col_double()
  )
) |>
  select(time, close) |>
  mutate(
    time = as.POSIXct(time, tz = "America/New_York"),
    rateBps = (100 - close) * 100,
    changeBps = rateBps - 525
  ) |>
  filter(
    time > as.POSIXct("2024-08-01 00:00:00", tz = "America/New_York"),
    time < as.POSIXct("2024-09-30 23:59:59", tz = "America/New_York")
  )

ZQQ2024 <- read_csv(
  "./ZQ/ZQQ2024.csv",
  col_types = cols(
    # time = col_datetime(),
    open = col_double(),
    high = col_double(),
    low = col_double(),
    close = col_double()
  )
) |>
  select(time, close) |>
  mutate(
    time = as.POSIXct(time, tz = "America/New_York"),
    rateBps = (100 - close) * 100,
    changeBps = rateBps - 525
  ) |>
  filter(
    time > as.POSIXct("2024-08-01 00:00:00", tz = "America/New_York"),
    time < as.POSIXct("2024-09-30 23:59:59", tz = "America/New_York")
  )


range(PM_data$time)
range(ZQQ24$time)
range(ZQU24$time)
range(ZQV24$time)


PM_data_start <- min(PM_data$time)
PM_data_end <- max(PM_data$time)
september_end <- as.POSIXct("2024-09-30 23:59:59", tz = "America/New_York")

# August: Q
# September: U
# October: V

# dev.new()


# Plotting the 3 contracts
png(
  filename = paste0("./Plots/", "ZQ_changes_3_contracts.png"),
  width = 800,
  heigh = 600,
  res = 100
)

# Change
plot(zoo(ZQQ24$changeBps, order.by = ZQQ24$time),
  xlim = c(PM_data_start, september_end),
  ylim = c(-75, 25),
  col = "#440154",
  main = "Changes priced by 30-Day Federal Funds Rate Futures",
  xlab = "Date",
  ylab = "Priced average change in EFFR (in bps)",
  yaxt = "n"
)
axis(2, at = seq(-75, 25, 25))
lines(zoo(ZQU24$changeBps, order.by = ZQU24$time), col = "#2D708E")
lines(zoo(ZQV24$changeBps, order.by = ZQV24$time), col = "#73D055")
abline(h = -50, lwd = 1)
abline(h = c(seq(-75, 25, 25)), col = "lightgray", lty = "dotted")
abline(
  v = as.POSIXct("2024-09-18 14:00:00", tz = "America/New_York"),
  col = "gray60", lty = "dotted"
)
legend("bottomright",
  c("ZQ August", "ZQ September", "ZQ October"),
  col = c("#440154", "#2D708E", "#73D055"),
  lwd = c(5, 5, 5),
  bg = "white"
)

dev.off()

unified_data <- ZQQ24 |>
  full_join(ZQV24, by = "time") |>
  fill(
    close.x,
    close.y,
    rateBps.x,
    rateBps.y,
    changeBps.x,
    changeBps.y,
    .direction = "downup")


synthetic_ZQU24 <- unified_data |>
  mutate(
    close = close.x * (18 / 30) + close.y * (12 / 30),
    rateBps = rateBps.x * (18 / 30) + rateBps.y * (12 / 30),
    changeBps = changeBps.x * (18 / 30) + changeBps.y * (12 / 30) 
  ) |>
  select(time, close, rateBps, changeBps)

# Interpolation replication
png(
  filename = paste0("./Plots/", "ZQ_weighted_average_comparison.png"),
  width = 800,
  heigh = 600,
  res = 100
)

plot(zoo(ZQU24$changeBps, order.by = ZQU24$time),
  xlim = c(PM_data_start, september_end),
  ylim = c(-75, 25),
  col = "#2D708E",
  main = "Interpolated ZQ comparison",
  xlab = "Date",
  ylab = "Priced average change in EFFR (in bps)",
  yaxt = "n"
)
axis(2, at = seq(-75, 25, 25))
lines(zoo(synthetic_ZQU24$changeBps, order.by = synthetic_ZQU24$time), col = "#de7065")
abline(h = -50, lwd = 1)
abline(h = c(seq(-75, 25, 25)), col = "lightgray", lty = "dotted")
abline(
  v = as.POSIXct("2024-09-18 14:00:00", tz = "America/New_York"),
  col = "gray60", lty = "dotted"
)
legend("bottomright",
  c("ZQ September", "ZQ Replicated"),
  col = c("#2D708E", "#de7065"),
  lwd = c(5, 5),
  bg = "white"
)

dev.off()

# WARNING: Different calculations needed for rate hikes, or when switching between potential
# hikes or cuts

# NOTE: For october contract
char <- (abs(ZQV24$changeBps / 25) %/% 1) * sign(ZQV24$changeBps)
mantissa <- (abs(ZQV24$changeBps / 25) %% 1) * sign(ZQV24$changeBps)
recreated <- (char + mantissa) * 25
 
# char <- (abs(ZQV24$changeBps) %/% 25) * sign(ZQV24$changeBps)
# mantissa <- (abs(ZQV24$changeBps) %% 25) * sign(ZQV24$changeBps)

cbind(ZQV24$changeBps, char, mantissa, recreated)
unique(char)

######### Calculating implied probabillities #########
implied_probs <- tibble(
  # NOTE: higher mathematically (lower in abs value here)
  time = ZQV24$time,
  higher = char * 25,
  lower = (char - 1) * 25,
  probHigher = 1 - abs(mantissa),
  probLower = abs(mantissa)
) |>
  mutate(
    down50 = case_when(
      higher == -50 ~ probHigher,
      lower == -50 ~ probLower,
      (higher != -50) & (lower != -50) ~ 0
    ),
    down25 = case_when(
      higher == -25 ~ probHigher,
      lower == -25 ~ probLower,
      (higher != -25) & (lower != -25) ~ 0
    ),
    noChange = case_when(
      higher == 0 ~ probHigher,
      lower == 0 ~ probLower,
      (higher != 0) & (lower != 0) ~ 0
    ),
    up25 = case_when(
      higher == 25 ~ probHigher,
      lower == 25 ~ probLower,
      (higher != 25) & (lower != 25) ~ 0
    )
  ) |>
  select(
    time, down50, down25, noChange, up25
  ) |>
  filter(PM_data_start < time & time < PM_data_end)


PM_probs_unscaled <- PM_data |>
  mutate(
    down50 = case_when(
      (asset == "down50") ~ price
    ),
    down25 = case_when(
      (asset == "down25") ~ price
    ),
    noChange = case_when(
      (asset == "noChange") ~ price
    ),
    up25 = case_when(
      (asset == "up25") ~ price
    )
  ) |>
  fill(
    down50,
    down25,
    noChange,
    up25,
    .direction = "downup"
  ) |>
  select(time, down50, down25, noChange, up25)

PM_probs <- PM_probs_unscaled |> 
  mutate(
    total = down50 + down25 + noChange + up25
  ) |> 
  mutate(
    down50 = down50 / total,
    down25 = down25 / total,
    noChange = noChange / total,
    up25 = up25 / total
  ) |>
  select(-total) |>
  filter(PM_data_start < time & time < PM_data_end)

# dev.new()

PM_data_start
PM_data_end
range(PM_probs$time)
range(implied_probs$time)


###### ggplot stacked area charts ######

#### ZQ implied ####
# NOTE: Version 1
png(
  filename = paste0("./Plots/", "ZQ_implied_probs_v1.png"),
  width = 800,
  heigh = 600,
  res = 100
)
data_long <- implied_probs |>
  pivot_longer(
    cols = c(down50, down25, noChange, up25),
    names_to = "category",
    values_to = "value"
  )

# 4. Set the desired stacking order by converting 'category' to a factor
# This is the crucial step to control the layer order in the plot.
order_levels <- c("down50", "down25", "noChange", "up25")
data_long$category <- factor(data_long$category, levels = order_levels)


# 5. Create the plot
ggplot(data_long, aes(x = time, y = value, fill = category)) +
  geom_area(position = 'stack') +
  scale_fill_viridis_d(option = "viridis") + # Using the colorblind-friendly 'cividis' palette
  labs(
    title = "Stacked Area Chart of Changes Over Time",
    x = "Time",
    y = "Proportion",
    fill = "Category"
  ) +
  theme_minimal() +
  theme(legend.position = "top")
dev.off()


# NOTE: Version 2
png(
  filename = paste0("./Plots/", "ZQ_implied_probs_v2.png"),
  width = 800,
  heigh = 600,
  res = 100
)
# 2. reshape to long form and set stack order
df_long <- implied_probs |> 
  pivot_longer(
    cols      = c(down50, down25, noChange, up25),
    names_to  = "category",
    values_to = "value"
  ) %>%
  mutate(
    category = factor(category,
                      levels = c("down50", "down25", "noChange", "up25"))
  )

# 3. plot
ggplot(df_long, aes(x = time, y = value, fill = category)) +
  geom_area() +                                    # stacked by default
  scale_fill_viridis_d(                            # discrete viridis palette
    name   = "Rate decision",
    option = "D"                                   # try "A", "B", "C", "D"
  ) +
  labs(
    x     = "Time",
    y     = "Implied risk-neutral probabilities",
    title = "Implied risk-neutral probabilities (Fed Funds futures)"
  ) +
  theme_minimal()
dev.off()


#### PM implied ####
# NOTE: Version 1
png(
  filename = paste0("./Plots/", "PM_implied_probs_v1.png"),
  width = 800,
  heigh = 600,
  res = 100
)
data_long <- PM_probs |>
  pivot_longer(
    cols = c(down50, down25, noChange, up25),
    names_to = "category",
    values_to = "value"
  )

# 4. Set the desired stacking order by converting 'category' to a factor
# This is the crucial step to control the layer order in the plot.
order_levels <- c("down50", "down25", "noChange", "up25")
data_long$category <- factor(data_long$category, levels = order_levels)


# 5. Create the plot
ggplot(data_long, aes(x = time, y = value, fill = category)) +
  geom_area(position = 'stack') +
  scale_fill_viridis_d(option = "viridis") + # Using the colorblind-friendly 'cividis' palette
  labs(
    title = "Stacked Area Chart of Changes Over Time",
    x = "Time",
    y = "Proportion",
    fill = "Category"
  ) +
  theme_minimal() +
  theme(legend.position = "top")
dev.off()

# NOTE: Version 2
png(
  filename = paste0("./Plots/", "PM_implied_probs_v2.png"),
  width = 800,
  heigh = 600,
  res = 100
)
# 2. reshape to long form and set stack order
df_long <- PM_probs |> 
  pivot_longer(
    cols      = c(down50, down25, noChange, up25),
    names_to  = "category",
    values_to = "value"
  ) %>%
  mutate(
    category = factor(category,
                      levels = c("down50", "down25", "noChange", "up25"))
  )

# 3. plot
ggplot(df_long, aes(x = time, y = value, fill = category)) +
  geom_area() +                                    # stacked by default
  scale_fill_viridis_d(                            # discrete viridis palette
    name   = "Rate decision",
    option = "D"                                   # try "A", "B", "C", "D"
  ) +
  labs(
    x     = "Time",
    y     = "Implied risk-neutral probabilities",
    title = "Implied risk-neutral probabilities (Polymarket)"
  ) +
  theme_minimal()
dev.off()


# NOTE: Granger causality stuff
ZQU24$time[first(which(ZQU24$time > min(PM_data$time)))]
which(ZQV24$time > min(PM_data$time))

min(ZQU24$time) > min(PM_data$time)

# Sys.setenv(TZ = "America/New_York")


# # Rate
# plot(zoo(ZQQ24$rateBps, order.by = ZQQ24$time),
#   xlim = c(PM_data_start, september_end),
#   ylim = c(450, 550),
#   col = "#440154",
#   main = "Rates priced by 30-Day Federal Funds Rate Futures",
#   xlab = "Date",
#   ylab = "Priced average EFFR (in bps)"
# )
# lines(zoo(ZQU24$rateBps, order.by = ZQU24$time), col = "#2D708E")
# lines(zoo(ZQV24$rateBps, order.by = ZQV24$time), col = "#73D055")
# legend("bottomright",
#   c("ZQ August", "ZQ September", "ZQ October"),
#   col = c("#440154", "#2D708E", "#73D055"),
#   lwd = c(5, 5, 5)
# )
