source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

demo <- read_dt(file.path(config$interim_dir, "demo_merged.csv.gz"))
demo[, caseversion_num := as_integer_safely(caseversion)]
demo[, primaryid_num := as_numeric_safely(primaryid)]

case_version_stats <- demo[, .(
  raw_reports = .N,
  n_caseversions = uniqueN(caseversion),
  max_caseversion = max(caseversion_num, na.rm = TRUE)
), by = caseid]

data.table::setorder(demo, caseid, -caseversion_num, -primaryid_num)
demo_latest <- demo[, .SD[1], by = caseid]

latest_ids <- demo_latest[, .(
  primaryid,
  caseid,
  caseversion,
  source_year,
  source_quarter
)]

summary <- data.table::data.table(
  metric = c(
    "raw_demo_reports",
    "unique_caseid_before_deduplication",
    "caseids_with_multiple_versions",
    "reports_removed_by_caseversion_deduplication",
    "final_latest_caseid_reports"
  ),
  value = c(
    nrow(demo),
    data.table::uniqueN(demo$caseid),
    sum(case_version_stats$n_caseversions > 1L),
    nrow(demo) - nrow(demo_latest),
    nrow(demo_latest)
  )
)

write_dt(demo_latest, file.path(config$interim_dir, "demo_deduplicated.csv.gz"))
write_dt(latest_ids, file.path(config$interim_dir, "latest_primaryids.csv.gz"))
write_dt(summary, file.path(config$results_dir, "deduplication_summary.csv"))
write_dt(summary, file.path(config$qc_dir, "2025_deduplication_summary.csv"))

message("Deduplicated DEMO table written to data/interim/2025/demo_deduplicated.csv.gz")
