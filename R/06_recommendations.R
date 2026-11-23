# ==============================================================================
# 06_recommendations.R
# Phase 8 & 9: Statistical checks, segment labeling, and business summary
# ==============================================================================

library(tidyverse)

rfm_clustered   <- readRDS("data/processed/rfm_clustered.rds")
cluster_profile <- read_csv("outputs/tables/05_cluster_profile.csv", show_col_types = FALSE)

# 1. Statistical analysis: Spearman correlation & Kruskal-Wallis test
spearman_cor <- round(cor(select(rfm_clustered, recency, frequency, monetary), method = "spearman"), 3)
cat("--- Spearman Rank Correlations ---\n")
print(spearman_cor)

kw_test <- kruskal.test(monetary ~ cluster, data = rfm_clustered)
cat("\n--- Kruskal-Wallis Test (Monetary ~ Cluster) ---\n")
print(kw_test)

# 2. Assign evidence-based segment labels ordered by median_monetary
segment_map <- cluster_profile %>%
  arrange(desc(median_monetary)) %>%
  mutate(
    segment = c(
      "High-Value Loyalists",
      "Mid-Tier Regulars",
      "Recent Low-Frequency",
      "Inactive / One-Time"
    )
  ) %>%
  select(cluster, segment) %>%
  mutate(cluster = as.factor(cluster))

rfm_segmented <- rfm_clustered %>%
  left_join(segment_map, by = "cluster")

write_csv(rfm_segmented, "outputs/tables/06_rfm_segmented.csv")
cat("\nSaved segmented customer table to outputs/tables/06_rfm_segmented.csv\n")
