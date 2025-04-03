rm(list = ls())

nyt_harris_needle <- read.table("needle_data/harris_odds_needle.txt", skip = 1, sep = ',')
nyt_trump_needle <- read.table("needle_data/trump_odds_needle.txt", skip = 1, sep = ',')

nyt_harris_needle
nyt_trump_needle

colnames(nyt_harris_needle) <- c("time", "odds")
colnames(nyt_trump_needle) <- c("time", "odds")


nyt_harris_needle[,"odds"] <- 1 - (nyt_harris_needle[,"odds"] / 210)
nyt_trump_needle[,"odds"] <- 1 - (nyt_trump_needle[,"odds"] / 210)

nyt_harris_needle[,"time"] <- nyt_harris_needle[,"time"] / 612
nyt_trump_needle[,"time"] <- nyt_trump_needle[,"time"] / 612

# Starting time: ca. 8PM ET, 01:00 UTC, 6th of November
# Ending time: 5:38AM ET, 10:38 UTC, 6th of November

needleStart <- as.numeric(as.POSIXct("2024-11-06 01:00", tz = "UTC"))
needleEnd <- as.numeric(as.POSIXct("2024-11-06 10:38", tz = "UTC"))
timelength <- needleEnd - needleStart

nyt_harris_needle[,"time"] <- as.POSIXct(needleStart + nyt_harris_needle[,"time"] * timelength)
nyt_trump_needle[,"time"] <- as.POSIXct(needleStart + nyt_trump_needle[,"time"] * timelength)


polymarket_harris <- read.csv("needle_data/minute_data_harris.csv",
                              header = TRUE)

polymarket_trump <- read.csv("needle_data/minute_data_trump.csv",
                              header = TRUE)

head(polymarket_harris)
head(polymarket_trump)

polymarket_data <- data.frame("Timestamp" = as.POSIXct(polymarket_harris$timestamp, tz = "UTC"),
                              "Harris" = polymarket_harris$price,
                              "Trump" = polymarket_trump$price)

polymarket_data <- polymarket_data[needleStart <= polymarket_data$Timestamp &
                  polymarket_data$Timestamp <= needleEnd,]

polymarket_harris_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Harris)

polymarket_trump_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Trump)


plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris NY Times election needle",
     xlab = "UTC time")
lines(nyt_trump_needle, type = 'l', col = "red")
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)

plot(polymarket_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris Polymarket election needle",
     xlab = "UTC time")
lines(polymarket_trump_needle, type = 'l', col = "red")
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)



plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "NY Times vs Polymarket election needle",
     ylab = "Odds at winning the presidency",
     xlab = "UTC time", lty = "dashed")
lines(nyt_trump_needle, type = 'l', col = "red", lty = "dashed")

lines(polymarket_harris_needle, type = 'l', col = "navy")
lines(polymarket_trump_needle, type = 'l', col = "darkred")
legend("right", legend = c("Polymarket Trump", "Polymarket Harris",
                           "NY Times Trump", "NY Times Harris"),
       col = c("navy", "darkred", "red", "blue"), lwd = 2,
       lty = c("solid", "solid", "dashed", "dashed"))


plot(nyt_trump_needle, type = 'l', col = "red", ylim = c(0.5, 1),
     main = "NY Times vs Polymarket election needle: Trump",
     ylab = "Odds at winning the presidency",
     xlab = "UTC time", lty = "solid")
lines(polymarket_trump_needle, type = 'l', col = "darkred")
legend("right", legend = c("Polymarket Trump", "NY Times Trump"),
       col = c("darkred", "red"), lwd = 2,
       lty = c("solid", "solid"))


plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 0.5),
     main = "NY Times vs Polymarket election needle: Harris",
     ylab = "Odds at winning the presidency",
     xlab = "UTC time", lty = "solid")
lines(polymarket_harris_needle, type = 'l', col = "navy")
legend("right", legend = c("Polymarket Harris", "NY Times Harris"),
       col = c("navy", "blue"), lwd = 2,
       lty = c("solid", "solid"))



