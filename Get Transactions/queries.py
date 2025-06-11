from datetime import datetime
from enum import StrEnum, Enum
from pathlib import Path
import glob
import itertools
import json
import numpy
import os
import pandas as pd
import re
import requests


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
class SQ(dict, Enum):
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
            """asset {
id
condition {
    id
    payouts
}
complement
outcomeIndex
            }
            """,
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
            """asset {
    id
    condition {
        id
        payouts
    }
    complement
    outcomeIndex
}""",
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
            """condition {
    id
    payouts
}""",
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
    FPMM'text IDs
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


# Class for subqueries, which are the payload of the queries sent to the API
class Subquery:
    """
    Creates subqueries which are building blocks of queries
    """

    def __init__(self, subqueryType: SQ, name: str, orderText: str | None = None, filterText: str | None = None, startPage: int = 0):
        self.Type = subqueryType
        self.SubQueryName = subqueryType["name"]
        self.Name = f"{subqueryType["name"]}_{name}"
        self.Order = orderText
        self.Filter = filterText
        self.StartPage = startPage
        self.__buildSubQuery()


    def __buildSubQuery(self) -> None:
        text = f"""
    {self.SubQueryName} (
        skip: VAR_SKIP
        first: VAR_FIRST"""

        if self.Order is not None:
            text += f"\n{self.Order}"

        if self.Filter is not None:
            text += f"""
        where: {{
            {self.Filter}
        }}"""

        text += f"""
    ) {{
        {"\n".join(self.Type["returnVariables"])}
    }}"""

        self.QueryText = text


    def __str__(self) -> str:
        return(self.QueryText)


class Query:
    """
    Query which is comprised of subqueries which are all sent to GoldSky API
    """

    def __init__(self, operationName: str, endPoint: SG, subqueries: list[Subquery] | Subquery):
        # XOR(subqeries is not None, customQuery is not None)
        self.Name = operationName
        self.APILink = endPoint

        # Ensure subqueries are a list
        if isinstance(subqueries, list):
            self.Subqueries = subqueries
        else:
            self.Subqueries = [subqueries]

        self.__buildQuery(self.Subqueries)


    # Builds query from subqueries still in queue
    def __buildQuery(self, sqQueue) -> None:
        sqCount = len(sqQueue)

        # Create query arguments, a.k.a. skip and first variables
        paginationVariables = [f"$skip{i}: Int, $first{i}: Int" for i in range(sqCount)]
        queryArguments = f"({", ".join(paginationVariables)})"

        # Builds full query text from subqueries, with given operation name
        text = f"""
query {self.Name} {queryArguments} {{
    {"\n".join([sq.QueryText for sq in sqQueue])}
}}
        """

        # Replace each VAR_SKIP and VAR_FIRST with corresponding $skip and $first values
        counter = itertools.count(0)
        re.sub(r"VAR_SKIP", lambda _: f"$skip{next(counter)}", text)
        re.sub(r"VAR_FIRST", lambda _: f"$first{next(counter)}", text)

        self.QueryText = text
        

    def run_query(self, create_csvs: bool):
        OUTPUT_DIR_START = f"{Path(__file__).parent.parent}/Data Transactions/{self.Name}/"
        TIMEOUT = 100
        PAGESIZE = 1000
        SQ_Queue = self.Subqueries

        skipPages = []
        output_paths = []

        for sq in SQ_Queue:
            # Get queryNames for subqueries
            skipPages.append(sq.StartPage)
            fileName = f"{self.Name}_{sq.Name}_{sq.StartPage}.json"
            output_paths.append(os.path.join(OUTPUT_DIR_START, sq.Name, fileName))

        # Create output paths
        for p in output_paths:
            parent_dir = Path(p).parent
            os.makedirs(parent_dir, exist_ok=True)

        self.OutputDirectories = [Path(p).parent for p in output_paths]

        while True:
            # Add variables used for pagination
            subqueryCount = len(SQ_Queue)
            paginationVariables = {}
            for i in range(subqueryCount):
                paginationVariables[f"skip{i}"] = skipPages[i]
                paginationVariables[f"first{i}"] = PAGESIZE

            # Prepare request payload
            payload = {
                "query": self.QueryText,
                "operationName": self.Name,
                "variables": paginationVariables
            }

            # Catch potential errors
            try:
                response = requests.post(self.APILink, json=payload, timeout=TIMEOUT)
                response.raise_for_status()
                response_json = response.json()
            except requests.RequestException as e:
                print(f"[variables={paginationVariables}] [time={datetime.now()}] Network/HTTP error: {e}")
                break
            except json.JSONDecodeError:
                print(f"[variables={paginationVariables}] [time={datetime.now()}] Failed to parse JSON response.")
                break

            # Catch GraphQL errors
            if "errors" in response_json:
                print(f"[variables={paginationVariables}] [time={datetime.now()}] GraphQL errors:\n", json.dumps(response_json["errors"]))
                break

            # Data should be error-free here and start with key `data`
            if "data" not in response_json:
                print(f"[variables={paginationVariables}] [time={datetime.now()}] Unknown response:\n", json.dumps(response_json))
                break

            data = response_json.get("data")

            stopSQ = []

            # Parsing each subquery
            for i, sq in enumerate(SQ_Queue):
                sqKey = sq.SubQueryName
                output_path = output_paths[i]

                sqResult = data.get(sqKey)

                with open(output_path, "w") as file:
                    json.dump(sqResult, file)
                    print(f"[skip={skipPages[i]}] Saved {len(sqResult)} outputs to {output_path}.")

                if len(sqResult) < PAGESIZE:
                    print(f"[time={datetime.now()}] Last page reached for {sqKey}.")
                    stopSQ.append(i)
                else:
                    skipPages[i] += PAGESIZE
                    fileName = f"{self.Name}_{sq.Name}_{skipPages[i]}.json"
                    output_paths[i] = (os.path.join(OUTPUT_DIR_START, sq.Name, fileName))


            # If any SQs have reached the end
            if len(stopSQ) != 0:
                for i in stopSQ:
                    SQ_Queue.pop(i)
                    skipPages.pop(i)
                    output_paths.pop(i)
                if len(SQ_Queue) == 0:
                    print("Running queries exited successfully.")
                    break
                else:
                    self.__buildQuery(SQ_Queue)

        if create_csvs:
            for dir in self.OutputDirectories:
                csv_filename = f"{self.Name}_{sq.Name}.csv"
                csv_path = os.path.join(dir.parent, csv_filename)
                json_files_to_one_csv(dir, csv_path)

    def add_query(self, subquery):
        self.Subqueries.append(subquery)

    def __str__(self):
        s = f"""operationName: {self.Name}
API: {self.APILink}
Subqueries: {self.Subqueries}
OutputDirectories: {self.OutputDirectories}
Query: {self.QueryText}"""
        return s


