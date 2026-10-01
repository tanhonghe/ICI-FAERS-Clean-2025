source(file.path("scripts", "00_config.R"))

steps <- c(
  "01_download_info.R",
  "02_read_faers.R",
  "03_merge_quarters.R",
  "04_deduplicate_cases.R",
  "05_standardize_drugs.R",
  "06_extract_ici.R",
  "07_clean_demographics.R",
  "08_clean_reactions.R",
  "09_clean_outcomes.R",
  "10_clean_indications.R",
  "11_build_relational_dataset.R",
  "12_build_analysis_dataset.R",
  "13_quality_control.R",
  "14_generate_figures.R"
)

for (step in steps) {
  message("\n==> Running ", step)
  source(file.path(config$scripts_dir, step), chdir = FALSE)
}

message("\nPipeline complete: ", config$project_name, " ", config$version)
