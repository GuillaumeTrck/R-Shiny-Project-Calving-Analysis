# R-Shiny-Project-Calving-Analysis

An R project that loads a SQLite dataset, enriches it with genetic inheritance logic, and visualizes calvings over time and by lunar phase[web:65].

## Files

- Data loading and processing (incl. genetic inheritance): `recuperationdata.R` (previously “Untitled-2”)[web:52].
- Helper: `read.sql` to parse `.sql` files into executable statements[web:52].
- Shiny application (UI and plots): `app.R` (previously “Untitled-1”)[web:65].

## Libraries

- DBI, RSQLite, tidyverse, magrittr, dplyr, shiny, lunar, ggplot2[web:65].

Install in R:
install.packages(c(
"DBI", "RSQLite", "tidyverse", "magrittr",
"dplyr", "shiny", "lunar", "ggplot2"
))

[web:57][web:54]

## Data expectations

- A DDL file named `table_scheme_exemple.sql` to create tables[web:52].
- A folder `sql-data` containing `.sql` files with `INSERT` statements[web:52].
- A SQLite database `db.sqlite` will be created/filled automatically[web:65].

## Setup

1. Open the project in R or VS Code[web:52].
2. Ensure the working directory points to the project root (or update paths in `recuperationdata.R` and `app.R`)[web:52].
3. Run the data preparation script to create/seed the database and compute inheritance[web:52].

Run:
In R console
source("recuperationdata.R")

This will:
- Create `db.sqlite` via DBI + RSQLite[web:65].
- Execute schema SQL from `table_scheme_exemple.sql`[web:52].
- Load data from `sql-data/*.sql`[web:52].
- Compute genetic inheritance by joining parent/child tables and extend `animaux_types`[web:52].

## Run the Shiny app

The app provides:
- Tab “Calvings by year and family”: number of calvings grouped by day for a selected family and date range[web:65].
- Tab “Calvings by lunar phase”: number of calvings by lunar phase for a selected year[web:55].

## Notes

- Dates are parsed as `"%d/%m/%Y"`[web:52].
- Lunar phase is computed with `lunar.phase` from the `lunar` package[web:65].
- If files are moved, update paths in `setwd` or, preferably, switch to relative paths and `here::here()` for portability[web:52].
