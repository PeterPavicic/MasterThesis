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
    for i in range(10):
        if i % 2 == 0:
            continue
        else:
            print(i)
    pass
