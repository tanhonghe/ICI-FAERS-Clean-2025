# ICI-FAERS-Clean-2025

Reproducible 2025 FAERS clean-dataset project for immune checkpoint inhibitor pharmacovigilance research.

This repository is Phase 1 of the broader **ICI-FAERS Research Pipeline**. It is designed as a public data-engineering research product, not a one-off cleaning script.

## What This Project Does

This project rebuilds a clean 2025 ICI-associated FAERS dataset from official FDA quarterly ASCII extracts.

It preserves:

- raw-data provenance
- modular cleaning code
- case-version deduplication logic
- ICI drug-name normalization
- relational FAERS structure
- analysis-ready case-level data
- QC tables and figures
- versioned documentation

## Research Roadmap

- [x] FAERS 2025 raw-data ingestion
- [x] ICI drug dictionary
- [x] Drug-name normalization with raw-name preservation
- [x] CASEID / CASEVERSION deduplication
- [x] ICI-associated report extraction
- [x] Relational clean dataset
- [x] Case-level analysis-ready dataset
- [x] Automated QC tables and figures
- [ ] Pharmacovigilance signal analysis
- [ ] Temporal trend analysis
- [ ] Machine-learning prediction of serious reported outcomes
- [ ] Monte Carlo / microsimulation
- [ ] Cost-effectiveness analysis

## Data Source

Data source: FDA Adverse Event Reporting System (FAERS) quarterly ASCII extracts.

This release covers:

```text
2025 Q1
2025 Q2
2025 Q3
2025 Q4
```

Official FDA source page:

https://www.fda.gov/drugs/fdas-adverse-event-reporting-system-faers/fda-adverse-event-reporting-system-faers-latest-quarterly-data-files

Direct download URLs are recorded in:

```text
metadata/faers_2025_quarters.csv
```

Raw FDA zip files are not tracked in Git. See `raw/README.md`.

## Target ICI Drugs

The first release includes 8 immune checkpoint inhibitors.

PD-1:

- pembrolizumab
- nivolumab
- cemiplimab
- dostarlimab

PD-L1:

- atezolizumab
- durvalumab
- avelumab

CTLA-4:

- ipilimumab

The drug dictionary is stored as a project data asset:

```text
metadata/ici_drug_dictionary.csv
```

## Repository Structure

```text
ICI-FAERS-Clean-2025/
  README.md
  LICENSE
  CITATION.cff
  CHANGELOG.md
  docs/
  metadata/
  scripts/
  raw/
  data/
  results/
  figures/
  notebooks/
  releases/
```

## Rebuild The Dataset

Place the four FDA zip files in:

```text
raw/2025/
```

Expected names:

```text
faers_ascii_2025q1.zip
faers_ascii_2025q2.zip
faers_ascii_2025q3.zip
faers_ascii_2025Q4.zip
```

Then run from the repository root:

```bash
Rscript scripts/run_pipeline.R
```

If the raw files are stored elsewhere:

```bash
FAERS_RAW_DIR="/path/to/faers/2025" Rscript scripts/run_pipeline.R
```

## Cleaning Pipeline

```text
00_config.R
01_download_info.R
02_read_faers.R
03_merge_quarters.R
04_deduplicate_cases.R
05_standardize_drugs.R
06_extract_ici.R
07_clean_demographics.R
08_clean_reactions.R
09_clean_outcomes.R
10_clean_indications.R
11_build_relational_dataset.R
12_build_analysis_dataset.R
13_quality_control.R
14_generate_figures.R
```

Each script has explicit inputs and outputs. Shared helper functions are in `scripts/lib/`.

## Main Outputs

Relational clean datasets:

```text
data/processed/2025/cases.csv.gz
data/processed/2025/drugs.csv.gz
data/processed/2025/reactions.csv.gz
data/processed/2025/outcomes.csv.gz
data/processed/2025/indications.csv.gz
data/processed/2025/therapy.csv.gz
```

Analysis-ready dataset:

```text
data/analysis/ici_case_level_2025.csv.gz
```

Unit of analysis:

```text
one row = one deduplicated ICI-associated FAERS case
```

## QC Outputs

Key QC tables:

```text
results/deduplication_summary.csv
results/drug_mapping_summary.csv
results/qc/2025_data_flow.csv
results/qc/missingness.csv
results/qc/case_counts.csv
results/qc/drug_counts.csv
results/qc/reaction_counts.csv
results/qc/country_counts.csv
results/qc/age_summary.csv
results/qc/sex_distribution.csv
```

Key QC figures:

```text
figures/case_dedup_flow.png
figures/qc/01_case_flow.png
figures/qc/02_age_distribution.png
figures/qc/03_sex_distribution.png
figures/qc/04_top_ici_drugs.png
figures/qc/05_top_adverse_events.png
figures/qc/06_missingness.png
```

## Important Limitations

FAERS is a spontaneous reporting database.

This dataset can support pharmacovigilance signal detection and descriptive analysis of reported adverse-event cases. It cannot estimate true incidence because FAERS does not provide a complete exposed-population denominator.

Reported adverse events are not automatically clinically confirmed immune-related adverse events. In this release, MedDRA Preferred Terms from `REAC` are preserved without reclassifying them as irAEs.

## Versioning

Current release:

```text
v1.0.0: FAERS 2025 Q1-Q4 ICI clean dataset
```

Planned expansion:

```text
v1.1: add 2024-2025
v1.2: add 2023-2025
v2.0: add 2020-2025
future: add 2011-2025
```

See `CHANGELOG.md`.
