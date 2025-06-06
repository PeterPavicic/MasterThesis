rm(list = ls())


nyt_harris_needle <- read.table("needle_data/harris_odds_needle.txt", skip = 1, sep = ',')
nyt_trump_needle <- read.table("needle_data/trump_odds_needle.txt", skip = 1, sep = ',')

# # Keep only second entry for each timestep since data is from SVG format
# # Where coordinates are given for drawing vector graphics
# nyt_harris_needle <- nyt_harris_needle[seq(1, nrow(nyt_trump_needle), 2),]
# nyt_trump_needle <- nyt_trump_needle[seq(1, nrow(nyt_trump_needle), 2),]

colnames(nyt_harris_needle) <- c("time", "odds")
colnames(nyt_trump_needle) <- c("time", "odds")


nyt_harris_needle[,"odds"] <- 1 - (nyt_harris_needle[,"odds"] / 210)
nyt_trump_needle[,"odds"] <- 1 - (nyt_trump_needle[,"odds"] / 210)

nyt_harris_needle[,"time"] <- nyt_harris_needle[,"time"] / 612
nyt_trump_needle[,"time"] <- nyt_trump_needle[,"time"] / 612

# Starting time: ca. 8PM ET aka New York time
# Ending time: 5:38AM ET

needleStart <- as.numeric(as.POSIXct("2024-11-05 20:00", tz = "America/New_York"))
needleEnd <- as.numeric(as.POSIXct("2024-11-06 05:38", tz = "America/New_York"))
timelength <- needleEnd - needleStart

nyt_harris_needle[,"time"] <- as.POSIXct(needleStart + nyt_harris_needle[,"time"] * timelength)
nyt_trump_needle[,"time"] <- as.POSIXct(needleStart + nyt_trump_needle[,"time"] * timelength)


polymarket_harris <- read.csv("needle_data/minute_data_harris.csv",
                              header = TRUE)

polymarket_trump <- read.csv("needle_data/minute_data_trump.csv",
                              header = TRUE)

head(polymarket_harris)
head(polymarket_trump)


polymarket_data <- data.frame("Timestamp" = as.POSIXct(polymarket_harris$timestamp, tz = "America/New_York"),
                              "Harris" = polymarket_harris$price,
                              "Trump" = polymarket_trump$price)

polymarket_data <- polymarket_data[needleStart <= as.numeric(polymarket_data$Timestamp) &
                                           as.numeric(polymarket_data$Timestamp) <= needleEnd,]

polymarket_harris_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Harris)

polymarket_trump_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Trump)


Sys.setenv(TZ = "America/New_York")

plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris NY Times election needle",
     xlab = "New York time",
     ylab = "Odds",
     yaxt = "n")
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
grid()
lines(nyt_trump_needle, type = 'l', col = "red")
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)


plot(polymarket_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris Polymarket election needle",
     xlab = "New York time",
     ylab = "odds",
     yaxt = "n")
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
lines(polymarket_trump_needle, type = 'l', col = "red")
grid()
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)



plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "NY Times vs Polymarket election needle",
     ylab = "Odds at winning the presidency",
     xlab = "New York time", lty = "dashed",
     yaxt = "n")
axis(2, at = seq(0, 1, .2), labels = paste0(seq(0, 100, 20), "%"))
lines(nyt_trump_needle, type = 'l', col = "red", lty = "dashed")
lines(polymarket_harris_needle, type = 'l', col = "navy")
lines(polymarket_trump_needle, type = 'l', col = "darkred")
grid()
legend("right", legend = c("Polymarket Trump", "Polymarket Harris",
                           "NY Times Trump", "NY Times Harris"),
       col = c("navy", "darkred", "red", "blue"), lwd = 2,
       lty = c("solid", "solid", "dashed", "dashed"))


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




# Granger's causality test
if(!require(tseries)) install.packages("tseries"); library(tseries)
if(!require(vars)) install.packages("vars"); library(vars)
if(!require(urca)) install.packages("urca"); library(urca)


