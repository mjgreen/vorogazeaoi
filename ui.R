library(shiny)
library(bslib)

ui <- page_fillable(
  title = "Vorogaze",
  theme = app_theme(),
  app_head(),
  navset_card_pill(
    aoi_demo_panel(),
    fixations_panel(),
    screen_panel(),
    faces_panel(),
    sanity_panel(),
    aoi_workbench_panel(),
    developer_panel()
  )
)
