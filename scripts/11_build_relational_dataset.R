source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))

drugs <- read_dt(file.path(config$interim_dir, "drugs_standardized_latest.csv.gz"))
drugs <- drugs[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]
drugs_clean <- drugs[, .(
  primaryid,
  caseid,
  source_year,
  source_quarter,
  drug_seq,
  role_cod,
  drug_name_raw,
  prod_ai_raw,
  val_vbm,
  route,
  dose_vbm,
  cum_dose_chr,
  cum_dose_unit,
  dechal,
  rechal,
  lot_num,
  exp_dt,
  nda_num,
  dose_amt,
  dose_unit,
  dose_form,
  dose_freq,
  is_ici_drug,
  drug_name_standard,
  ici_class,
  ici_target,
  ici_match_terms
)]

ther <- read_dt(file.path(config$interim_dir, "ther_merged.csv.gz"))
ther <- ther[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]
therapy <- ther[, .(
  primaryid,
  caseid,
  source_year,
  source_quarter,
  dsg_drug_seq,
  start_dt_raw = start_dt,
  start_date = parse_faers_date(start_dt),
  end_dt_raw = end_dt,
  end_date = parse_faers_date(end_dt),
  duration_raw = dur,
  duration_code = dur_cod
)]

row_counts <- data.table::data.table(
  table = c("cases", "drugs", "reactions", "outcomes", "indications", "therapy"),
  rows = c(
    nrow(read_dt(file.path(config$processed_dir, "cases.csv.gz"))),
    nrow(drugs_clean),
    nrow(read_dt(file.path(config$processed_dir, "reactions.csv.gz"))),
    nrow(read_dt(file.path(config$processed_dir, "outcomes.csv.gz"))),
    nrow(read_dt(file.path(config$processed_dir, "indications.csv.gz"))),
    nrow(therapy)
  )
)

write_dt(drugs_clean, file.path(config$processed_dir, "drugs.csv.gz"))
write_dt(therapy, file.path(config$processed_dir, "therapy.csv.gz"))
write_dt(row_counts, file.path(config$qc_dir, "2025_relational_row_counts.csv"))

message("Relational drugs and therapy tables written to data/processed/2025")
