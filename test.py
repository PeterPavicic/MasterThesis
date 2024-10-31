# import pandas as pd
# import json
#
# # Sample data (replace with actual JSON data)
# # for price changes
#
#
#
# data1 = [
#         {
#             "asks": [
#                 {
#                     "price": "0.999",
#                     "size": "22148384.66"
#                     },
#                 {
#                     "price": "0.65",
#                     "size": "36212.45"
#                     },
#                 {
#                     "price": "0.649",
#                     "size": "21763.7"
#                     },
#                 {
#                     "price": "0.616",
#                     "size": "21558.7"
#                     }
#                 ],
#             "asset_id": "21742633143463906290569050155826241533067272736897614950488156847949938836455",
#             "bids": [
#                 {
#                     "price": "0.001",
#                     "size": "10146620.2"
#                     },
#                 {
#                     "price": "0.647",
#                     "size": "44980.14"
#                     },
#                 {
#                     "price": "0.648",
#                     "size": "33672.16"
#                     }
#                 ],
#             "event_type": "book",
#             "hash": "7ac1d96b5f392b84b372f48228124c1bd67cbae3",
#             "market": "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917",
#             "timestamp": "1730371451593"
#             },
#         {
#             "asks": [
#                 {
#                     "price": "0.999",
#                     "size": "10146620.2"
#                     },
#                 {
#                     "price": "0.353",
#                     "size": "44980.14"
#                     },
#                 {
#                     "price": "0.352",
#                     "size": "33672.16"
#                     }
#                 ],
#             "asset_id": "48331043336612883890938759509493159234755048973500640148014422747788308965732",
#             "bids": [
#                 {
#                     "price": "0.001",
#                     "size": "22148384.66"
#                     },
#                 {
#                     "price": "0.345",
#                     "size": "67760.28"
#                     }
#                 ],
#             "event_type": "book",
#             "hash": "2bc0890f957bda1f018617da8bb4de0f8367799e",
#             "market": "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917",
#             "timestamp": "1730371451593"
#             },
#         {"asset_id": "21742633143463906290569050155826241533067272736897614950488156847949938836455",
#             "event_type": "last_trade_price",
#             "fee_rate_bps": "0",
#             "market": "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917",
#             "price": "0.648",
#             "side": "SELL",
#             "size": "27.79",
#             "timestamp": "1730371451633"
#             }
# ]
#
#
# data2 = [
#     {
#         "asset_id": "48331043336612883890938759509493159234755048973500640148014422747788308965732",
#         "changes": [
#             {
#                 "price": "0.352",
#                 "side": "SELL",
#                 "size": "27561.29"
#             }
#         ],
#         "event_type": "price_change",
#         "hash": "165a1f056cacb014e81c649cffe2e3a92e3e8e65",
#         "market": "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917",
#         "timestamp": "1730371450503"
#     },
#     {
#         "asset_id": "21742633143463906290569050155826241533067272736897614950488156847949938836455",
#         "changes": [
#             {
#                 "price": "0.648",
#                 "side": "BUY",
#                 "size": "27561.29"
#             }
#         ],
#         "event_type": "price_change",
#         "hash": "7ea562e42bddd4e87346341e56888d293618548e",
#         "market": "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917",
#         "timestamp": "1730371450503"
#     }
# ]
#
#
# data = data1
#
# for market in data:
#     event_type = market["event_type"]
#     hash_code = market["hash"]
#     market_name = market["market"]
#     timestamp = market["timestamp"]
#     asset_id = market["asset_id"]
#
#     if event_type == "book":
#         # Process buys and sells data into DataFrames
#         asks_df = pd.DataFrame(data["asks"])
#         bids_df = pd.DataFrame(data["bids"])
#         asks_df["type"] = "ask"
#         bids_df["type"] = "bid"
#         combined_df = pd.concat([asks_df, bids_df], ignore_index=True)
#         filename = f"{asset_id[0:10]}_{timestamp}.csv"
#         combined_df.to_csv(filename, index=False)
#         with open(filename, "a") as file:
#             file.write(f"\nevent_type {event_type}\nhash_code {hash_code}\nmarket_name {market_name}\ntimestamp {timestamp}\nasset_id {asset_id}")
#
#
# print("Data exported to test.csv")
#
#

import os
import datetime

now = datetime.datetime.now()


if now.month == 10:
    month = "oct"
else:
    month = "nov"

day = now.day
hour = now.hour
minute = now.minute
print(f"{month}{day}/{hour:02}/{minute:02}")

