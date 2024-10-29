# import csv
import requests
import json
import os
# from urllib3.util.util import to_str

# sources
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF#scrollTo=9I_zd74ix6Bo


# r = requests.get("https://gamma-api.polymarket.com/events?closed=false&tag=politics&limit=100")
r = requests.get("https://gamma-api.polymarket.com/events?id=903193")
response = r.json()

with open("json_files/full_response.json", 'w', encoding="utf-8") as file:
    json.dump(response, file, ensure_ascii=False, indent=4)

if os.path.exists("json_files/event_titles.json"):
    os.remove("json_files/event_titles.json")

relevant_events = {}
for event in response:
    title = event["title"]
    print(title)

    with open("json_files/event_titles.json", 'a', encoding="utf-8") as file:
        json.dump(title, file, ensure_ascii=False, indent=4)

    condition1 = "Kamala" in title
    condition2 = "Trump" in title
    condition3 = "President" in title
    if condition1 or condition2 or condition3:
        with open("json_files/relevant_events.json", 'a', encoding="utf-8") as file:
            json.dump(event, file, ensure_ascii=False, indent=4)
    # print(event)
    # relevant_events[event['id']] = event
    # 903193



# r = requests.get("https://gamma-api.polymarket.com/events?id=903193")
# response = r.json()
#
# relevant_markets = response["markets"]
#
# for market in relevant_markets:
#   if 'outcomePrices' in market and 'clobTokenIds' in market:
#     print(market['id'], market['question'], 'outcomePrices' in market and market['outcomePrices'])
#     print('clobTokenIds' in market and market['clobTokenIds'])
#     print('=====')

# r2 = requests.get("wss://ws-subscriptions-clob.polymarket.com/ws/market")
# response2 = r2.json()
# with open("json_files/text.json", 'w', encoding="utf-8") as file:
#     json.dump(response2, file, ensure_ascii=False, indent=4)
