import requests
import json

# Constants for subgraphs
ORDERS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/polymarket-orderbook-resync/prod/gn"
POSITIONS_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/positions-subgraph/0.0.7/gn"
ACTIVITY_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/activity-subgraph/0.0.4/gn"
OPEN_INTEREST_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/oi-subgraph/0.0.6/gn"
PNL_SG = "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/pnl-subgraph/0.0.14/gn"


def run_graphql_query(query: str, operation_name: str, subGraph: str, timeout: int = 10): 
    """
    Sends a GraphQL query to the specified endpoint and returns the JSON response.
    Includes handling for common API errors.
    """
    url = subGraph
    payload = {
        "query": query,
        "operationName": operation_name
    }
    
    try:
        # Send the POST request with a timeout
        response = requests.post(url, json=payload, timeout=timeout)
        # Raise HTTPError if the response status code indicates an error (e.g., 4xx, 5xx)
        response.raise_for_status()
    except requests.exceptions.Timeout:
        print("Request timed out. Increase the timeout value or check your network connection.")
        return None
    except requests.exceptions.ConnectionError:
        print("Connection error occurred. Please check your network connectivity.")
        return None
    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")
        return None
    except requests.exceptions.RequestException as req_err:
        print(f"A network-related error occurred: {req_err}")
        return None

    try:
        # Attempt to parse the response as JSON.
        result = response.json()
    except json.decoder.JSONDecodeError:
        print("Error decoding JSON. The response may not be valid JSON.")
        return None
    
    # Check if the GraphQL response includes any errors.
    if "errors" in result:
        print("GraphQL errors encountered:")
        for error in result["errors"]:
            print(f" - {error.get('message')}")
        # You might wish to return None or the errors for further handling.
        return None
    
    return result

# Example GraphQL query: get the first 100 orderFilledEvents
query = """
query GetOrderFills {
  orderFilledEvents(
    first: 100,
    orderBy: timestamp,
    orderDirection: asc,
    where: {
      makerAssetId_in: [
        "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "48331043336612883890938759509493159234755048973500640148014422747788308965732"
      ],
      takerAssetId_in: [
        "21742633143463906290569050155826241533067272736897614950488156847949938836455",
        "48331043336612883890938759509493159234755048973500640148014422747788308965732"
      ]
    }
  ) {
    id
    timestamp
    maker
    taker
    makerAmountFilled
    takerAmountFilled
    transactionHash
  }
}
"""

operation_name = "GetOrderFills"

# Run the query and handle common errors
result = run_graphql_query(query, operation_name, "https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/orderbook-subgraph/prod/gn")
if result:
    try:
        events = result["data"]["orderFilledEvents"]
        print(f"Retrieved {len(events)} orderFilledEvents:")
        for event in events:
            print(event)
    except KeyError as key_err:
        print(f"Unexpected response structure, missing key: {key_err}")
else:
    print("No valid data returned.")
