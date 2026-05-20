#' Launch Vorogaze
#'
#' Starts the bundled Shiny app after the package has been installed.
#'
#' @param ... Arguments passed on to [shiny::runApp()], such as `port`,
#'   `host`, or `launch.browser`.
#'
#' @export
run_app <- function(...) {
  app_dir <- system.file("app", package = "vorogazeaoi3", mustWork = TRUE)
  shiny::runApp(appDir = app_dir, ...)
}
