library(shiny)
library(bslib)

Sys.setenv(
  VOROGAZE_PUBLIC_MODE = "true",
  VOROGAZE_ENABLE_DEVELOPER = "false",
  VOROGAZE_EXAMPLE_FIXTURE_DIR = "/app/demo/lisa1",
  VOROGAZE_DEFAULT_FIXREP = "/app/demo/lisa1/fixrep_demo.csv",
  VOROGAZE_BUNDLED_FACE_DIR = "/app/demo/lisa1/faces"
)

source("global.R", local = TRUE)
options(shiny.maxRequestSize = 75 * 1024^2)

public_modules <- c(
  "R/aoi_demo.R",
  "R/aoi_workbench.R",
  "R/face.R",
  "R/fixrep.R",
  "R/sanity.R",
  "R/screen.R",
  "R/server_helpers.R",
  "R/ui_helpers.R"
)

for (module in public_modules) {
  source(module, local = TRUE)
}

server_source <- if (file.exists("R/workbench_server.R")) {
  "R/workbench_server.R"
} else {
  "server.R"
}
source(server_source, local = TRUE)

public_workbench_ui <- function() {
  page_fillable(
    title = "VoroGaze Research Workbench",
    theme = app_theme(),
    app_head(),
    tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "public-workbench.css"
      )
    ),
    public_workbench_notice(),
    navset_card_pill(
      aoi_demo_panel(),
      fixations_panel(),
      screen_panel(),
      faces_panel(),
      sanity_panel(),
      aoi_workbench_panel()
    )
  )
}

ui <- public_workbench_ui()
shinyApp(ui, server)
