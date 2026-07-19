# Server helper functions ----

# Resolves an optional configured path relative to the app root.
configured_app_path <- function(environment_name, fallback) {
  configured <- Sys.getenv(environment_name, unset = "")
  path <- if (nzchar(configured)) configured else fallback

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

# Returns the bundled face directory path if it exists, otherwise NULL.
bundled_face_dir_path <- function() {
  path <- configured_app_path(
    "VOROGAZE_BUNDLED_FACE_DIR",
    file.path(getwd(), "faces", "faces_300x350")
  )
  
  if (dir.exists(path)) path else NULL
}

# Returns the bundled fixation report path if it exists, otherwise NULL.
default_fixrep_path <- function() {
  path <- configured_app_path(
    "VOROGAZE_DEFAULT_FIXREP",
    file.path(getwd(), "fixreps", "combined_alex1_done_by_matt_fixrep.csv")
  )

  if (file.exists(path)) path else NULL
}

# Public upload limits are kept in one place for UI, server and smoke tests.
public_upload_limits <- function() {
  list(
    fixation_bytes = 25 * 1024^2,
    face_count = 25L,
    face_bytes = 5 * 1024^2,
    faces_total_bytes = 50 * 1024^2,
    face_dimension = 4096L
  )
}

# Returns validation messages for a public fixation-report upload.
public_fixrep_upload_errors <- function(upload, limits = public_upload_limits()) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(character(0))
  }

  if (!all(c("name", "size", "datapath") %in% names(upload))) {
    return("The fixation-report upload metadata is incomplete.")
  }

  errors <- character(0)
  extensions <- tolower(tools::file_ext(upload$name))
  sizes <- suppressWarnings(as.numeric(upload$size))
  paths <- as.character(upload$datapath)

  if (nrow(upload) != 1) {
    errors <- c(errors, "Upload one fixation report at a time.")
  }

  if (any(!extensions %in% c("csv", "tsv", "txt", "xls", "xlsx"))) {
    errors <- c(errors, "Fixation reports must be CSV, TSV, TXT, XLS, or XLSX files.")
  }

  if (any(!is.finite(sizes)) || any(sizes > limits$fixation_bytes, na.rm = TRUE)) {
    errors <- c(errors, "The fixation report must be no larger than 25 MiB.")
  }

  if (any(!file.exists(paths))) {
    errors <- c(errors, "The uploaded fixation report is no longer available.")
  }

  unique(errors)
}

# Returns validation messages for a public batch of face images.
public_face_upload_errors <- function(upload, limits = public_upload_limits()) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(character(0))
  }

  if (!all(c("name", "size", "datapath") %in% names(upload))) {
    return("The face-image upload metadata is incomplete.")
  }

  errors <- character(0)
  extensions <- tolower(tools::file_ext(upload$name))
  sizes <- suppressWarnings(as.numeric(upload$size))
  paths <- as.character(upload$datapath)

  if (nrow(upload) > limits$face_count) {
    errors <- c(errors, "Upload no more than 25 face images at a time.")
  }

  if (any(!extensions %in% c("png", "jpg", "jpeg"))) {
    errors <- c(errors, "Face images must be PNG or JPEG files.")
  }

  if (any(!is.finite(sizes)) || any(sizes > limits$face_bytes, na.rm = TRUE)) {
    errors <- c(errors, "Each face image must be no larger than 5 MiB.")
  }

  if (sum(sizes, na.rm = TRUE) > limits$faces_total_bytes) {
    errors <- c(errors, "The face-image batch must be no larger than 50 MiB in total.")
  }

  if (any(!file.exists(paths))) {
    errors <- c(errors, "One or more uploaded face images are no longer available.")
  }

  if (length(errors) > 0) {
    return(unique(errors))
  }

  image_errors <- lapply(seq_len(nrow(upload)), function(index) {
    info <- tryCatch(
      magick::image_info(magick::image_read(paths[[index]])),
      error = function(error) NULL
    )

    if (is.null(info) || nrow(info) != 1) {
      return(sprintf("%s is not a valid single-frame PNG or JPEG image.", basename(upload$name[[index]])))
    }

    if (!toupper(info$format[[1]]) %in% c("PNG", "JPEG", "JPG")) {
      return(sprintf("%s is not a PNG or JPEG image.", basename(upload$name[[index]])))
    }

    if (
      info$width[[1]] > limits$face_dimension ||
      info$height[[1]] > limits$face_dimension
    ) {
      return(sprintf("%s exceeds the 4096 x 4096 pixel limit.", basename(upload$name[[index]])))
    }

    NULL
  })

  unique(unlist(image_errors, use.names = FALSE))
}

