# ==============================================================================
# 03_eda_sales.R
# Phase 3: Exploratory Data Analysis (sales, trends, products, countries, orders)
# ==============================================================================

library(tidyverse)
library(lubridate)
library(scales)

retail_sales <- readRDS("data/processed/retail_sales.rds")

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

theme_retail <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# A. Sales overview
sales_overview <- retail_sales %>%
  summarise(
    total_sales_gbp   = sum(sales_value),
    n_invoices        = n_distinct(invoice_no),
    n_customers_known = n_distinct(customer_id, na.rm = TRUE),
    n_products        = n_distinct(stock_code),
    avg_invoice_gbp   = total_sales_gbp / n_invoices
  )
print(sales_overview)
write_csv(sales_overview, "outputs/tables/03_sales_overview.csv")

# B. Monthly sales over time
monthly_sales <- retail_sales %>%
  group_by(invoice_month) %>%
  summarise(
    monthly_revenue = sum(sales_value),
    n_invoices      = n_distinct(invoice_no),
    .groups         = "drop"
  ) %>%
  arrange(invoice_month)
write_csv(monthly_sales, "outputs/tables/03_monthly_sales.csv")

p_monthly <- ggplot(monthly_sales, aes(x = invoice_month, y = monthly_revenue)) +
  geom_line(color = "#2C3E50", linewidth = 1) +
  geom_point(color = "#E74C3C", size = 2.5) +
  scale_x_datetime(date_breaks = "1 month", date_labels = "%b %Y") +
  scale_y_continuous(labels = label_dollar(prefix = "£", scale = 1e-3, suffix = "K")) +
  labs(
    title    = "Monthly Gross Revenue (Valid Sales)",
    subtitle = "Dec 2010 - Dec 2011 (Dec 2011 is partial, ending Dec 9)",
    x        = "Month",
    y        = "Revenue (£ Thousands)"
  ) +
  theme_retail +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/figures/01_monthly_revenue.png", p_monthly, width = 9, height = 5, dpi = 300)

# C. Product analysis
product_summary <- retail_sales %>%
  group_by(stock_code, description) %>%
  summarise(
    total_revenue = sum(sales_value),
    total_qty     = sum(quantity),
    n_invoices    = n_distinct(invoice_no),
    .groups       = "drop"
  )

top10_rev <- slice_max(product_summary, total_revenue, n = 10)
top10_qty <- slice_max(product_summary, total_qty, n = 10)
write_csv(top10_rev, "outputs/tables/03_top10_products_revenue.csv")
write_csv(top10_qty, "outputs/tables/03_top10_products_qty.csv")

p_products <- ggplot(top10_rev, aes(x = reorder(str_trunc(description, 32), total_revenue), y = total_revenue)) +
  geom_col(fill = "#2980B9") +
  coord_flip() +
  scale_y_continuous(labels = label_dollar(prefix = "£", scale = 1e-3, suffix = "K")) +
  labs(
    title = "Top 10 Products by Gross Sales Value",
    x     = NULL,
    y     = "Total Revenue (£ Thousands)"
  ) +
  theme_retail
ggsave("outputs/figures/02_top10_products_revenue.png", p_products, width = 9, height = 5, dpi = 300)

# D. Country analysis
country_summary <- retail_sales %>%
  group_by(country) %>%
  summarise(
    total_revenue     = sum(sales_value),
    n_invoices        = n_distinct(invoice_no),
    n_customers_known = n_distinct(customer_id, na.rm = TRUE),
    revenue_share_pct = round(sum(sales_value) / sum(retail_sales$sales_value) * 100, 2),
    .groups           = "drop"
  ) %>%
  arrange(desc(total_revenue))
write_csv(head(country_summary, 15), "outputs/tables/03_top_countries.csv")

p_countries <- country_summary %>%
  filter(country != "United Kingdom") %>%
  slice_max(total_revenue, n = 10) %>%
  ggplot(aes(x = reorder(country, total_revenue), y = total_revenue)) +
  geom_col(fill = "#16A085") +
  coord_flip() +
  scale_y_continuous(labels = label_dollar(prefix = "£", scale = 1e-3, suffix = "K")) +
  labs(
    title    = "Top 10 Non-UK Markets by Gross Sales Value",
    subtitle = "United Kingdom dominates total revenue and is omitted here for scale",
    x        = NULL,
    y        = "Total Revenue (£ Thousands)"
  ) +
  theme_retail
ggsave("outputs/figures/03_top10_non_uk_countries.png", p_countries, width = 9, height = 5, dpi = 300)

# E. Invoice value and quantity distributions
invoice_totals <- retail_sales %>%
  group_by(invoice_no) %>%
  summarise(invoice_value = sum(sales_value), .groups = "drop")

p_invoice_dist <- ggplot(invoice_totals, aes(x = invoice_value)) +
  geom_histogram(bins = 50, fill = "#8E44AD", color = "white", alpha = 0.85) +
  scale_x_log10(labels = label_dollar(prefix = "£")) +
  labs(
    title = "Distribution of Invoice Values (Log10 Scale)",
    x     = "Invoice Value (£, log10 scale)",
    y     = "Number of Invoices"
  ) +
  theme_retail
ggsave("outputs/figures/04_invoice_value_dist.png", p_invoice_dist, width = 8, height = 5, dpi = 300)

p_qty_box <- ggplot(retail_sales, aes(y = quantity)) +
  geom_boxplot(fill = "#E67E22", alpha = 0.7, outlier.alpha = 0.25) +
  scale_y_log10(labels = comma) +
  labs(
    title = "Line-Item Quantity Distribution (Log10 Scale)",
    y     = "Quantity per Line (log10 scale)",
    x     = NULL
  ) +
  theme_retail
ggsave("outputs/figures/05_quantity_boxplot.png", p_qty_box, width = 6, height = 5, dpi = 300)
