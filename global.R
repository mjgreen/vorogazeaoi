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

format_plot_click <- function(
    click,
    screen_left = 0,
    screen_right = 1600,
    screen_top = 0,
    screen_bottom = 900,
    screen_origin = c("top_left", "center")
) {
  if (is.null(click)) {
    return("Click plot to show coordinates")
  }
  
  screen_origin <- match.arg(screen_origin)
  
  if (identical(screen_origin, "center")) {
    screen_width <- screen_right - screen_left
    screen_height <- abs(screen_bottom - screen_top)
    x <- click$x + screen_width / 2
    y <- click$y + screen_height / 2
  } else {
    x <- click$x
    y <- click$y
  }
  
  sprintf("screen px x: %.0f, y: %.0f", x, y)
}