# Creates one private upload directory and removes it when the Shiny session ends.
new_public_session_upload_store <- function(session) {
  root <- tempfile("vorogaze-session-")
  dir.create(root, mode = "0700", recursive = TRUE)

  if (!is.null(session)) {
    session$onSessionEnded(function() {
      unlink(root, recursive = TRUE, force = TRUE)
    })
  }

  list(root = root)
}

# Copies a validated fixation report into the current session's private directory.
stage_public_fixrep_upload <- function(upload, store) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(NULL)
  }

  errors <- public_fixrep_upload_errors(upload)
  shiny::validate(shiny::need(length(errors) == 0, paste(errors, collapse = " ")))

  target_dir <- file.path(store$root, "fixation-report")
  unlink(target_dir, recursive = TRUE, force = TRUE)
  dir.create(target_dir, mode = "0700", recursive = TRUE)

  extension <- tolower(tools::file_ext(upload$name[[1]]))
  target <- file.path(target_dir, paste0("fixation-report.", extension))
  copied <- file.copy(upload$datapath[[1]], target, overwrite = TRUE)
  shiny::validate(shiny::need(copied, "The fixation report could not be staged for this session."))
  Sys.chmod(target, mode = "0600")
  target
}

# Copies validated face images into the current session's private directory.
stage_public_face_uploads <- function(upload, store) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(character(0))
  }

  errors <- public_face_upload_errors(upload)
  shiny::validate(shiny::need(length(errors) == 0, paste(errors, collapse = " ")))

  target_dir <- file.path(store$root, "face-images")
  unlink(target_dir, recursive = TRUE, force = TRUE)
  dir.create(target_dir, mode = "0700", recursive = TRUE)

  extensions <- tolower(tools::file_ext(upload$name))
  targets <- file.path(
    target_dir,
    sprintf("%03d.%s", seq_len(nrow(upload)), extensions)
  )
  copied <- file.copy(upload$datapath, targets, overwrite = TRUE)
  shiny::validate(shiny::need(all(copied), "The face images could not be staged for this session."))
  Sys.chmod(targets, mode = "0600")
  names(targets) <- upload$name
  targets
}

# Returns the current uploaded fixation report path, if one exists.
uploaded_fixrep_path <- function(upload) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(NULL)
  }

  upload$datapath[[1]] %||% NULL
}

# Uses an uploaded fixation report when available, otherwise the bundled data.
active_fixrep_path <- function(upload, bundled_path) {
  uploaded_path <- uploaded_fixrep_path(upload)

  if (!is.null(uploaded_path)) {
    return(uploaded_path)
  }

  bundled_path
}

# Copies one bundled file into a Shiny download path.
copy_bundled_file <- function(source_path, output_path) {
  shiny::validate(shiny::need(!is.null(source_path), "Bundled file is not available."))
  file.copy(source_path, output_path, overwrite = TRUE)
}

# Zips the bundled face folder into a Shiny download path.
zip_bundled_face_dir <- function(source_dir, output_path) {
  shiny::validate(shiny::need(!is.null(source_dir), "Bundled face folder is not available."))

  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)

  setwd(dirname(source_dir))
  utils::zip(
    zipfile = output_path,
    files = basename(source_dir),
    flags = "-r9Xq"
  )
}

# Lists image files supported by the face preview and sanity plots.
list_face_image_files <- function(dir) {
  if (is.null(dir) || !dir.exists(dir)) {
    return(character(0))
  }
  
  list.files(
    path = dir,
    pattern = "\\.(png|jpg|jpeg)$",
    full.names = TRUE,
    ignore.case = TRUE
  )
}

