#!./venv/bin/python

from datetime import datetime
from pathlib import Path
import glob
import json
import numpy
import os
import pandas as pd
import requests



if __name__ == "__main__":
    here = Path(__file__)
    slug_file = os.path.join(here.parent.parent, "Markets/all_fomc_slugs.txt")
    print(slug_file)
    slugs = []
    with open(slug_file, 'r') as file:
        for line in file:
            slugs.append(line[:-1])
    print(slugs)
    pass

