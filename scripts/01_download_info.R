source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))

manifest <- data.table::fread(config$quarter_manifest, showProgress = FALSE)

manifest[, local_zip_path := vapply(quarter, function(q) {
  tryCatch(faers_zip_path(tolower(q)), error = function(e) NA_character_)
}, character(1))]
manifest[, local_file_exists := !is.na(local_zip_path) & file.exists(local_zip_path)]
manifest[, local_file_size_mb := vapply(local_zip_path, file_size_mb, numeric(1))]
manifest[, local_md5 := ifelse(local_file_exists, unname(tools::md5sum(local_zip_path)), NA_character_)]
manifest[, local_zip_file := ifelse(local_file_exists, basename(local_zip_path), NA_character_)]
manifest[, local_zip_path := NULL]
manifest[, checked_at := format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")]

write_dt(manifest, file.path(config$logs_dir, "2025_raw_zip_manifest.csv"))

if (!all(manifest$local_file_exists)) {
  missing <- manifest[local_file_exists == FALSE, quarter]
  stop(
    "Missing FAERS raw zip file(s): ",
    paste(missing, collapse = ", "),
    ". See raw/README.md for download instructions.",
    call. = FALSE
  )
}

message("Raw zip manifest written to results/logs/2025_raw_zip_manifest.csv")
