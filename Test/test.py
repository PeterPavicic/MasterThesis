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
    yesAsset = "\"100647932394524753511024372351439090270565953451319138975996721541418061568325\""
    noAsset = "\"78809347143547697320307181120608030232127524836798973473083856775752906357974\""

    asd = [yesAsset, noAsset]

    whereFilter = f"""
        token_in: [
        {{ {"},\n{".join(asd)} }}
        ]
    """

    print(whereFilter)

    # for i in range(10):
    #     if i % 2 == 0:
    #         continue
    #     else:
    #         print(i)
    # pass
