library(dplyr)

maker_transactions <- read.csv("./Transactions/TrumpElection_maker.csv")
taker_transactions <- read.csv("./Transactions/TrumpElection_taker.csv")



# Asset IDs are:
# TrumpYes - "21742633143463906290569050155826241533067272736897614950488156847949938836455"
# TrumpNo  - "48331043336612883890938759509493159234755048973500640148014422747788308965732"


View(maker_transactions)
View(taker_transactions)



print(paste(collapse = ", ", colnames(maker_transactions)))

summary(maker_transactions)
summary(taker_transactions)

hist(maker_transactions$fee)

min(maker_transactions$takerAmountFilled)

hist(maker_transactions$takerAmountFilled)


summary(maker_transactions$timestamp)
summary(taker_transactions$timestamp)



# Transactions

# No. of transactions occuring at the same time
sum(duplicated(maker_transactions$timestamp))

# No. of transactions occuring at the same time with the same maker/taker
sum(duplicated(maker_transactions$timestamp) & duplicated(maker_transactions$maker))
sum(duplicated(maker_transactions$timestamp) & duplicated(maker_transactions$taker))

# No. of transactions occuring at the same time with the same maker AND taker
sum(duplicated(maker_transactions$timestamp) & duplicated(maker_transactions$maker) & duplicated(maker_transactions$taker))
