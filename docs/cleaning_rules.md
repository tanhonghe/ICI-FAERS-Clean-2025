# Cleaning Rules

## Scope

This release processes FAERS 2025 Q1-Q4 ASCII quarterly extracts and builds an ICI-associated public clean dataset.

## Raw Data

Raw FAERS zip files are not committed. The pipeline reads FDA ASCII files directly from local zip archives.

## Deduplication

FAERS may contain multiple versions for the same `CASEID`.

Rule:

```text
For each CASEID, keep the row with the highest CASEVERSION.
```

If multiple rows share the same maximum `CASEVERSION`, the row with the largest `PRIMARYID` is retained as a deterministic tie-breaker.

Outputs:

```text
results/deduplication_summary.csv
results/qc/2025_deduplication_summary.csv
figures/case_dedup_flow.png
```

## Drug Name Standardization

ICI matching uses `metadata/ici_drug_dictionary.csv`.

The pipeline searches both `DRUGNAME` and `PROD_AI`, normalizes case and punctuation, and uses token-aware matching. Raw values are preserved:

```text
drug_name_raw
prod_ai_raw
drug_name_standard
```

The current dictionary includes:

- PD-1: pembrolizumab, nivolumab, cemiplimab, dostarlimab
- PD-L1: atezolizumab, durvalumab, avelumab
- CTLA-4: ipilimumab

Outputs:

```text
results/drug_mapping_summary.csv
results/qc/2025_drug_mapping_summary.csv
```

## ICI-Associated Reports

A case is included if at least one retained latest-version drug record matches the ICI dictionary.

All drug records for included cases are retained, not only the ICI drug rows. This preserves concomitant-drug context for later pharmacovigilance and machine-learning stages.

## Reactions

`REAC.PT` is preserved as the reported MedDRA Preferred Term.

This release does not classify adverse events as immune-related adverse events. FAERS adverse-event terms are not equivalent to clinically confirmed irAEs.

## Outcomes

Outcome records are mapped from FAERS `OUTC_COD` using `metadata/outcome_code_dictionary.csv`.

The case-level table includes separate flags for death, hospitalization, life-threatening events, disability, congenital anomaly, required intervention, and other outcome.

## Unit of Analysis

Relational outputs preserve FAERS one-to-many structure.

The analysis-ready file `data/analysis/ici_case_level_2025.csv.gz` has one row per deduplicated ICI-associated case.
