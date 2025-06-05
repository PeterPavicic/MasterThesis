def getOrders(operationName: str, type: str):
    assert (type == "maker" or type == "taker")
    
        

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
