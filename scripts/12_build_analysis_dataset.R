source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

cases <- read_dt(file.path(config$processed_dir, "cases.csv.gz"))
drugs <- read_dt(file.path(config$processed_dir, "drugs.csv.gz"))
reactions <- read_dt(file.path(config$processed_dir, "reactions.csv.gz"))
outcomes <- read_dt(file.path(config$processed_dir, "outcomes.csv.gz"))
indications <- read_dt(file.path(config$processed_dir, "indications.csv.gz"))
case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))

drug_agg <- drugs[, .(
  n_drug_rows = .N,
  n_unique_drug_names = data.table::uniqueN(drug_name_raw),
  n_ici_drug_records = sum(is_ici_drug %in% c(TRUE, "TRUE", "true", "1"), na.rm = TRUE),
  n_concomitant_drug_names = data.table::uniqueN(drug_name_raw[!(is_ici_drug %in% c(TRUE, "TRUE", "true", "1"))])
), by = .(primaryid, caseid)]

reaction_agg <- reactions[, .(
  n_reactions = data.table::uniqueN(reaction_pt),
  reaction_terms = collapse_unique(reaction_pt, max_n = 150L)
), by = .(primaryid, caseid)]

indication_agg <- indications[, .(
  n_indications = data.table::uniqueN(indication_pt),
  indication_terms = collapse_unique(indication_pt, max_n = 100L)
), by = .(primaryid, caseid)]

outcome_agg <- outcomes[, .(
  has_outcome_record = .N > 0,
  serious_outcome = any(outc_cod %in% serious_outcome_codes),
  death = any(outc_cod == "DE"),
  life_threatening = any(outc_cod == "LT"),
  hospitalization = any(outc_cod == "HO"),
  disability = any(outc_cod == "DS"),
  congenital_anomaly = any(outc_cod == "CA"),
  required_intervention = any(outc_cod == "RI"),
  other_outcome = any(outc_cod == "OT"),
  outcome_codes = collapse_unique(outc_cod),
  outcome_labels = collapse_unique(outcome_label)
), by = .(primaryid, caseid)]

analysis <- merge(cases, case_index, by = c("primaryid", "caseid"), all.x = TRUE, sort = FALSE)
analysis <- merge(analysis, drug_agg, by = c("primaryid", "caseid"), all.x = TRUE, sort = FALSE)
analysis <- merge(analysis, reaction_agg, by = c("primaryid", "caseid"), all.x = TRUE, sort = FALSE)
analysis <- merge(analysis, indication_agg, by = c("primaryid", "caseid"), all.x = TRUE, sort = FALSE)
analysis <- merge(analysis, outcome_agg, by = c("primaryid", "caseid"), all.x = TRUE, sort = FALSE)

for (col in c(
  "has_outcome_record", "serious_outcome", "death", "life_threatening", "hospitalization",
  "disability", "congenital_anomaly", "required_intervention", "other_outcome"
)) {
  analysis[is.na(get(col)), (col) := FALSE]
}
for (col in c("n_drug_rows", "n_unique_drug_names", "n_ici_drug_records", "n_concomitant_drug_names", "n_reactions", "n_indications")) {
  analysis[is.na(get(col)), (col) := 0L]
}

write_dt(analysis, file.path(config$analysis_dir, "ici_case_level_2025.csv.gz"))
write_dt(head(analysis, 100L), file.path(config$sample_dir, "ici_case_level_2025_sample.csv"))

message("Analysis-ready case-level dataset written to data/analysis/ici_case_level_2025.csv.gz")
