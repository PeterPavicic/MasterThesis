#!./venv/bin/python

from pathlib import Path
import json
import pandas as pd
import requests
from datetime import datetime
import glob
import os


def fetch_and_save_pages(api_url: str, operationName: str, queryText: str, output_dir: str, max_entries = None,
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


        # FIX: The 'get' is broken if not specifically what I am searching for 

        events = data.get("data", {}).get("netUserBalances", [])
        if not events:
            print(f"[skip={skip}] [time={datetime.now()}] No more events. Stopping.")
            break

        # Write this page to its own JSON file
        filename = os.path.join(output_dir, f"{operationName}{skip}.json")
        with open(filename, "w") as f:
            json.dump(events, f, indent=2)
        print(f"[skip={skip}] Saved {len(events)} events to {filename}")

        # If fewer than pageSize, we're done
        if len(events) < pageSize:
            print(f"[time={datetime.now()}] Last page reached.")
            break

        skip += pageSize 
        # time.sleep(0.2)  # optional back‑off



def json_files_to_one_csv(file_path, out_csv):
    all_dfs = []

    # for path in glob.glob(os.path.join(json_dir, '*.json')):
    path = os.path.join(file_path, '*.json')
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    # Flatten into dataframe
    df = pd.json_normalize(data, sep='_')
    # explode any list columns
    df.explode
    list_cols = [c for c in df.columns if df[c].apply(lambda x: isinstance(x, list)).any()]
    for col in list_cols:
        df = df.explode(col)
    all_dfs.append(df)

    # concatenate all, reset index
    master = pd.concat(all_dfs, ignore_index=True)
    master.to_csv(out_csv, index=False)
    print(f"Wrote {len(master)} total rows to {out_csv}")


if __name__ == "__main__":
    # usage
    
    # print(f"{Path(__file__).parent.parent}/Data Transactions/")
    # Path(__file__).parent.parent asd = findTrumpMatchedOrdersTaker0


#     myQuery = """
# query ArrayTest ($first: Int, $skip: Int) {
#   netUserBalances(
#     first: $first
#     skip: $skip
#     where: {
#       # user: "0x83c168728c512f8d0e577c1525089ccf10909019"
#       user: "0x04902c7046da0f93f29d070b00f9366a165ac81f"
#       # user: "0x1d7d255f0d1bbfddb7bf5025a9c52aa7110b7e36"
#     }
#   ) {
#     # id
#     # user
#     asset {
#             id
#         }
#       # outcomeIndex
#     balance
#     #asset {
#     #  id
#     #  condition {
#     #    id
#     #    payouts
#     #  }
#     #  complement
#     #  }
#     #  # outcomeIndex
#     #balance
#   }
# } """

    # fetch_and_save_pages("https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/positions-subgraph/0.0.7/gn",
                        # "cake", myQuery, "/home/peter/Documents/MT Master Thesis/Data Transactions/test/")
