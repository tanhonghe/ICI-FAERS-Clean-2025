source(file.path("scripts", "00_config.R"))
source(file.path(config$scripts_dir, "lib", "io.R"))
source(file.path(config$scripts_dir, "lib", "cleaning.R"))

dictionary <- data.table::fread(config$ici_dictionary, showProgress = FALSE)
dictionary <- dictionary[tolower(include) %in% c("true", "1", "yes", "y")]
dictionary[, match_pattern := vapply(raw_name, drug_token_regex, character(1))]

drugs <- read_dt(file.path(config$interim_dir, "drug_merged.csv.gz"))
latest_ids <- read_dt(file.path(config$interim_dir, "latest_primaryids.csv.gz"))
drugs <- drugs[latest_ids[, .(primaryid)], on = "primaryid", nomatch = 0]

drugs[, drug_name_raw := drugname]
drugs[, prod_ai_raw := prod_ai]
drugs[, drug_search_text := normalize_drug_text(paste(drugname, prod_ai))]

matches <- list()
for (i in seq_len(nrow(dictionary))) {
  pattern <- dictionary$match_pattern[[i]]
  idx <- grepl(pattern, drugs$drug_search_text, perl = TRUE)
  if (!any(idx)) next

  hit <- drugs[idx, .(
    primaryid,
    caseid,
    drug_seq,
    role_cod,
    drug_name_raw,
    prod_ai_raw
  )]
  hit[, raw_name := dictionary$raw_name[[i]]]
  hit[, standard_name := dictionary$standard_name[[i]]]
  hit[, brand_name := dictionary$brand_name[[i]]]
  hit[, ici_class := dictionary$ici_class[[i]]]
  hit[, target := dictionary$target[[i]]]
  matches[[length(matches) + 1L]] <- hit
}

if (length(matches) == 0L) {
  mentions <- data.table::data.table(
    primaryid = character(),
    caseid = character(),
    drug_seq = character(),
    role_cod = character(),
    drug_name_raw = character(),
    prod_ai_raw = character(),
    raw_name = character(),
    standard_name = character(),
    brand_name = character(),
    ici_class = character(),
    target = character()
  )
} else {
  mentions_raw <- unique(data.table::rbindlist(matches, fill = TRUE))
  mentions <- mentions_raw[, .(
    role_cod = role_cod[[1]],
    drug_name_raw = drug_name_raw[[1]],
    prod_ai_raw = prod_ai_raw[[1]],
    raw_name = collapse_unique(raw_name),
    brand_name = collapse_unique(brand_name),
    ici_class = ici_class[[1]],
    target = target[[1]]
  ), by = .(primaryid, caseid, drug_seq, standard_name)]
}

row_map <- mentions[, .(
  drug_name_standard = collapse_unique(standard_name),
  ici_class = collapse_unique(ici_class),
  ici_target = collapse_unique(target),
  ici_match_terms = collapse_unique(raw_name)
), by = .(primaryid, caseid, drug_seq)]

drugs <- merge(
  drugs,
  row_map,
  by = c("primaryid", "caseid", "drug_seq"),
  all.x = TRUE,
  sort = FALSE
)
drugs[, is_ici_drug := !is.na(drug_name_standard) & nzchar(drug_name_standard)]
drugs[, drug_search_text := NULL]

mapping_summary <- mentions[, .(
  n_drug_rows = .N,
  n_cases = data.table::uniqueN(caseid),
  n_raw_drug_names = data.table::uniqueN(drug_name_raw),
  example_raw_names = collapse_unique(drug_name_raw, max_n = 12L)
), by = .(standard_name, ici_class, target)]
data.table::setorder(mapping_summary, ici_class, standard_name)

write_dt(drugs, file.path(config$interim_dir, "drugs_standardized_latest.csv.gz"))
write_dt(mentions, file.path(config$interim_dir, "ici_drug_mentions.csv.gz"))
write_dt(mapping_summary, file.path(config$results_dir, "drug_mapping_summary.csv"))
write_dt(mapping_summary, file.path(config$qc_dir, "2025_drug_mapping_summary.csv"))

message("ICI drug mentions written to data/interim/2025/ici_drug_mentions.csv.gz")
