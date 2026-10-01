source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

outc <- read_dt(file.path(config$interim_dir, "outc_merged.csv.gz"))
case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))
labels <- outcome_labels()

outc <- outc[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]
outcomes <- merge(outc, labels, by = "outc_cod", all.x = TRUE, sort = FALSE)
outcomes[, serious_outcome_component := outc_cod %in% serious_outcome_codes]

outcomes <- outcomes[, .(
  primaryid,
  caseid,
  source_year,
  source_quarter,
  outc_cod,
  outcome_label,
  serious_outcome_component
)]

outcome_counts <- outcomes[, .(
  n_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = .(outc_cod, outcome_label, serious_outcome_component)]
data.table::setorder(outcome_counts, -n_cases, outc_cod)

write_dt(outcomes, file.path(config$processed_dir, "outcomes.csv.gz"))
write_dt(outcome_counts, file.path(config$qc_dir, "2025_outcome_counts.csv"))

message("Clean outcomes table written to data/processed/2025/outcomes.csv.gz")
