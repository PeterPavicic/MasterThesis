#!./venv/bin/python
import requests
import json
import os
# import time

# SUBGRAPH CONSTANTS
ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/polymarket-orderbook-resync/prod/gn"
POSITIONS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/positions-subgraph/0.0.7/gn"
ACTIVITY_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/activity-subgraph/0.0.4/gn"
OPEN_INTEREST_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/oi-subgraph/0.0.6/gn"
PNL_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/pnl-subgraph/0.0.14/gn"

# QUERY CONSTANTS
PAGE_SIZE = 1000
OUTPUT_DIR = "/run/media/peter/SanDisk_SSD/Transactions/"
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
        timestamp
        makerAssetId
        takerAssetId
        maker
        taker
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
        timestamp
        makerAssetId
        takerAssetId
        maker
        taker
        makerAmountFilled
        takerAmountFilled
        fee
    }
}
"""


def fetch_and_save_pages(api_url: str, query_template: str, startPage: int=0, pageSize: int=PAGE_SIZE, output_dir: str=OUTPUT_DIR, timeout: int=100):
    """
    Runs the given query at the given API. Paginates automatically, starting from startPage, writing files to output_dir.
    """
    skip = startPage
    while True:
        variables = {"skip": skip, "first": pageSize}
        payload = {
            "query": query_template,
            "operationName": "TrumpWinsElectionMarket",
            "variables": variables
        }

        try:
            resp = requests.post(api_url, json=payload, timeout=timeout)
            resp.raise_for_status()
            data = resp.json()
        except requests.RequestException as e:
            print(f"[skip={skip}] Network/HTTP error: {e}")
            break
        except json.JSONDecodeError:
            print(f"[skip={skip}] Failed to parse JSON response.")
            break

        if "errors" in data:
            print(f"[skip={skip}] GraphQL errors:", data["errors"])
            break

        events = data.get("data", {}).get("orderFilledEvents", [])
        if not events:
            print(f"[skip={skip}] No more events. Stopping.")
            break

        # Write this page to its own JSON file
        filename = os.path.join(output_dir, f"TrumpWins{skip}.json")
        with open(filename, "w") as f:
            json.dump(events, f, indent=2)
        print(f"[skip={skip}] Saved {len(events)} events to {filename}")

        # If fewer than pageSize, we're done
        if len(events) < pageSize:
            print("Last page reached.")
            break

        skip += pageSize 
        # time.sleep(0.2)  # optional back‑off



if __name__ == "__main__":
    fetch_and_save_pages(ORDERS_SG, QUERY_TEMPLATE_MAKER)

