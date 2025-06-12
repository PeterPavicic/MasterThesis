#!./venv/bin/python

from queries import *

def getTrumpMarket(startPages: int | list[int] = 0):
    trumpYes = '"21742633143463906290569050155826241533067272736897614950488156847949938836455"'
    trumpNo = '"48331043336612883890938759509493159234755048973500640148014422747788308965732"'

    # TODO: change startPage using object function
    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"
    trumpElectionTransactionsMaker  = Subquery(SQ.OrdersFilled, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionTransactionsTaker  = Subquery(SQ.OrdersFilled, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersMaker        = Subquery(SQ.OrdersMatched, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersTaker        = Subquery(SQ.OrdersMatched, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")

    subqueries = [
        trumpElectionTransactionsMaker,
        trumpElectionTransactionsTaker,
        trumpElectionOrdersMaker,
        trumpElectionOrdersTaker
    ]

    sqCount = len(subqueries)

    if isinstance(startPages, int) and startPages != 0:
        startPages = [startPages] * sqCount


    if isinstance(startPages, list):
        for i, sq in enumerate(subqueries):
            sq.setStartPage(startPages[i])

    myQuery = Query("TrumpElectionWinner", SG.ORDERS_SG, subqueries)
    print(myQuery.QueryText)
    myQuery.run_query(True)
    print("Done getting Trump Market data")


def getFOMCMarket(startPages: int | list[int] = 0):

    # 50+ bps down
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


    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"
    FOMCMarket1  = Subquery(SQ.OrdersFilled, name="down50_Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{down50Yes},\n\t\t{down50No}]")
    FOMCMarket2  = Subquery(SQ.OrdersFilled, name="down50_Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{down50Yes},\n\t\t{down50No}]")
    FOMCMarket3  = Subquery(SQ.OrdersFilled, name="down25_Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{down25Yes},\n\t\t{down25No}]")
    FOMCMarket4  = Subquery(SQ.OrdersFilled, name="down25_Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{down25Yes},\n\t\t{down25No}]")
    FOMCMarket5  = Subquery(SQ.OrdersFilled, name="NoChange_Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{noChangeYes},\n\t\t{noChangeNo}]")
    FOMCMarket6  = Subquery(SQ.OrdersFilled, name="NoChange_Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{noChangeYes},\n\t\t{noChangeNo}]")
    FOMCMarket7  = Subquery(SQ.OrdersFilled, name="up25_Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{up25Yes},\n\t\t{up25No}]")
    FOMCMarket8  = Subquery(SQ.OrdersFilled, name="up25_Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{up25Yes},\n\t\t{up25No}]")

    subqueries = [
        FOMCMarket1,
        FOMCMarket2,
        FOMCMarket3,
        FOMCMarket4,
        FOMCMarket5,
        FOMCMarket6,
        FOMCMarket7,
        FOMCMarket8
    ]

    sqCount = len(subqueries)

    if isinstance(startPages, int) and startPages != 0:
        startPages = [startPages] * sqCount


    if isinstance(startPages, list):
        for i, sq in enumerate(subqueries):
            sq.setStartPage(startPages[i])


    myQuery = Query("FOMCMarketSeptember24", SG.ORDERS_SG, subqueries)
    print(f"Running Query:\n{myQuery.QueryText}")
    myQuery.run_query(True)
    print("Done getting FOMC September 24 orderbook data")


if __name__ == "__main__":
    # getTrumpMarket(719000)
    getFOMCMarket()






