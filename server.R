server <- function(input, output, session) {
  
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
  
  # Face view functions -----
  
  face_image_path <- reactive({
    if (isTRUE(input$use_bundled_face)) {
      return("B_F 01.jpg")
    }
    
    if (is.null(input$upload_face)) {
      return(NULL)
    }
    
    input$upload_face$datapath
  })
  
  output$view_face <- renderPlot({
    req(input$image_origin)
    
    if (identical(input$image_origin, "other")) {
      plot.new()
      text(
        x = 0.5,
        y = 0.5,
        labels = "Other image origins are not supported yet.",
        cex = 1.2
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
      face_image_path = face_image_path(),
      face_centered_on_screen = input$face_centered_on_screen,
      fix_x = "FIX_X",
      fix_y = "FIX_Y",
      screen_left = screen$left,
      screen_right = screen$right,
      screen_top = screen$top,
      screen_bottom = screen$bottom,
      screen_origin = input$screen_origin
    )
  })
  
}