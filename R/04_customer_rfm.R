# ==============================================================================
# 04_customer_rfm.R
# Phase 4: Construct customer-level Recency, Frequency, and Monetary (RFM) table
# ==============================================================================

library(tidyverse)

retail_customers <- readRDS("data/processed/retail_customers.rds")

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Reference date: 1 day after the latest eligible transaction date
ref_date <- max(retail_customers$invoice_day) + 1
cat("RFM Reference Date:", as.character(ref_date), "\n")

rfm <- retail_customers %>%
  group_by(customer_id) %>%
  summarise(
    recency   = as.numeric(ref_date - max(invoice_day)),
    frequency = n_distinct(invoice_no),
    monetary  = sum(sales_value),
    .groups   = "drop"
  )

print(summary(select(rfm, recency, frequency, monetary)))

p_rfm_dist <- rfm %>%
  pivot_longer(cols = c(recency, frequency, monetary), names_to = "metric", values_to = "value") %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 40, fill = "#2E86C1", color = "white", alpha = 0.85) +
  facet_wrap(~ metric, scales = "free") +
  labs(
    title    = "Raw RFM Metric Distributions",
    subtitle = "Frequency and Monetary are heavily right-skewed",
    x        = "Value",
    y        = "Customer Count"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave("outputs/figures/06_rfm_distributions.png", p_rfm_dist, width = 10, height = 4.5, dpi = 300)
saveRDS(rfm, "data/processed/rfm.rds")
