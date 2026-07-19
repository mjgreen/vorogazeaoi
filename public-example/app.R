library(shiny)
library(bslib)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

source("R/face.R", local = TRUE)
source("R/aoi_demo.R", local = TRUE)

ui <- page_fillable(
  title = "VoroGaze – interactive worked example",
  theme = bs_theme(version = 5, primary = "#007c91"),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  navset_card_pill(aoi_demo_panel())
)

server <- function(input, output, session) {
  aoi_demo_server(input, output, session)
}

shinyApp(ui, server)
