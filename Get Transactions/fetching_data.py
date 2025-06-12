#!./venv/bin/python

from queries import *

def getTrumpMarket():
    trumpYes = '"21742633143463906290569050155826241533067272736897614950488156847949938836455"'
    trumpNo = '"48331043336612883890938759509493159234755048973500640148014422747788308965732"'

    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"
    trumpElectionTransactionsMaker  = Subquery(SQ.OrdersFilled, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionTransactionsTaker  = Subquery(SQ.OrdersFilled, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersMaker        = Subquery(SQ.OrdersMatched, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersTaker        = Subquery(SQ.OrdersMatched, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")

    subqueries = [trumpElectionTransactionsMaker,
                  trumpElectionTransactionsTaker,
                  trumpElectionOrdersMaker,
                  trumpElectionOrdersTaker
                  ]

    myQuery = Query("TrumpElectionWinner", SG.ORDERS_SG, subqueries)
    print(myQuery.QueryText)
    myQuery.run_query(True)
    print("Done getting Trump Market data")


if __name__ == "__main__":
    getTrumpMarket()






