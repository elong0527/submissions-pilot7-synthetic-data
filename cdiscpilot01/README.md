# cdiscpilot01

Public CDISC SDTM/ADaM Pilot Project, assessed with the released **R yamaa
0.5.0** package. See [the assessment report](log/yamaa-assessment-report.md)
and [R execution instructions](program/adam/README.md).

- `data/sdtm/`: 22 frozen SDTM Parquet inputs.
- `data/adam/`: ten frozen reference ADaM files and ignored generated
  `<dataset>-yamaa.parquet` candidates.
- `spec/define/`: unchanged original SDTM and ADaM define.xml files.
- `spec/yamaa/`: ten native derivation specifications and `project.yaml`.
- `program/adam/r/`: R runner, independent comparator and synthetic checks.
- `log/yamaa-*`: assessment reports, metrics, inventories and feedback drafts.

The R dry run reproduces every reference data cell. Strict acceptance remains
blocked by missing labels in Parquet saved by R yamaa 0.5.0. Reference equality
also does not establish exhaustive derivation logic coverage: source conflicts
and missing original programs require human review. The historical Python
programs remain available, but are not used by this R assessment.

Source: [CDISC pilot submission](https://github.com/cdisc-org/sdtm-adam-pilot-project/tree/667511d4b183871d74392ba691c935c38d431d39/updated-pilot-submission-package/900172/m5/datasets/cdiscpilot01).
