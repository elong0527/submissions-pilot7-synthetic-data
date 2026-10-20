# Public feedback drafts: R yamaa 0.5.0

These drafts use invented examples and public package behavior. They contain
no organizational study data, internal paths, source programs, specifications,
or identifying records. They have not been posted as issues. The public study
assessment and its discrepancies are separate evidence.

## Engine/output: preserve declared labels in saved R Parquet

**Observed:** a valid specification declares `label: Unique Subject Identifier`.
Checking, running and saving succeed with zero issues. Independent R Arrow
reads the expected record but finds no `yamaa:label` field metadata.

**Expected:** preserve the declared label in the saved schema, or document an
explicitly supported metadata publication step. A matching declaration alone
cannot prove metadata fidelity.

**Reproduce:** install released R yamaa 0.5.0 and R Arrow; run
[`reproduce-labels.R`](../program/adam/r/reproduce-labels.R). It creates a
single invented `TEST-1` record and a temporary specification. The script is
standalone and needs no study files. The observed saved label is `NULL`.
Tested on R 4.5.3, Debian 13, Arrow 25.0.0. Root cause is not established.

**Suggested improvement:** preserve supported declared field metadata through
R saving and qualify it with an independent Parquet reader. No workaround was
applied to the baseline output. A future-version test must be reported as a
separate experiment.

## Specification schema/authoring: make handler absence explicit

**Documented behavior:** `invalid: null` means no authored handler;
`invalid: {literal: null}` explicitly returns a missing value. These are easy
to confuse when adapting an existing specification.

**Invented example:** a date source contains an empty string. An author intends
`invalid: null` to produce a missing date but retains default error behavior.
The explicit literal handler produces the intended missing value.

**Suggested improvement:** add this distinction to R authoring examples and
consider a targeted authoring hint for a bare-null handler. This is a usability
request, not a claim that the current schema violates its contract.

## R user interface: expose formatting and phase-planning guidance

**Observed:** R 0.5.0 provides check/resolve/run/save, but no exported style
checker. Static checking also does not guarantee runtime phase planning will
succeed. For example, a grouped filter must read completed unqualified row
columns; a qualified lookup reference in that filter can fail during running.

**Suggested improvement:** provide an R-accessible style review tool or clearly
scoped checklist, make the static/runtime boundary visible in package help,
and show a minimal grouped-filter example using a row-derived helper. Preserve
a useful condition message even when an error's issue table is empty.
No claim of a new engine defect or synthetic performance regression is made.

## Installation: document independent comparison dependencies

**Observed:** compiling the released source requires the R and Rust/C toolchains.
Independent validation additionally needs format readers, such as R Arrow;
these are separate prerequisites. A fresh environment can successfully install
yamaa while lacking compatible reader packages.

**Suggested improvement:** add an R study-assessment prerequisite example with
separate runtime and comparison dependencies, writable-library configuration,
and a saved-output smoke check. This is an onboarding request.
