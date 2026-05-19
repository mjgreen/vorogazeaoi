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
  
  output$face_display <- renderPlot(
    plot_face_image()
  )
  
  # Screen view functions -----
  
  output$view_screen <- renderPlot({
    plot_screen(
      fixrep = fixrep(),
      fix_x = "FIX_X",
      fix_y = "FIX_Y"
    )
  })
}