library(data.table)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

write_dt <- function(x, path) {
  ensure_dir(dirname(path))
  data.table::fwrite(x, path, na = "")
  invisible(path)
}

read_dt <- function(path, ...) {
  data.table::fread(path, na.strings = c("", "NA", "NaN"), showProgress = FALSE, ...)
}

faers_zip_path <- function(quarter) {
  stopifnot(quarter %in% config$quarters)
  expected <- sprintf("faers_ascii_%s%s.zip", config$year, quarter)
  candidate <- file.path(config$raw_dir, expected)
  if (file.exists(candidate)) return(candidate)

  files <- list.files(config$raw_dir, pattern = "\\.zip$", full.names = TRUE, ignore.case = TRUE)
  hit <- files[tolower(basename(files)) == tolower(expected)]
  if (length(hit) > 0) return(hit[[1]])

  stop(
    "Missing raw zip for ", toupper(quarter), ". Expected file like: ",
    expected, " in ", config$raw_dir,
    call. = FALSE
  )
}

faers_member_name <- function(table, quarter) {
  table <- tolower(table)
  suffix <- sprintf("%02d%s", config$year %% 100L, toupper(quarter))

  if (table == "delete") return(sprintf("Deleted/DELETE%s.txt", suffix))

  table_code <- switch(
    table,
    demo = "DEMO",
    drug = "DRUG",
    reac = "REAC",
    outc = "OUTC",
    indi = "INDI",
    ther = "THER",
    rpsr = "RPSR",
    stop("Unknown FAERS table: ", table, call. = FALSE)
  )
  sprintf("ASCII/%s%s.txt", table_code, suffix)
}

extract_faers_member <- function(zip_path, member) {
  temp_dir <- tempfile("faers_member_")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  extracted <- utils::unzip(
    zipfile = zip_path,
    files = member,
    exdir = temp_dir,
    junkpaths = TRUE,
    overwrite = TRUE
  )
  if (length(extracted) == 0L || !file.exists(extracted[[1]])) {
    stop("Could not extract ", member, " from ", zip_path, call. = FALSE)
  }
  list(path = extracted[[1]], temp_dir = temp_dir)
}

read_faers_table <- function(table, quarter, nrows = Inf, select = NULL) {
  zip_path <- faers_zip_path(quarter)
  member <- faers_member_name(table, quarter)
  extracted <- extract_faers_member(zip_path, member)
  on.exit(unlink(extracted$temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  if (tolower(table) == "delete") {
    args <- list(
      input = extracted$path,
      sep = "$",
      header = FALSE,
      col.names = "caseid",
      colClasses = "character",
      blank.lines.skip = TRUE,
      showProgress = FALSE
    )
    if (!is.infinite(nrows)) args$nrows <- nrows
    x <- do.call(data.table::fread, args)
  } else {
    args <- list(
      input = extracted$path,
      sep = "$",
      header = TRUE,
      colClasses = "character",
      quote = "",
      fill = TRUE,
      select = select,
      na.strings = c("", "NA"),
      showProgress = FALSE
    )
    if (!is.null(select)) args$select <- select
    if (!is.infinite(nrows)) args$nrows <- nrows
    x <- do.call(data.table::fread, args)
  }

  data.table::setnames(x, tolower(names(x)))
  x[, source_year := as.character(config$year)]
  x[, source_quarter := toupper(quarter)]
  x
}

zip_member_row_count <- function(table, quarter) {
  zip_path <- faers_zip_path(quarter)
  member <- faers_member_name(table, quarter)
  extracted <- extract_faers_member(zip_path, member)
  on.exit(unlink(extracted$temp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  wc <- suppressWarnings(system2("wc", c("-l", extracted$path), stdout = TRUE))
  raw_count <- suppressWarnings(as.integer(strsplit(trimws(wc), "\\s+")[[1]][[1]]))
  if (is.na(raw_count)) return(NA_integer_)
  if (tolower(table) == "delete") {
    max(raw_count - 1L, 0L)
  } else {
    max(raw_count - 1L, 0L)
  }
}

file_size_mb <- function(path) {
  if (!file.exists(path)) return(NA_real_)
  round(file.info(path)$size / 1024^2, 2)
}
