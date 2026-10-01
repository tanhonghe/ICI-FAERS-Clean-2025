# Reproducibility

## Rebuild From Raw FAERS

1. Clone this repository.
2. Download the official FDA FAERS 2025 ASCII quarterly zip files.
3. Place them in `raw/2025/`, or set `FAERS_RAW_DIR`.
4. Run:

```bash
Rscript scripts/run_pipeline.R
```

## Expected Data Flow

```text
FDA zip files
  -> raw table inspection
  -> merged quarterly tables
  -> CASEID / CASEVERSION deduplication
  -> ICI dictionary matching
  -> relational clean tables
  -> case-level analysis-ready dataset
  -> QC tables and figures
```

## Generated Results

QC tables:

```text
results/qc/
```

QC figures:

```text
figures/qc/
```

The large intermediate staging directory `data/interim/` is ignored by Git because it is fully reproducible from FDA raw zip files.
