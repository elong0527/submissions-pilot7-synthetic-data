# Pilot 6 ADaM derivations

See the [study README](../../README.md) for the initial ADSL specification,
the missing production reference data, and the seven remaining datasets.

`python/run.py` runs `../../spec/yamaa/project.yaml` with the pinned yamaa
1.0 engine and saves `../../data/adam/adsl-yamaa.parquet`. It resolves the
study from its own location, so it works from any working directory.

Use the repository validation command to build and record the unverified
status explicitly:

```bash
python .github/scripts/validate_yamaa.py submission-pilot6
```
