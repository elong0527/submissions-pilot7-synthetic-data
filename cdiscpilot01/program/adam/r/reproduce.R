# Compare two completed candidate snapshots byte for byte, with no hashing.
args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
roots <- lapply(args, normalizePath, mustWork = TRUE)
scope <- read.csv(file.path(roots[[1]], 'log/yamaa-scope.csv'))
results <- lapply(scope$candidate, function(relative) {
  paths <- vapply(roots, file.path, character(1), relative)
  stopifnot(all(file.exists(paths)))
  sizes <- file.info(paths)$size
  bytes <- lapply(seq_along(paths), function(i) readBin(paths[[i]], 'raw', n = sizes[[i]]))
  data.frame(candidate = relative, bytes = sizes[[1]], byte_identical = identical(bytes[[1]], bytes[[2]]))
})
result <- do.call(rbind, results)
write.csv(result, file.path(roots[[1]], 'log/yamaa-reproducibility.csv'), row.names = FALSE)
print(result, row.names = FALSE)
stopifnot(all(result$byte_identical))
