# Pilot 1 ADaM derivations in R

Run from the `cdiscpilot01` study root. Use R >= 4.4, Rust/Cargo >= 1.82 and
a C toolchain. This assessment compiled the released source archive with
R 4.5.3 and Rust/Cargo 1.99.1 on Debian 13; it did not install a Python yamaa
package or execute the historical Python study runner.

Download `yamaa_0.5.0.tar.gz` from the
[0.5.0 release](https://github.com/elong0527/yamaa/releases/tag/yamaa-v0.5.0)
or an approved mirror. In R, using a writable library:

```r
install.packages("yamaa_0.5.0.tar.gz", repos = NULL, type = "source")
install.packages(c("arrow", "yaml", "jsonlite"))
library(yamaa)
stopifnot(as.character(packageVersion("yamaa")) == "0.5.0")
```

Configure `R_LIBS_USER` if needed so subsequent `Rscript --vanilla` sessions
use the same library. Independent comparison was tested with arrow 25.0.0,
yaml 2.3.12 and jsonlite 2.0.0; package versions are recorded in
`log/yamaa-r-packages.csv`. Installing Arrow may need platform prerequisites.
An attempt to use the available R 4.6.1 environment failed to provision its
reader dependencies; the complete qualification used a fresh R 4.5.3 library.

```bash
Rscript --vanilla program/adam/r/reproduce-labels.R
Rscript --vanilla program/adam/r/qualify.R . > log/yamaa-qualification.log 2>&1
Rscript --vanilla program/adam/r/check-comparator.R . > log/yamaa-comparator-checks.log 2>&1
attempt=$(date -u +%Y%m%dT%H%M%SZ)
Rscript --vanilla program/adam/r/run.R . > "log/yamaa-run-${attempt}.log" 2>&1
Rscript --vanilla program/adam/r/compare.R . > "log/yamaa-compare-${attempt}.log" 2>&1
```

`run.R` is 25 lines. It calls only the installed R package for checking,
generation and saving; `assessment.R` records attempts and archives previous
candidates and assessment logs before clearing only the ten generated targets. By default the
archive is the ignored repository-level `.cdiscpilot01-yamaa-attempts/` folder.
Set `YAMAA_ARCHIVE_ROOT` to a controlled persistent location to override it.
Archives retain the study layout. Current candidates remain in `data/adam/`.
The runtime writes detailed native issue/report RDS files locally; these
machine-readable diagnostics are ignored by git. Inspect them with `readRDS()`.

`project.yaml` links ADSL to its consumers, ADAE to ADTTE, and ADLBC to ADLBHY.
Every ADaM value is derived in native YAML. R handles orchestration,
measurement and independent comparison. The generator reads SDTM and its
own generated dependencies; it never reads reference ADaM values.

The frozen scope is `log/yamaa-scope.csv`, including the two previously
missing specifications ADQSADAS and ADQSCIBC. ADQSNPIX retains its upstream
filename spelling `adqsnipx.yaml` / `adqsnipx-yamaa.parquet`; the reference
filename is `adqsnpix.parquet`. This mapping is explicit in scope.

The comparator reads every saved column/cell with R Arrow, aligns by reviewed
unique keys, and checks required physical row and column order separately.
It treats Arrow string and large_string as the same logical text type.
Null and empty text differ. Exact numeric equality and differences within
absolute tolerance `1e-10` are reported separately. Zero engine issues,
a successful current attempt, current inputs/specifications, and no stale
or unscoped generated files are required. A missing output keeps its full
reference denominator and is blocked.

**Expected current exits:** generation exits 0; strict comparison exits 1.
All 9,119,605 reference cells match exactly and all ten data structures/orders
match. All 415 declared YAML labels match, but R 0.5.0 omits these labels in
saved Parquet. Strict full matching therefore remains 0/10. The standalone
`reproduce-labels.R` confirms this behavior on one invented record; it exits
0 when the reported omission is reproduced. It must be revisited for a
future package version. No post-processing repairs or hides this limitation.

`qualify.R` uses invented records to check questionnaire visit selection,
equal-distance ties, boundaries, carry-forward scores/donor fields, missing
scores, zero baseline and invalid dates. `check-comparator.R` uses disposable
copies for positive/negative comparison controls, including a deliberately
changed cell, duplicate key, missing/stale output and failed attempt. Those
copies are never used as derivation inputs or copied back to study outputs.
`reproduce.R . <previous-archived-study-root>` compares completed output
snapshots byte for byte without hashing.

The [assessment report](../../log/yamaa-assessment-report.md) records source
conflicts, evidence limits, time/cost availability and the human review gate.
