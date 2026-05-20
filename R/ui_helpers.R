# UI helper functions ----

# Builds the Bootstrap theme used by every page in the app.
app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    base_font_size = "0.9rem",
    "input-font-size" = "0.8rem",
    "input-padding-y" = "0.15rem",
    "input-padding-x" = "0.4rem"
  )
}

# Adds app-wide browser assets, currently just the stylesheet in www/.
app_head <- function() {
  shiny::tags$head(
    shiny::tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  )
}

# Wraps a plot and hover label in the positioned container Shiny needs.
hover_plot_box <- function(plot_id, hover_id, label_id, style = NULL, label_style = NULL) {
  shiny::div(
    style = style %||% "position: relative; width: 100%;",
    shiny::plotOutput(
      plot_id,
      hover = shiny::hoverOpts(
        id = hover_id,
        delay = 0,
        delayType = "throttle",
        clip = TRUE
      )
    ),
    shiny::uiOutput(label_id, style = label_style)
  )
}

# Creates the upload and mapping controls for the fixation report tab.
fixations_input_card <- function() {
  bslib::card(
    bslib::card_header("input"),
    bslib::card_body(
      shiny::div(
        class = "fixrep-upload-box",
        shiny::fileInput(
          "upload_fixrep",
          "Upload fixation report",
          width = "100%"
        )
      ),
      shiny::div(
        class = "fixrep-mapping-ui",
        shiny::uiOutput("fixrep_mapping_ui")
      )
    )
  )
}

# Creates one compact table card for either raw or processed fixation data.
fixrep_preview_card <- function(title, output_id) {
  bslib::card(
    bslib::card_header(title),
    bslib::card_body(
      shiny::div(
        class = "compact-table-output",
        shiny::tableOutput(output_id)
      )
    )
  )
}

# Assembles the fixation report upload and preview tab.
fixations_panel <- function() {
  bslib::nav_panel(
    "fixations",
    bslib::layout_columns(
      col_widths = c(4, 8),
      fixations_input_card(),
      bslib::layout_columns(
        col_widths = 12,
        fixrep_preview_card("raw", "fixrep_raw_preview"),
        fixrep_preview_card("processed", "fixrep_preview")
      )
    )
  )
}

# Creates the four numeric screen boundary inputs.
screen_boundary_inputs <- function() {
  shiny::tagList(
    shiny::numericInput("screen_left", "Screen left", value = 0, step = 1),
    shiny::numericInput("screen_right", "Screen right", value = 1600, step = 1),
    shiny::numericInput("screen_top", "Screen top", value = 0, step = 1),
    shiny::numericInput("screen_bottom", "Screen bottom", value = 900, step = 1)
  )
}

# Assembles the screen controls and coordinate preview plot.
screen_panel <- function() {
  bslib::nav_panel(
    "screen",
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::card(
        bslib::card_header("input"),
        bslib::card_body(
          origin_radio_buttons("screen_origin", "Screen origin", selected = "top_left"),
          screen_boundary_inputs()
        )
      ),
      bslib::card(
        bslib::card_header("view"),
        bslib::card_body(
          hover_plot_box("view_screen", "view_screen_hover", "view_screen_hover_label")
        )
      )
    )
  )
}

# Creates a shared origin selector for screen and image coordinate systems.
origin_radio_buttons <- function(input_id, label, selected) {
  shiny::radioButtons(
    input_id,
    label,
    choices = c(
      "Top left" = "top_left",
      "Centre" = "center",
      "Other" = "other"
    ),
    selected = selected
  )
}

# Assembles the face image directory controls and image preview plot.
images_panel <- function() {
  bslib::nav_panel(
    "images",
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::card(
        bslib::card_header("input"),
        bslib::card_body(
          shinyFiles::shinyDirButton(
            id = "face_dir",
            label = "Browse face directory",
            title = "Choose the directory containing face images"
          ),
          shiny::div(
            class = "loaded-file-box",
            shiny::span(class = "loaded-file-label", "Face directory:"),
            shiny::textOutput("face_dir_display", inline = TRUE)
          ),
          shiny::uiOutput("face_file_ui"),
          origin_radio_buttons("image_origin", "Image origin", selected = "center")
        )
      ),
      bslib::card(
        bslib::card_header("view"),
        bslib::card_body(shiny::plotOutput("view_face"))
      )
    )
  )
}

# Assembles the sanity-check filters and combined image/fixation preview.
sanity_panel <- function() {
  bslib::nav_panel(
    "sanity",
    bslib::layout_columns(
      col_widths = c(4, 8),
      bslib::card(
        bslib::card_header("verify params"),
        bslib::card_body(shiny::uiOutput("sanity_filter_ui"))
      ),
      bslib::card(
        bslib::card_header("view everything"),
        bslib::card_body(
          hover_plot_box(
            "view_sanity",
            "view_sanity_hover",
            "view_sanity_hover_label",
            style = "position: relative; width: 100%; padding: 0; margin: 0;",
            label_style = paste(
              "position: absolute;",
              "left: 0;",
              "top: 0;",
              "width: 0;",
              "height: 0;",
              "overflow: visible;",
              "pointer-events: none;"
            )
          )
        )
      )
    )
  )
}

# Builds one markdown editor/preview card for the developer tab.
developer_markdown_card <- function(title, input_id, output_id, file_path, label) {
  bslib::card(
    bslib::card_header(title),
    bslib::card_body(
      shiny::textAreaInput(
        input_id,
        label,
        value = paste(readLines(file_path, warn = FALSE), collapse = "\n"),
        width = "100%",
        height = "220px"
      ),
      shiny::tags$hr(),
      shiny::uiOutput(output_id)
    )
  )
}

# Assembles the developer-only debug and markdown editing controls.
developer_panel <- function() {
  bslib::nav_panel(
    "developer",
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      bslib::card(
        bslib::card_header("debug params"),
        bslib::card_body(shiny::verbatimTextOutput("debug_params"))
      ),
      developer_markdown_card(
        "TODO",
        "developer_todo_md",
        "developer_todo_preview",
        "dev/TODO.md",
        "Developer notes"
      ),
      developer_markdown_card(
        "DOCUMENTATION",
        "developer_docs_md",
        "developer_docs_preview",
        "dev/DOCUMENTATION.md",
        "Draft user-facing documentation"
      )
    )
  )
}
