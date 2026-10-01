source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

reac <- read_dt(file.path(config$interim_dir, "reac_merged.csv.gz"))
case_index <- read_dt(file.path(config$interim_dir, "ici_case_index.csv.gz"))
reac <- reac[case_index[, .(primaryid, caseid)], on = c("primaryid", "caseid"), nomatch = 0]

reactions <- reac[, .(
  primaryid,
  caseid,
  source_year,
  source_quarter,
  reaction_pt = trimws(pt),
  drug_rec_act = trimws(drug_rec_act)
)]
reactions <- reactions[nzchar(reaction_pt)]

reaction_counts <- reactions[, .(
  n_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = reaction_pt]
data.table::setorder(reaction_counts, -n_cases, reaction_pt)

write_dt(reactions, file.path(config$processed_dir, "reactions.csv.gz"))
write_dt(reaction_counts, file.path(config$qc_dir, "2025_reaction_counts.csv"))

message("Clean reactions table written to data/processed/2025/reactions.csv.gz")