# Returns uploaded local image files from the browser's directory picker.
uploaded_face_image_files <- function(upload) {
  if (is.null(upload) || nrow(upload) == 0) {
    return(character(0))
  }

  keep <- grepl("\\.(png|jpg|jpeg)$", upload$name, ignore.case = TRUE)
  files <- upload$datapath[keep]
  names(files) <- upload$name[keep]
  files
}

# Describes the active uploaded face-image source for display in the UI.
face_source_label <- function(upload, bundled_dir = NULL) {
  uploaded_files <- uploaded_face_image_files(upload)

  if (length(uploaded_files) > 0) {
    directory_names <- unique(dirname(names(uploaded_files)))
    directory_names <- directory_names[!directory_names %in% c(".", "")]

    if (length(directory_names) == 1) {
      return(sprintf("%s (%d image%s uploaded)", directory_names, length(uploaded_files), if (length(uploaded_files) == 1) "" else "s"))
    }

    return(sprintf("%d image%s uploaded from local directory", length(uploaded_files), if (length(uploaded_files) == 1) "" else "s"))
  }

  bundled_files <- list_face_image_files(bundled_dir)

  if (length(bundled_files) > 0) {
    if (vorogaze_public_mode()) {
      return(sprintf(
        "Bundled DeBruine et al face (%d image%s)",
        length(bundled_files),
        if (length(bundled_files) == 1) "" else "s"
      ))
    }

    return(sprintf(
      "Bundled data: %s (%d image%s)",
      basename(bundled_dir),
      length(bundled_files),
      if (length(bundled_files) == 1) "" else "s"
    ))
  }

  "None"
}

# Describes the active uploaded fixation report for display in the UI.
fixrep_source_label <- function(upload, bundled_path = NULL) {
  if (!is.null(upload) && nrow(upload) > 0) {
    return(upload$name[[1]] %||% "None")
  }

  if (!is.null(bundled_path) && file.exists(bundled_path)) {
    if (vorogaze_public_mode()) {
      return("Bundled DeBruine et al fixation report")
    }

    return(sprintf("Bundled data: %s", basename(bundled_path)))
  }

  "None"
}

# Builds the face image selector, or a small note when the directory is empty.
make_face_file_ui <- function(files) {
  if (length(files) == 0) {
    return(
      shiny::div(
        class = "dev-note",
        "No .png, .jpg, or .jpeg files found in this directory."
      )
    )
  }
  
  shiny::selectInput(
    "selected_face_file",
    "Face image",
    choices = stats::setNames(unname(files), basename(names(files) %||% files)),
    selected = files[1]
  )
}

screen_dimension_size <- function(value) {
  switch(
    value,
    "1600x900" = c(width = 1600, height = 900),
    "1920x1280" = c(width = 1920, height = 1280),
    NULL
  )
}

screen_bounds_from_size <- function(width, height, origin) {
  if (identical(origin, "center")) {
    return(list(
      left = -width / 2,
      right = width / 2,
      top = -height / 2,
      bottom = height / 2
    ))
  }

  list(
    left = 0,
    right = width,
    top = 0,
    bottom = height
  )
}

screen_bounds_from_custom_inputs <- function(input, origin) {
  shiny::req(
    input$screen_left,
    input$screen_right,
    input$screen_top,
    input$screen_bottom
  )

  left <- input$screen_left
  right <- input$screen_right
  top <- input$screen_top
  bottom <- input$screen_bottom

  shiny::validate(
    shiny::need(left < right, "Screen left must be less than screen right."),
    shiny::need(top < bottom, "Screen top must be less than screen bottom.")
  )

  if (identical(origin, "center")) {
    width <- right - left
    height <- bottom - top
    return(screen_bounds_from_size(width, height, origin))
  }

  list(
    left = left,
    right = right,
    top = top,
    bottom = bottom
  )
}

