source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

mentions <- read_dt(file.path(config$interim_dir, "ici_drug_mentions.csv.gz"))

case_index <- mentions[, .(
  n_ici_agents = data.table::uniqueN(standard_name),
  n_ici_drug_rows = .N,
  ici_agents = collapse_unique(standard_name),
  ici_classes = collapse_unique(ici_class),
  ici_targets = collapse_unique(target)
), by = .(primaryid, caseid)]

agent_counts <- mentions[, .(
  n_drug_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = .(standard_name, ici_class, target)]
data.table::setorder(agent_counts, -n_cases, standard_name)

class_counts <- mentions[, .(
  n_drug_rows = .N,
  n_cases = data.table::uniqueN(caseid)
), by = .(ici_class, target)]
data.table::setorder(class_counts, -n_cases, ici_class)

overall <- data.table::data.table(
  metric = c("ici_associated_cases", "ici_drug_rows", "distinct_ici_agents"),
  value = c(nrow(case_index), nrow(mentions), data.table::uniqueN(mentions$standard_name))
)

write_dt(case_index, file.path(config$interim_dir, "ici_case_index.csv.gz"))
write_dt(overall, file.path(config$qc_dir, "2025_ici_case_counts.csv"))
write_dt(agent_counts, file.path(config$qc_dir, "2025_ici_agent_counts.csv"))
write_dt(class_counts, file.path(config$qc_dir, "2025_ici_class_counts.csv"))

message("ICI case index written to data/interim/2025/ici_case_index.csv.gz")
