#!./venv/bin/python
import csv
import json
import os
import requests
import time
from datetime import datetime
from pathlib import Path

##### SUBGRAPH CONSTANTS #####
# ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/polymarket-orderbook-resync/prod/gn"
ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/orderbook-subgraph/0.0.1/gn"
POSITIONS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/positions-subgraph/0.0.7/gn"
ACTIVITY_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/activity-subgraph/0.0.4/gn"
OPEN_INTEREST_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/oi-subgraph/0.0.6/gn"
PNL_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/pnl-subgraph/0.0.14/gn"

# QUERY CONSTANTS
MAX_PAGE_SIZE = 1000
OUTPUT_DIR = "./Data Transactions/"
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

def fetch_and_save_pages(api_url: str, operationName: str, query_template: str, startPage: int=0, pageSize: int=MAX_PAGE_SIZE, output_dir: str=OUTPUT_DIR, timeout: int=100, max_entries = None):
    """
    Runs the given query at the given API. Paginates automatically, starting from startPage, writing files to output_dir.
    """
    output_dir = os.path.join(output_dir, operationName)
    os.makedirs(output_dir, exist_ok=True)
    skip = startPage
    pageSize = max(MAX_PAGE_SIZE, pageSize)

    while True:
        if max_entries is not None and max_entries <= skip :
                    print(f"[skip={skip}] [time={datetime.now()}] Reached max_entries={max_entries}, stopping.")
                    break

        variables = {"skip": skip, "first": pageSize}
        payload = {
            "query": query_template,
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


        # TODO: parameterise ordersMatchedEvents here
        events = data.get("data", {}).get("ordersMatchedEvents", [])
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

def jsons_to_csv(input_dir, output_csv_path):
    fieldnames = [
        "transactionHash",
        "orderHash",
        "timestamp",
        "makerAssetId",
        "takerAssetId",
        "maker",
        "taker",
        "makerAmountFilled",
        "takerAmountFilled",
        "fee"
    ]

    with open(output_csv_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        # Loop through all .json files in the directory
        for json_path in Path(input_dir).glob("*.json"):
            print(f"Processing file: {json_path.name}")
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            records = data if isinstance(data, list) else [data]

            for rec in records:
                # Build a flat row dict
                row = {}
                for key in fieldnames:
                    if key in ("maker", "taker"):
                        nested = rec.get(key, {})
                        row[key] = nested.get("id") if isinstance(nested, dict) else None
                    else:
                        row[key] = rec.get(key)
                writer.writerow(row)

    print(f"All done! Combined CSV written to: {output_csv_path}")



if __name__ == "__main__":
    fetch_and_save_pages(ORDERS_SG, "findTrumpMatchedOrdersMaker", QUERY_TEMPLATE_MATCHED_MAKER, max_entries=100000)
    fetch_and_save_pages(ORDERS_SG, "findTrumpMatchedOrdersTaker", QUERY_TEMPLATE_MATCHED_MAKER, max_entries=100000)
    
    # jsons_to_csv(input_dir="./Data Transactions/TrumpElectionMaker/", 
    #              output_csv_path="./Transactions/TrumpElection_maker.csv")
    # jsons_to_csv(input_dir="./Data Transactions/TrumpElectionTaker/", 
    #              output_csv_path="./Transactions/TrumpElection_taker.csv")
    


