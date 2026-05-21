# Fixation report helpers -----

library(tibble)

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

screen_central_choice <- "<SCREEN CENTRAL, AUTO CALCULATE>"

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

# Coerces categorical-looking character columns for a more useful summary().
format_fixrep_for_summary <- function(df, max_levels = 50, max_unique_fraction = 0.25) {
  if (is.null(df)) return(df)

  df <- tibble::as_tibble(df)

  df[] <- lapply(df, function(x) {
    if (!is.character(x)) return(x)

    non_missing <- x[!is.na(x)]
    n_non_missing <- length(non_missing)

    if (n_non_missing == 0) {
      return(factor(x))
    }

    n_unique <- length(unique(non_missing))

    if (n_unique <= max_levels || n_unique / n_non_missing <= max_unique_fraction) {
      factor(x)
    } else {
      x
    }
  })

  df
}

fixrep_summary_table <- function(df) {
  if (is.null(df)) return(tibble::tibble())

  df <- format_fixrep_for_summary(df)
  summary_lines <- lapply(df, fixrep_column_summary_lines)
  n_rows <- max(lengths(summary_lines), 0)

  if (n_rows == 0) return(tibble::tibble())

  summary_lines <- lapply(summary_lines, \(x) c(x, rep("", n_rows - length(x))))
  tibble::as_tibble(summary_lines, .name_repair = "minimal")
}

fixrep_column_summary_lines <- function(x, maxsum = 7L) {
  summary_x <- summary(x, maxsum = maxsum)
  labels <- names(summary_x)

  if (is.null(labels)) {
    return(capture.output(summary_x))
  }

  values <- unname(summary_x)
  label_width <- max(nchar(labels), na.rm = TRUE)

  paste0(
    format(labels, width = label_width, justify = "left"),
    ": ",
    format(values, trim = TRUE)
  )
}

## constructor helpers ----

# Reads the mapping select inputs and requires each one before standardising.
req_fixrep_map <- function(input) {
  list(
    participant = req(input$map_participant),
    face        = req(input$map_face),
    trial       = req(input$map_trial),
    condition   = req(input$map_condition),
    fix_x       = req(input$map_fix_x),
    fix_y       = req(input$map_fix_y),
    fix_dur     = req(input$map_fix_dur),
    image_position = req(input$map_image_position)
  )
}

req_fixrep_map_matches_cols <- function(raw, map) {
  required_cols <- c(
    map$participant,
    map$face,
    map$trial,
    map$condition,
    map$fix_x,
    map$fix_y,
    map$fix_dur
  )

  if (!identical(map$image_position, screen_central_choice)) {
    required_cols <- c(required_cols, map$image_position)
  }

  required_cols <- unique(stats::na.omit(required_cols))
  shiny::req(all(required_cols %in% names(raw)))
  invisible(TRUE)
}

mapped_fixrep_col <- function(raw, col) {
  shiny::req(length(col) == 1, !is.na(col), nzchar(col), col %in% names(raw))
  raw[[col]]
}

parse_point_column <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""

  stripped <- gsub("[()]", "", x)
  parts <- strsplit(stripped, ",", fixed = TRUE)

  parsed <- lapply(parts, function(part) {
    if (length(part) < 2) {
      return(c(x = NA_real_, y = NA_real_))
    }

    c(
      x = suppressWarnings(as.numeric(trimws(part[[1]]))),
      y = suppressWarnings(as.numeric(trimws(part[[2]])))
    )
  })

  data.frame(
    x = vapply(parsed, `[[`, numeric(1), "x"),
    y = vapply(parsed, `[[`, numeric(1), "y")
  )
}

screen_centre_from_params <- function(screen) {
  if (is.null(screen)) {
    return(c(x = NA_real_, y = NA_real_))
  }

  left <- to_num(screen$left)
  right <- to_num(screen$right)
  top <- to_num(screen$top)
  bottom <- to_num(screen$bottom)

  if (!all(is.finite(c(left, right, top, bottom)))) {
    return(c(x = NA_real_, y = NA_real_))
  }

  if (identical(screen$origin, "other")) {
    return(c(x = NA_real_, y = NA_real_))
  }

  if (identical(screen$origin, "center")) {
    width <- right - left
    height <- abs(bottom - top)
    left <- -width / 2
    right <- width / 2
    top <- -height / 2
    bottom <- height / 2
  }

  c(
    x = mean(c(left, right)),
    y = mean(c(bottom, top))
  )
}

image_position_values_for_standardisation <- function(raw, image_position, screen) {
  if (identical(image_position, screen_central_choice)) {
    centre <- screen_centre_from_params(screen)
    return(data.frame(
      x = rep(centre[["x"]], nrow(raw)),
      y = rep(centre[["y"]], nrow(raw))
    ))
  }

  if (!image_position %in% names(raw)) {
    return(data.frame(
      x = rep(NA_real_, nrow(raw)),
      y = rep(NA_real_, nrow(raw))
    ))
  }

  parse_point_column(raw[[image_position]])
}

# Renames and coerces the uploaded fixation report into the app's standard columns.
standardise_fixrep <- function(raw, map, screen = NULL) {
  req_fixrep_map_matches_cols(raw, map)

  image_position <- image_position_values_for_standardisation(
    raw = raw,
    image_position = map$image_position,
    screen = screen
  )

  tibble(
    SUBJECT   = as.character(mapped_fixrep_col(raw, map$participant)),
    FACE      = as.character(mapped_fixrep_col(raw, map$face)),
    TRIAL_ID  = to_int_if_possible(mapped_fixrep_col(raw, map$trial)),
    CONDITION = mapped_fixrep_col(raw, map$condition),
    IMG_X     = image_position$x,
    IMG_Y     = image_position$y,
    FIX_X     = to_num(mapped_fixrep_col(raw, map$fix_x)),
    FIX_Y     = to_num(mapped_fixrep_col(raw, map$fix_y)),
    FIX_DUR   = to_num(mapped_fixrep_col(raw, map$fix_dur)),
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
      selected = choose_col(cols, c("unique_pp", "RECORDING_SESSION_LABEL"))
    ),

    shiny::selectInput(
      "map_face",
      "FACE",
      choices = cols,
      selected = choose_col(cols, c("file_b1", "face", "file", "which_face", "FACE"))
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
      selected = choose_col(cols, c("position", "condition"))
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
      "map_image_position",
      "IMAGE POSITION",
      choices = c(screen_central_choice, cols),
      selected = choose_col(
        c(screen_central_choice, cols),
        c("location_b1", "face_location", screen_central_choice)
      )
    )
  )
}

## low-level helpers ----

# Adds derived columns used for mapping without changing the imported raw data.
prepare_fixrep_for_standardisation <- function(raw) {
  requireNamespace("tibble", quietly = TRUE)

  out <- tibble::as_tibble(raw)
  attr(out, "read_mode") <- attr(raw, "read_mode", exact = TRUE)
  out
}

# Reads a fixation report from text or Excel while preserving imported columns.
read_fixrep <- function(path) {
  stopifnot(length(path) == 1, is.character(path), file.exists(path))

  requireNamespace("readr", quietly = TRUE)
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

  raw <- tibble::as_tibble(raw)
  attr(raw, "read_mode") <- res$mode
  raw
}
