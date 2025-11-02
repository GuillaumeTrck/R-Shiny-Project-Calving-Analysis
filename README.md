# R-Shiny-Project-Calving-Analysis

An R project that loads a SQLite dataset, enriches it with genetic inheritance logic, and visualizes calvings over time and by lunar phase.

This project was part of an R programming course at the Haute école en Hainaut in Mons. The project was carried out in 2023 during my first year of a master's degree.
## Files

- Data loading and processing (incl. genetic inheritance): `recuperationdata.R`.
- Helper: `read.sql` to parse `.sql` files into executable statements.
- Shiny application (UI and plots): `app.R` (previously “Untitled-1”).

## Libraries

- DBI, RSQLite, tidyverse, magrittr, dplyr, shiny, lunar, ggplot2.

Install in R:
install.packages(c(
"DBI", "RSQLite", "tidyverse", "magrittr",
"dplyr", "shiny", "lunar", "ggplot2"
))

[web:57][web:54]

## Data expectations

- A DDL file named `table_scheme_exemple.sql` to create tables.
- A folder `sql-data` containing `.sql` files with `INSERT` statements.
- A SQLite database `db.sqlite` will be created/filled automatically.

## Setup

1. Open the project in R or VS Code.
2. Ensure the working directory points to the project root (or update paths in `recuperationdata.R` and `app.R`).
3. Run the data preparation script to create/seed the database and compute inheritance.

Run:
In R console
source("recuperationdata.R")

This will:
- Create `db.sqlite` via DBI + RSQLite.
- Execute schema SQL from `table_scheme_exemple.sql`.
- Load data from `sql-data/*.sql`.
- Compute genetic inheritance by joining parent/child tables and extend `animaux_types`.

## Run the Shiny app

The app provides:
- Tab “Calvings by year and family”: number of calvings grouped by day for a selected family and date range.
- Tab “Calvings by lunar phase”: number of calvings by lunar phase for a selected year.

## Notes

- Dates are parsed as `"%d/%m/%Y"`.
- Lunar phase is computed with `lunar.phase` from the `lunar` package.
- If files are moved, update paths in `setwd` or, preferably, switch to relative paths and `here::here()` for portability.
