#!./venv/bin/python

from pathlib import Path
import json
import pandas as pd
import glob
import os

def json_files_to_one_csv(json_dir, out_csv):
    all_dfs = []

    for path in glob.glob(os.path.join(json_dir, '*.json')):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        # ensure list of records
        records = data if isinstance(data, list) else [data]
        # flatten
        df = pd.json_normalize(records, sep='_')
        # explode any list columns
        list_cols = [c for c in df.columns if df[c].apply(lambda x: isinstance(x, list)).any()]
        for col in list_cols:
            df = df.explode(col)
        all_dfs.append(df)

    # concatenate all, reset index
    master = pd.concat(all_dfs, ignore_index=True)
    master.to_csv(out_csv, index=False)
    print(f"Wrote {len(master)} total rows to {out_csv}")

if __name__ == "__main__":
    # usage
    # json_files_to_one_csv('path/to/json_folder', 'combined.csv')
    asd = os.path.join("../Data Transactions/", "findMatchedOrders", f"{12323}.json")
    print(asd)
    print(Path(asd).parent)
    b = os.path.abspath(".")
    print(b)
    asd = {23: 123}
    print(type(asd))
    print((asd).keys())
    print(str(asd))

