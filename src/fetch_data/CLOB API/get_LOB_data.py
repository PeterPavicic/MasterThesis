import requests
import json
import os


# Replace with your actual Polymarket API key
API_KEY = os.getenv("POLYGON_API_KEY")


# Market ID for which historical CLOB data is to be fetched
MARKET_ID = "21742633143463906290569050155826241533067272736897614950488156847949938836455"

# Base URL for the Polymarket API
BASE_URL = "https://api.polymarket.com/v1/"

# Endpoint for historical CLOB data
CLOB_ENDPOINT = f"markets/{MARKET_ID}/orderbook"

# Headers for authentication and content type
headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

def get_clob_data():
    """Fetches historical CLOB data for a specified market."""
    try:
        url = f"{BASE_URL}{CLOB_ENDPOINT}"
        response = requests.get(url, headers=headers)

        # Check if the request was successful
        if response.status_code == 200:
            clob_data = response.json()
            print("Successfully fetched CLOB data.")
            return clob_data
        else:
            print(f"Failed to fetch CLOB data: {response.status_code} {response.text}")
            return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

if __name__ == "__main__":
    clob_data = get_clob_data()

    # Save the data to a JSON file for later analysis
    if clob_data:
        with open("clob_data.json", "w") as file:
            json.dump(clob_data, file, indent=4)
            print("CLOB data saved to clob_data.json")
