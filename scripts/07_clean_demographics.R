source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

demo <- read_dt(file.path(config$interim_dir, "demo_deduplicated.csv.gz"))
case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))
cases <- demo[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]

cases[, case_version := as_integer_safely(caseversion)]
cases[, event_date := parse_faers_date(event_dt)]
cases[, manufacturer_date := parse_faers_date(mfr_dt)]
cases[, initial_fda_date := parse_faers_date(init_fda_dt)]
cases[, fda_date := parse_faers_date(fda_dt)]
cases[, report_date := parse_faers_date(rept_dt)]
cases[, age_years := convert_age_to_years(age, age_cod)]
cases[, weight_kg := convert_weight_to_kg(wt, wt_cod)]
cases[, sex_standard := standardize_sex(sex)]
cases[, report_year := as_integer_safely(substr(fda_dt, 1, 4))]

cases_clean <- cases[, .(
  primaryid,
  caseid,
  case_version,
  source_year,
  source_quarter,
  i_f_code,
  event_dt_raw = event_dt,
  event_date,
  mfr_dt_raw = mfr_dt,
  manufacturer_date,
  init_fda_dt_raw = init_fda_dt,
  initial_fda_date,
  fda_dt_raw = fda_dt,
  fda_date,
  rept_dt_raw = rept_dt,
  report_date,
  report_year,
  rept_cod,
  mfr_num,
  mfr_sndr,
  age_raw = age,
  age_cod,
  age_years,
  age_grp,
  sex_raw = sex,
  sex_standard,
  weight_raw = wt,
  wt_cod,
  weight_kg,
  occp_cod,
  reporter_country,
  occr_country,
  e_sub
)]

write_dt(cases_clean, file.path(config$processed_dir, "cases.csv.gz"))

message("Clean cases table written to data/processed/2025/cases.csv.gz")
