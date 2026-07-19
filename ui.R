library(shiny)
library(bslib)

research_panels <- list(
  aoi_demo_panel(),
  fixations_panel(),
  screen_panel(),
  faces_panel(),
  sanity_panel(),
  aoi_workbench_panel()
)

if (vorogaze_developer_enabled()) {
  research_panels <- c(research_panels, list(developer_panel()))
}

ui <- page_fillable(
  title = "VoroGaze",
  theme = app_theme(),
  app_head(),
  do.call(navset_card_pill, research_panels)
)
