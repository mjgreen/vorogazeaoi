# Server helper functions ----

# Returns the bundled face directory path if it exists, otherwise NULL.
default_face_dir_path <- function() {
  path <- normalizePath(
    file.path(getwd(), "faces", "faces_300x350"),
    winslash = "/",
    mustWork = FALSE
  )
  
  if (dir.exists(path)) path else NULL
}

# Resolves the chosen shinyFiles directory, falling back to the bundled faces.
selected_face_dir_path <- function(input, volumes, default_dir) {
  if (!is.null(input$face_dir)) {
    path <- shinyFiles::parseDirPath(volumes, input$face_dir)
    
    if (length(path) > 0) {
      return(path)
    }
  }
  
  default_dir
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
    choices = stats::setNames(files, basename(files)),
    selected = files[1]
  )
}

# Packages the four screen inputs into one named list for plotting helpers.
screen_params_from_input <- function(input) {
  shiny::req(
    input$screen_left,
    input$screen_right,
    input$screen_top,
    input$screen_bottom
  )
  
  list(
    left = input$screen_left,
    right = input$screen_right,
    top = input$screen_top,
    bottom = input$screen_bottom
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

# Converts markdown text to HTML for the developer previews.
markdown_preview_html <- function(text) {
  shiny::HTML(markdown::markdownToHTML(
    text = text %||% "",
    fragment.only = TRUE
  ))
}

# Collects the values shown in the developer debug pane.
debug_params_list <- function(
    input,
    fixrep_read_mode,
    invalid_image_position_use_center,
    invalid_image_position_dismissed
) {
  list(
    screen_left = input$screen_left,
    screen_right = input$screen_right,
    screen_top = input$screen_top,
    screen_bottom = input$screen_bottom,
    screen_origin = input$screen_origin,
    image_origin = input$image_origin,
    fixrep_read_mode = fixrep_read_mode,
    sanity_face = input$sanity_face,
    sanity_condition = input$sanity_condition,
    invalid_image_position_use_center = invalid_image_position_use_center,
    invalid_image_position_dismissed = invalid_image_position_dismissed,
    selected_face_file = input$selected_face_file
  )
}
