#!./venv/bin/python

from pathlib import Path
from typing import Any
import glob
import json
import numpy
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
    """
    Input: raw json file for an event acquired from Gamma API

    Return: For each eventFilePath returns a dictionary formatted
    {
        groupItemTitle: {
            "slug": market's slug
            "Yes": yesAsset's TokenID,
            "No": noAsset's TokenID,
            "outcomeYes": yesAsset's outcome price (or market price if market not closed),
            "outcomeNo": noAsset's outcome price (or market price if market not closed)
        }
    }
    """

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
                marketSlug = market.get("slug")
                clobEntry = market.get("clobTokenIds")
                outcomePrices = market.get("outcomePrices")
                groupItemTitle = market.get("groupItemTitle")

                # HACK: Assets with no token IDs are skipped and not written to markets
                if clobEntry is None:
                    print(f"{marketSlug} skipped")
                    continue
                clobIDs = clobEntry[1:-1].split(", ")
                outcomePrices = clobEntry[1:-1].split(", ")
                yesAsset = clobIDs[0]
                noAsset = clobIDs[1]
                outcomeYes = outcomePrices[0]
                outcomeNo = outcomePrices[1]

                marketDict = {
                    groupItemTitle: {
                        "slug": marketSlug,
                        "Yes": yesAsset,
                        "No": noAsset,
                        "outcomeYes": outcomeYes,
                        "outcomeNo": outcomeNo
                    }
                }
                marketList.append(marketDict)

            resultDict["markets"] = marketList

        resultDicts.append(resultDict)

    if len(resultDicts) != 1:
        return resultDicts
    else:
        return resultDicts[0]



# TODO: Finish writing this
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


def get_token_table(eventFilePaths: str | Path | list[str] | list[Path]) -> list | list[list]:
    # Generates a table from all eventFilePaths' tokens to determine outcomePrices

    if not isinstance(eventFilePaths, list):
        eventFilePaths = [eventFilePaths]

    assert isinstance(eventFilePaths, list)
    resultDicts = []
    for event in eventFilePaths:
        with open(event, "r") as file:
            data = json.load(file)

            event_slug = data.get("slug")
            marketsData = data.get("markets")

        marketList = []
        for market in marketsData:
            slug = market.get("slug")
            volume = market.get("volume")
            conditionId = market.get("conditionId")
            clobEntry = market.get("clobTokenIds")
            outcomePricesEntry = market.get("outcomePrices")
            groupItemTitle = market.get("groupItemTitle")

            # HACK: Assets with no token IDs are skipped and not written to markets
            if clobEntry is None:
                print(f"{conditionId} skipped")
                continue

            clobIDs = clobEntry[1:-1].split(", ")
            outcomePrices = outcomePricesEntry[1:-1].split(", ")
            yesAsset = clobIDs[0]
            noAsset = clobIDs[1]
            outcomeYes = outcomePrices[0]
            outcomeNo = outcomePrices[1]

            marketDict = {
                "event_slug": event_slug,
                "slug": slug,
                "marketTitle": groupItemTitle,
                "volume": volume,
                "Condition": conditionId,
                "Yes": yesAsset,
                "No": noAsset,
                "outcomeYes": outcomeYes,
                "outcomeNo": outcomeNo
            }
            marketList.append(marketDict)

        resultDicts.append(marketList)

    if len(resultDicts) != 1:
        return resultDicts
    else:
        return resultDicts[0]


def json_files_to_one_csv(json_dir, out_csv):
    all_dfs = []

    for path in glob.glob(os.path.join(json_dir, '*.json')):
        print(f"Processing {path}")
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


if __name__ == "__main__":

    # presidentialEvent = "/home/peter/WU_OneDrive/QFin/MT Master Thesis/Data Markets/Presidential_win_market.json"
    # presidentialEvent = "/home/peter/WU_OneDrive/QFin/MT Master Thesis/Data Markets/simplified_Presidential_win_market.json"

    # tokenLists = get_token_table(presidentialEvent)
    #
    # with open(os.path.join(ROOT_DIR, "Markets", "ElectionTokens", "ElectionTokens.json"), 'w') as file:
    #     json.dump(tokenLists, file, indent = 2)
    #
    #
    # json_files_to_one_csv("/home/peter/WU_OneDrive/QFin/MT Master Thesis/Markets/ElectionTokens/", os.path.join(ROOT_DIR, "Markets", "Election Tokens.csv"))


    jsons_dir = os.path.join(ROOT_DIR, "Data Markets", "FOMC Events")

    fileNames = [f for f in os.listdir(jsons_dir)]
    json_files = [os.path.join(jsons_dir, f) for f in os.listdir(jsons_dir)]

    tokenLists = get_token_table(json_files)

    target_dir = os.path.join(ROOT_DIR, "Markets", "FOMC Tokens")

    for i, eventList in enumerate(tokenLists):
        output_path = os.path.join(target_dir, fileNames[i])

        with open(output_path, 'w') as file:
            json.dump(eventList, file, indent=2)
            print(f"{fileNames[i]} simplified and written to {output_path}")

            print("Done")

    json_files_to_one_csv(target_dir, os.path.join(ROOT_DIR, "Markets", "FOMC Tokens.csv"))


