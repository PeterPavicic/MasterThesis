from enum import EnumDict, StrEnum

# Subgraphs
class SG(StrEnum):
# ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/polymarket-orderbook-resync/prod/gn"
    ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/orderbook-subgraph/0.0.1/gn"
    POSITIONS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/positions-subgraph/0.0.7/gn"
    ACTIVITY_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/activity-subgraph/0.0.4/gn"
    OPEN_INTEREST_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/oi-subgraph/0.0.6/gn"
    PNL_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/pnl-subgraph/0.0.14/gn"


# TODO: Also implement duplicates here, maybe in separate classses?

# Define Enum where we specify each type of query & the corresponding
# queryName, and variables returned by the query
class SQ(EnumDict):
    # from OrderBook subgraph
    MarketData = {
        "name": "marketDatas",
        "returnVariables": [
            "id",
            "condition",
            "outcomeIndex"
        ]
    }
    """
    Information about the market 
    Input: Filtering
    Returns: id, condition, outcomeIndex
    """

    OrdersFilled = {
        "name": "orderFilledEvents",
        "returnVariables": [
            "transactionHash",
            "timestamp",
            "orderHash",
            "maker",
            "taker",
            "makerAssetId",
            "takerAssetId",
            "makerAmountFilled",
            "takerAmountFilled",
            "fee"
        ]
    }
    """
    Exchange OrderFilled event stored directly (transactions)
    Input: Filtering
    Returns: transactionHash, timestamp, orderHash, maker, taker, makerAssetId, takerAssetId, makerAmountFilled, takerAmountFilled, fee
    """

    OrdersMatched = {
        "name": "ordersMatchedEvents",
        "returnVariables": [
            "id",
            "timestamp",
            "makerAssetID",
            "takerAssetID",
            "makerAmountFilled",
            "takerAmountFilled"
        ]
    }
    """
    Exchange OrdersMatched event stored directly
    Input: Filtering
    Returns: id, timestamp, makerAssetID, takerAssetID, makerAmountFilled, takerAmountFilled
    """

    OrderBook = {
        "name": "orderbooks",
        "returnVariables": [
            "id",
            "tradesQuantity",
            "buysQuantity",
            "sellsQuantity",
            "collateralVolume",
            "scaledCollateralVolume",
            "collateralBuyVolume",
            "scaledCollateralBuyVolume",
            "collateralSellVolume",
            "scaledCollateralSellVolume"
        ]
    }
    """
    Aggregate order book info for 1 asset id
    Input: ERC1155 TokenID
    Returns: id, tradesQuantity, buysQuantity, sellsQuantity, collateralVolume, scaledCollateralVolume, collateralBuyVolume, scaledCollateralBuyVolume, collateralSellVolume, scaledCollateralSellVolume
    """

    OrdersMatchedGlobal = {
        "name": "ordersMatchedGlobals",
        "returnVariables": [
            "tradesQuantity",
            "buysQuantity",
            "sellsQuantity",
            "collateralVolume",
            "scaledCollateralVolume",
            "collateralBuyVolume",
            "scaledCollateralBuyVolume",
            "collateralSellVolume",
            "scaledCollateralSellVolume"
        ]
    }
    """
    Exchange - all trades aggregated
    Input: Filtering
    Returns: tradesQuantity, buysQuantity, sellsQuantity, collateralVolume, scaledCollateralVolume, collateralBuyVolume, scaledCollateralBuyVolume, collateralSellVolume, scaledCollateralSellVolume
    """

    # from Positions subgraph
    UserBalances = {
        "name": "userBalances",
        "returnVariables": [
            "id",
            "user",
            "asset",
            "balance"
        ]
    }
    """
    User Balances in each asset ever traded
    Input: Filtering
    Returns: id, user, asset, balance
    """

    NetUserBalances = {
        "name": "netUserBalances",
        "returnVariables": [
            "id",
            "user",
            "asset",
            "balance"
        ]
    }
    """
    Net User Balances in each asset ever traded
    Input: Filtering
    Returns: id, user, asset, balance
    """

    TokenIdConditions = {
        "name": "TokenIdConditions",
        "returnVariables": [
            "id",
            "condition",
            "complement",
            "outcomeIndex"
        ]
    }
    """
    Data about ERC1155 token
    Input: Filtering
    Returns: id, condition, complement, outcomeIndex
    """

    Conditions = {
        "name": "conditions",
        "returnVariables": [
            "id",
            "payouts"
        ]
    }
    """
    Conditions for ERC1155 token
    Input: Filtering
    Returns: id, payouts
    """

    # from Activity subgraph
    Split = {
        "name": "splits",
        "returnVariables": [
            "id",
            "timestamp",
            "stakeholder",
            "condition",
            "amount"
        ]
    }
    """
    Information about splits
    Input: Filtering
    Returns: id, timestamp, stakeholder, condition, amount
    """

    Merge = {
        "name": "merges",
        "returnVariables": [
            "id",
            "timestamp",
            "stakeholder",
            "condition",
            "amount"
        ]
    }
    """
    Information about merges
    Input: Filtering
    Returns: id, timestamp, stakeholder, condition, amount
    """

    Redemption = {
        "name": "redemptions",
        "returnVariables": [
            "id",
            "timestamp",
            "redeemer",
            "condition",
            "indexSets",
            "payout"
        ]
    }
    """
    Information about redemptions 
    Input: Filtering
    Returns: id, timestamp, redeemer, condition, indexSets, payout
    """

    NegRiskConversion = {
        "name": "negRiskConversions",
        "returnVariables": [
            "id",
            "timestamp",
            "stakeholder",
            "negRiskMarketId",
            "amount",
            "indexSet",
            "questionCount"
        ]
    }
    """
    Information about events of NegRisk conversion
    Input: Filtering
    Returns: id, timestamp, stakeholder, negRiskMarketId, amount, indexSet, questionCount
    """

    NegRiskEvents = {
        "name": "NegRiskEvents",
        "returnVariables": [
            "id",
            "condition",
            "outcomeIndex"
        ]
    }
    """
    Markets where NegRisk can happen and question count
    Input: Filtering
    Returns: id, condition, outcomeIndex
    """

    Fpmms = {
        "name": "fixedProductMarketMakers",
        "returnVariables": [
            "id"
        ]
    }
    """
    FPMM's IDs
    Input: Filtering
    Returns: id
    """

    Position = {
        "name": "positions",
        "returnVariables": [
            "id",
            "condition",
            "outcomeIndex"
        ]
    }
    """
    Metadata for the market, by ERC1155 token IDs
    Input: Filtering
    Returns: id, condition, outcomeIndex
    """

    Condition = {
        "name": "conditions",
        "returnVariables": [
            "id"
        ]
    }
    """
    Condition IDs
    Input: Filtering
    Returns: id
    """

    # from Open Interest subgraph
    # Conditions
    # NegRiskEvents
     
    MarketOpenInterest = {
        "name": "marketOpenInterests",
        "returnVariables": [
            "id",
            "amount"
        ]
    }
    """
    Open interest amount for market
    Input: Filtering
    Returns: id, amount
    """

    GlobalOpenInterest = {
        "name": "globalOpenInterest",
        "returnVariables": [
            "id",
            "amount"
        ]
    }
    """
    Open interest on all of Polymarket
    Input: Filtering
    Returns: id, amount
    """

    # from P&L subgraph
    UserPosition = {
        "name": "UserPositions",
        "returnVariables": [
            "id",
            "user",
            "tokenId",
            "amount",
            "avgPrice",
            "realizedPnl",
            "totalBought"
        ]
    }
    """
    Users' active ERC1155 token positions
    Input: Filtering
    Returns: id, user, tokenId, amount, avgPrice, realizedPnl, totalBought
    """


