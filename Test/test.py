#!./venv/bin/python

from datetime import datetime
from pathlib import Path
import glob
import json
import numpy
import os
import pandas as pd
import requests

FILE_LOCATION = Path(__file__)
ROOT_DIR = FILE_LOCATION.parent.parent


if __name__ == "__main__":

    tokenCSV = os.path.join(ROOT_DIR, "Analysis", "FOMC analysis", "FOMC Tokens.csv")
    with open(tokenCSV, 'r') as file:
        df = pd.read_csv(file)

    print(df)
    conds = df["Condition"]


    print("Now converted to list:")
    print(list[conds])
    print(type(conds))
    print(type(list(conds)))
    for entry in list(conds):
        print(entry)
        print(type(entry))


