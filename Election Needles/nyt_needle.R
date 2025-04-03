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


plot(nyt_harris_needle, type = 'l', col = "blue", ylim = c(0, 1),
     main = "Trump vs Harris NY Times election needle",
     xlab = "UTC time")
lines(nyt_trump_needle, type = 'l', col = "red")
legend("right", legend = c("Trump", "Harris"),
       col = c("red", "blue"), lwd = 2)

