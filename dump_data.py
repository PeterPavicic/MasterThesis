# import csv
import json
import requests
import re
import asyncio
import websockets
import datetime


# sources
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF#scrollTo=9I_zd74ix6Bo


# Queries
other_query = "https://gamma-api.polymarket.com/events?closed=false&tag=politics&limit=100"
popular_vote_query = "https://gamma-api.polymarket.com/markets?id=253706&id=253727"
election_query = "https://gamma-api.polymarket.com/events/903193"

# Getting response
r = requests.get(election_query)
response = r.json()

# Writing full reponse
with open("events_markets/full_response.json", 'w', encoding="utf-8") as file:
    json.dump(response, file, ensure_ascii=False, indent=4)


markets = response["markets"]

# Writing markets
with open("events_markets/raw_election_markets.json", 'w', encoding="utf-8") as file:
    json.dump(markets, file, ensure_ascii=False, indent=4)


relevant_data = []
for market in markets:

    # Parsing prices and ids
    prices = market["outcomePrices"]
    pricesString = re.findall(r'"(\d+\.\d+)"', prices)
    yesPrice = float(pricesString[0])
    noPrice = float(pricesString[1])

    clobTokenIds = market["clobTokenIds"]
    idsString = re.findall(r'"(\d+)"', clobTokenIds)
    yesId = int(idsString[0])
    noId = int(idsString[1])

    data = {
            "id": market["id"],
            "question": market["question"],
            "volume": market["volumeNum"],
            "volume24hrClob": market["volume24hrClob"],
            "volume24hr": market["volume24hr"],
            "liquidity": market["liquidityNum"],
            "liquidityClob": market["liquidityClob"],
            "yesPrice": yesPrice,
            "noPrice": noPrice,
            "yesId": yesId,
            "noId": noId,
            "competitive": market["competitive"],
            "spread": market["spread"]
            }
    relevant_data.append(data)

# Dumping relevant market data
with open("events_markets/election_markets.json", 'w', encoding="utf-8") as file:
    json.dump(relevant_data, file, ensure_ascii=False, indent=4)
