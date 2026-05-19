library(markdown)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

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

format_plot_click <- function(click, prefix = "plot") {
  if (is.null(click)) {
    return(sprintf("%s: move/click plot to show coordinates", prefix))
  }

  sprintf("%s x: %.1f, y: %.1f", prefix, click$x, click$y)
}
