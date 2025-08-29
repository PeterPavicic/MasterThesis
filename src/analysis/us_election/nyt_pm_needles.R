if (!require(car)) install.packages("car"); library(car)
if (!require(dplyr)) install.packages("dplyr"); library(dplyr)
if (!require(tseries)) install.packages("tseries"); library(tseries)
if (!require(urca)) install.packages("urca"); library(urca)
if (!require(vars)) install.packages("vars"); library(vars)

nyt_harris_needle <- read.table(
  "NYT_needle_data/harris_odds_needle.txt",
  skip = 1,
  sep = ','
)

nyt_trump_needle <- read.table(
  "NYT_needle_data/trump_odds_needle.txt",
  skip = 1,
  sep = ','
)

# Keep only second entry for each timestep since data is from SVG format
# Where coordinates are given for drawing vector graphics
nyt_harris_needle <- nyt_harris_needle[seq(1, nrow(nyt_trump_needle), 2), ]
nyt_trump_needle <- nyt_trump_needle[seq(1, nrow(nyt_trump_needle), 2), ]

colnames(nyt_harris_needle) <- c("time", "odds")
colnames(nyt_trump_needle) <- c("time", "odds")


nyt_harris_needle[, "odds"] <- 1 - (nyt_harris_needle[, "odds"] / 210)
nyt_trump_needle[, "odds"] <- 1 - (nyt_trump_needle[, "odds"] / 210)

nyt_harris_needle[, "time"] <- nyt_harris_needle[, "time"] / 612
nyt_trump_needle[, "time"] <- nyt_trump_needle[, "time"] / 612

# Starting time: ca. 8PM ET aka New York time
# Ending time: 5:38AM ET

needleStart <- as.numeric(as.POSIXct("2024-11-05 20:00", tz = "America/New_York"))
needleEnd <- as.numeric(as.POSIXct("2024-11-06 05:38", tz = "America/New_York"))
timelength <- needleEnd - needleStart

nyt_harris_needle[, "time"] <- as.POSIXct(needleStart + nyt_harris_needle[, "time"] * timelength)
nyt_trump_needle[, "time"] <- as.POSIXct(needleStart + nyt_trump_needle[, "time"] * timelength)



polymarket_harris <- read.csv(
  "PM_minute_data/harris_full_minute_data.csv",
  header = TRUE)

polymarket_trump <- read.csv(
  "PM_minute_data/trump_full_minute_data.csv",
  header = TRUE)

head(polymarket_harris)
head(polymarket_trump)


length(intersect(polymarket_trump$timestamp, polymarket_harris$timestamp))
length(polymarket_trump$timestamp)
length(polymarket_harris$timestamp)
range(polymarket_trump$timestamp)
range(polymarket_harris$timestamp)


polymarket_data <- polymarket_harris |> 
  as_tibble() |> 
  inner_join(as_tibble(polymarket_trump), by = "timestamp", suffix = c("Harris", "Trump")) |>
  filter(
    needleStart <= as.numeric(timestamp) & as.numeric(timestamp) <= needleEnd
  ) |>
  mutate(Timestamp = as.POSIXct(timestamp, tz = "America/New_York")) |> 
  dplyr::select(
    Timestamp,
    Harris = priceHarris,
    Trump = priceTrump
  )


polymarket_harris_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
  "odds" = polymarket_data$Harris)

polymarket_trump_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
  "odds" = polymarket_data$Trump)


Sys.setenv(TZ = "America/New_York")


# plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
#   main = "Trump vs Harris NY Times election needle",
#   xlab = "New York time",
#   ylab = "Odds",
#   yaxt = "n")
# axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
# grid()
# lines(nyt_trump_needle, type = 'l', col = "red")
# legend("right", legend = c("Trump", "Harris"),
#   col = c("red", "blue"), lwd = 2)


# plot(polymarket_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
#   main = "Trump vs Harris Polymarket election needle",
#   xlab = "New York time",
#   ylab = "odds",
#   yaxt = "n")
# axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
# lines(polymarket_trump_needle, type = 'l', col = "red")
# grid()
# legend("right", legend = c("Trump", "Harris"),
#   col = c("red", "blue"), lwd = 2)


# png(
#   file = "needle_comparison.png",
#   width = 1134,
#   height = 688,
#   res = 120,
#   type = "cairo-png",
#   antialias = "subpixel"
# )

plot(nyt_harris_needle, type = 'n', col = "blue", ylim = c(0, 1),
  main = "NY Times vs Polymarket election needle",
  ylab = "Odds at winning the presidency",
  xlab = "New York time", lty = "dashed",
  yaxt = "n",
  cex.main = 1.5,
  cex.lab = 1.2,
  cex.axis = 1.0)
grid()
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"), cex.axis = 1)
lines(nyt_harris_needle, type = 'l', col = "blue", lty = "dotted", lwd = 2)
lines(nyt_trump_needle, type = 'l', col = "red", lty = "dotted", lwd = 2)
lines(polymarket_harris_needle, type = 'l', col = "navy", lwd = 2)
lines(polymarket_trump_needle, type = 'l', col = "darkred", lwd = 2)
legend("right", legend = c("Polymarket Trump", "NY Times Trump",
  "NY Times Harris", "Polymarket Harris"),
  col = c("darkred", "red", "blue", "navy"), lwd = 2,
  lty = c("solid", "dotted", "dotted", "solid"))
