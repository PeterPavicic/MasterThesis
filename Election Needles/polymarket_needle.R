
polymarket_harris <- read.csv("needle_data/minute_data_harris.csv",
                              header = TRUE)
polymarket_trump <- read.csv("needle_data/minute_data_trump.csv",
                              header = TRUE)

head(polymarket_harris)
head(polymarket_trump)

polymarket_data <- data.frame("Timestamp" = as.POSIXct(polymarket_harris$timestamp, tz = "UTC"),
                              "Harris" = polymarket_harris$price,
                              "Trump" = polymarket_trump$price)


needleStart <- as.numeric(as.POSIXct("2024-11-06 01:00", tz = "UTC"))
needleEnd <- as.numeric(as.POSIXct("2024-11-06 10:38", tz = "UTC"))

polymarket_data <- polymarket_data[needleStart <= polymarket_data$Timestamp &
                  polymarket_data$Timestamp <= needleEnd,]


polymarket_harris_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Harris)

polymarket_trump_needle <- data.frame("Timestamp" = polymarket_data$Timestamp,
                                       "odds" = polymarket_data$Trump)


plot(polymarket_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris Polymarket election needle",
     xlab = "UTC time")
lines(polymarket_trump_needle, type = 'l', col = "red")
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)

