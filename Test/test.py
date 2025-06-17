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
    asd = ["a", 'b', 'c', 'd', 'e']

    for i, letter in enumerate(asd):
        print(f"{i}th letter is: {letter}")

