# Raw FAERS Data

Raw FDA FAERS quarterly zip files are intentionally not tracked in Git.

Download the 2025 ASCII extracts from the FDA FAERS quarterly data page and place them in:

```text
raw/2025/
```

Expected files:

```text
faers_ascii_2025q1.zip
faers_ascii_2025q2.zip
faers_ascii_2025q3.zip
faers_ascii_2025Q4.zip
```

Official source page:

https://www.fda.gov/drugs/fdas-adverse-event-reporting-system-faers/fda-adverse-event-reporting-system-faers-latest-quarterly-data-files

Direct URLs are listed in `metadata/faers_2025_quarters.csv`.

Alternative local input:

```r
Sys.setenv(FAERS_RAW_DIR = "/path/to/faers/2025")
```

Then run:

```bash
Rscript scripts/run_pipeline.R
```