pm_trump_odds <- polymarket_trump_needle$odds
nyt_trump_odds <- nyt_trump_needle$odds
pm_harris_odds <- polymarket_harris_needle$odds
nyt_harris_odds <- nyt_harris_needle$odds


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
  xout = polymarket_trump_needle$Timestamp
)$y


# ADF test for stationarity
adf_polymarket <- adf.test(pm_trump_odds, alternative = "stationary")
adf_nyt_needle <- adf.test(nyt_trump_odds, alternative = "stationary")

print(adf_polymarket)
print(adf_nyt_needle)
# We cannot reject the null that the timeseries are non-stationary

# Therefore, we use first order differences
polymarket_diff <- diff(pm_trump_odds)
nyt_needle_diff <- diff(nyt_trump_odds)


# Re-test for stationarity after differencing
adf_polymarket_diff <- adf.test(polymarket_diff, alternative = "stationary")
adf_nyt_needle_diff <- adf.test(nyt_needle_diff, alternative = "stationary")

print(adf_polymarket_diff)
print(adf_nyt_needle_diff)
# Null of non-stationarity rejected


# Test for cointegration since original series are non-stationary
var_select <- VARselect(cbind(polymarket_diff, nyt_needle_diff), type = "trend")
print(var_select$selection)
johansen_test <- ca.jo(cbind(pm_trump_odds, nyt_trump_odds), type = "trace",
                       K = var_select$selection["SC(n)"], ecdet = "trend")
summary(johansen_test)
# We reject the null of no cointegrating relationship


# Same result with Engle-Granger Two-Step Method:
eg_model <- lm(nyt_trump_odds ~ pm_trump_odds)
residuals_eg <- residuals(eg_model)
adf_residuals <- adf.test(residuals_eg, alternative = "stationary")
print(adf_residuals)


grangertest(nyt_trump_odds, pm_trump_odds, order = 2)
grangertest(pm_trump_odds, nyt_trump_odds, order = 2)



# # Granger Causality test
# optimal_lag <- var_select$selection["AIC(n)"] # Using AIC
# var_model <- VAR(cbind(polymarket_diff, nyt_needle_diff), p = optimal_lag, type = "trend")
#
# # Test if Polymarket predicts NYT needle
# granger_test <- causality(var_model, cause = "polymarket_diff")
# print(granger_test)
#
# # Test if NYT needle predicts Polymarket needle
# granger_test <- causality(var_model, cause = "nyt_needle_diff")
# print(granger_test)
#
# # Using BIC
# optimal_lag <- var_select$selection["SC(n)"]
# var_model <- VAR(cbind(polymarket_diff, nyt_needle_diff), p = optimal_lag, type = "trend")
# granger_test <- causality(var_model, cause = "polymarket_diff")  # Test if Polymarket predicts NYT needle
# print(granger_test)
#
# granger_test <- causality(var_model, cause = "nyt_needle_diff")  # Test if Polymarket predicts NYT needle
# print(granger_test)


# Load the "urca" package if not already installed
if (!require(urca)) install.packages("urca"); library(urca)
if (!require(car)) install.packages("car"); library(car)


# VECM
vecm <- cajorls(johansen_test, r = 1)  # Use r = 1 because Johansen test found cointegrating relationship


# Display the VECM results
print(vecm$rlm)

# Step 3: Test for causality
# Use the short-term coefficients (lagged differences) and the error correction term for hypothesis testing
linearHypothesis(vecm$rlm, c("pm_trump_odds.dl1 = 0", "nyt_trump_odds.dl1 = 0"))

vecm$rlm

short_term_causality <- waldtest(b = coef(vecm$rlm),
                                  Sigma = vcov(vecm$rlm),
                                  Terms = c(2, 3))
cat("\nShort-Term Granger Causality:\n")
print(short_term_causality)

long_term_causality <- summary(vecm$rlm)$coefficients["ect1", "Pr(>|t|)"]  # Error correction term
cat("\nLong-Term Causality (ECT):\n")
print(long_term_causality)



