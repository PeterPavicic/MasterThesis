import csv
import requests
import json
from urllib3.util.util import to_str

# sources
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF
# https://colab.research.google.com/drive/13mGFq_BqskRUxxIZoimomaD_6cKFfWnF#scrollTo=9I_zd74ix6Bo


r = requests.get("https://gamma-api.polymarket.com/events?closed=false")
response = r.json()

# with open("text.txt", 'w') as file:
#   file.write(response)
# print(response)

relevant_events = {}
for event in response:
  condition1 = False # 'Kamala' in event['title']
  condition2 = 'Trump' in event['title']
  condition3 =  False # 'President' in event['title']
  if condition1 or condition2 or condition3:
    print(type(event))
    with open('data.json', 'w', encoding='utf-8') as file:
      json.dump(event, file, ensure_ascii=False, indent=4)
    print(event)
    # relevant_events[event['id']] = event
