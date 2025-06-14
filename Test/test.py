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
    # This is how to parse the clobTokenIds entries

    a = "Teststring"

    asd = {
        a: "bla bla"
    }

    print(asd)
    print(asd.get("Teststring"))
    for k, v in asd.items():
        print(f"Key: {k}\nValue: {v}\n")

    pass