# Granger's causality test
if(!require(tseries)) install.packages("tseries"); library(tseries)
if(!require(vars)) install.packages("vars"); library(vars)
if(!require(urca)) install.packages("urca"); library(urca)


pm_trump_odds <- polymarket_trump_needle$odds

# Remove duplicates caused by vector graphics format
nyt_trump_odds <- nyt_trump_needle[seq(1, nrow(nyt_trump_needle), 2),]

plot(nyt_trump_odds, type='l')


View(nyt_trump_needle)



nyt_interpolated <- approx(
  x = nyt_trump_needle$time,                       # Original time indices for nyt_trump_odds
  y = nyt_trump_needle$odds,                 # Original nyt_trump_odds values
  xout = polymarket_trump_needle$Timestamp                      # Target time indices for interpolation
)$y


nyt_interpolated




polymarket_trump_needle
nyt_trump_needle

# ADF test for stationarity
adf_polymarket <- adf.test(pm_trump_odds, alternative = "stationary")
adf_nyt_needle <- adf.test(nyt_trump_odds, alternative = "stationary")

print(adf_polymarket)
print(adf_nyt_needle)

# We cannot reject the null that the timeseries are stationary

polymarket_diff <- diff(pm_trump_odds)
nyt_needle_diff <- diff(nyt_trump_odds)

# Re-test for stationarity after differencing
adf_polymarket_diff <- adf.test(polymarket_diff, alternative = "stationary")
adf_nyt_needle_diff <- adf.test(nyt_needle_diff, alternative = "stationary")

print(adf_polymarket_diff)
print(adf_nyt_needle_diff)

# These vectors are now stationary


# Step 4: Test for cointegration if original series are non-stationary
cat("\nTesting for Cointegration...\n")
johansen_test <- ca.jo(cbind(pm_trump_odds, nyt_trump_odds), type = "trace", K = 2)
summary(johansen_test)
# No evidence of cointegration



# length(nyt_trump_odds) * 2
# length(pm_trump_odds)
#
# # Step 1: Perform a regression of one series on the other
# eg_model <- lm(nyt_trump_odds ~ pm_trump_odds)
#
# # Display regression summary
# cat("\nRegression Summary:\n")
# summary(eg_model)
#
# # Extract the residuals from the regression
# residuals_eg <- residuals(eg_model)
#
# # Step 2: Test the residuals for stationarity
# adf_residuals <- adf.test(residuals_eg, alternative = "stationary")
#
# # Display ADF test results for residuals
# cat("\nADF Test for Residuals:\n")
# print(adf_residuals)
# Interpretation
# if (adf_residuals$p.value < 0.05) {
#   cat("\nThe residuals are stationary (p-value <", adf_residuals$p.value,
#       "), indicating cointegration between the series.\n")
# } else {
#   cat("\nThe residuals are non-stationary (p-value =", adf_residuals$p.value,
#       "), indicating no cointegration between the series.\n")
# }


grangertest(nyt_trump_odds ~ pm_trump_odds)


# Step 5: Select optimal lag length for Granger causality
cat("\nSelecting optimal lag length...\n")
var_select <- VARselect(cbind(polymarket_diff, nyt_needle_diff), type = "const")
print(var_select$selection)



# Step 6: Fit VAR model and perform Granger causality test
optimal_lag <- var_select$selection["AIC(n)"]  # Replace "AIC(n)" with your chosen criterion (e.g., "BIC(n)")
var_model <- VAR(cbind(polymarket_diff, nyt_needle_diff), p = optimal_lag, type = "const")

cat("\nPerforming Granger causality test...\n")
granger_test <- causality(var_model, cause = "polymarket_diff")  # Test if Polymarket predicts NYT needle
print(granger_test)



# Step 7: Interpretation
if (granger_test$Granger$p.value < 0.05) {
  cat("\nPolymarket probabilities Granger-cause the NYT needle!\n")
} else {
  cat("\nPolymarket probabilities do NOT Granger-cause the NYT needle.\n")
}




