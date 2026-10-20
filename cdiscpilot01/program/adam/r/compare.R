# Compare every frozen target using independent Arrow reads and explicit keys.
suppressPackageStartupMessages(library(arrow))
suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(jsonlite))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
root <- normalizePath(args[[1]], mustWork = TRUE)
log_dir <- file.path(root, 'log')
# A failed comparison must not leave a previous successful summary in place.
unlink(file.path(log_dir, c('yamaa-comparison-summary.json',
  'yamaa-dataset-metrics.csv', 'yamaa-cell-mismatches.csv',
  'yamaa-metadata-mismatches.csv')))
scope <- read.csv(file.path(log_dir, 'yamaa-scope.csv'), stringsAsFactors = FALSE)
manifest <- read_json(file.path(log_dir, 'yamaa-attempt.json'), simplifyVector = TRUE)
status <- read.csv(file.path(log_dir, 'yamaa-run-status.csv'))
stopifnot(identical(manifest$status, 'success'), manifest$validation_issues == 0L,
  manifest$output_count == nrow(scope), setequal(status$dataset, scope$dataset),
  all(status$issues == 0L), manifest$yamaa_version == '0.5.0')
start_epoch <- manifest$started_epoch
inputs <- c(file.path(root, scope$spec),
  list.files(file.path(root, 'data/sdtm'), '[.]parquet$', full.names = TRUE),
  list.files(file.path(root, 'program/adam/r'), '[.]R$', full.names = TRUE),
  file.path(root, 'log/yamaa-scope.csv'), file.path(root, 'spec/yamaa/project.yaml'))
# Reject outputs from failed/old attempts and edits made after this attempt began.
stopifnot(all(file.exists(inputs)), all(as.numeric(file.info(inputs)$mtime) <= start_epoch))
for (path in file.path(root, scope$candidate)) {
  if (file.exists(path) && as.numeric(file.info(path)$mtime) < start_epoch)
    stop('Stale candidate: ', basename(path))
}
extras <- setdiff(list.files(file.path(root, 'data/adam'), '-yamaa[.]parquet$'),
                 basename(scope$candidate))
if (length(extras)) stop('Unscoped generated datasets: ', paste(extras, collapse = ', '))

