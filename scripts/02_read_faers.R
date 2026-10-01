source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))

row_counts <- list()
columns <- list()

for (quarter in config$quarters) {
  for (table in config$tables) {
    message("Inspecting ", toupper(table), " ", toupper(quarter))
    preview <- read_faers_table(table, quarter, nrows = 0L)
    columns[[paste(table, quarter, sep = "_")]] <- data.table::data.table(
      year = config$year,
      quarter = toupper(quarter),
      table = table,
      column_name = names(preview),
      column_order = seq_along(names(preview))
    )
    row_counts[[paste(table, quarter, sep = "_")]] <- data.table::data.table(
      year = config$year,
      quarter = toupper(quarter),
      table = table,
      raw_rows = zip_member_row_count(table, quarter)
    )
  }
}

write_dt(data.table::rbindlist(row_counts), file.path(config$qc_dir, "2025_raw_table_counts.csv"))
write_dt(data.table::rbindlist(columns), file.path(config$metadata_dir, "2025_raw_columns.csv"))

message("Raw table counts written to results/qc/2025_raw_table_counts.csv")
