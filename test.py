import pandas as pd
import json

# Sample data (replace with actual JSON data)
data = {
    "event_type": "book",
    "asset_id": "65818619657568813473441868652308942079804919287380422192892211131408793125422",
    "market": "0xbd31dc8a20211944f6b70f31557f1001557b59905b7738480ca99bd4532f84af",
    "buys": [
        {"price": ".48", "size": "30"},
        {"price": ".49", "size": "20"},
        {"price": ".50", "size": "15"}
    ],
    "sells": [
        {"price": ".52", "size": "25"},
        {"price": ".53", "size": "60"},
        {"price": ".54", "size": "10"}
    ],
    "timestamp": "123456789000",
    "hash": "0x0...."
}

# Process buys and sells data into DataFrames
buys_df = pd.DataFrame(data["buys"])
sells_df = pd.DataFrame(data["sells"])

# Add a column to identify the type of entry (buy or sell)
buys_df["type"] = "buy"
sells_df["type"] = "sell"

# Concatenate the buys and sells data
combined_df = pd.concat([buys_df, sells_df], ignore_index=True)

# Export to CSV
combined_df.to_csv("test.csv", index=False)

print("Data exported to market_data.csv")
