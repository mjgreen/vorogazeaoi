library(shiny)
library(bslib)

Sys.setenv(VOROGAZE_EXAMPLE_FIXTURE_DIR = file.path(getwd(), "demo", "lisa1"))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

source("R/aoi_demo.R", local = TRUE)

fixrep <- aoi_demo_read_fixrep()
landmarks <- aoi_demo_default_landmarks()
assignments <- aoi_demo_assign_fixations(
  fixrep,
  landmarks,
  350,
  466
)
metrics <- aoi_demo_metrics(assignments, landmarks)
panel <- aoi_demo_panel()

stopifnot(
  file.exists(aoi_demo_face_path()),
  file.exists(aoi_demo_fixrep_path()),
  nrow(fixrep) > 0,
  nrow(assignments) > 0,
  nrow(metrics) == nrow(landmarks),
  inherits(panel, "shiny.tag"),
  grepl("Worked Example", as.character(panel), fixed = TRUE),
  !grepl("Lisa1", as.character(panel), fixed = TRUE)
)

cat("Interactive worked-example smoke test passed\n")
