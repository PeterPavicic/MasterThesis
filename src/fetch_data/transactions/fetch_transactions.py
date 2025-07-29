#!./venv/bin/python

from queries import *

FILE_LOCATION = Path(__file__)
ROOT_DIR = FILE_LOCATION.parent.parent


def getTrumpMarket(startPages: int | list[int] = 0):
    trumpYes = '"21742633143463906290569050155826241533067272736897614950488156847949938836455"'
    trumpNo = '"48331043336612883890938759509493159234755048973500640148014422747788308965732"'

    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"
    trumpElectionTransactionsMaker = Subquery(SQ.OrdersFilled, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionTransactionsTaker = Subquery(SQ.OrdersFilled, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetId_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersMaker = Subquery(SQ.OrdersMatched, name="Maker", orderText=orderTimestamp, filterText=f"makerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")
    trumpElectionOrdersTaker = Subquery(SQ.OrdersMatched, name="Taker", orderText=orderTimestamp, filterText=f"takerAssetID_in: [{trumpYes},\n\t\t{trumpNo}]")

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


def getTransactions(queryName: str, marketsList: list[dict[str, dict[str, str]]], startPages: int | list[int] = 0) -> None:
    """
    Gets all orderFilled and OrdersMatched data from orders subgraph from dictionary of Yes/No assets
    marketsList needs to have format (default format for data retrieved using Gamma API):
    [
        {
          "assetName": {
            "Yes": `"AssetID"`,
            "No": `"AssetID"` 
          }
        },
        {
          "nextAssetName": {
            "Yes": `"AssetID"`,
            "No": `"AssetID"` 
          }
        }
    ]
    """

    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"

    subqueries = []

    # go through individual markets, create subqueries
    for market_dict in marketsList:
        # marktName: market Name, assetIDPairs: Yes-No pairs
        for marketName, assetIDPairs in market_dict.items():
            yesAsset = assetIDPairs.get("Yes")
            noAsset = assetIDPairs.get("No")
            if yesAsset is None or noAsset is None:
                raise Exception(f"{marketName} contains invalid assetIDs")

            # Orders Filled
            whereFilterFilled = f"""
                or: [
            {{makerAssetId_in: [{yesAsset},\n\t\t{noAsset}]}},
            {{takerAssetId_in: [{yesAsset},\n\t\t{noAsset}]}}
                ]
            """

            # Orders Matched
            # whereFilterMatched = f"""
            #     or: [
            # {{makerAssetID_in: [{yesAsset},\n\t\t{noAsset}]}},
            # {{takerAssetID_in: [{yesAsset},\n\t\t{noAsset}]}}
            #     ]
            # """

            # Orders Filled
            sq_filled_orders = Subquery(SQ.OrdersFilled, name=f"filledOrders_{marketName}", orderText=orderTimestamp, filterText=whereFilterFilled)

            # Orders Matched
            # sq_matched_orders = Subquery(SQ.OrdersMatched, name=f"matchedOrders_{marketName}", orderText=orderTimestamp, filterText=whereFilterMatched)

            subqueries.append(sq_filled_orders)
            # subqueries.append(sq_matched_orders)


    sqCount = len(subqueries)

    if isinstance(startPages, int) and startPages != 0:
        startPages = [startPages] * sqCount


    if isinstance(startPages, list):
        for i, sq in enumerate(subqueries):
            sq.setStartPage(startPages[i])

    myQuery = Query(queryName, SG.ORDERS_SG, subqueries)
    print(f"Running Query:\n{myQuery.QueryText}")
    myQuery.run_query(True)
    print(f"Done getting {queryName} orderbook data")


# TODO: Rewrite this for fetching data from raw market json
def getUserPnLs(queryName: str, marketsList: list[dict[str, dict[str, str]]], startPages: int | list[int] = 0) -> None:
    """
    Gets all userPnLs from list of user IDs (which are strings)
    """

    ordering = "\torderBy: user\n\torderDirection: asc"

    subqueries = []

    # go through individual markets, create subqueries
    for market_dict in marketsList:
        # marktName: market Name, assetIDPairs: Yes-No pairs
        for marketName, assetIDPairs in market_dict.items():

            yesAsset = assetIDPairs.get("Yes")
            noAsset = assetIDPairs.get("No")
            if yesAsset is None or noAsset is None:
                raise Exception(f"{marketName} contains invalid assetIDs")

            # Orders Filled
            yesFilter = f"tokenId: {yesAsset}"

            # Orders Matched
            noFilter = f"tokenId: {noAsset}"

            # Yes Asset
            sq_yes = Subquery(SQ.UserPosition, name=f"{marketName}_Yes", orderText=ordering, filterText=yesFilter)
            # No Asset
            sq_no = Subquery(SQ.UserPosition, name=f"{marketName}_No", orderText=ordering, filterText=noFilter)

            subqueries.append(sq_yes)
            subqueries.append(sq_no)


    sqCount = len(subqueries)

    if isinstance(startPages, int) and startPages != 0:
        startPages = [startPages] * sqCount


    if isinstance(startPages, list):
        for i, sq in enumerate(subqueries):
            sq.setStartPage(startPages[i])

    myQuery = Query(queryName, SG.PNL_SG, subqueries)
    print(f"Running Query:\n{myQuery.QueryText}")
    myQuery.run_query(True)
    print(f"Done getting {queryName} orderbook data")


# TODO: Rewrite this so data taken from csv, turned into df
def getTokenActivity(queryName: str, conditionList, startPages: int | list[int] = 0) -> None:
    """
    Get splits and merges from a dataframe of tokens (subqueries are events, not markets)
    """

    orderTimestamp = "\torderBy: timestamp\n\torderDirection: asc"

    # Works for both splits and merges
    whereFilter = f"""
    condition_in: [{",\n".join([f"\"{c}\"" for c in conditionList])}]
    """

    # Splits
    sq_splits = Subquery(SQ.Split, name=f"", orderText=orderTimestamp, filterText=whereFilter)
    # Merges
    sq_merges = Subquery(SQ.Merge, name=f"", orderText=orderTimestamp, filterText=whereFilter)

    subqueries = [sq_splits, sq_merges]

    sqCount = len(subqueries)

    if isinstance(startPages, int) and startPages != 0:
        startPages = [startPages] * sqCount

    if isinstance(startPages, list):
        for i, sq in enumerate(subqueries):
            sq.setStartPage(startPages[i])

    myQuery = Query(queryName, SG.ACTIVITY_SG, subqueries)
    print(f"Running Query:\n{myQuery.QueryText}")
    myQuery.run_query(True)
    print(f"Done getting {queryName} activity data")


if __name__ == "__main__":

    # jsons_dir = os.path.join(ROOT_DIR, "data/interim/02_renamed/polymarket/markets")
    # fileNames = [f for f in os.listdir(jsons_dir)]

    json_files = [
        os.path.join(ROOT_DIR, "/data/interim/02_renamed/polymarket/markets/fed-interest-rates-may-2024.json")
    ]
    
    for json_file in json_files:
        # print(json_file)
        with open(json_file, 'r') as file:
            data = json.load(file)
        eventTitle = data.get("title")
        markets = data.get("markets")
        # getTransactions(eventTitle, markets)
        getUserPnLs(eventTitle, markets)

    print("Done getting missing data")
    pass



