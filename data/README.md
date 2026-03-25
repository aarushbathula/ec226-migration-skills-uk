# Data Layout

This directory is intentionally kept mostly out of Git. Only the placeholder files are tracked so the repository keeps its structure.

## Expected Local Inputs

Place source data under `data/raw/`. The current pipeline expects files such as:

- `gdp_per_capita_2021.dta`
- `2021.dta`
- `dist_cepii.dta`
- `API_SE.XPD.TERT.PC.ZS_DS2_en_csv_v2_27784.csv`

## Generated Files

The scripts write intermediate and final datasets to:

- `data/interim/`
- `data/final/`

One expected output is:

- `data/final/finaldataset.dta`

These files are local-only and excluded from version control.
