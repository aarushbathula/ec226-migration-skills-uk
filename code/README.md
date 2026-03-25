# Code Layout

This folder contains the runnable Stata pipeline for the EC226 project.

## Scripts

- `master.do`: entry point that resolves the project root and runs the full pipeline
- `01_data_build.do`: merges source files, constructs the final dataset, and saves `data/final/finaldataset.dta`
- `02_analysis.do`: produces tables, margins, regressions, and figures from the final dataset
- `archive/EC226Finalisedv2.do`: archival version kept for reference

## Conventions

- Run scripts from the repository root or from within `code/`
- Do not edit the hard-coded local data files into the repository
- Intermediate and output files should be regenerated locally, not committed
