import json

# Load the JSON data
with open("get_presidential_markets.py", "r") as file:
    data = json.load(file)

# Extract relevant information
result = {}
for market in data.get("markets", []):
    group_item_title = market.get("groupItemTitle")
    clob_token_ids = market.get("clobTokenIds", "[]")
    # Convert clobTokenIds string to list and get the first token ID
    clob_token_ids_list = json.loads(clob_token_ids)
    if group_item_title and clob_token_ids_list:
        result[group_item_title] = clob_token_ids_list[0]

# Output the result
print(result)
