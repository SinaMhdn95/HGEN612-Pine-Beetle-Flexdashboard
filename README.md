# Pine Beetle Modeling Flexdashboard

[![R checks](https://github.com/SinaMhdn95/HGEN612-Pine-Beetle-Flexdashboard/actions/workflows/r-check.yml/badge.svg)](https://github.com/SinaMhdn95/HGEN612-Pine-Beetle-Flexdashboard/actions/workflows/r-check.yml)

An interactive `flexdashboard` created for **HGEN 612: Methods in Data Science** at Virginia Commonwealth University. The project examines tree- and neighborhood-level measurements from a 1993 Jeffrey pine beetle dataset and compares regression approaches for predicting the minimum distance to the nearest brood tree (`DeadDist`).

## What the dashboard contains

- Interactive spatial and exploratory views of the tree measurements
- A conventional linear-regression model and assumption checks
- Ridge and lasso regression workflows built with `tidymodels`
- Model summaries, coefficients, RMSE, and R² comparisons
- Embedded source code for transparent review

The `tidymodels` workflows use `sqrt(DeadDist)` as the outcome. Their reported RMSE values are therefore on the square-root distance scale, not the original distance scale.

## Repository layout

```text
.
├── dashboard.Rmd                 # Flexdashboard source
├── data/
│   └── pine_beetle_1993.xlsx     # Course-provided analysis dataset
├── scripts/
│   ├── install_packages.R        # Dependency installer
│   └── privacy_check.sh          # Secret and local-path checks
└── tests/
    └── smoke_test.R              # Structure and data validation
```

## Run locally

Use R 4.3 or newer. From the repository root:

```r
source("scripts/install_packages.R")
rmarkdown::render("dashboard.Rmd")
```

The rendered `dashboard.html` is intentionally ignored because it is generated from the source and is approximately 18 MB.

## Reproducibility

The source uses a relative path to the included workbook and sets all model seeds explicitly where resampling occurs. Run the smoke test before rendering:

```r
source("tests/smoke_test.R")
```

## Data and reuse

The workbook was supplied for an HGEN 612 course assignment. It contains ecological measurements, not human-subject data. Its upstream license was not provided with the course materials, so it is included in this private repository only to reproduce the assignment and should not be redistributed independently. See [NOTICE.md](NOTICE.md).

## Author

Sina Mahdiani — HGEN 612, Spring 2025
