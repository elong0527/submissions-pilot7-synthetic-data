# Standalone public reproducer; only invented data and local temporary files.
library(yamaa)
library(arrow)
stopifnot(as.character(packageVersion('yamaa')) == '0.5.0')
fixture <- tempfile('yamaa-label-'); dir.create(fixture)
write_parquet(data.frame(USUBJID = 'TEST-1'), file.path(fixture, 'input.parquet'))
writeLines(c('schema_version: "1.0"', 'domain: TEST', 'keys: [USUBJID]',
  'input:', '  SOURCE: input.parquet',
  'output:', '  path: output.parquet', '  columns: [USUBJID]', 'columns:', '  - name: USUBJID',
  '    type: str', '    label: Unique Subject Identifier',
  'rows:', '  - id: observed', '    dataset: SOURCE',
  '    derivations:', '      USUBJID: SOURCE.USUBJID'), file.path(fixture, 'spec.yaml'))
spec <- yamaa_spec(file.path(fixture, 'spec.yaml'))
checked <- spec$check(); stopifnot(nrow(checked$issues) == 0L)
result <- spec$run(); stopifnot(nrow(result$issues) == 0L); result$save()
table <- read_parquet(file.path(fixture, 'output.parquet'), as_data_frame = FALSE)
stopifnot(identical(table$USUBJID$as_vector(), 'TEST-1'))
label <- table$schema$fields[[1]]$metadata[['yamaa:label']]
cat('Declared label: Unique Subject Identifier\nSaved yamaa:label:')
print(label)
stopifnot(is.null(label)) # Confirms the reported 0.5.0 limitation.
