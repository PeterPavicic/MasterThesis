import json
import asyncio
import websockets
import datetime

# tokens = [21742633143463906290569050155826241533067272736897614950488156847949938836455,
#               48331043336612883890938759509493159234755048973500640148014422747788308965732]

tokens = ["21742633143463906290569050155826241533067272736897614950488156847949938836455",
          "48331043336612883890938759509493159234755048973500640148014422747788308965732"]

async def getMarketData(asset_ids):
    url = 'wss://ws-subscriptions-clob.polymarket.com/ws/market'
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
            
            with open("lob_data/live_data_30_10.json", 'w', encoding = "ascii") as file:
                json.dump(parsed_answer, file, ensure_ascii=False, indent=4)

            # print(parsed_answer)

            if last_time_pong + datetime.timedelta(minutes=5) < datetime.datetime.now():
                await websocket.send("PING")
            # else:
                # msgs.append(d)

asyncio.run(getMarketData(tokens))



# with open("json_files/text.json", 'w', encoding="utf-8") as file:
#     json.dump(response2, file, ensure_ascii=False, indent=4)
