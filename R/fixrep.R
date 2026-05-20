# Fixation report helpers -----

## mini-helpers ----

# Converts text-like numeric columns to numbers while quietly keeping NAs.
to_num <- function(x) {
  suppressWarnings(as.numeric(x))
}

# Converts a column to integer only when every non-missing value is whole.
to_int_if_possible <- function(x) {
  x_num <- suppressWarnings(as.numeric(x))
  
  if (all(!is.na(x_num) | is.na(x)) && all(x_num == floor(x_num), na.rm = TRUE)) {
    as.integer(x_num)
  } else {
    x
  }
}

# Picks the first preferred column name that exists, otherwise falls back to the first column.
choose_col <- function(cols, candidates) {
  hit <- candidates[candidates %in% cols]
  if (length(hit) > 0) hit[1] else cols[1]
}

## format helpers ----

# Formats all-whole numeric columns as integers for cleaner preview tables.
format_table_int <- function(df) {
  if (is.null(df)) return(df)
  
  df <- tibble::as_tibble(df)
  
  df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(\(x) is.numeric(x) && all(x == round(x), na.rm = TRUE)),
        as.integer
      )
    )
}

## constructor helpers ----

# Reads the mapping select inputs and requires each one before standardising.
req_fixrep_map <- function(input) {
  list(
    participant = shiny::req(input$map_participant),
    face        = shiny::req(input$map_face),
    trial       = shiny::req(input$map_trial),
    condition   = shiny::req(input$map_condition),
    fix_x       = shiny::req(input$map_fix_x),
    fix_y       = shiny::req(input$map_fix_y),
    fix_dur     = shiny::req(input$map_fix_dur),
    img_x       = shiny::req(input$map_img_x),
    img_y       = shiny::req(input$map_img_y)
  )
}

# Renames and coerces the uploaded fixation report into the app's standard columns.
standardise_fixrep <- function(raw, map) {
  tibble::tibble(
    SUBJECT   = as.character(raw[[map$participant]]),
    FACE      = as.character(raw[[map$face]]),
    TRIAL_ID  = to_int_if_possible(raw[[map$trial]]),
    CONDITION = raw[[map$condition]],
    IMG_X     = to_num(raw[[map$img_x]]),
    IMG_Y     = to_num(raw[[map$img_y]]),
    FIX_X     = to_num(raw[[map$fix_x]]),
    FIX_Y     = to_num(raw[[map$fix_y]]),
    FIX_DUR   = to_num(raw[[map$fix_dur]]),
    AOI       = "Not assigned"
  )
}

# Builds the column-mapping controls after a fixation report has been uploaded.
make_fixrep_mapping_ui <- function(cols) {
  
  shiny::tagList(
    div(
      class = "fixrep-mapping-title",
      "Choose columns for variables"
    ),
    shiny::selectInput(
      "map_participant",
      "PARTICIPANT",
      choices = cols,
      selected = choose_col(cols, c("RECORDING_SESSION_LABEL"))
    ),
    
    shiny::selectInput(
      "map_face",
      "FACE",
      choices = cols,
      selected = choose_col(cols, c("face", "file", "which_face", "file_b1", "FACE"))
    ),
    
    shiny::selectInput(
      "map_trial",
      "TRIAL",
      choices = cols,
      selected = choose_col(cols, c("TRIAL_INDEX"))
    ),
    
    shiny::selectInput(
      "map_condition",
      "CONDITION",
      choices = cols,
      selected = choose_col(cols, c("condition", "position"))
    ),
    
    shiny::selectInput(
      "map_fix_x",
      "FIXATION X",
      choices = cols,
      selected = choose_col(cols, c("CURRENT_FIX_X"))
    ),
    
    shiny::selectInput(
      "map_fix_y",
      "FIXATION Y",
      choices = cols,
      selected = choose_col(cols, c("CURRENT_FIX_Y"))
    ),
    
    shiny::selectInput(
      "map_fix_dur",
      "FIXATION DURATION",
      choices = cols,
      selected = choose_col(cols, c("CURRENT_FIX_DURATION"))
    ),
    
    shiny::selectInput(
      "map_img_x",
      "IMAGE X",
      choices = cols,
      selected = choose_col(cols, c("image_location_x", "image_x"))
    ),
    
    shiny::selectInput(
      "map_img_y",
      "IMAGE Y",
      choices = cols,
      selected = choose_col(cols, c("image_location_y", "image_y"))
    )
  )
}

## low-level helpers ----

