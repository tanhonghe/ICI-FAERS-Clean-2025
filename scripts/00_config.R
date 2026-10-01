options(stringsAsFactors = FALSE)

required_packages <- c("data.table", "ggplot2", "scales", "yaml")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    ". Install them before running the pipeline.",
    call. = FALSE
  )
}

find_project_root <- function() {
  env_root <- Sys.getenv("ICI_FAERS_PROJECT_ROOT", unset = "")
  if (nzchar(env_root)) {
    env_root <- normalizePath(env_root, mustWork = TRUE)
    if (file.exists(file.path(env_root, "scripts", "00_config.R"))) return(env_root)
  }

  cwd <- normalizePath(getwd(), mustWork = TRUE)
  candidates <- unique(normalizePath(
    c(cwd, file.path(cwd, ".."), file.path(cwd, "../..")),
    mustWork = FALSE
  ))

  hits <- candidates[file.exists(file.path(candidates, "scripts", "00_config.R"))]
  if (length(hits) == 0) {
    stop("Could not locate project root. Run scripts from the repository root.", call. = FALSE)
  }
  hits[[1]]
}

project_root <- find_project_root()

local_raw_candidates <- c(
  file.path(project_root, "raw", "2025"),
  file.path(dirname(project_root), "清洗FAERS 原始数据", "2025")
)
env_raw_dir <- Sys.getenv("FAERS_RAW_DIR", unset = "")
raw_dir <- if (nzchar(env_raw_dir)) {
  env_raw_dir
} else {
  candidate_has_zip <- vapply(
    local_raw_candidates,
    function(path) dir.exists(path) && length(list.files(path, pattern = "\\.zip$", ignore.case = TRUE)) > 0,
    logical(1)
  )
  if (any(candidate_has_zip)) local_raw_candidates[which(candidate_has_zip)[[1]]] else local_raw_candidates[[1]]
}

config <- list(
  project_name = "ICI-FAERS-Clean-2025",
  version = "v1.0.0",
  year = 2025L,
  quarters = c("q1", "q2", "q3", "q4"),
  tables = c("demo", "drug", "reac", "outc", "indi", "ther", "rpsr", "delete"),
  raw_dir = normalizePath(raw_dir, mustWork = FALSE),
  project_root = project_root,
  scripts_dir = file.path(project_root, "scripts"),
  metadata_dir = file.path(project_root, "metadata"),
  interim_dir = file.path(project_root, "data", "interim", "2025"),
  processed_dir = file.path(project_root, "data", "processed", "2025"),
  analysis_dir = file.path(project_root, "data", "analysis"),
  sample_dir = file.path(project_root, "data", "sample"),
  results_dir = file.path(project_root, "results"),
  qc_dir = file.path(project_root, "results", "qc"),
  logs_dir = file.path(project_root, "results", "logs"),
  figures_dir = file.path(project_root, "figures", "qc"),
  ici_dictionary = file.path(project_root, "metadata", "ici_drug_dictionary.csv"),
  outcome_dictionary = file.path(project_root, "metadata", "outcome_code_dictionary.csv"),
  quarter_manifest = file.path(project_root, "metadata", "faers_2025_quarters.csv")
)

dir.create(config$interim_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$sample_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$qc_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$logs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(config$figures_dir, recursive = TRUE, showWarnings = FALSE)

message("Project root: ", config$project_root)
message("FAERS raw directory: ", config$raw_dir)
