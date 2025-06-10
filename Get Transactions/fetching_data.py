#!./venv/bin/python
import csv
import json
from pathlib import Path
from queries import *

# asd = Subquery(SQ.NegRiskConversion, 'maker: "0xasjkdnkansjkdj"', 0)
# Query("asdasd", SG.OPEN_INTEREST_SG, asd)
#
# a = Subquery(SQ.OrdersFilled, 'maker: "lkasdka"', 200)
# Query("asdasd", SG.ORDERS_SG, [asd, a])


def jsons_to_csv(input_dir, output_csv_path):
    fieldnames = [
        "transactionHash",
        "orderHash",
        "timestamp",
        "makerAssetId",
        "takerAssetId",
        "maker",
        "taker",
        "makerAmountFilled",
        "takerAmountFilled",
        "fee"
    ]

    with open(output_csv_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        # Loop through all .json files in the directory
        for json_path in Path(input_dir).glob("*.json"):
            print(f"Processing file: {json_path.name}")
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            records = data if isinstance(data, list) else [data]

            for rec in records:
                # Build a flat row dict
                row = {}
                for key in fieldnames:
                    if key in ("maker", "taker"):
                        nested = rec.get(key, {})
                        row[key] = nested.get("id") if isinstance(nested, dict) else None
                    else:
                        row[key] = rec.get(key)
                writer.writerow(row)

    print(f"All done! Combined CSV written to: {output_csv_path}")



if __name__ == "__main__":
    # jsons_to_csv(input_dir="./Data Transactions/TrumpElectionMaker/", 
    #              output_csv_path="./Transactions/TrumpElection_maker.csv")
    # jsons_to_csv(input_dir="./Data Transactions/TrumpElectionTaker/", 
    #              output_csv_path="./Transactions/TrumpElection_taker.csv")
    pass
