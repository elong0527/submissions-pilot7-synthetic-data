# Exercise comparison controls in disposable copies, never study output files.
library(arrow)
library(jsonlite)
root <- normalizePath(commandArgs(TRUE)[[1]])
source_scope <- read.csv(file.path(root, 'log/yamaa-scope.csv'))
scope <- source_scope[source_scope$dataset == 'ADSL', ]
results <- list()
for (case in c('positive-control', 'one-cell', 'missing-output', 'duplicate-key',
               'failed-attempt', 'stale-output', 'extra-output', 'edited-spec')) {
  fixture <- tempfile('yamaa-comparison-')
  for (dir in c('data/adam', 'data/sdtm', 'spec/yamaa', 'program/adam/r', 'log'))
    dir.create(file.path(fixture, dir), recursive = TRUE)
  write.csv(scope, file.path(fixture, 'log/yamaa-scope.csv'), row.names = FALSE)
  for (path in c(scope$reference, scope$spec, 'spec/yamaa/project.yaml',
                 paste0('program/adam/r/', c('run.R', 'assessment.R', 'compare.R'))))
    stopifnot(file.copy(file.path(root, path), file.path(fixture, path)))
  started <- Sys.time()
  # An identical independent copy is the comparator's positive control only.
  candidate <- file.path(fixture, scope$candidate)
  stopifnot(file.copy(file.path(root, scope$reference), candidate))
  write.csv(data.frame(dataset = 'ADSL', issues = 0),
            file.path(fixture, 'log/yamaa-run-status.csv'), row.names = FALSE)
  manifest <- list(status = 'success', validation_issues = 0,
    output_count = 1, yamaa_version = '0.5.0', started_epoch = as.numeric(started),
    attempt = case)
  if (case %in% c('one-cell', 'duplicate-key')) {
    frame <- read_parquet(candidate)
    if (case == 'one-cell') frame$AGE[1] <- frame$AGE[1] + 1
    if (case == 'duplicate-key') frame[2, c('STUDYID', 'USUBJID')] <- frame[1, c('STUDYID', 'USUBJID')]
    write_parquet(frame, candidate)
  }
  if (case == 'missing-output') unlink(candidate)
  if (case == 'failed-attempt') manifest$status <- 'failed'
  if (case == 'stale-output') Sys.setFileTime(candidate, started - 60)
  if (case == 'extra-output') file.copy(candidate, file.path(fixture, 'data/adam/extra-yamaa.parquet'))
  if (case == 'edited-spec') Sys.setFileTime(file.path(fixture, scope$spec), started + 60)
  write_json(manifest, file.path(fixture, 'log/yamaa-attempt.json'),
             auto_unbox = TRUE, digits = NA)
  summary_path <- file.path(fixture, 'log/yamaa-comparison-summary.json')
  write_json(list(stale = TRUE), summary_path)
  output <- file.path(fixture, 'log/test.log')
  exit <- system2(file.path(R.home('bin'), 'Rscript'),
    c('--vanilla', shQuote(file.path(fixture, 'program/adam/r/compare.R')),
      shQuote(fixture)), stdout = output, stderr = output)
  summary_path <- file.path(fixture, 'log/yamaa-comparison-summary.json')
  summary <- if (file.exists(summary_path)) read_json(summary_path) else NULL
  passed <- if (case == 'positive-control') exit == 0 && summary$datasets_fully_matching == 1 else exit != 0
  if (case == 'one-cell') passed <- passed && summary$exact_matching_cells == 12191
  if (case == 'missing-output') passed <- passed && summary$datasets_blocked == 1 && summary$total_reference_cells == 12192
  if (case %in% c('duplicate-key', 'failed-attempt', 'stale-output', 'extra-output', 'edited-spec'))
    passed <- passed && !file.exists(summary_path)
  if (!passed) stop(case, ': ', paste(readLines(output), collapse = '\n'))
  results[[case]] <- data.frame(case, passed, exit_status = exit)
}
write.csv(do.call(rbind, results), file.path(root, 'log/yamaa-comparator-checks.csv'), row.names = FALSE)
print(do.call(rbind, results), row.names = FALSE)