# Computes screen bounds from the selected preset/custom dimensions and origin.
# This assumes top-left/centre-style screen coordinates where y increases downward.
# Bottom-left or other upward-y origins will need substantial rewiring.
screen_params_from_input <- function(input) {
  origin <- shiny::req(input$screen_origin)
  dimensions <- input$screen_dimensions %||% "1600x900"

  if (identical(origin, "other")) {
    return(list(
      left = NA_real_,
      right = NA_real_,
      top = NA_real_,
      bottom = NA_real_,
      origin = "other",
      selected_origin = origin,
      dimensions = dimensions
    ))
  }

  size <- screen_dimension_size(dimensions)
  bounds <- if (is.null(size)) {
    screen_bounds_from_custom_inputs(input, origin)
  } else {
    screen_bounds_from_size(
      width = size[["width"]],
      height = size[["height"]],
      origin = origin
    )
  }

  c(
    bounds,
    list(
      origin = "computed",
      selected_origin = origin,
      dimensions = dimensions
    )
  )
}

format_screen_bound <- function(x) {
  if (!is.finite(x)) {
    return("NA")
  }

  format(round(x, 2), trim = TRUE, scientific = FALSE)
}

screen_bounds_summary_ui <- function(screen) {
  bounds <- c(
    left = screen$left,
    right = screen$right,
    top = screen$top,
    bottom = screen$bottom
  )

  if (!all(is.finite(bounds))) {
    return(shiny::div(
      class = "loaded-file-box",
      shiny::span(class = "loaded-file-label", "Computed bounds:"),
      shiny::span("Choose a supported screen origin.")
    ))
  }

  shiny::div(
    class = "loaded-file-box",
    shiny::span(class = "loaded-file-label", "Computed bounds:"),
    shiny::tags$code(paste(
      paste0(names(bounds), " = ", vapply(bounds, format_screen_bound, character(1))),
      collapse = " | "
    ))
  )
}

# Produces a floating coordinate label at the current plot hover position.
hover_coordinate_label <- function(hover) {
  shiny::req(hover)
  
  shiny::div(
    style = paste0(
      "position: absolute;",
      "left: ", hover$coords_css$x + 12, "px;",
      "top: ", hover$coords_css$y + 12, "px;",
      "z-index: 1000;",
      "pointer-events: none;",
      "background: rgba(255, 255, 255, 0.9);",
      "border: 1px solid #ccc;",
      "border-radius: 4px;",
      "padding: 2px 6px;",
      "font-size: 12px;",
      "font-family: monospace;"
    ),
    sprintf("x = %.0f, y = %.0f", hover$x, hover$y)
  )
}

# Builds the face and condition controls from the current standardised data.
make_sanity_filter_ui <- function(dat) {
  faces <- sort(unique(dat$FACE))
  conditions <- sort(unique(dat$CONDITION))
  
  shiny::tagList(
    shiny::selectInput(
      "sanity_face",
      "Face",
      choices = faces,
      selected = faces[1]
    ),
    shiny::selectInput(
      "sanity_condition",
      "Condition",
      choices = conditions,
      selected = conditions[1]
    )
  )
}

# Applies the sanity tab's selected face and condition filters to the data.
filter_sanity_fixrep <- function(dat, face = NULL, condition = NULL) {
  if (is.null(dat)) {
    return(NULL)
  }
  
  if (!is.null(face) && "FACE" %in% names(dat)) {
    dat <- dat[dat$FACE == face, , drop = FALSE]
  }
  
  if (!is.null(condition) && "CONDITION" %in% names(dat)) {
    dat <- dat[dat$CONDITION == condition, , drop = FALSE]
  }
  
  dat
}

# Returns the standard missing-position structure used before data is loaded.
missing_image_position_info <- function() {
  list(status = "missing", x = NA_real_, y = NA_real_)
}

# Shows the choice dialog used when IMG_X/IMG_Y cannot identify one position.
show_invalid_image_position_modal <- function() {
  shiny::showModal(shiny::modalDialog(
    title = "Image placement is ambiguous",
    "The selected face and condition have IMG_X and IMG_Y columns, but they do not resolve to one valid image position.",
    footer = shiny::tagList(
      shiny::actionButton(
        inputId = "dismiss_invalid_image_position",
        label = "Keep checking data"
      ),
      shiny::actionButton(
        inputId = "use_center_for_invalid_image_position",
        label = "Use screen centre"
      )
    ),
    easyClose = TRUE
  ))
}