key_values <- function(frame, columns) {
  parts <- lapply(frame[columns], function(x) {
    value <- if (inherits(x, 'Date')) format(x, '%Y-%m-%d') else if (is.numeric(x)) trimws(formatC(x, digits = 17, format = 'g')) else as.character(x)
    ifelse(is.na(x), 'N', paste0(nchar(value, type = 'bytes'), ':', value))
  })
  do.call(paste, c(parts, sep = '|'))
}
logical_type <- function(field) {
  type <- field$type$ToString()
  if (type %in% c('string', 'large_string')) 'text' else type
}
format_value <- function(value) {
  ifelse(is.na(value), '<null>', if (is.numeric(value)) format(value, digits = 17, trim = TRUE) else as.character(value))
}
metrics <- list(); details <- list(); schema_details <- list()
started <- Sys.time()
for (index in seq_len(nrow(scope))) {
  item <- scope[index, ]
  before <- Sys.time()
  expected_table <- read_parquet(file.path(root, item$reference), as_data_frame = FALSE)
  expected <- as.data.frame(expected_table)
  total_cells <- nrow(expected) * ncol(expected)
  metric <- data.frame(dataset = item$dataset, status = 'blocked', reference_rows = nrow(expected), generated_rows = NA_integer_, reference_columns = ncol(expected), generated_columns = NA_integer_, matched_columns = 0L, exact_data_columns = 0L, exact_cells = 0, total_cells = total_cells, tolerance_only_cells = 0, outside_tolerance_cells = 0, max_absolute_numeric_difference = 0, extra_cells = 0, missing_rows = nrow(expected), extra_rows = 0L, missing_columns = ncol(expected), extra_columns = 0L, logical_type_differences = 0L, spec_label_differences = 0L, serialized_label_differences = 0L, required_order_matches = FALSE, exact_data_match = FALSE, dataset_fully_matches = FALSE, comparison_seconds = 0)
  candidate <- file.path(root, item$candidate)
  spec_path <- file.path(root, item$spec)
  if (file.exists(candidate) && file.exists(spec_path)) {
    generated_table <- read_parquet(candidate, as_data_frame = FALSE)
    generated <- as.data.frame(generated_table)
    spec <- read_yaml(spec_path)
    labels <- setNames(lapply(spec$columns, function(column) column$label), vapply(spec$columns, function(column) column$name, character(1)))
    key <- strsplit(item$keys, ';', fixed = TRUE)[[1]]
    stopifnot(all(key %in% names(expected)), all(key %in% names(generated)))
    expected_key <- key_values(expected, key); generated_key <- key_values(generated, key)
    if (anyDuplicated(expected_key) || anyDuplicated(generated_key)) stop('Nonunique comparison key for ', item$dataset)
    matched <- match(expected_key, generated_key)
    aligned <- generated[matched, , drop = FALSE]
    metric$generated_rows <- nrow(generated); metric$generated_columns <- ncol(generated)
    metric$missing_rows <- sum(is.na(matched)); metric$extra_rows <- sum(!generated_key %in% expected_key)
    metric$missing_columns <- sum(!names(expected) %in% names(generated)); metric$extra_columns <- sum(!names(generated) %in% names(expected))
    metric$extra_cells <- metric$extra_rows * ncol(generated) + sum(!is.na(matched)) * metric$extra_columns
    metric$required_order_matches <- identical(expected_key, generated_key) && identical(names(expected), names(generated))
    for (column in intersect(names(expected), names(generated))) {
      e <- expected[[column]]; g <- aligned[[column]]
      missing_e <- is.na(e); missing_g <- is.na(g)
      equal <- (missing_e & missing_g) | (!missing_e & !missing_g & e == g)
      equal[is.na(equal)] <- FALSE
      equal[is.na(matched)] <- FALSE
      tolerance <- rep(FALSE, length(e)); outside <- rep(FALSE, length(e))
      if (is.double(e) && !inherits(e, c('Date', 'POSIXt')) && is.numeric(g)) {
        finite <- is.finite(e) & is.finite(g) & !is.na(matched)
        tolerance[finite] <- !equal[finite] & abs(e[finite] - g[finite]) <= 1e-10
        outside[finite] <- !equal[finite] & !tolerance[finite]
        if (any(finite)) metric$max_absolute_numeric_difference <- max(metric$max_absolute_numeric_difference, abs(e[finite] - g[finite]))
      }
      ef <- expected_table$schema$fields[[match(column, names(expected))]]
      gf <- generated_table$schema$fields[[match(column, names(generated))]]
      type_matches <- identical(logical_type(ef), logical_type(gf))
      expected_label <- ef$metadata[['yamaa:label']]
      spec_label_matches <- identical(expected_label, labels[[column]])
      serialized_label_matches <- identical(expected_label, gf$metadata[['yamaa:label']])
      metric$logical_type_differences <- metric$logical_type_differences + !type_matches
      metric$spec_label_differences <- metric$spec_label_differences + !spec_label_matches
      metric$serialized_label_differences <- metric$serialized_label_differences + !serialized_label_matches
      metric$exact_cells <- metric$exact_cells + sum(equal)
      metric$tolerance_only_cells <- metric$tolerance_only_cells + sum(tolerance)
      metric$outside_tolerance_cells <- metric$outside_tolerance_cells + sum(outside)
      metric$exact_data_columns <- metric$exact_data_columns + (all(equal) && type_matches)
      metric$matched_columns <- metric$matched_columns + (all(equal) && type_matches && spec_label_matches && serialized_label_matches)
      if (!type_matches || !spec_label_matches || !serialized_label_matches) {
        schema_details[[length(schema_details) + 1L]] <- data.frame(dataset = item$dataset, column, reference_type = ef$type$ToString(), generated_type = gf$type$ToString(), reference_label = if (is.null(expected_label)) '' else expected_label, spec_label = if (is.null(labels[[column]])) '' else labels[[column]], generated_label = if (is.null(gf$metadata[['yamaa:label']])) '' else gf$metadata[['yamaa:label']], type_matches, spec_label_matches, serialized_label_matches)
      }
      bad <- which(!equal)
      if (length(bad)) {
        # Retain all differences; record identities are the reviewed key values.
        details[[length(details) + 1L]] <- data.frame(dataset = item$dataset, record_key = expected_key[bad], variable = column, reference = format_value(e[bad]), generated = format_value(g[bad]), within_numeric_tolerance = tolerance[bad])
      }
    }
    metric$exact_data_match <- metric$exact_cells == total_cells && metric$missing_rows == 0L && metric$extra_rows == 0L && metric$missing_columns == 0L && metric$extra_columns == 0L && metric$required_order_matches && metric$logical_type_differences == 0L
    metric$dataset_fully_matches <- metric$exact_data_match && metric$spec_label_differences == 0L && metric$serialized_label_differences == 0L
    metric$status <- if (metric$dataset_fully_matches) 'matched' else 'mismatched'
  }
  metric$comparison_seconds <- as.numeric(difftime(Sys.time(), before, units = 'secs'))
  metrics[[index]] <- metric
  cat(item$dataset, metric$status, sprintf('%.0f/%.0f exact cells; %.0f within tolerance only; %d serialized label differences\n', metric$exact_cells, total_cells, metric$tolerance_only_cells, metric$serialized_label_differences))
}
result <- do.call(rbind, metrics)
write.csv(result, file.path(log_dir, 'yamaa-dataset-metrics.csv'), row.names = FALSE)
if (length(details)) write.csv(do.call(rbind, details), file.path(log_dir, 'yamaa-cell-mismatches.csv'), row.names = FALSE) else writeLines('dataset,record_key,variable,reference,generated,within_numeric_tolerance', file.path(log_dir, 'yamaa-cell-mismatches.csv'))
if (length(schema_details)) write.csv(do.call(rbind, schema_details), file.path(log_dir, 'yamaa-metadata-mismatches.csv'), row.names = FALSE)
summary <- list(attempt = manifest$attempt, datasets_in_scope = nrow(scope), datasets_fully_matching = sum(result$dataset_fully_matches), datasets_exact_data_matching = sum(result$exact_data_match), datasets_blocked = sum(result$status == 'blocked'), exact_matching_cells = sum(result$exact_cells), total_reference_cells = sum(result$total_cells), tolerance_only_cells = sum(result$tolerance_only_cells), outside_tolerance_numeric_cells = sum(result$outside_tolerance_cells), max_absolute_numeric_difference = max(result$max_absolute_numeric_difference), extra_cells = sum(result$extra_cells), serialized_label_differences = sum(result$serialized_label_differences), comparison_seconds = as.numeric(difftime(Sys.time(), started, units = 'secs')))
write_json(summary, file.path(log_dir, 'yamaa-comparison-summary.json'), pretty = TRUE, auto_unbox = TRUE, na = 'null')
if (!all(result$dataset_fully_matches)) quit(status = 1L)
