# Preprocess DataViewer fixation reports for combined analysis.

input_dir <- "fixreps"
output_path <- file.path(input_dir, "combined_alex1_done_by_matt_fixrep.txt")

source_files <- list.files(
  input_dir,
  pattern = "^[a-z]+_deployed_DViewer_Matt_Fix_Rep\\.txt$",
  full.names = TRUE
)

if (length(source_files) == 0) {
  stop("No source fixation reports found in ", input_dir, call. = FALSE)
}

source_files <- sort(source_files)

read_source_fixrep <- function(path) {
  source_file <- basename(path)
  source_id <- sub("_DViewer_Matt_Fix_Rep\\.txt$", "", source_file)

  fixrep <- read.delim(
    path,
    sep = "\t",
    header = TRUE,
    quote = "\"",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    colClasses = "character"
  )

  fixrep$source_file <- source_file
  fixrep$source_id <- source_id
  fixrep$unique_pp <- paste(fixrep$RECORDING_SESSION_LABEL, source_id, sep = "_")

  fixrep
}

fixreps <- lapply(source_files, read_source_fixrep)

if (requireNamespace("dplyr", quietly = TRUE)) {
  combined <- dplyr::bind_rows(fixreps)
} else {
  all_cols <- unique(unlist(lapply(fixreps, names), use.names = FALSE))
  fixreps <- lapply(fixreps, function(x) {
    missing_cols <- setdiff(all_cols, names(x))
    x[missing_cols] <- NA_character_
    x[all_cols]
  })
  combined <- do.call(rbind, fixreps)
}

write.table(
  combined,
  file = output_path,
  sep = "\t",
  quote = TRUE,
  row.names = FALSE,
  na = ""
)

message(
  "Wrote ",
  nrow(combined),
  " rows and ",
  ncol(combined),
  " columns to ",
  output_path
)
