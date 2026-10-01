source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
library(ggplot2)

theme_qc <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold"),
      axis.title.y = ggplot2::element_blank()
    )
}

save_plot <- function(plot, filename, width = 8, height = 5) {
  path <- file.path(config$figures_dir, filename)
  ensure_dir(dirname(path))
  png_type <- if (Sys.info()[["sysname"]] == "Darwin") {
    "quartz"
  } else if (capabilities("cairo")) {
    "cairo"
  } else {
    "Xlib"
  }
  grDevices::png(
    filename = path,
    width = width,
    height = height,
    units = "in",
    res = 300,
    type = png_type
  )
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)
  invisible(path)
}

data_flow <- read_dt(file.path(config$qc_dir, "2025_data_flow.csv"))
analysis <- read_dt(file.path(config$analysis_dir, "ici_case_level_2025.csv.gz"))
sex_distribution <- read_dt(file.path(config$qc_dir, "sex_distribution.csv"))
drug_counts <- read_dt(file.path(config$qc_dir, "drug_counts.csv"))
reaction_counts <- read_dt(file.path(config$qc_dir, "reaction_counts.csv"))
missingness <- read_dt(file.path(config$qc_dir, "missingness.csv"))

p_flow <- ggplot(data_flow, aes(x = reorder(step, step_order), y = n_records)) +
  geom_col(fill = "#2F6F73", width = 0.7) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "2025 FAERS to ICI Case Flow", x = NULL, y = "Records") +
  theme_qc()
save_plot(p_flow, "01_case_flow.png", width = 8, height = 4.5)
save_plot(p_flow, "../case_dedup_flow.png", width = 8, height = 4.5)

p_age <- ggplot(analysis[!is.na(age_years) & age_years >= 0 & age_years <= 110], aes(x = age_years)) +
  geom_histogram(binwidth = 5, fill = "#6C8EBF", color = "white") +
  labs(title = "Age Distribution", x = "Age, years", y = "Cases") +
  theme_qc()
save_plot(p_age, "02_age_distribution.png")

p_sex <- ggplot(sex_distribution, aes(x = reorder(sex_standard, n_cases), y = n_cases)) +
  geom_col(fill = "#C96B58", width = 0.7) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Sex Distribution", x = NULL, y = "Cases") +
  theme_qc()
save_plot(p_sex, "03_sex_distribution.png")

p_drug <- ggplot(head(drug_counts, 12L), aes(x = reorder(drug_name_standard, n_cases), y = n_cases, fill = ici_class)) +
  geom_col(width = 0.7) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_manual(values = c("PD-1" = "#2F6F73", "PD-L1" = "#6C8EBF", "CTLA-4" = "#C96B58")) +
  labs(title = "Top ICI Drugs", x = NULL, y = "Cases", fill = "Class") +
  theme_qc()
save_plot(p_drug, "04_top_ici_drugs.png")

p_reac <- ggplot(head(reaction_counts, 20L), aes(x = reorder(reaction_pt, n_cases), y = n_cases)) +
  geom_col(fill = "#6B7A40", width = 0.7) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Top Reported MedDRA Preferred Terms", x = NULL, y = "Cases") +
  theme_qc()
save_plot(p_reac, "05_top_adverse_events.png", width = 9, height = 6)

miss_plot_data <- head(missingness, 25L)
p_missing <- ggplot(miss_plot_data, aes(x = reorder(variable, pct_missing), y = pct_missing)) +
  geom_col(fill = "#8A7CA8", width = 0.7) +
  coord_flip() +
  labs(title = "Missingness in Case-Level Dataset", x = NULL, y = "Missing (%)") +
  theme_qc()
save_plot(p_missing, "06_missingness.png", width = 8, height = 6)

message("QC figures written to figures/qc")
