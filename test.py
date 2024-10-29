import json
import requests
r = requests.get("https://gamma-api.polymarket.com/events?closed=true")
response = r.json()

with open("json_files/test_response.json", 'w', encoding="utf-8") as file:
    json.dump(response, file, ensure_ascii=False, indent=4)

