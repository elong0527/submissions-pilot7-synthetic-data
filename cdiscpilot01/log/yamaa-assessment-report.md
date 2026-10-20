# R yamaa 0.5.0: public cdiscpilot01 dry run

**Ready for human review. Strict acceptance fails on saved labels.** All ten
ADaM candidates generate with zero native issues and reproduce all 9,119,605
reference cells exactly. The package omits 415 declared column labels when
saving Parquet, so fully matching datasets remain **0/10**. No labels or data
were patched after generation. Original code is incomplete and source
metadata conflicts remain: exhaustive logic equivalence is not established.

## Scope and reproducible environment

Study inputs/reference: RConsortium/submissions-pilot7-synthetic-data at
`151a49720906e38d78e5d37b033f272d77c2bfa9`, study `cdiscpilot01`.
All 22 SDTM and ten reference ADaM Parquet files and original define.xml
files remain unchanged. An explicit git comparison against that base passed.
Reference ADaM values are used only for independent comparison; candidate
YAML consumes SDTM and generated ADaM dependencies. New output structures
and labels were transcribed from reference metadata; their values were not
used as derivation inputs. Existing and historical public specifications
and SAP/define evidence supplied the algorithms.

The released `yamaa_0.5.0.tar.gz` R source archive compiled successfully in
a fresh R 4.5.3 library on Debian 13, x86_64, using Rust/Cargo 1.99.1 and
GCC 14.2.0. The bundled Rust build reported 244 seconds. Independent readers:
R Arrow 25.0.0, yaml 2.3.12, jsonlite 2.0.0; metadata inventory used xml2 1.6.0.
An initial reader-environment provisioning attempt for R 4.6.1 failed due
to dependency availability; R 4.5.3 was then provisioned and yamaa rebuilt.
Earlier eight-dataset R 4.6.1 probes are identified in the attempt ledger.
Only the final R 4.5.3 runs qualify this complete study. No Python yamaa
runtime or historical Python study runner was used for this assessment.

See [resource availability](yamaa-resource-availability.csv),
[dataset inventory](yamaa-dataset-inventory.csv), [frozen scope](yamaa-scope.csv)
and [R instructions](../program/adam/README.md).

## Overall metrics

| Metric | Result |
| --- | ---: |
| Frozen target datasets | 10 |
| Generated datasets with zero engine issues | 10/10 |
| Exact data, logical types, shape and required order | 10/10 |
| Fully matching datasets, including saved metadata | 0/10 |
| Strict status: matched / mismatched / blocked / not compared | 0 / 10 / 0 / 0 |
| Exact reference cells | 9,119,605/9,119,605 (100%) |
| Tolerance-only cells (absolute 1e-10) | 0 |
| Maximum absolute numeric difference | 0 |
| Extra cells, rows, columns or datasets | 0 |
| Exact data columns / total columns | 415/415 |
| Declared labels matching reference | 415/415 |
| Saved labels matching reference | 0/415 |
| Strict fully matching columns | 0/415 |
| Final preflight, generation and saving | 22.834 seconds |
| Final independent comparison | 10.636 seconds |
| Recorded project attempts / failures | 12 / 2 |
| Job wall time through report freeze | 37.5 minutes |
| AI input / cached input / output tokens | unavailable / unavailable / unavailable |
| AI, compute, license and total USD spent | unavailable |
| Active programmer / reviewer hours | not measured / review pending |

Clock: **2026-10-20T19:57:07Z to 2026-10-20T20:34:38Z**, UTC.
The interface exposes no per-job token/billing counters, applicable rates or
compute/license charges. These costs were not measured and are not zero.
No estimate is substituted for an invoice. Phase timings are limited to
recorded measurements; overlapping work need not sum to job wall time.
The ledger counts recorded project attempts, including incomplete-scope
diagnostic probes, rather than claiming to count every exploratory R call.
See [job metrics](yamaa-job-metrics.json), [attempt ledger](yamaa-attempt-ledger.csv),
[dataset metrics](yamaa-dataset-metrics.csv), [native run status](yamaa-run-status.csv)
and [comparison summary](yamaa-comparison-summary.json).

## Dataset results

| Dataset | Rows | Columns | Exact cells | Strict full match |
| --- | ---: | ---: | ---: | --- |
| ADAE | 1,191 | 55 | 65,505/65,505 | No: saved labels |
| ADLBC | 74,264 | 46 | 3,416,144/3,416,144 | No: saved labels |
| ADLBH | 49,932 | 46 | 2,296,872/2,296,872 | No: saved labels |
| ADLBHY | 9,954 | 43 | 428,022/428,022 | No: saved labels |
| ADQSADAS | 12,463 | 40 | 498,520/498,520 | No: saved labels |
| ADQSCIBC | 730 | 36 | 26,280/26,280 | No: saved labels |
| ADQSNPIX | 31,140 | 41 | 1,276,740/1,276,740 | No: saved labels |
| ADSL | 254 | 48 | 12,192/12,192 | No: saved labels |
| ADTTE | 254 | 26 | 6,604/6,604 | No: saved labels |
| ADVS | 32,139 | 34 | 1,092,726/1,092,726 | No: saved labels |

