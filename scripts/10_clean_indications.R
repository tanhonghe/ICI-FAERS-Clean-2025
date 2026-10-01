source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))

indi <- read_dt(file.path(config$interim_dir, "indi_merged.csv.gz"))
case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))
indi <- indi[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]

indications <- indi[, .(
  primaryid,
  caseid,
  source_year,
  source_quarter,
  indi_drug_seq,
  indication_pt = trimws(indi_pt)
)]
indications <- indications[nzchar(indication_pt)]

indication_counts <- indications[, .(
  n_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = indication_pt]
data.table::setorder(indication_counts, -n_cases, indication_pt)

write_dt(indications, file.path(config$processed_dir, "indications.csv.gz"))
write_dt(indication_counts, file.path(config$qc_dir, "2025_indication_counts.csv"))

message("Clean indications table written to data/processed/2025/indications.csv.gz")
