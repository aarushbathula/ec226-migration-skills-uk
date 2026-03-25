# EC226 - Migration, Skills, and the UK Labour Market

This repository is a replication package for an applied econometrics project studying how migrant background, English-language exposure, and country-of-birth characteristics relate to occupational skill outcomes in the UK labour market.

## How to Replicate

- Software: Stata 18
- Command: `do code/master.do`
- Input data: place raw files in `data/raw/`
- Outputs: tables, figures, and logs are written to `output/`

Run the project from the repository root in Stata:

```stata
do code/master.do
```

## Project Overview

The workflow combines UK Census microdata with external country-level covariates and estimates descriptive, ordered-response, multinomial, and second-stage models.

Core inputs include:

- UK 2021 Census microdata
- World Bank GDP per capita
- World Bank tertiary education expenditure
- CEPII migration distance data
- country-code crosswalk files
- constructed cohort and migration-history variables

## Data and Paper Assets

- `data/`: local-only raw, intermediate, and final datasets
- `paper/`: manuscript files, Overleaf sources, and placeholders
- Place raw inputs under `data/raw/`
- Let intermediate files be written to `data/interim/`
- Let final analysis files be written to `data/final/`

The `.gitignore` preserves the directory structure in Git while keeping local data contents untracked.

## Software and Dependencies

- Stata 18
- User-written Stata packages: `estout`, `outreg2`
- The code resolves paths relative to the repository rather than a machine-specific home directory
- Archived scripts under `code/archive/` are retained for reference, but the active pipeline is the top-level one

## Outputs

Expected generated outputs include:

- `output/tables/*.tex`
- `output/figures/*.png`
- `output/logs/*.log`

## PROJECT_STATUS

- Replication workflow: ready
- Data availability: local-only
- Paper assets: included
- Known gaps: full replication depends on access to the underlying census inputs and installed user-written Stata packages

## Limitations

- The raw source files used to build the dataset are not distributed through this repository
- Full replication depends on local access to census and country-level inputs
- The Stata environment must include the required user-written packages for all table exports and analysis steps to run