# Reads a fixation report from text or Excel and performs light column cleanup.
read_fixrep <- function(path) {
  stopifnot(length(path) == 1, is.character(path), file.exists(path))
  
  requireNamespace("readr", quietly = TRUE)
  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("stringr", quietly = TRUE)
  requireNamespace("tibble", quietly = TRUE)
  requireNamespace("readxl", quietly = TRUE)
  
  ext <- tolower(tools::file_ext(path))
  
  # Reads CSV/TSV-like files after guessing whether tabs or commas are dominant.
  read_as_text <- function(path) {
    first_line <- readLines(path, n = 1, warn = FALSE)
    
    if (length(first_line) == 0) {
      stop("Fixation report appears to be empty.")
    }
    
    n_tabs <- stringr::str_count(first_line, "\t")
    n_commas <- stringr::str_count(first_line, ",")
    
    delim <- if (n_tabs >= n_commas) "\t" else ","
    
    raw <- readr::read_delim(
      file = path,
      delim = delim,
      col_types = readr::cols(.default = readr::col_character()),
      trim_ws = TRUE,
      progress = FALSE,
      show_col_types = FALSE
    )
    
    list(data = raw, mode = sprintf("delimited text (%s)", if (delim == "\t") "tab" else "comma"))
  }
  
  # Reads the first worksheet from Excel files while preserving columns as text.
  read_as_excel <- function(path) {
    raw <- readxl::read_excel(
      path = path,
      sheet = 1,
      col_types = "text",
      .name_repair = "unique"
    ) |>
      tibble::as_tibble()
    
    list(data = raw, mode = "Excel workbook")
  }
  
  res <- NULL
  
  if (ext %in% c("xls", "xlsx")) {
    res <- tryCatch(
      read_as_excel(path),
      error = function(e) {
        tmp <- read_as_text(path)
        tmp$mode <- paste0(tmp$mode, " (fallback from .", ext, ")")
        tmp
      }
    )
  } else {
    res <- read_as_text(path)
  }
  
  raw <- res$data
  
  nm <- names(raw)
  nm <- stringr::str_replace_all(nm, "\uFEFF", "")
  nm <- stringr::str_trim(nm)
  names(raw) <- nm
  
  location_col <- intersect(c("location_b1", "face_location"), names(raw))[1]
  
  if (!is.na(location_col)) {
    loc <- raw[[location_col]] |>
      as.character() |>
      stringr::str_remove_all("[()]") |>
      stringr::str_split_fixed(",", 2)
    
    raw$image_location_x <- suppressWarnings(as.numeric(stringr::str_trim(loc[, 1])))
    raw$image_location_y <- suppressWarnings(as.numeric(stringr::str_trim(loc[, 2])))
  }
  
  out <- raw
  
  if ("RECORDING_SESSION_LABEL" %in% names(out)) {
    out <- dplyr::mutate(out, RECORDING_SESSION_LABEL = suppressWarnings(as.integer(.data$RECORDING_SESSION_LABEL)))
  }
  if ("TRIAL_INDEX" %in% names(out)) {
    out <- dplyr::mutate(out, TRIAL_INDEX = suppressWarnings(as.integer(.data$TRIAL_INDEX)))
  }
  if ("CURRENT_FIX_INDEX" %in% names(out)) {
    out <- dplyr::mutate(out, CURRENT_FIX_INDEX = suppressWarnings(as.integer(.data$CURRENT_FIX_INDEX)))
  }
  if ("CURRENT_FIX_X" %in% names(out)) {
    out <- dplyr::mutate(out, CURRENT_FIX_X = suppressWarnings(as.numeric(.data$CURRENT_FIX_X)))
  }
  if ("CURRENT_FIX_Y" %in% names(out)) {
    out <- dplyr::mutate(out, CURRENT_FIX_Y = suppressWarnings(as.numeric(.data$CURRENT_FIX_Y)))
  }
  if ("CURRENT_FIX_DURATION" %in% names(out)) {
    out <- dplyr::mutate(out, CURRENT_FIX_DURATION = suppressWarnings(as.numeric(.data$CURRENT_FIX_DURATION)))
  }
  if (all(c("CURRENT_FIX_X", "CURRENT_FIX_Y") %in% names(out))) {
    out <- dplyr::mutate(out, FIX_X = .data$CURRENT_FIX_X, FIX_Y = .data$CURRENT_FIX_Y)
  }
  if ("CURRENT_FIX_DURATION" %in% names(out)) {
    out <- dplyr::mutate(out, FIX_DUR = .data$CURRENT_FIX_DURATION)
  }
  out <- tibble::as_tibble(out)
  attr(out, "read_mode") <- res$mode
  out
}
