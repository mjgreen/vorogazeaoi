plot_screen <- function(
    fixrep_path = NULL,
    fix_x = "FIX_X",
    fix_y = "FIX_Y",
    screen_left = 0,
    screen_right = 1600,
    screen_top = 900,
    screen_bottom = 0,
    tick_by = 100
) {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  # Read fixation report, if supplied
  if (!is.null(fixrep_path)) {
    fixrep <- readr::read_csv(fixrep_path, show_col_types = FALSE)
    
    fix_x_values <- fixrep[[fix_x]]
    fix_y_values <- fixrep[[fix_y]]
    
    keep <- is.finite(fix_x_values) & is.finite(fix_y_values)
    fix_x_values <- fix_x_values[keep]
    fix_y_values <- fix_y_values[keep]
  } else {
    fix_x_values <- numeric(0)
    fix_y_values <- numeric(0)
  }
  
  # Plotting region must include both screen and all valid fixations
  plot_left <- min(c(screen_left, fix_x_values), na.rm = TRUE)
  plot_right <- max(c(screen_right, fix_x_values), na.rm = TRUE)
  plot_top <- max(c(screen_top, fix_y_values), na.rm = TRUE)
  plot_bottom <- min(c(screen_bottom, fix_y_values), na.rm = TRUE)
  
  x_ticks <- seq(
    floor(plot_left / tick_by) * tick_by,
    ceiling(plot_right / tick_by) * tick_by,
    by = tick_by
  )
  
  y_ticks <- seq(
    ceiling(plot_top / tick_by) * tick_by,
    floor(plot_bottom / tick_by) * tick_by,
    by = -tick_by
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
    ylim = c(plot_top, plot_bottom),
    asp = 1,
    axes = FALSE,
    ann = FALSE
  )
  
  axis(side = 3, pos = 0, at = x_ticks)
  axis(side = 2, pos = 0, at = y_ticks, las = 1)
  
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
      pch = 19,
      cex = 0.6
    )
  }
}

