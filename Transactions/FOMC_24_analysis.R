library(dplyr)


# 50 bps down
down50Yes = '"106191328358576540351439267765925450329859429577455659884974413809922495874408"'
down50No = '"9214127416164770663428045171731158534317583924108886506080862617439489581164"'

# 25 bps down
down25Yes = '"88244443360063235221444316604590968694314258311386447899087521723508440858841"'
down25No = '"68670890969542385995453083110367487631448978600988239315882323042259997093658"'

# No change
noChangeYes = '"89262722133387845193166560202808972424089924545438804960915341631492994906283"'
noChangeNo = '"33507963070620649762144944331241609312903313601210934738148421620353685107636"'

# 25 bps up
up25Yes = '"95823178650727331613915203831778682038645976746731326695569990405131199144192"'
up25No = '"22975325364139703836483070412535421663459933235801997078698722577155796494270"'


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




# TODO: Figure how transactions work, and most importantly what amounts are and write code which makes it more accessible