The empty [cell mismatch file](yamaa-cell-mismatches.csv) is intentional.
All 415 saved-label differences remain in [metadata mismatches](yamaa-metadata-mismatches.csv).
Generation exits 0. Strict comparison exits 1 and retains this failed result.

## Changes and source discrepancies

The intake had eight active YAML files; seven failed initial R 0.5.0 checks
with 62 issues. Syntax was adapted to the released operations, explicit null
handlers and supported compute expressions, and producer schema links were
made explicit. See the retained [initial check](yamaa-initial-check.log).
One native specification each was added for ADQSADAS and ADQSCIBC; all data
derivation stays in YAML. R scripts provide orchestration, measurement and
independent verification. Checks reject empty analyses, reversed available
treatment dates, and efficacy membership outside ITT where those flags exist.

ADAS/CIBC algorithms were reconstructed from Pilot 7 historical specs at
`086abc2c5ea526b0bce477ea7633932af3ca02cd`, original define metadata, and the
[public CSR SAP Appendix 9](https://github.com/cdisc-org/sdtm-adam-pilot-project/blob/667511d4b183871d74392ba691c935c38d431d39/updated-pilot-submission-package/900172/m5/53-clin-stud-rep/535-rep-effic-safety-stud/5351-stud-rep-contr/cdiscpilot01/cdiscpilot01.pdf).
Observed items retain missing scores. Selection uses closest target, with
earlier date then sequence as ties. ADAS unselected total-score records carry
the prior selected score; synthetic empty windows carry latest raw donor
fields. CIBC empty windows carry the latest selected score but latest raw
donor fields. This distinction is covered by independently expected fixtures.

Material source conflicts are retained in [source discrepancies](yamaa-source-discrepancies.csv):

- Public ADAE SAS writes ADUR rather than the current ADURN/ADURU schema,
  and its included setup program is unavailable. No original SAS execution
  or license was available; the frozen reference was not changed.
- Define EFFFL comments name absent ADSL.FASFL; generated ADSL.EFFFL is used.
- ADQSADAS CHG is labelled Baseline Value in define metadata, while the
  reference correctly labels Change from Baseline.
- Value-level ACTOT QSSEQ metadata says to omit postbaseline sequences,
  while reference/historical specs retain source/donor sequences.
- Explicit multiply-before-divide association resolved 768 NPI PCHG
  tolerance-only differences. ADAS requires divide-before-multiply, as its
  historical spec states; using the other association caused 1,101
  tolerance-only differences. No rounding or subject-specific rule was used.
- Original independent executable programs are absent for most targets.
  Existing yamaa specs and output equality cannot replace that evidence.

The [415-variable traceability map](yamaa-traceability.csv) records original
define comments, native implementation location, evidence and review status.
Review is pending throughout. Observed-record comparison covers every output
cell, but exhaustive branch coverage is **not established**. A human must
adjudicate source priority/version conflicts and review unobserved branches
before claiming 100% derivation logic equivalence.

## Verification and review gate

- All ten complete candidates were regenerated twice; every Parquet file
  is byte-identical across the two completed snapshots, with no hashing.
  See [reproducibility](yamaa-reproducibility.csv).
- Invented ADAS/CIBC cases pass for rank, equal-distance ties, window
  boundaries, missing windows, donor versus selected values, missing
  item scores, zero baseline and invalid dates.
- All eight comparator controls pass: a matching positive control, changed
  cell, absent output, duplicate key, failed attempt, stale output, extra
  dataset and edited specification. See [controls](yamaa-comparator-checks.csv).
- The standalone invented-record [label reproducer](../program/adam/r/reproduce-labels.R)
  confirms the saved metadata omission independently of study data.
- Repository structure validation passes with `--strict`: zero errors and
  warnings. All generated current artifacts use Pilot 7 study folders.
- Reference inputs, reference ADaM, defines and historical Python programs
  are unchanged. Native R issue tables are retained locally as RDS; raw
  machine paths and logs are excluded from the public review bundle.

Human review must resolve source discrepancies, review full rule/branch
evidence, decide the saved-label blocker, and obtain actual usage/billing
records if complete cost accounting is required. A future package fix or
explicit metadata publication step must be qualified separately from the
released baseline. This dry run is not a signed study validation.

## Public product feedback

[GitHub-ready feedback drafts](yamaa-public-feedback.md) cover R output labels,
handler authoring, R formatting/diagnostics, and installation prerequisites.
The standalone reproducer uses invented data. The drafts contain no internal
study details and were not posted as issues. A reader can reproduce the
confirmed package limitation without organizational resources.