class Query:
    """
    Creates a query consisting of subqueries which can be sent to the GoldSky API
    """
    def __init__(self, queryName, endPoint):
        self.name = queryName
        self.subqueries = []
        self.APILink = endPoint
        # self.queryText = None


    # TODO: rewrite this into buildQuery function which builds query from subqueries
    def buildQuery(self):
        s = f"""
        query {self.name}($skip: Int!, $first: Int!) {{
        }}
        """
        self.queryText = s

    def printQuery(self):
        if self.queryText is None:
            self.buildQuery()
        print(self.queryText)


    def add_query(self, subquery):
        self.subqueries.append(subquery)

class Subqueries:
    """Creates subqueries which are building blocks of queries"""


def queryOrdersFilled(operationName: str, type: str):
    assert (type == "maker" or type == "taker")

def queryMatchedOrders(operationName: str, type: str):
    assert (type == "maker" or type == "taker")
        
def queryTransactions():
    pass

def queryUserBalances():
    pass


def queryNetUserBalances():
    pass





QUERY_TEMPLATE_MAKER = """
query TrumpWinsElectionMarket($skip: Int!, $first: Int!) {
    orderFilledEvents(
        skip: $skip,
        first: $first,
        orderBy: timestamp,
        orderDirection: asc,
        where: {
        makerAssetId_in: [
        "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "48331043336612883890938759509493159234755048973500640148014422747788308965732"
        ]
    }
        ) {
        transactionHash
        orderHash
        timestamp
        makerAssetId
        takerAssetId
        maker {
            id
        }
        taker {
            id
        }
        makerAmountFilled
        takerAmountFilled
        fee
    }
}
"""

QUERY_TEMPLATE_TAKER = """
query TrumpWinsElectionMarket($skip: Int!, $first: Int!) {
    orderFilledEvents(
        skip: $skip,
        first: $first,
        orderBy: timestamp,
        orderDirection: asc,
        where: {
        takerAssetId_in: [
        "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "48331043336612883890938759509493159234755048973500640148014422747788308965732"
        ]
    }
        ) {
        transactionHash
        orderHash
        timestamp
        makerAssetId
        takerAssetId
        maker {
            id
        }
        taker {
            id
        }
        makerAmountFilled
        takerAmountFilled
        fee
    }
}
"""

QUERY_TEMPLATE_MATCHED_MAKER = """
query findTrumpMatchedOrders($skip: Int!, $first: Int!) {
    ordersMatchedEvents (
        skip: $skip,
        first: $first,
        orderBy: timestamp
        orderDirection: asc
        where:{
        makerAssetID_in: [
        "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "48331043336612883890938759509493159234755048973500640148014422747788308965732"
        ]
    }
        )
    {
        id    
        timestamp
        makerAssetID
        takerAssetID
        makerAmountFilled
        takerAmountFilled
    }
}
"""

QUERY_TEMPLATE_MATCHED_TAKER = """
query TrumpWinsMatchedOrders ($skip: Int!, $first: Int!) {
    ordersMatchedEvents (
        skip: $skip,
        first: $first,
        orderBy: timestamp,
        orderDirection: asc,
        where: {
        takerAssetId_in: [
        21742633143463906290569050155826241533067272736897614950488156847949938836455,
        48331043336612883890938759509493159234755048973500640148014422747788308965732
        ]
    }
        ) {
        id    
        timestamp
        makerAssetID
        takerAssetID
        makerAmountFilled
        takerAmountFilled
    }
}
"""
