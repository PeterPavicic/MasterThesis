import json
import asyncio
import websockets
import datetime
import pandas as pd

# tokens = [21742633143463906290569050155826241533067272736897614950488156847949938836455,
#               48331043336612883890938759509493159234755048973500640148014422747788308965732]



tokens = ["21742633143463906290569050155826241533067272736897614950488156847949938836455",
          "88027839609243624193415614179328679602612916497045596227438675518749602824929",
          "75551890681049796405776295654438099776333571510662809052054780589218524237663",
          "19083349462791593334532840548890602187185739923311385087650426802477691161360",
          "69236923620077691027083946871148646972011131466059644796654161903044970987404",
          "95128817762909535143571435260705470642391662537976312011260538371392879420759",
          "48285207411891694847413807268670593735244327770017422161322089036370055854362",
          "42699080635179861375280720242213672850141860123562672932351602811041149946128",
          "21271000291843361249209065706097167029083067325856089903026951915683588703117"]

async def getMarketData(asset_ids):
    url = "wss://ws-subscriptions-clob.polymarket.com/ws/market"
    last_time_pong = datetime.datetime.now()

    # msgs = []

    subcribe_message = {
            "assets_ids": asset_ids,
            "type": "market"
            # "channel": "market",
            }

    # {
    #         "assets_ids":[kamala_trump_yes_token, kamala_trump_no_token],
    #         "type":"market"
    #         }

    async with websockets.connect(url) as websocket:

        await websocket.send(json.dumps(subcribe_message))

        print(f"Subscribed to asset ids: {asset_ids}")

        while True:
            response = await websocket.recv()
            if response != "PONG":
                last_time_pong = datetime.datetime.now()

            parsed_answer = json.loads(response)
            event_type = parsed_answer[0]["event_type"]

            ltp = last_time_pong

            # Format the date and time as MMDD_HHMMSS
            formatted_date = ltp.strftime("%m%d_%H%M%S")
            
            n = len(parsed_answer)

            now = datetime.datetime.now()

            if now.month == 10:
                month = "oct"
            else:
                month = "nov"

            day = now.day
            hour = now.hour
            minute = now.minute
            date_path = f"{month}{day}/{hour:02}/{minute:02}"

            if event_type == "price_change":
                fileName = f"live_data/{event_type}/{date_path}/{formatted_date}.json"

                with open(fileName, 'w', encoding = "ascii") as file:
                    json.dump(parsed_answer, file, ensure_ascii=False, indent=4)

                print(f"Data exported to {fileName}")

            else:  # event_type = book
                for i in range(0, n - 1):  # for each market
                    market = parsed_answer[i]
                    market_name = market["market"]
                    timestamp = market["timestamp"]
                    asset_id = market["asset_id"]
                    event_type = market["event_type"]

                    if event_type == "last_trade_price":
                        fileName = f"live_data/{event_type}/{date_path}/last_trade_{timestamp}.json"
                        with open(fileName, 'w', encoding = "ascii") as file:
                            json.dump(market, file, ensure_ascii=False, indent=4)
                        print(f"Data exported to {fileName}")
                    elif event_type == "book":
                        # Process buys and sells data into DataFrames
                        hash_code = market["hash"]

                        asks_df = pd.DataFrame(market["asks"])
                        bids_df = pd.DataFrame(market["bids"])
                        asks_df["type"] = "ask"
                        bids_df["type"] = "bid"
                        combined_df = pd.concat([asks_df, bids_df], ignore_index=True)

                        fileName = f"live_data/{event_type}/{date_path}/{asset_id[0:10]}_{timestamp}.csv"
                        with open(fileName, "w") as file:
                            combined_df.to_csv(file, index=False)

                        with open(fileName, "a") as file:
                            toWrite = f"\nevent_type {event_type}\nhash_code {hash_code}\nmarket_name {market_name}\ntimestamp {timestamp}\nasset_id {asset_id}"
                            file.write(toWrite)
                        print(f"Data exported to {fileName}")
                                # print(parsed_answer)

            if last_time_pong + datetime.timedelta(seconds=10) < datetime.datetime.now():
                await websocket.send("PING")
            # else:
                # msgs.append(d)

asyncio.run(getMarketData(tokens))



# with open("json_files/text.json", 'w', encoding="utf-8") as file:
#     json.dump(response2, file, ensure_ascii=False, indent=4)
