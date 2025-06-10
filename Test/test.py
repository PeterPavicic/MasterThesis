#!/usr/bin/python

from datetime import datetime
import re
import os


def fetch_and_save_pages(api_url: str, operationName: str, query_template: str, startPage: int=0, pageSize: int=MAX_PAGE_SIZE, output_dir: str=OUTPUT_DIR, timeout: int=100, max_entries = None):
    """
    Runs the given query at the given API. Paginates automatically, starting from startPage, writing files to output_dir.
    # """
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


if __name__ == "__main__":

    pattern = re.compile(r'\bquery\s+(\w+)', re.IGNORECASE)

    text = ""

    all_words = pattern.findall(text)
    print(all_words)   # → ['first', 'second', 'third']


