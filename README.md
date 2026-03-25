# EC226: Migration, Skills, and the UK Labour Market

Aarush Bathula · University of Warwick · 2025

This repository is a replication package for an applied econometrics project studying how migrant background, English-language exposure, and country-of-birth characteristics relate to occupational skill outcomes in the UK labour market. The workflow combines UK Census microdata with external country-level covariates and estimates descriptive, ordered-response, multinomial, and second-stage models.

## What Lives Here

- `code/`: Stata scripts for data construction, analysis, and figures/tables
- `data/`: local-only raw, intermediate, and final datasets
- `output/`: generated tables, figures, and logs
- `paper/`: manuscript files, Overleaf sources, and placeholders

## Research Overview

The project examines how origin-country characteristics such as GDP per capita, migration distance, tertiary education expenditure, colonial ties, and English-language prevalence predict migrants' employment skill level in the UK.

Core inputs include:

- UK 2021 Census microdata
- World Bank GDP per capita
- World Bank tertiary education expenditure
- CEPII migration distance data
- country-code crosswalk files
- constructed cohort and migration-history variables

## How To Run

Run the project from the repository root with Stata 18:

```stata
do code/master.do
```

The master script detects the repository root from either the root directory or the `code/` folder, so no personal machine path is required.

## Pipeline

1. `code/01_data_build.do`
2. `code/02_analysis.do`

The first script builds the analysis dataset and the second script produces descriptive tables, margins, regressions, and figures.

## Data Availability

The repository does not include the raw source files used to build the dataset.

- Place raw inputs under `data/raw/`
- Let intermediate files be written to `data/interim/`
- Let final analysis files be written to `data/final/`

The `.gitignore` preserves the directory structure in Git while keeping local data contents untracked.

## Main Outputs

Expected generated outputs include:

- `output/tables/*.tex`
- `output/figures/*.png`
- `output/logs/*.log`

These files are reproducible from the scripts and are intentionally excluded from version control.

## Reproducibility Notes

- The scripts are written for Stata 18
- Required user-written commands include `estout` and `outreg2`
- The code resolves paths relative to the repository rather than a machine-specific home directory
- Archived scripts under `code/archive/` are retained for reference, but the active pipeline is the top-level one
