# ==============================================================================
# 05_clustering.R
# Phase 6 & 7: Log-scaling, K selection, K-Means clustering, and profiling
# ==============================================================================

library(tidyverse)
library(cluster)
library(scales)

rfm <- readRDS("data/processed/rfm.rds")

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

# 1. Log1p transform + standardize
rfm_scaled <- rfm %>%
  mutate(
    r_log = log1p(recency),
    f_log = log1p(frequency),
    m_log = log1p(monetary)
  ) %>%
  select(r_log, f_log, m_log) %>%
  scale() %>%
  as_tibble()

# 2. Evaluate K = 1..8 via WSS and Silhouette
dist_mat <- dist(rfm_scaled)

k_eval <- map_dfr(1:8, function(k) {
  set.seed(42)
  km <- kmeans(rfm_scaled, centers = k, nstart = 25)
  avg_sil <- if (k == 1) NA_real_ else mean(silhouette(km$cluster, dist_mat)[, 3])
  tibble(
    k              = k,
    tot_withinss   = round(km$tot.withinss, 1),
    avg_silhouette = round(avg_sil, 4)
  )
})
print(k_eval)
write_csv(k_eval, "outputs/tables/05_k_evaluation.csv")

p_elbow <- ggplot(k_eval, aes(x = k, y = tot_withinss)) +
  geom_line(color = "#2C3E50", linewidth = 1) +
  geom_point(color = "#E74C3C", size = 3) +
  scale_x_continuous(breaks = 1:8) +
  labs(title = "Elbow Method (WSS) for Candidate K", x = "K", y = "Total Within-Cluster SS") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))
ggsave("outputs/figures/07_kmeans_elbow.png", p_elbow, width = 7, height = 4.5, dpi = 300)

p_sil <- k_eval %>%
  filter(!is.na(avg_silhouette)) %>%
  ggplot(aes(x = k, y = avg_silhouette)) +
  geom_line(color = "#16A085", linewidth = 1) +
  geom_point(color = "#16A085", size = 3) +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Average Silhouette Width for Candidate K", x = "K", y = "Average Silhouette Width") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))
ggsave("outputs/figures/08_kmeans_silhouette.png", p_sil, width = 7, height = 4.5, dpi = 300)

# 3. Fit K = 4
set.seed(42)
km_4 <- kmeans(rfm_scaled, centers = 4, nstart = 25)

rfm_clustered <- rfm %>%
  mutate(cluster = factor(km_4$cluster))

# 4. PCA cluster visualization
pca_res <- prcomp(rfm_scaled, center = FALSE, scale. = FALSE)
var_exp <- round(summary(pca_res)$importance[2, 1:2] * 100, 1)

pca_df <- as_tibble(pca_res$x[, 1:2]) %>%
  mutate(cluster = rfm_clustered$cluster)

p_pca <- ggplot(pca_df, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(alpha = 0.45, size = 1.4) +
  stat_ellipse(level = 0.90, linewidth = 0.9) +
  labs(
    title    = "Customer Segments via K-Means (K = 4, Log-Scaled RFM)",
    subtitle = paste0("PCA projection (PC1: ", var_exp[1], "%, PC2: ", var_exp[2], "%)"),
    x        = paste0("PC1 (", var_exp[1], "%)"),
    y        = paste0("PC2 (", var_exp[2], "%)"),
    color    = "Cluster"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))
ggsave("outputs/figures/09_kmeans_clusters_pca.png", p_pca, width = 8, height = 5.5, dpi = 300)

# 5. Cluster profiling
cluster_profile <- rfm_clustered %>%
  group_by(cluster) %>%
  summarise(
    n_customers      = n(),
    customer_share   = round(n() / nrow(rfm_clustered) * 100, 1),
    median_recency   = round(median(recency), 1),
    median_frequency = round(median(frequency), 1),
    median_monetary  = round(median(monetary), 1),
    mean_recency     = round(mean(recency), 1),
    mean_frequency   = round(mean(frequency), 1),
    mean_monetary    = round(mean(monetary), 1),
    total_revenue    = round(sum(monetary), 0),
    revenue_share    = round(sum(monetary) / sum(rfm_clustered$monetary) * 100, 1),
    .groups          = "drop"
  ) %>%
  arrange(desc(median_monetary))

print(cluster_profile)
write_csv(cluster_profile, "outputs/tables/05_cluster_profile.csv")

p_profile <- rfm_clustered %>%
  pivot_longer(cols = c(recency, frequency, monetary), names_to = "metric", values_to = "value") %>%
  ggplot(aes(x = cluster, y = value, fill = cluster)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.2) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_y_log10(labels = comma) +
  labs(
    title = "RFM Characteristics by Cluster (Log10 Y-Axis)",
    x     = "Cluster",
    y     = "Value (log10 scale)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"), legend.position = "none")
ggsave("outputs/figures/10_cluster_profiles_boxplot.png", p_profile, width = 10, height = 5, dpi = 300)

saveRDS(rfm_clustered, "data/processed/rfm_clustered.rds")
