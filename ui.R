library(shiny)
library(bslib)

ui <- page_fillable(
  title = "Vorogaze",
  theme = app_theme(),
  app_head(),
  navset_card_pill(
    fixations_panel(),
    screen_panel(),
    faces_panel(),
    sanity_panel(),
    developer_panel()
  )
)
