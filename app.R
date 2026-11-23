# ==============================================================================
# app.R
# Interactive R Shiny Dashboard for Customer Behavior Analytics & RFM Segments
# Run locally with: shiny::runApp()
# ==============================================================================

library(shiny)
library(bslib)
library(tidyverse)
library(scales)
library(plotly)
library(DT)

# Helper to load either local script outputs or Colab-exported CSVs
read_first_existing <- function(paths) {
  found <- paths[file.exists(paths)][1]
  if (is.na(found)) {
    stop("Required file not found. Checked: ", paste(paths, collapse = ", "))
  }
  read_csv(found, show_col_types = FALSE)
}

rfm_segmented <- read_first_existing(c(
  "outputs/tables/06_rfm_segmented.csv",
  "outputs/tables/rfm_segmented.csv"
)) %>%
  mutate(
    cluster = as.factor(cluster),
    segment = as.factor(segment)
  )

cluster_profile <- read_first_existing(c(
  "outputs/tables/05_cluster_profile.csv",
  "outputs/tables/cluster_profile.csv"
))

cleaning_audit <- read_first_existing(c(
  "outputs/tables/02_cleaning_audit.csv",
  "outputs/tables/cleaning_audit.csv"
))

segment_choices <- levels(rfm_segmented$segment)

ui <- page_sidebar(
  title = "Customer Behavior Analytics & RFM Segmentation",
  theme = bs_theme(bootswatch = "flatly", primary = "#2C3E50"),
  sidebar = sidebar(
    width = 290,
    h5("Segment & Metric Filters"),
    checkboxGroupInput(
      "segments",
      "Customer Segments",
      choices  = segment_choices,
      selected = segment_choices
    ),
    sliderInput(
      "recency_range",
      "Recency (Days Since Last Purchase)",
      min   = min(rfm_segmented$recency),
      max   = max(rfm_segmented$recency),
      value = c(min(rfm_segmented$recency), max(rfm_segmented$recency))
    ),
    sliderInput(
      "freq_range",
      "Frequency (Distinct Invoices)",
      min   = min(rfm_segmented$frequency),
      max   = max(rfm_segmented$frequency),
      value = c(min(rfm_segmented$frequency), max(rfm_segmented$frequency))
    ),
    hr(),
    downloadButton("download_filtered", "Download Filtered CSV", class = "btn-primary w-100")
  ),
  layout_columns(
    fill = FALSE,
    value_box(
      title = "Filtered Customers",
      value = textOutput("kpi_customers"),
      theme = "primary"
    ),
    value_box(
      title = "Total Customer Spend",
      value = textOutput("kpi_revenue"),
      theme = "success"
    ),
    value_box(
      title = "Median Recency",
      value = textOutput("kpi_recency"),
      theme = "info"
    ),
    value_box(
      title = "Median Frequency",
      value = textOutput("kpi_frequency"),
      theme = "warning"
    )
  ),
  navset_card_tab(
    nav_panel(
      "Segment Overview",
      layout_columns(
        col_widths = c(7, 5),
        plotlyOutput("plot_share", height = "380px"),
        DTOutput("tbl_profile")
      )
    ),
    nav_panel(
      "RFM Explorer",
      layout_columns(
        col_widths = c(7, 5),
        plotlyOutput("plot_fm_scatter", height = "400px"),
        plotlyOutput("plot_recency_hist", height = "400px")
      )
    ),
    nav_panel(
      "Customer Lookup",
      DTOutput("tbl_customers")
    ),
    nav_panel(
      "Data Audit & Methods",
      h5("Data Cleaning Audit"),
      DTOutput("tbl_audit"),
      hr(),
      p("Segmentation uses log1p-transformed, standardized RFM features (ref_date = 2011-12-10) with K-Means (K = 4, nstart = 25, seed = 42).")
    )
  )
)

server <- function(input, output, session) {
  filtered_rfm <- reactive({
    req(input$segments)
    rfm_segmented %>%
      filter(
        segment %in% input$segments,
        recency >= input$recency_range[1],
        recency <= input$recency_range[2],
        frequency >= input$freq_range[1],
        frequency <= input$freq_range[2]
      )
  })

  output$kpi_customers <- renderText({
    comma(nrow(filtered_rfm()))
  })

  output$kpi_revenue <- renderText({
    dollar(sum(filtered_rfm()$monetary), prefix = "£", accuracy = 1)
  })

  output$kpi_recency <- renderText({
    paste0(round(median(filtered_rfm()$recency), 1), " days")
  })

  output$kpi_frequency <- renderText({
    paste0(round(median(filtered_rfm()$frequency), 1), " orders")
  })

  output$plot_share <- renderPlotly({
    df <- filtered_rfm() %>%
      group_by(segment) %>%
      summarise(
        customers = n(),
        revenue   = sum(monetary),
        .groups   = "drop"
      ) %>%
      mutate(
        cust_pct = customers / sum(customers) * 100,
        rev_pct  = revenue / sum(revenue) * 100
      ) %>%
      pivot_longer(cols = c(cust_pct, rev_pct), names_to = "metric", values_to = "pct") %>%
      mutate(metric = recode(metric, cust_pct = "Customer Share (%)", rev_pct = "Revenue Share (%)"))

    p <- ggplot(df, aes(x = reorder(segment, pct), y = pct, fill = metric)) +
      geom_col(position = "dodge") +
      coord_flip() +
      labs(title = "Customer Share vs. Revenue Share by Segment", x = NULL, y = "Share (%)", fill = NULL) +
      theme_minimal(base_size = 12)
    ggplotly(p)
  })

  output$tbl_profile <- renderDT({
    datatable(cluster_profile, options = list(dom = "t", scrollX = TRUE), rownames = FALSE)
  })

  output$plot_fm_scatter <- renderPlotly({
    df <- filtered_rfm()
    if (nrow(df) > 2500) df <- slice_sample(df, n = 2500)
    p <- ggplot(df, aes(x = frequency, y = monetary, color = segment, text = paste("Customer:", customer_id))) +
      geom_point(alpha = 0.55, size = 1.8) +
      scale_x_log10() +
      scale_y_log10(labels = label_dollar(prefix = "£")) +
      labs(title = "Frequency vs. Monetary (Log10)", x = "Frequency (orders)", y = "Monetary (£)") +
      theme_minimal(base_size = 12)
    ggplotly(p, tooltip = c("text", "x", "y", "colour"))
  })

  output$plot_recency_hist <- renderPlotly({
    p <- ggplot(filtered_rfm(), aes(x = recency, fill = segment)) +
      geom_histogram(bins = 30, color = "white", alpha = 0.85) +
      labs(title = "Recency Distribution", x = "Days Since Last Purchase", y = "Customers") +
      theme_minimal(base_size = 12)
    ggplotly(p)
  })

  output$tbl_customers <- renderDT({
    filtered_rfm() %>%
      select(customer_id, segment, recency, frequency, monetary) %>%
      arrange(desc(monetary)) %>%
      datatable(options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE) %>%
      formatCurrency("monetary", currency = "£")
  })

  output$tbl_audit <- renderDT({
    datatable(cleaning_audit, options = list(dom = "t"), rownames = FALSE)
  })

  output$download_filtered <- downloadHandler(
    filename = function() paste0("rfm_filtered_", Sys.Date(), ".csv"),
    content  = function(file) write_csv(filtered_rfm(), file)
  )
}

shinyApp(ui, server)
