# Execution bookkeeping only; all data derivations remain in YAML.
begin_attempt <- function(root) {
  scope <- read.csv(file.path(root, "log/yamaa-scope.csv"))
  stopifnot(nrow(scope) == 10L, !anyDuplicated(scope$candidate),
    all(grepl("^data/adam/[a-z0-9]+-yamaa[.]parquet$", scope$candidate)))
  started <- Sys.time()
  attempt <- format(started, "%Y%m%dT%H%M%OS6", tz = "UTC")
  archive <- file.path(Sys.getenv("YAMAA_ARCHIVE_ROOT",
    file.path(dirname(root), paste0(".", basename(root), "-yamaa-attempts"))),
                       paste0("yamaa-", attempt), basename(root))
  paths <- c(scope$candidate, file.path("log", list.files(
    file.path(root, "log"), "^yamaa-", full.names = FALSE)))
  for (relative in paths) {
    path <- file.path(root, relative)
    if (file.exists(path)) {
      destination <- file.path(archive, relative)
      dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
      stopifnot(file.copy(path, destination))
    }
  }
  unlink(file.path(root, scope$candidate))
  unlink(file.path(root, "log/yamaa-failure.rds"))
  context <- list(root = root, started = started, attempt = attempt, scope = scope)
  finish_attempt(context, "running")
  cat("Attempt:", attempt, "UTC; previous evidence archived at", archive, "\n")
  context
}
finish_attempt <- function(context, status, runs = NULL) {
  ended <- Sys.time()
  manifest <- list(attempt = context$attempt, status = status,
    started_utc = format(context$started, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    ended_utc = format(ended, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    started_epoch = as.numeric(context$started),
    elapsed_seconds = as.numeric(difftime(ended, context$started, units = "secs")),
    r_version = as.character(getRversion()), yamaa_version = "0.5.0",
    output_count = if (is.null(runs)) 0L else length(runs$names),
    validation_issues = if (is.null(runs)) NA_integer_ else nrow(runs$issues))
  jsonlite::write_json(manifest, file.path(context$root, "log/yamaa-attempt.json"),
                       pretty = TRUE, auto_unbox = TRUE, na = "null")
  if (!is.null(runs)) {
    results <- do.call(rbind, lapply(runs$names, function(name) data.frame(
      dataset = name, issues = nrow(runs[[name]]$issues),
      rows = nrow(runs[[name]]$output), columns = ncol(runs[[name]]$output))))
    write.csv(results, file.path(context$root, "log/yamaa-run-status.csv"), row.names = FALSE)
    cat("Elapsed seconds:", manifest$elapsed_seconds, "\n")
    print(results, row.names = FALSE)
  }
}
