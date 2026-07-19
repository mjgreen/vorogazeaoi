# Developer-only UI and server helpers ----

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

developer_panel <- function() {
  bslib::nav_panel(
    "Developer",
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

markdown_preview_html <- function(text) {
  shiny::HTML(markdown::markdownToHTML(
    text = text %||% "",
    fragment.only = TRUE
  ))
}

debug_params_list <- function(
    input,
    fixrep_read_mode,
    invalid_image_position_use_center,
    invalid_image_position_dismissed
) {
  list(
    screen_dimensions = input$screen_dimensions,
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

format_debug_param_value <- function(value) {
  if (is.null(value)) {
    return("<NULL>")
  }

  if (length(value) == 0) {
    return("<empty>")
  }

  if (is.character(value)) {
    return(paste(shQuote(value), collapse = ", "))
  }

  paste(as.character(value), collapse = ", ")
}

debug_params_text <- function(params) {
  names_width <- max(nchar(names(params)))
  lines <- vapply(
    names(params),
    function(name) {
      sprintf(
        "%-*s : %s",
        names_width,
        name,
        format_debug_param_value(params[[name]])
      )
    },
    character(1)
  )

  paste(lines, collapse = "\n")
}

developer_server <- function(
    input,
    output,
    fixrep_read_mode,
    invalid_image_position_use_center,
    invalid_image_position_dismissed
) {
  output$debug_params <- shiny::renderText({
    debug_params_text(debug_params_list(
      input = input,
      fixrep_read_mode = fixrep_read_mode(),
      invalid_image_position_use_center = invalid_image_position_use_center(),
      invalid_image_position_dismissed = invalid_image_position_dismissed()
    ))
  })

  output$developer_todo_preview <- shiny::renderUI({
    markdown_preview_html(input$developer_todo_md)
  })

  output$developer_docs_preview <- shiny::renderUI({
    markdown_preview_html(input$developer_docs_md)
  })
}
