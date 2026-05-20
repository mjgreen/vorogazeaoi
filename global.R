library(markdown)

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
