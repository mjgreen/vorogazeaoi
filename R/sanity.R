plot_sanity <- function(
    fixrep = NULL,
    face_image_path = NULL,
    selected_face = NULL,
    selected_condition = NULL,
    face_centered_on_screen = TRUE,
    fix_x = "FIX_X",
    fix_y = "FIX_Y",
    img_x = "IMG_X",
    img_y = "IMG_Y",
    face_col = "FACE",
    condition_col = "CONDITION",
    screen_left = 0,
    screen_right = 1600,
    screen_top = 0,
    screen_bottom = 900,
    screen_origin = c("top_left", "center"),
    image_origin = c("center", "top_left"),
    tick_by = 100,
    fixation_pad = 50,
    placeholder_width = 600,
    placeholder_height = 800
) {
  screen_origin <- match.arg(screen_origin)
  image_origin <- match.arg(image_origin)
  
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
    if (!is.null(selected_face) && face_col %in% names(fixrep)) {
      fixrep <- fixrep[fixrep[[face_col]] == selected_face, , drop = FALSE]
    }
    
    if (!is.null(selected_condition) && condition_col %in% names(fixrep)) {
      fixrep <- fixrep[fixrep[[condition_col]] == selected_condition, , drop = FALSE]
    }
  }
  
  if (!is.null(fixrep) && nrow(fixrep) > 0) {
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
  
  if (isTRUE(face_centered_on_screen)) {
    image_centre_x <- screen_centre_x
    image_centre_y <- screen_centre_y
  } else {
    if (
      is.null(fixrep) ||
      nrow(fixrep) == 0 ||
      !all(c(img_x, img_y) %in% names(fixrep))
    ) {
      plot.new()
      box()
      text(
        x = 0.5,
        y = 0.55,
        labels = "Non-centred face placement needs IMG_X and IMG_Y.",
        cex = 1.1,
        font = 2
      )
      text(
        x = 0.5,
        y = 0.45,
        labels = "Select a face and condition with valid image-position columns.",
        cex = 1
      )
      return(invisible(NULL))
    }
    
    image_x_value <- unique(stats::na.omit(fixrep[[img_x]]))
    image_y_value <- unique(stats::na.omit(fixrep[[img_y]]))
    
    if (length(image_x_value) != 1 || length(image_y_value) != 1) {
      plot.new()
      box()
      text(
        x = 0.5,
        y = 0.55,
        labels = "Selected data does not have one unique IMG_X and IMG_Y.",
        cex = 1.1,
        font = 2
      )
      text(
        x = 0.5,
        y = 0.45,
        labels = "Check FACE, CONDITION, IMG_X, and IMG_Y.",
        cex = 1
      )
      return(invisible(NULL))
    }
    
    if (identical(image_origin, "top_left")) {
      image_centre_x <- image_x_value + image_width / 2
      image_centre_y <- image_y_value + image_height / 2
    } else {
      image_centre_x <- image_x_value
      image_centre_y <- image_y_value
    }
  }
  
  image_left <- image_centre_x - image_width / 2
  image_right <- image_centre_x + image_width / 2
  image_top <- image_centre_y - image_height / 2
  image_bottom <- image_centre_y + image_height / 2
  
  if (length(fix_x_values) > 0) {
    fix_min_x <- min(fix_x_values, na.rm = TRUE)
    fix_max_x <- max(fix_x_values, na.rm = TRUE)
    fix_min_y <- min(fix_y_values, na.rm = TRUE)
    fix_max_y <- max(fix_y_values, na.rm = TRUE)
  } else {
    fix_min_x <- screen_left
    fix_max_x <- screen_right
    fix_min_y <- screen_top
    fix_max_y <- screen_bottom
  }
  
  base_left <- min(screen_left, image_left)
  base_right <- max(screen_right, image_right)
  base_top <- min(screen_top, image_top)
  base_bottom <- max(screen_bottom, image_bottom)
  
  plot_left <- if (fix_min_x < base_left) {
    fix_min_x - fixation_pad
  } else {
    base_left
  }
  
  plot_right <- if (fix_max_x > base_right) {
    fix_max_x + fixation_pad
  } else {
    base_right
  }
  
  plot_top <- if (fix_min_y < base_top) {
    fix_min_y - fixation_pad
  } else {
    base_top
  }
  
  plot_bottom <- if (fix_max_y > base_bottom) {
    fix_max_y + fixation_pad
  } else {
    base_bottom
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
  
  axis(side = 3, pos = plot_top, at = x_ticks)
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
      x = image_centre_x,
      y = image_centre_y,
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
