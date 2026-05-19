plot_screen <- function(
    fixrep = NULL,
    fix_x = "FIX_X",
    fix_y = "FIX_Y",
    screen_left = 0,
    screen_right = 1600,
    screen_top = 900,
    screen_bottom = 0,
    screen_origin = c("top_left", "center"),
    tick_by = 100,
    fixation_pad = 50
) {
  screen_origin <- match.arg(screen_origin)
  
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  screen_width <- screen_right - screen_left
  screen_height <- abs(screen_bottom - screen_top)
  
  if (identical(screen_origin, "center")) {
    screen_left <- -screen_width / 2
    screen_right <- screen_width / 2
    screen_top <- -screen_height / 2
    screen_bottom <- screen_height / 2
  }
  
  if (!is.null(fixrep)) {
    fix_x_values <- fixrep[[fix_x]]
    fix_y_values <- fixrep[[fix_y]]
    
    keep <- is.finite(fix_x_values) & is.finite(fix_y_values)
    fix_x_values <- fix_x_values[keep]
    fix_y_values <- fix_y_values[keep]
  } else {
    fix_x_values <- numeric(0)
    fix_y_values <- numeric(0)
  }
  
  if (length(fix_x_values) > 0) {
    fix_min_x <- min(fix_x_values, na.rm = TRUE)
    fix_max_x <- max(fix_x_values, na.rm = TRUE)
    fix_min_y <- min(fix_y_values, na.rm = TRUE)
    fix_max_y <- max(fix_y_values, na.rm = TRUE)
  } else {
    fix_min_x <- screen_left
    fix_max_x <- screen_right
    fix_min_y <- screen_bottom
    fix_max_y <- screen_top
  }
  
  plot_left <- if (fix_min_x < screen_left) {
    fix_min_x - fixation_pad
  } else {
    screen_left
  }
  
  plot_right <- if (fix_max_x > screen_right) {
    fix_max_x + fixation_pad
  } else {
    screen_right
  }
  
  plot_top <- if (fix_min_y < screen_top) {
    fix_min_y - fixation_pad
  } else {
    screen_top
  }
  
  plot_bottom <- if (fix_max_y > screen_bottom) {
    fix_max_y + fixation_pad
  } else {
    screen_bottom
  }
  
  x_ticks <- seq(
    floor(plot_left / tick_by) * tick_by,
    ceiling(plot_right / tick_by) * tick_by,
    by = tick_by
  )
  
  y_ticks <- seq(
    floor(plot_top / tick_by) * tick_by,
    ceiling(plot_bottom / tick_by) * tick_by,
    by = tick_by
  )
  
  par(
    mar = c(1.5, 4, 3, 1),
    xaxs = "i",
    yaxs = "i"
  )
  
  plot(
    NA,
    NA,
    type = "n",
    xlim = c(plot_left, plot_right),
    ylim = c(plot_bottom, plot_top),
    asp = 1,
    axes = FALSE,
    ann = FALSE
  )
  
  axis(
    side = 3,
    pos = plot_top,
    at = x_ticks
  )
  
  axis(
    side = 2,
    pos = plot_left,
    at = y_ticks,
    las = 1
  )
  
  rect(
    xleft = screen_left,
    ybottom = screen_bottom,
    xright = screen_right,
    ytop = screen_top,
    border = "black"
  )
  
  if (length(fix_x_values) > 0) {
    points(
      x = fix_x_values,
      y = fix_y_values,
      pch = 4,
      cex = 0.9,
      lwd = 2,
      col = "#FF0000"
    )
  }
  
  invisible(NULL)
}