def json_files_to_one_csv(json_dir, out_csv):
    all_dfs = []

    for path in glob.glob(os.path.join(json_dir, '*.json')):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        # ensure type list
        entries = data if isinstance(data, list) else [data]
        # Flatten into pandas dataframe
        df = pd.json_normalize(entries, sep='_')

        for c in df.columns:
            isList = df[c].apply(lambda x: isinstance(x, list)).any()
            assert isinstance(isList, numpy.bool) or isinstance(isList, bool)
            if(isList):
                df = df.explode(c)
        # explode any list columns
        all_dfs.append(df)

    # concatenate all, reset index
    master = pd.concat(all_dfs, ignore_index=True)
    master.to_csv(out_csv, index=False)
    print(f"Wrote {len(master)} total rows to {out_csv}")


def fetch_and_save_pages(api_url: str, operationName: str, queryText: str, queryName: str, output_dir: str, max_entries = None,
                         startPage: int=0, pageSize: int=1000, timeout: int=100):
    """
    Runs given query at the given API. Paginates automatically, starting from startPage, writing files to output_dir.
    Code also works if no pagination necessary.
    """
    output_dir = os.path.join(output_dir, operationName)
    os.makedirs(output_dir, exist_ok=True)
    skip = startPage
    pageSize = pageSize

    while True:
        if max_entries is not None and max_entries <= skip :
            print(f"[skip={skip}] [time={datetime.now()}] Reached max_entries={max_entries}, stopping.")
            break

        variables = {"skip": skip, "first": pageSize}
        payload = {
            "query": queryText,
            "operationName": operationName,
            "variables": variables
        }

        try:
            resp = requests.post(api_url, json=payload, timeout=timeout)
            resp.raise_for_status()
            data = resp.json()
        except requests.RequestException as e:
            print(f"[skip={skip}] [time={datetime.now()}] Network/HTTP error: {e}")
            break
        except json.JSONDecodeError:
            print(f"[skip={skip}] [time={datetime.now()}] Failed to parse JSON response.")
            break

        if "errors" in data:
            print(f"[skip={skip}] [time={datetime.now()}] GraphQL errors:", data["errors"])
            break


        # Find name of query from queryText
        events = data.get("data", {}).get(queryName, [])
        if not events:
            print(f"[skip={skip}] [time={datetime.now()}] No more events. Stopping.")
            break

        # Write this page to its own JSON file
        filename = os.path.join(output_dir, f"./{operationName}{skip}.json")
        with open(filename, "w") as f:
            json.dump(events, f, indent=2)
        print(f"[skip={skip}] Saved {len(events)} events to {filename}")

        # If fewer than pageSize, we're done
        if len(events) < pageSize:
            print(f"[time={datetime.now()}] Last page reached.")
            break

        skip += pageSize 
        # time.sleep(0.2)  # optional back‑off
