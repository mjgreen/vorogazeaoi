server <- function(input, output, session) {

  # Fixation report tab ----

  fixrep_raw <- reactive({
    req(input$upload_fixrep)
    read_fixrep(input$upload_fixrep$datapath)
  })

  fixrep_for_standardisation <- reactive({
    prepare_fixrep_for_standardisation(fixrep_raw())
  })

  fixrep_read_mode <- reactive({
    if (is.null(input$upload_fixrep)) {
      return(NULL)
    }

    tryCatch(
      attr(fixrep_raw(), "read_mode", exact = TRUE),
      error = function(e) NULL
    )
  })

  fixrep_map <- reactive({
    req_fixrep_map(input)
  })

  screen_params <- reactive({
    screen_params_from_input(input)
  })

  fixrep <- reactive({
    standardise_fixrep(
      raw = fixrep_for_standardisation(),
      map = fixrep_map(),
      screen = screen_params()
    )
  })

  screen_fixrep <- reactive({
    if (is.null(input$upload_fixrep)) {
      return(NULL)
    }

    tryCatch(
      fixrep(),
      error = function(e) NULL
    )
  })

  output$fixrep_mapping_ui <- renderUI({
    cols <- tryCatch(
      names(fixrep_for_standardisation()),
      error = function(e) character(0)
    )

    make_fixrep_mapping_ui(cols)
  })

  output$fixrep_raw_preview <- DT::renderDT({
    DT::datatable(
      format_table_int(fixrep_raw()),
      rownames = FALSE,
      filter = "top",
      extensions = c("FixedColumns"),
      options = list(
        dom = "tip",
        searching = TRUE,
        paging = TRUE,
        pageLength = 5,
        lengthChange = FALSE,
        scrollX = TRUE,
        fixedColumns = list(leftColumns = 1),
        autoWidth = TRUE,
        columnDefs = list(
          list(targets = "_all", className = "dt-nowrap")
        )
      ),
      class = "compact stripe hover nowrap"
    )
  })

  output$fixrep_preview <- DT::renderDT({
    DT::datatable(
      format_table_int(fixrep()),
      rownames = FALSE,
      filter = "top",
      extensions = c("FixedColumns"),
      options = list(
        dom = "tip",
        searching = TRUE,
        paging = TRUE,
        pageLength = 5,
        lengthChange = FALSE,
        scrollX = TRUE,
        fixedColumns = list(leftColumns = 1),
        autoWidth = TRUE,
        columnDefs = list(
          list(targets = "_all", className = "dt-nowrap")
        )
      ),
      class = "compact stripe hover nowrap"
    )
  })

  output$fixrep_summary <- DT::renderDT({
    DT::datatable(
      fixrep_summary_table(fixrep()),
      rownames = FALSE,
      options = list(
        dom = "t",
        searching = FALSE,
        paging = FALSE,
        ordering = FALSE,
        scrollX = TRUE,
        autoWidth = TRUE,
        columnDefs = list(
          list(targets = "_all", className = "dt-nowrap")
        )
      ),
      class = "compact stripe hover nowrap"
    )
  })

  # Face directory and image tab ----

  default_face_dir <- default_face_dir_path()

  output$face_dir_display <- renderText({
    face_source_label(input$upload_face_dir, default_face_dir)
  })

  face_files <- reactive({
    uploaded_files <- uploaded_face_image_files(input$upload_face_dir)

    if (length(uploaded_files) > 0) {
      return(uploaded_files)
    }

    default_files <- list_face_image_files(default_face_dir)
    names(default_files) <- default_files
    default_files
  })

  output$face_file_ui <- renderUI({
    make_face_file_ui(face_files())
  })

  face_image_path <- reactive({
    input$selected_face_file %||% NULL
  })

  sanity_face_image_path <- reactive({
    if (is.null(input$sanity_face)) {
      return(NULL)
    }

    find_face_file(
      face = input$sanity_face,
      files = face_files()
    )
  })

  output$view_face <- renderPlot({
    req(input$image_origin)

    if (identical(input$image_origin, "other")) {
      plot_message(
        title = "This image origin is not supported yet.",
        subtitle = "Choose Top left or Centre to continue."
      )
      return(invisible(NULL))
    }

    plot_face_image(
      face_image_path = face_image_path(),
      image_origin = input$image_origin
    )
  })

  # Screen tab ----

  output$view_screen <- renderPlot({
    req(input$screen_origin)

    if (identical(input$screen_origin, "other")) {
      plot_message(
        title = "Other screen origins are not supported yet.",
        subtitle = "Choose Top left or Centre to continue."
      )
      return(invisible(NULL))
    }

    plot_screen(
      fixrep = screen_fixrep(),
      fix_x = "FIX_X",
      fix_y = "FIX_Y",
      screen_left = input$screen_left,
      screen_right = input$screen_right,
      screen_top = input$screen_top,
      screen_bottom = input$screen_bottom,
      screen_origin = input$screen_origin,
      tick_by = 100,
      fixation_pad = 50
    )
  })

  output$view_screen_hover_label <- renderUI({
    hover_coordinate_label(input$view_screen_hover)
  })

  # Sanity tab ----

  output$sanity_filter_ui <- renderUI({
    req(fixrep())
    make_sanity_filter_ui(fixrep())
  })

  sanity_fixrep <- reactive({
    if (is.null(input$upload_fixrep)) {
      return(NULL)
    }

    dat <- tryCatch(
      fixrep(),
      error = function(e) NULL
    )

    filter_sanity_fixrep(
      dat = dat,
      face = input$sanity_face,
      condition = input$sanity_condition
    )
  })

  invalid_image_position_use_center <- reactiveVal(FALSE)
  invalid_image_position_dismissed <- reactiveVal(FALSE)

  observeEvent(
    list(input$upload_fixrep, input$sanity_face, input$sanity_condition, input$image_origin),
    {
      invalid_image_position_use_center(FALSE)
      invalid_image_position_dismissed(FALSE)
    },
    ignoreInit = TRUE
  )

  observeEvent(input$dismiss_invalid_image_position, {
    invalid_image_position_dismissed(TRUE)
    removeModal()
  })

  observeEvent(input$use_center_for_invalid_image_position, {
    invalid_image_position_use_center(TRUE)
    removeModal()
  })

  sanity_image_position_info <- reactive({
    if (is.null(input$upload_fixrep)) {
      return(missing_image_position_info())
    }

    req(input$sanity_face, input$sanity_condition)

    image_position_values(
      fixrep = sanity_fixrep(),
      img_x = "IMG_X",
      img_y = "IMG_Y"
    )
  })

  output$view_sanity <- renderPlot({
    req(input$screen_origin, input$image_origin)

    if (identical(input$screen_origin, "other")) {
      plot_message(
        title = "Other screen origins are not supported yet.",
        subtitle = "Choose Top left or Centre to continue."
      )
      return(invisible(NULL))
    }

    if (identical(input$image_origin, "other")) {
      plot_message(
        title = "Other image origins are not supported yet.",
        subtitle = "Choose Top left or Centre to continue."
      )
      return(invisible(NULL))
    }

    screen <- screen_params()
    has_fixrep <- !is.null(input$upload_fixrep)

    if (isTRUE(has_fixrep)) {
      req(input$sanity_face, input$sanity_condition)
    }

    image_position_info <- if (isTRUE(has_fixrep)) {
      sanity_image_position_info()
    } else {
      missing_image_position_info()
    }

    if (
      identical(image_position_info$status, "invalid") &&
      !isTRUE(invalid_image_position_use_center())
    ) {
      if (!isTRUE(invalid_image_position_dismissed())) {
        show_invalid_image_position_modal()
      }

      plot_message(
        title = "Image placement is ambiguous.",
        subtitle = "Choose how to place the image in the warning dialog.",
        title_cex = 1.1
      )
      return(invisible(NULL))
    }

    plot_sanity(
      fixrep = sanity_fixrep(),
      face_image_path = sanity_face_image_path(),
      image_position = if (isTRUE(invalid_image_position_use_center())) "screen_center" else "auto",
      show_image = isTRUE(has_fixrep),
      fix_x = "FIX_X",
      fix_y = "FIX_Y",
      img_x = "IMG_X",
      img_y = "IMG_Y",
      face_col = "FACE",
      condition_col = "CONDITION",
      screen_left = screen$left,
      screen_right = screen$right,
      screen_top = screen$top,
      screen_bottom = screen$bottom,
      screen_origin = input$screen_origin,
      image_origin = input$image_origin
    )
  })

  output$view_sanity_hover_label <- renderUI({
    hover_coordinate_label(input$view_sanity_hover)
  })

  # Developer tab ----

  output$debug_params <- renderText({
    debug_params_text(debug_params_list(
      input = input,
      fixrep_read_mode = fixrep_read_mode(),
      invalid_image_position_use_center = invalid_image_position_use_center(),
      invalid_image_position_dismissed = invalid_image_position_dismissed()
    ))
  })

  output$developer_todo_preview <- renderUI({
    markdown_preview_html(input$developer_todo_md)
  })

  output$developer_docs_preview <- renderUI({
    markdown_preview_html(input$developer_docs_md)
  })
}
