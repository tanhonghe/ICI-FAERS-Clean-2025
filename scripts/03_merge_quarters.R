source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))

for (table in config$tables) {
  message("Merging ", toupper(table), " across 2025 quarters")
  quarterly <- lapply(config$quarters, function(quarter) read_faers_table(table, quarter))
  merged <- data.table::rbindlist(quarterly, fill = TRUE, use.names = TRUE)
  out_path <- file.path(config$interim_dir, sprintf("%s_merged.csv.gz", table))
  write_dt(merged, out_path)
  rm(quarterly, merged)
  gc()
}

message("Merged quarterly tables written to data/interim/2025")
