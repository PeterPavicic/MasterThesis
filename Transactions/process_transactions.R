maker_transactions <- read.csv("./Transactions/TrumpElection_maker.csv")
taker_transactions <- read.csv("./Transactions/TrumpElection_taker.csv")


# NOTE: AssetIDs here are either:
# TrumpYes: "21742633143463906290569050155826241533067272736897614950488156847949938836455"
# TrumpNo:  "48331043336612883890938759509493159234755048973500640148014422747788308965732"



# TODO: Figure out what all of these are
# NOTE: The variables are supposed to be the following:
# transactionHash: id for transaction, hex
# orderHash: id for order (?), hex
# timestamp: UNIX timestamp, integer
# makerAssetId: traded AssetID, string/integer
# takerAssetId: always 0, indicates cash, integer
# maker: makerID - wallet, hex 
# taker: takerID - wallet, hex 
# makerAmountFilled: ?????
# takerAmountFilled: ?????
# fee: ?????

print(paste(collapse = ", ", colnames(maker_transactions)))

summary(maker_transactions)
summary(taker_transactions)

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




# TODO: Figure how transactions work, and most importantly what amounts are and write code which makes it more accessible



