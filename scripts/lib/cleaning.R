library(data.table)

as_integer_safely <- function(x) {
  suppressWarnings(as.integer(x))
}

as_numeric_safely <- function(x) {
  suppressWarnings(as.numeric(x))
}

normalize_drug_text <- function(x) {
  x <- ifelse(is.na(x), "", x)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", " ", x, perl = TRUE)
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trimws(x)
}

drug_token_regex <- function(term) {
  term <- normalize_drug_text(term)
  pieces <- strsplit(term, "\\s+", perl = TRUE)[[1]]
  pieces <- pieces[nzchar(pieces)]
  if (length(pieces) == 0) return("$a")
  phrase <- paste(pieces, collapse = "\\s+")
  paste0("(^|\\s)", phrase, "(\\s|$)")
}

parse_faers_date <- function(x) {
  x <- trimws(ifelse(is.na(x), "", x))
  out <- rep(as.Date(NA), length(x))
  full <- grepl("^\\d{8}$", x)
  out[full] <- as.Date(x[full], format = "%Y%m%d")
  out
}

standardize_sex <- function(x) {
  x <- toupper(trimws(ifelse(is.na(x), "", x)))
  fifelse(
    x == "M", "Male",
    fifelse(
      x == "F", "Female",
      fifelse(x %in% c("UNK", "U", "NS", ""), "Unknown", "Other/Unknown")
    )
  )
}

convert_age_to_years <- function(age, age_cod) {
  value <- as_numeric_safely(age)
  unit <- toupper(trimws(ifelse(is.na(age_cod), "", age_cod)))
  out <- rep(NA_real_, length(value))
  out[unit %in% c("YR", "YEAR", "YEARS")] <- value[unit %in% c("YR", "YEAR", "YEARS")]
  out[unit %in% c("MON", "MONTH", "MONTHS")] <- value[unit %in% c("MON", "MONTH", "MONTHS")] / 12
  out[unit %in% c("WK", "WEEK", "WEEKS")] <- value[unit %in% c("WK", "WEEK", "WEEKS")] / 52.1775
  out[unit %in% c("DY", "DAY", "DAYS")] <- value[unit %in% c("DY", "DAY", "DAYS")] / 365.25
  out[unit %in% c("HR", "HOUR", "HOURS")] <- value[unit %in% c("HR", "HOUR", "HOURS")] / 8766
  out[unit %in% c("DEC", "DECADE", "DECADES")] <- value[unit %in% c("DEC", "DECADE", "DECADES")] * 10
  out
}

convert_weight_to_kg <- function(wt, wt_cod) {
  value <- as_numeric_safely(wt)
  unit <- toupper(trimws(ifelse(is.na(wt_cod), "", wt_cod)))
  out <- rep(NA_real_, length(value))
  out[unit %in% c("KG", "KILOGRAM", "KILOGRAMS")] <- value[unit %in% c("KG", "KILOGRAM", "KILOGRAMS")]
  out[unit %in% c("LBS", "LB", "POUND", "POUNDS")] <- value[unit %in% c("LBS", "LB", "POUND", "POUNDS")] * 0.45359237
  out[unit %in% c("G", "GRAM", "GRAMS")] <- value[unit %in% c("G", "GRAM", "GRAMS")] / 1000
  out
}

collapse_unique <- function(x, max_n = 100L) {
  values <- unique(trimws(as.character(x)))
  values <- values[!is.na(values) & nzchar(values)]
  if (length(values) == 0) return(NA_character_)
  if (length(values) > max_n) {
    values <- c(values[seq_len(max_n)], sprintf("... plus %d more", length(values) - max_n))
  }
  paste(sort(values), collapse = "; ")
}

outcome_labels <- function() {
  data.table::fread(config$outcome_dictionary, showProgress = FALSE)
}

serious_outcome_codes <- c("DE", "LT", "HO", "DS", "CA", "RI")
