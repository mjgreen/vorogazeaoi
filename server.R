server <- function(input, output, session) {
  
  # Directory browser setup -----
  
  volumes <- shinyFiles::getVolumes()()
  
  shinyFiles::shinyDirChoose(
    input = input,
    id = "face_dir",
    roots = volumes,
    session = session
  )
  
  # Fixation report functions -----
  
  fixrep_raw <- reactive({
    req(input$upload_fixrep)
    read_fixrep(input$upload_fixrep$datapath)
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
  
  fixrep <- reactive({
    standardise_fixrep(
      raw = fixrep_raw(),
      map = fixrep_map()
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
      names(fixrep_raw()),
      error = function(e) character(0)
    )
    
    make_fixrep_mapping_ui(cols)
  })
  
  output$fixrep_raw_preview <- renderTable({
    fixrep_raw() |>
      head(5) |>
      format_table_int()
  })
  
  output$fixrep_preview <- renderTable({
    fixrep() |>
      head(5) |>
      format_table_int()
  })
  
  # Face directory and image functions -----
  
  default_face_dir <- normalizePath(
    file.path(getwd(), "faces", "faces_300x350"),
    winslash = "/",
    mustWork = FALSE
  )
  
  face_dir_path <- reactive({
    if (!is.null(input$face_dir)) {
      path <- shinyFiles::parseDirPath(volumes, input$face_dir)
      
      if (length(path) > 0) {
        return(path)
      }
    }
    
    if (dir.exists(default_face_dir)) {
      return(default_face_dir)
    }
    
    NULL
  })
  
  output$face_dir_display <- renderText({
    path <- face_dir_path()
    
    if (is.null(path)) {
      return("None")
    }
    
    path
  })
  
  face_files <- reactive({
    dir <- face_dir_path()
    
    if (is.null(dir) || !dir.exists(dir)) {
      return(character(0))
    }
    
    list.files(
      path = dir,
      pattern = "\\.(png|jpg|jpeg)$",
      full.names = TRUE,
      ignore.case = TRUE
    )
  })
  
  output$face_file_ui <- renderUI({
    files <- face_files()
    
    if (length(files) == 0) {
      return(
        div(
          class = "dev-note",
          "No .png, .jpg, or .jpeg files found in this directory."
        )
      )
    }
    
    selectInput(
      "selected_face_file",
      "Face image",
      choices = stats::setNames(files, basename(files)),
      selected = files[1]
    )
  })
  
  face_image_path <- reactive({
    if (is.null(input$selected_face_file)) {
      return(NULL)
    }
    
    input$selected_face_file
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
  
  # Screen view functions -----
  
  screen_params <- reactive({
    req(
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
  })
  
  output$view_screen <- renderPlot({
    req(input$screen_origin)
    
    if (identical(input$screen_origin, "other")) {
      plot_message(
        title = "Other screen origins are not supported yet.",
        subtitle = "Choose Top left or Centre to continue."
      )
      return(invisible(NULL))
    }
    
    screen <- screen_params()
    
    plot_screen(
      fixrep = screen_fixrep(),
      fix_x = "FIX_X",
      fix_y = "FIX_Y",
      screen_left = screen$left,
      screen_right = screen$right,
      screen_top = screen$top,
      screen_bottom = screen$bottom,
      screen_origin = input$screen_origin
    )
  })
  
  output$view_screen_click_coords <- renderText({
    format_plot_click(input$view_screen_click)
  })
  
  # Sanity view functions ----
  
  output$sanity_filter_ui <- renderUI({
    req(fixrep())
    
    dat <- fixrep()
    
    faces <- sort(unique(dat$FACE))
    conditions <- sort(unique(dat$CONDITION))
    
    tagList(
      selectInput(
        "sanity_face",
        "Face",
        choices = faces,
        selected = faces[1]
      ),
      
      selectInput(
        "sanity_condition",
        "Condition",
        choices = conditions,
        selected = conditions[1]
      )
    )
  })
  
  sanity_fixrep <- reactive({
    if (is.null(input$upload_fixrep)) {
      return(NULL)
    }
    
    dat <- tryCatch(
      fixrep(),
      error = function(e) NULL
    )
    
    if (is.null(dat)) {
      return(NULL)
    }
    
    if (!is.null(input$sanity_face) && "FACE" %in% names(dat)) {
      dat <- dat[dat$FACE == input$sanity_face, , drop = FALSE]
    }
    
    if (!is.null(input$sanity_condition) && "CONDITION" %in% names(dat)) {
      dat <- dat[dat$CONDITION == input$sanity_condition, , drop = FALSE]
    }
    
    dat
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
      return(list(status = "missing", x = NA_real_, y = NA_real_))
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
      list(status = "missing", x = NA_real_, y = NA_real_)
    }
    
    if (
      identical(image_position_info$status, "invalid") &&
      !isTRUE(invalid_image_position_use_center())
    ) {
      if (!isTRUE(invalid_image_position_dismissed())) {
        showModal(modalDialog(
          title = "Image placement is ambiguous",
          "The selected face and condition have IMG_X and IMG_Y columns, but they do not resolve to one valid image position.",
          footer = tagList(
            actionButton(
              inputId = "dismiss_invalid_image_position",
              label = "Keep checking data"
            ),
            actionButton(
              inputId = "use_center_for_invalid_image_position",
              label = "Use screen centre"
            )
          ),
          easyClose = TRUE
        ))
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
  
  output$view_sanity_click_coords <- renderText({
    format_plot_click(input$view_sanity_click)
  })
  
  # developer pane functions ---
  
  output$debug_params <- renderPrint({
    list(
      screen_left = input$screen_left,
      screen_right = input$screen_right,
      screen_top = input$screen_top,
      screen_bottom = input$screen_bottom,
      screen_origin = input$screen_origin,
      image_origin = input$image_origin,
      fixrep_read_mode = fixrep_read_mode(),
      sanity_face = input$sanity_face,
      sanity_condition = input$sanity_condition,
      invalid_image_position_use_center = invalid_image_position_use_center(),
      invalid_image_position_dismissed = invalid_image_position_dismissed(),
      selected_face_file = input$selected_face_file
    )
  })
  
  output$developer_todo_preview <- renderUI({
    HTML(markdown::markdownToHTML(
      text = input$developer_todo_md %||% "",
      fragment.only = TRUE
    ))
  })
  
  output$developer_docs_preview <- renderUI({
    HTML(markdown::markdownToHTML(
      text = input$developer_docs_md %||% "",
      fragment.only = TRUE
    ))
  })
}
