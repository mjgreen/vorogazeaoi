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
  
  fixrep_map <- reactive({
    req_fixrep_map(input)
  })
  
  fixrep <- reactive({
    standardise_fixrep(
      raw = fixrep_raw(),
      map = fixrep_map()
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
  
  face_dir_path <- reactive({
    if (is.null(input$face_dir)) {
      return(NULL)
    }
    
    path <- shinyFiles::parseDirPath(volumes, input$face_dir)
    
    if (length(path) == 0) {
      return(NULL)
    }
    
    path
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
    
    if (!identical(input$image_origin, "center")) {
      plot.new()
      box()
      text(
        x = 0.5,
        y = 0.55,
        labels = "This image origin is not supported yet.",
        cex = 1.2,
        font = 2
      )
      text(
        x = 0.5,
        y = 0.45,
        labels = "Choose Centre to continue.",
        cex = 1
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
      plot.new()
      box()
      text(
        x = 0.5,
        y = 0.55,
        labels = "Other screen origins are not supported yet.",
        cex = 1.2,
        font = 2
      )
      text(
        x = 0.5,
        y = 0.45,
        labels = "Choose Top left or Centre to continue.",
        cex = 1
      )
      return(invisible(NULL))
    }
    
    screen <- screen_params()
    
    plot_screen(
      fixrep = fixrep(),
      fix_x = "FIX_X",
      fix_y = "FIX_Y",
      screen_left = screen$left,
      screen_right = screen$right,
      screen_top = screen$top,
      screen_bottom = screen$bottom,
      screen_origin = input$screen_origin
    )
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
  
  output$view_sanity <- renderPlot({
    req(input$screen_origin)
    
    if (identical(input$screen_origin, "other")) {
      plot.new()
      box()
      text(
        x = 0.5,
        y = 0.55,
        labels = "Other screen origins are not supported yet.",
        cex = 1.2,
        font = 2
      )
      text(
        x = 0.5,
        y = 0.45,
        labels = "Choose Top left or Centre to continue.",
        cex = 1
      )
      return(invisible(NULL))
    }
    
    screen <- screen_params()
    
    plot_sanity(
      fixrep = fixrep(),
      face_image_path = sanity_face_image_path(),
      selected_face = input$sanity_face,
      selected_condition = input$sanity_condition,
      face_centered_on_screen = input$face_centered_on_screen,
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
      screen_origin = input$screen_origin
    )
  })
}