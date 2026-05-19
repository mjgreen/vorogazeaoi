plot_screen <- function(screen_x = 1600, screen_y = 900) {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  par(
    mar = c(1.5, 4, 3, 1),
    xaxs = "i",
    yaxs = "i"
  )
  
  plot(
    NA,
    NA,
    type = "n",
    xlim = c(0, screen_x),
    ylim = c(screen_y, 0),
    asp = 1,
    axes = FALSE,
    ann = FALSE
  )
  
  # Screen boundary
  rect(0, 0, screen_x, screen_y, border = "black")
  
  # X-axis fixed to the top edge of the screen rectangle
  axis(
    side = 3,
    pos = 0,
    at = seq(0, screen_x, by = 200)
  )
  
  # Y-axis fixed to the left edge of the screen rectangle
  axis(
    side = 2,
    pos = 0,
    at = seq(0, screen_y, by = 100),
    las = 1
  )
}

plot_screen()