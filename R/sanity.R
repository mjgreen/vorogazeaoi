plot_sanity <- function(
    fixrep = NULL,
    face_image_path = NULL,
    face_centered_on_screen = TRUE,
    fix_x = "FIX_X",
    fix_y = "FIX_Y",
    screen_left = 0,
    screen_right = 1600,
    screen_top = 900,
    screen_bottom = 0,
    screen_origin = c("top_left", "center"),
    tick_by = 100,
    fixation_pad = 50,
    placeholder_width = 600,
    placeholder_height = 800
) {
  screen_origin <- match.arg(screen_origin)
  
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  if (!isTRUE(face_centered_on_screen)) {
    plot.new()
    box()
    text(
      x = 0.5,
      y = 0.55,
      labels = "Non-centred face placement is not supported yet.",
      cex = 1.2,
      font = 2
    )
    text(
      x = 0.5,
      y = 0.45,
      labels = "In future this will use IMG_X and IMG_Y from the fixation report.",
      cex = 1
    )
    return(invisible(NULL))
  }
  
  screen_width <- screen_right - screen_left
  screen_height <- screen_top - screen_bottom
  
  if (identical(screen_origin, "center")) {
    screen_left <- -screen_width / 2
    screen_right <- screen_width / 2
    screen_bottom <- -screen_height / 2
    screen_top <- screen_height / 2
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
  
  if (is.null(face_image_path)) {
    face_image <- NULL
    image_width <- placeholder_width
    image_height <- placeholder_height
  } else {
    face_image <- read_face_image(face_image_path)
    image_width <- face_image$width
    image_height <- face_image$height
  }
  
  screen_centre_x <- mean(c(screen_left, screen_right))
  screen_centre_y <- mean(c(screen_bottom, screen_top))
  
  image_left <- screen_centre_x - image_width / 2
  image_right <- screen_centre_x + image_width / 2
  image_top <- screen_centre_y - image_height / 2
  image_bottom <- screen_centre_y + image_height / 2
  
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
  
  plot_left <- min(screen_left, image_left, fix_min_x) - fixation_pad
  plot_right <- max(screen_right, image_right, fix_max_x) + fixation_pad
  plot_bottom <- min(screen_bottom, image_top, fix_min_y) - fixation_pad
  plot_top <- max(screen_top, image_bottom, fix_max_y) + fixation_pad
  
  plot_left <- min(plot_left, screen_left)
  plot_right <- max(plot_right, screen_right)
  plot_bottom <- min(plot_bottom, screen_bottom)
  plot_top <- max(plot_top, screen_top)
  
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
  
  axis(side = 3, pos = plot_bottom, at = x_ticks)
  axis(side = 2, pos = plot_left, at = y_ticks, las = 1)
  
  rect(
    xleft = screen_left,
    ybottom = screen_bottom,
    xright = screen_right,
    ytop = screen_top,
    border = "black",
    lwd = 2
  )
  
  if (is.null(face_image)) {
    rect(
      xleft = image_left,
      ybottom = image_bottom,
      xright = image_right,
      ytop = image_top,
      border = "grey50",
      lty = 2
    )
    
    text(
      x = screen_centre_x,
      y = screen_centre_y,
      labels = "?",
      cex = 8,
      font = 2
    )
  } else {
    rasterImage(
      image = face_image$rast,
      xleft = image_left,
      ybottom = image_bottom,
      xright = image_right,
      ytop = image_top
    )
  }
  
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