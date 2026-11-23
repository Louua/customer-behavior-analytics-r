# ==============================================================================
# 02_clean_data.R
# Phase 2: Data cleaning, validation, and documented preparation rules
# ==============================================================================

library(tidyverse)
library(readxl)
library(lubridate)
library(janitor)

raw_retail <- read_excel("data/raw/Online Retail.xlsx")

# 1. Standardize column names and cast customer_id to character
retail_std <- raw_retail %>%
  clean_names() %>%
  mutate(
    customer_id = as.character(customer_id),
    quantity    = as.numeric(quantity),
    unit_price  = as.numeric(unit_price)
  )

# 2. Remove exact duplicate rows
retail_dedup <- retail_std %>%
  distinct()

# 3. Filter to valid sales (exclude "C" cancellations, quantity <= 0, unit_price <= 0)
#    Keep missing customer_id for aggregate sales EDA; exclude only for RFM.
retail_sales <- retail_dedup %>%
  filter(
    !str_starts(invoice_no, "C"),
    quantity > 0,
    unit_price > 0
  ) %>%
  mutate(
    sales_value   = quantity * unit_price,
    invoice_day   = as.Date(invoice_date),
    invoice_month = floor_date(invoice_date, unit = "month")
  )

retail_customers <- retail_sales %>%
  filter(!is.na(customer_id))

# 4. Data-quality audit table
cleaning_audit <- tibble(
  stage = c(
    "1. Raw dataset",
    "2. After removing exact duplicates",
    "3. Valid sales (qty > 0, unit_price > 0, non-C)",
    "4. Valid sales with known customer_id (RFM base)"
  ),
  rows = c(
    nrow(raw_retail),
    nrow(retail_dedup),
    nrow(retail_sales),
    nrow(retail_customers)
  ),
  rows_removed_from_prev = c(
    0,
    nrow(raw_retail) - nrow(retail_dedup),
    nrow(retail_dedup) - nrow(retail_sales),
    nrow(retail_sales) - nrow(retail_customers)
  )
)
print(cleaning_audit)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

saveRDS(retail_sales, "data/processed/retail_sales.rds")
saveRDS(retail_customers, "data/processed/retail_customers.rds")
write_csv(cleaning_audit, "outputs/tables/02_cleaning_audit.csv")
