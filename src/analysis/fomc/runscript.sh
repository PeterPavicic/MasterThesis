#!/bin/bash

Rscript wrapper_FOMC_pooled_missing.R && git add . && git commit -m "calculated pooled robustness check results" && git push
