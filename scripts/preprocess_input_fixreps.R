# Preprocess DataViewer fixation reports for combined analysis.

source_dir <- "scripts"
output_dir <- "fixreps"
output_path <- file.path(output_dir, "combined_alex1_done_by_matt_fixrep.csv")
reference_fixrep_path <- file.path(output_dir, "fixrep_alex1_offset_faces_nice_names.csv")

source_files <- list.files(
  source_dir,
  pattern = "^[a-z]+_deployed_DViewer_Matt_Fix_Rep\\.txt$",
  full.names = TRUE
)

if (length(source_files) == 0) {
  stop("No source fixation reports found in ", source_dir, call. = FALSE)
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

col_if_present <- function(data, cols) {
  cols[cols %in% names(data)]
}

read_reference_fixrep_cols <- function(path) {
  if (!file.exists(path)) {
    warning("Reference fixation report not found: ", path, call. = FALSE)
    return(character())
  }

  names(read.csv(
    path,
    nrows = 0,
    check.names = FALSE,
    stringsAsFactors = FALSE
  ))
}

build_reduced_fixrep <- function(data, reference_cols) {
  fixrep_lookup_cols <- c(
    "RECORDING_SESSION_LABEL",
    "face",
    "file",
    "which_face",
    "file_b1",
    "FACE",
    "TRIAL_INDEX",
    "condition",
    "position",
    "CURRENT_FIX_X",
    "CURRENT_FIX_Y",
    "CURRENT_FIX_DURATION",
    "image_location_x",
    "image_x",
    "image_location_y",
    "image_y",
    "location_b1",
    "face_location"
  )

  unique_pp_cols <- c(
    "unique_pp",
    "source_id",
    "source_file",
    "RECORDING_SESSION_LABEL"
  )

  dataviewer_event_cols <- grep(
    "EVENT_MATCHED",
    names(data),
    value = TRUE
  )

  response_cols <- c(
    "b1_KEYPRESS_TIME",
    "b1_KEY_INPUT",
    "b1_RT",
    "correct_b1"
  )

  selected_cols <- unique(c(
    unique_pp_cols,
    reference_cols,
    fixrep_lookup_cols,
    dataviewer_event_cols,
    response_cols
  ))

  data[col_if_present(data, selected_cols)]
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

reference_cols <- read_reference_fixrep_cols(reference_fixrep_path)
combined <- build_reduced_fixrep(combined, reference_cols)

write.csv(combined, output_path, row.names = FALSE, na = "")

message(
  "Wrote ",
  nrow(combined),
  " rows and ",
  ncol(combined),
  " columns to ",
  output_path
)
