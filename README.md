# EC226 – Applied Econometrics Assignment

Aarush Bathula · University of Warwick · 2025

This repository contains a fully reproducible workflow for the EC226 Econometrics Project analysing how migrants’ countries of origin relate to skill-level outcomes in the UK labour market. The project merges UK 2021 Census microdata with external country-level datasets and implements ordered-probit, multinomial logit, and two-stage OLS models.


## Repository Structure
```
ec226-migration-skills-uk/
│
├── code/
│   ├── 01_data_build.do        # Complete data construction pipeline
│   ├── 02_analysis.do          # All econometric models (Tables, margins, plots)
│   ├── master.do               # Orchestration script: build → analysis
│   └── archive/                # Previous script versions (not executed)
│
├── data/
│   ├── raw/                    # Census & World Bank raw files (.gitkept)
│   ├── interim/                # Cleaned intermediate datasets
│   └── final/                  # Final analysis dataset (not tracked)
│
├── output/
│   ├── tables/                 # LaTeX tables
│   ├── figures/                # Exported graphs
│   └── logs/                   # Stata logs for reproducibility
│
├── paper/
│   └── main.pdf / main.tex     # Final write-up (not included in repo)
│
└── README.md
```
Empty folders are versioned using .gitkeep files to preserve structure.

## 1. Overview of Research

Objective

To quantify how origin-country characteristics such as GDP per capita, migration distance, tertiary education expenditure, colonial ties, and English language prevalence predict migrants’ employment skill-level in the UK.

Data Sources:
- UK 2021 Census Microdata
- World Bank GDP per capita (NY.GDP.PCAP.CD)
- World Bank Tertiary Education Expenditure (SE.XPD.TERT.PC.ZS)
- CEPII Migration Distance Data
- Custom-built country-to-code crosswalk
- Derived variables: time spent in UK, UK- vs foreign-born cohort, pre/post Brexit cohort, skill categories.

## 2. Reproducibility

Step 1. Clone the repository
```
git clone git@github.com:aarushbathula/ec226-migration-skills-uk.git
cd ec226-migration-skills-uk
```
Step 2. Place raw data files into:

```data/raw/```

Names must match those referenced inside `01_data_build.do`.

Step 3. Build the dataset

Open Stata and run:

```do code/master.do```

This executes:
	1.	`01_data_build.do` → Imports + merges + cleans all data
	2.	`02_analysis.do` → Runs all models, margins, figures, tables
	3.	Exports results into output/
	
## 3. Main Outputs

Tables
	•	Skill distribution by origin-country
	•	Base ordered-probit model
	•	Marginal effects (skill probabilities)
	•	Second-stage OLS regressions (GDP, distance, tertiary education, colonial history)
	•	Multinomial logit robustness

Figures
	•	Predicted probabilities vs. GDP
	•	vs. Migration Distance
	•	vs. Tertiary expenditure
	•	Country-level probability scatterplots

## 4. Reproducibility Notes
	•	No datasets or confidential Census microdata are included in this repository.
	•	Scripts assume Stata 17+.
	•	All paths are defined relative to $PROJROOT at the top of 01_data_build.do.


