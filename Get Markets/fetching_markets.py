from pathlib import Path
from typing import Any
import json
import os
import pandas as pd
import requests

FILE_LOCATION = Path(__file__)
ROOT_DIR = FILE_LOCATION.parent.parent

def download_json(url, output_file):
    """
    Downloads a JSON file from the given URL and saves it to the specified output file.

    Args:
        url (str): The URL to fetch the JSON data from.
        output_file (str): The path to the output file where JSON will be saved.
    """
    try:
        # Send a GET request to the URL
        response = requests.get(url)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx and 5xx)

        # Ensure the directory exists
        os.makedirs(os.path.dirname(output_file), exist_ok=True)

        # Write the JSON data to the file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(response.text)

        print(f"JSON data has been saved to {output_file}")

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from {url}: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


def fetch_events(eventQuery: dict[str, str] | list[dict[str, str]], output_dir: str | Path) -> None:
    """
    Downloads full event informations from Polymarket's Gamma API
    `eventQuery` contains a dictionary or list of dictionaries of the query parameters for each event queried
    """
    if isinstance(eventQuery, dict):
        eventQuery = [eventQuery]

    gammaURL = "https://gamma-api.polymarket.com/events"

    # Create output dir
    os.makedirs(output_dir, exist_ok=True)
    print(f"Output directory created: {output_dir}")

    for queryDict in eventQuery:
        try:
            response = requests.request("GET", gammaURL, params=queryDict)
            # print(response.text)
            data = response.json()[0]
            output_path = os.path.join(output_dir, f"{data.get("ticker")}.json")

            with open(output_path, "w") as file:
                json.dump(data, file, indent=2)
            print(f"Saved {data.get("title")} events to {output_path}")

        except requests.RequestException as e:
            print(f"Network/HTTP error: {e}")
            break

        except json.JSONDecodeError:
            print(f"Failed to parse JSON response.")
            break

        except Exception as e:
            print(f"An error occurred: {e}")
            break

    print(f"Saved all queries to {output_dir}")


def simplifyEvents(eventFilePaths: str | Path | list[str] | list[Path]) -> dict | list[dict]:
    # TODO: Add description

    if not isinstance(eventFilePaths, list):
        eventFilePaths = [eventFilePaths]

    assert isinstance(eventFilePaths, list)
    resultDicts = []
    for event in eventFilePaths:
        with open(event, "r") as file:
            data = json.load(file)
            resultDict = {}

            resultDict["title"] = data.get("title")
            resultDict["slug"] = data.get("slug")
            resultDict["startDate"] = data.get("startDate")
            resultDict["endDate"] = data.get("endDate")

            # print(resultDict)

            marketsData = data.get("markets")
            marketList = []
            for market in marketsData:
                marketQ = market.get("question")
                clobEntry = market.get("clobTokenIds")

                # HACK: Assets with no token IDs are skipped and not written to markets
                if clobEntry is None:
                    print(f"{marketQ} skipped")
                    continue
                clobIDs = clobEntry[1:-1].split(", ")
                yesAsset = clobIDs[0]
                noAsset = clobIDs[1]

                marketDict = {
                    marketQ: {
                        "Yes": yesAsset,
                        "No": noAsset
                    }
                }
                marketList.append(marketDict)

            resultDict["markets"] = marketList

        resultDicts.append(resultDict)

    if len(resultDicts) != 1:
        return resultDicts
    else:
        return resultDicts[0]


def fetch_user_Activity(activityQuery: dict[str, Any] | list[dict[str, Any]], output_dir: str | Path) -> None:
    """
    Downloads full userActivity informations from Polymarket's Gamma API
    `activityQuery` contains a dictionary or list of dictionaries of the query parameters for each event queried
    """
    if isinstance(activityQuery, dict):
        activityQuery = [activityQuery]

    gammaURL = "https://data-api.polymarket.com/activity"

    # Create output dir
    os.makedirs(output_dir, exist_ok=True)
    print(f"Output directory created: {output_dir}")

    for queryDict in activityQuery:
        while True:
            if "limit" not in queryDict.keys():
                queryDict["limit"] = 500
            if "offset" not in queryDict.keys():
                queryDict["offset"] = 0
            # TODO: Finish writing this
            try:
                response = requests.request("GET", gammaURL, params=queryDict)
                # print(response.text)
                response.raise_for_status()
                data = response.json()
                output_path = os.path.join(output_dir, f"{data[0].get("proxyWallet")}.json")

                with open(output_path, "w") as file:
                    json.dump(data, file, indent=2)
                print(f"Saved {data.get("title")} events to {output_path}")

                # Pagination
                if len(data) < queryDict["limit"]:
                    break
                else:
                    queryDict["offset"] += queryDict["limit"]

            except requests.RequestException as e:
                print(f"Network/HTTP error: {e}")
                break

            except json.JSONDecodeError:
                print(f"Failed to parse JSON response.")
                break

            except Exception as e:
                print(f"An error occurred: {e}")
                break

    print(f"Saved all queries to {output_dir}")


if __name__ == "__main__":
    json_file = os.path.join(ROOT_DIR, "Transactions", "myActivity.json")
    csv_file = os.path.join(ROOT_DIR, "Transactions", "myActivity.csv")
    # print(data)
    # print(type(data))
    # print(len(data))
    print(json_file)
    # df = pd.json_normalize(pd.read_json(json_file))
    df = pd.read_json(json_file) 

    # Ensure the output directory exists
    output_dir = os.path.dirname(csv_file)
    os.makedirs(output_dir, exist_ok=True)

    # Write DataFrame to CSV
    df.to_csv(csv_file, index=False)


