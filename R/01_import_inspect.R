# ==============================================================================
# 01_import_inspect.R
# Phase 1: Import and inspect the UCI Online Retail dataset
# ==============================================================================

library(tidyverse)
library(readxl)
library(janitor)
library(skimr)

raw_path <- "data/raw/Online Retail.xlsx"
if (!file.exists(raw_path)) {
  stop("Dataset not found at '", raw_path, "'. See README.md for download instructions.")
}

raw_retail <- read_excel(raw_path)

cat("Dimensions (rows, cols):", dim(raw_retail), "\n")
cat("Column names:\n")
print(names(raw_retail))

glimpse(raw_retail)
summary(raw_retail)

missing_summary <- tibble(
  column      = names(raw_retail),
  missing_n   = colSums(is.na(raw_retail)),
  missing_pct = round(colMeans(is.na(raw_retail)) * 100, 2)
)
print(missing_summary)

unique_counts <- raw_retail %>%
  summarise(
    unique_invoices  = n_distinct(InvoiceNo, na.rm = TRUE),
    unique_products  = n_distinct(StockCode, na.rm = TRUE),
    unique_customers = n_distinct(CustomerID, na.rm = TRUE),
    unique_countries = n_distinct(Country, na.rm = TRUE)
  )
print(unique_counts)

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(missing_summary, "outputs/tables/01_missing_summary.csv")