abline(v = as.POSIXct("2024-11-06 01:22", tz = "America/New_York"), col = "purple", lwd = 2)
abline(v = as.POSIXct("2024-11-06 01:47", tz = "America/New_York"), col = "purple", lwd = 2)
text(x = as.POSIXct("2024-11-06 01:13", tz = "America/New_York"),
  y = 0.25,
  labels = "Decision Desk HQ\ncall election",
  col = "purple",
  adj = 1,
  cex = 1.0)
text(x =  as.POSIXct("2024-11-06 01:56", tz = "America/New_York"),
  y = 0.25,
  labels = "Fox News\ncall election",
  col = "purple",
  adj = 0,
  cex = 1.0)


# dev.off()

# png(
#   file = "trump_needle.png",
#   width = 1134,
#   height = 688,
#   res = 120,
#   type = "cairo-png",
#   antialias = "subpixel"
# )

plot(nyt_trump_needle, type = 'l', col = "red", ylim = c(0.5, 1),
     main = "NY Times vs Polymarket election needle: Trump",
     ylab = "Odds at winning the presidency",
     xlab = "New York time", lty = "solid",
     yaxt = "n")
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
lines(polymarket_trump_needle, type = 'l', col = "darkred")
grid()
legend("right", legend = c("Polymarket Trump", "NY Times Trump"),
       col = c("darkred", "red"), lwd = 2,
       lty = c("solid", "solid"))


# dev.off()


# png(
#   file = "harris_needle.png",
#   width = 1134,
#   height = 688,
#   res = 120,
#   type = "cairo-png",
#   antialias = "subpixel"
# )

plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 0.5),
     main = "NY Times vs Polymarket election needle: Harris",
     ylab = "Odds at winning the presidency",
     xlab = "New York time", lty = "solid",
     yaxt = "n")
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
lines(polymarket_harris_needle, type = 'l', col = "navy")
grid()
legend("right", legend = c("Polymarket Harris", "NY Times Harris"),
       col = c("navy", "blue"), lwd = 2,
       lty = c("solid", "solid"))

# dev.off()


########### Granger's causality test ###########


# At this point Trump was called the winner by Decision Desk HQ
# winner_called <- as.POSIXct("2024-11-06 01:22", tz = "America/New_York")

# At this point Trump was called the winner by Decision Desk HQ and Fox News
winner_called <- as.POSIXct("2024-11-06 01:47", tz = "America/New_York")

pm_trump_odds <- ts(polymarket_trump_needle$odds[polymarket_trump_needle$Timestamp <= winner_called])
nyt_trump_odds <- ts(nyt_trump_needle$odds[nyt_trump_needle$time <= winner_called])
pm_harris_odds <- ts(polymarket_harris_needle$odds[polymarket_harris_needle$Timestamp <= winner_called])
nyt_harris_odds <- ts(nyt_harris_needle$odds[nyt_harris_needle$time <= winner_called])


# All are numerically zero, therefore it is sufficient to look at one market, e.g. Trump
pm_trump_odds + pm_harris_odds - 1
nyt_trump_odds + nyt_harris_odds - 1


# NYT election needle first results are at 8:01 PM so we add an observation
# At 8PM which is the same as the next, since there were no results yet
# And NYT election needle initially relies on polls information


nyt_trump_needle <- rbind(
  c(as.POSIXct("2024-11-05 20:00:00"), nyt_trump_needle$odds[1]),
  nyt_trump_needle)

# Linearly interpolate NYT Election needle odds to line up to Polymarket data
nyt_trump_odds <- approx(
  x = nyt_trump_needle$time,
  y = nyt_trump_needle$odds,
  xout = polymarket_trump_needle$Timestamp[polymarket_trump_needle$Timestamp <= winner_called]
)$y

nyt_trump_odds <- ts(nyt_trump_odds)


# ADF test for stationarity
adf_polymarket <- adf.test(pm_trump_odds, alternative = "stationary")
adf_nyt_needle <- adf.test(nyt_trump_odds, alternative = "stationary")

print(adf_polymarket)
print(adf_nyt_needle)
# We cannot reject the null that the timeseries are non-stationary

# Therefore, we use first order differences
pm_needle_diff <- diff(pm_trump_odds)
nyt_needle_diff <- diff(nyt_trump_odds)


# Re-test for stationarity after differencing
adf_pm_needle_diff <- adf.test(pm_needle_diff, alternative = "stationary")
adf_nyt_needle_diff <- adf.test(nyt_needle_diff, alternative = "stationary")

print(adf_pm_needle_diff)
print(adf_nyt_needle_diff)
# Null of non-stationarity rejected


# Test for cointegration
var_select <- VARselect(cbind(pm_needle_diff, nyt_needle_diff), lag.max = 10, type = "trend")
print(var_select$selection)
johansen_test <- ca.jo(cbind(pm_trump_odds, nyt_trump_odds), type = "trace",
  K = var_select$selection["SC(n)"], ecdet = "trend")

summary(johansen_test)
# No cointegrating relationship


# Using BIC
optimal_lag <- var_select$selection["SC(n)"]
var_model <- VAR(cbind(pm_needle_diff, nyt_needle_diff), p = optimal_lag, type = "const")
# Test if Polymarket predicts NYT needle
granger_test <- causality(var_model, cause = "pm_needle_diff")
print(granger_test$Granger)
# rejects non-causality

# Test if Polymarket predicts NYT needle
granger_test <- causality(var_model, cause = "nyt_needle_diff")
print(granger_test$Granger)
# does not reject non-causality
