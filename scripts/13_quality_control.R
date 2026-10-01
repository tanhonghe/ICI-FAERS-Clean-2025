source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))

analysis <- read_dt(file.path(config$analysis_dir, "ici_case_level_2025.csv.gz"))
cases <- read_dt(file.path(config$processed_dir, "cases.csv.gz"))
drugs <- read_dt(file.path(config$processed_dir, "drugs.csv.gz"))
reactions <- read_dt(file.path(config$processed_dir, "reactions.csv.gz"))
dedup <- read_dt(file.path(config$results_dir, "deduplication_summary.csv"))
mentions <- read_dt(file.path(config$interim_dir, "ici_drug_mentions.csv.gz"))

missingness <- data.table::rbindlist(lapply(names(analysis), function(col) {
  values <- analysis[[col]]
  n_missing <- sum(is.na(values) | trimws(as.character(values)) == "")
  data.table::data.table(
    variable = col,
    n_missing = n_missing,
    pct_missing = round(100 * n_missing / nrow(analysis), 2)
  )
}))
data.table::setorder(missingness, -pct_missing, variable)

case_counts <- cases[, .(n_cases = .N), by = .(source_year, source_quarter)]
data.table::setorder(case_counts, source_quarter)

drug_counts <- mentions[, .(
  n_drug_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = .(drug_name_standard = standard_name, ici_class)]
data.table::setorder(drug_counts, -n_cases, drug_name_standard)

reaction_counts <- reactions[, .(
  n_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = reaction_pt]
data.table::setorder(reaction_counts, -n_cases, reaction_pt)

country_counts <- cases[, .(n_cases = .N), by = .(reporter_country)]
data.table::setorder(country_counts, -n_cases, reporter_country)

age_summary <- analysis[, .(
  n_cases = .N,
  n_nonmissing_age = sum(!is.na(age_years)),
  mean_age_years = round(mean(age_years, na.rm = TRUE), 2),
  median_age_years = round(stats::median(age_years, na.rm = TRUE), 2),
  p25_age_years = round(stats::quantile(age_years, 0.25, na.rm = TRUE), 2),
  p75_age_years = round(stats::quantile(age_years, 0.75, na.rm = TRUE), 2)
)]

sex_distribution <- analysis[, .(n_cases = .N), by = sex_standard]
sex_distribution[, pct_cases := round(100 * n_cases / sum(n_cases), 2)]
data.table::setorder(sex_distribution, -n_cases)

data_flow <- data.table::data.table(
  step_order = 1:4,
  step = c(
    "Raw DEMO reports",
    "Unique CASEID before deduplication",
    "Latest CASEVERSION per CASEID",
    "ICI-associated case-level dataset"
  ),
  n_records = c(
    dedup[metric == "raw_demo_reports", value],
    dedup[metric == "unique_caseid_before_deduplication", value],
    dedup[metric == "final_latest_caseid_reports", value],
    nrow(analysis)
  )
)

write_dt(data_flow, file.path(config$qc_dir, "2025_data_flow.csv"))
write_dt(missingness, file.path(config$qc_dir, "missingness.csv"))
write_dt(case_counts, file.path(config$qc_dir, "case_counts.csv"))
write_dt(drug_counts, file.path(config$qc_dir, "drug_counts.csv"))
write_dt(head(reaction_counts, 100L), file.path(config$qc_dir, "reaction_counts.csv"))
write_dt(country_counts, file.path(config$qc_dir, "country_counts.csv"))
write_dt(age_summary, file.path(config$qc_dir, "age_summary.csv"))
write_dt(sex_distribution, file.path(config$qc_dir, "sex_distribution.csv"))

message("QC tables written to results/qc")
