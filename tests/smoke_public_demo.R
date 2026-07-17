library(shiny)
library(bslib)

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
  inherits(panel, "shiny.tag")
)

cat("Bundled public AOI demo smoke test passed\n")
