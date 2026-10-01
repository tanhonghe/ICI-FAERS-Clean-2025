# Data Dictionary

## Relational Clean Tables

All files are generated under:

```text
data/processed/2025/
```

### cases.csv.gz

Unit of analysis: one row per deduplicated ICI-associated FAERS case.

Key fields:

- `primaryid`: FAERS primary report identifier for the retained case version
- `caseid`: FAERS case identifier
- `case_version`: retained latest case version
- `source_quarter`: 2025 source quarter of the retained report
- `age_years`: age standardized to years when possible
- `sex_standard`: standardized sex label
- `reporter_country`, `occr_country`: reporter and occurrence country fields from DEMO

### drugs.csv.gz

Unit of analysis: one row per drug record for included ICI-associated cases.

Key fields:

- `drug_name_raw`: original FAERS `DRUGNAME`
- `prod_ai_raw`: original FAERS `PROD_AI`
- `is_ici_drug`: whether the row matched the ICI dictionary
- `drug_name_standard`: standardized ICI generic name when matched
- `ici_class`: PD-1, PD-L1, or CTLA-4 when matched

### reactions.csv.gz

Unit of analysis: one row per reported MedDRA Preferred Term per included case.

Key fields:

- `reaction_pt`: reported MedDRA Preferred Term from `REAC.PT`
- `drug_rec_act`: drug-reaction action field when present

### outcomes.csv.gz

Unit of analysis: one row per reported outcome code per included case.

Key fields:

- `outc_cod`: FAERS outcome code
- `outcome_label`: mapped outcome label
- `serious_outcome_component`: whether the code is treated as a serious-outcome component in the case-level table

### indications.csv.gz

Unit of analysis: one row per indication record per included case.

Key fields:

- `indi_drug_seq`: linked drug sequence
- `indication_pt`: reported indication preferred term

### therapy.csv.gz

Unit of analysis: one row per therapy interval record per included case.

Key fields:

- `dsg_drug_seq`: linked drug sequence
- `start_dt_raw`, `end_dt_raw`: original FAERS therapy dates
- `start_date`, `end_date`: parsed dates when full YYYYMMDD values are available

## Analysis-Ready Dataset

### data/analysis/ici_case_level_2025.csv.gz

Unit of analysis: one row per deduplicated ICI-associated FAERS case.

This file aggregates one-to-many FAERS tables to case level. It is suitable for descriptive analysis and later prediction of serious reported outcomes among reported ICI adverse-event cases.

Important derived fields:

- `ici_agents`: semicolon-separated ICI agents reported in the case
- `ici_classes`: semicolon-separated ICI classes
- `n_reactions`: number of distinct reported PTs
- `reaction_terms`: aggregated PT list
- `serious_outcome`: any serious-outcome component code among DE, LT, HO, DS, CA, RI
- `death`, `hospitalization`, `life_threatening`: outcome-specific flags

This file should not be interpreted as an exposed-population incidence dataset.
