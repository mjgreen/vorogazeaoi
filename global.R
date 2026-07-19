library(markdown)
library(magick)

options(shiny.maxRequestSize = 100 * 1024^2)

# Reads a conventional true/false environment flag.
vorogaze_env_flag <- function(name, default = FALSE) {
  value <- trimws(tolower(Sys.getenv(name, unset = "")))

  if (!nzchar(value)) {
    return(isTRUE(default))
  }

  value %in% c("1", "true", "yes", "on")
}

# Public mode enables the bounded, session-only upload boundary.
vorogaze_public_mode <- function() {
  vorogaze_env_flag("VOROGAZE_PUBLIC_MODE", default = FALSE)
}

# The internal app keeps its Developer tab; public images explicitly disable it.
vorogaze_developer_enabled <- function() {
  configured <- Sys.getenv("VOROGAZE_ENABLE_DEVELOPER", unset = "")

  if (nzchar(configured)) {
    return(vorogaze_env_flag("VOROGAZE_ENABLE_DEVELOPER"))
  }

  !vorogaze_public_mode()
}

# Returns the fallback value when the first value is NULL.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Draws a simple message inside a plot area when there is nothing to plot.
plot_message <- function(title, subtitle = NULL, title_cex = 1.2) {
  plot.new()
  box()
  text(
    x = 0.5,
    y = 0.55,
    labels = title,
    cex = title_cex,
    font = 2
  )
  
  if (!is.null(subtitle)) {
    text(
      x = 0.5,
      y = 0.45,
      labels = subtitle,
      cex = 1
    )
  }
  
  invisible(NULL)
}
