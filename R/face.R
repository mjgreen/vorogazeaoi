# ---- Image helpers ------------------------------------------------------

# requirenamespace imagemagick

read_face_image <- function(path) {
  img <- magick::image_read(path) |> magick::image_orient()
  if (length(img) > 1) img <- img[1]
  
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  
  magick::image_write(img, path = tmp, format = "png")
  
  rast <- png::readPNG(tmp, native = TRUE)
  list(
    rast = rast,
    width = ncol(rast),
    height = nrow(rast)
  )
}

plot_face_image <- function(
    face_image_path = NULL,
    face_centered_on_screen = TRUE,
    image_width = 600,
    image_height = 800
) {
  my_xlim <- c(0, image_width)
  my_ylim <- c(image_height, 0)
  
  my_xleft <- 0
  my_xright <- image_width
  my_ytop <- 0
  my_ybottom <- image_height
  
  plot(
    x = 0,
    y = 0,
    type = "n",
    xlim = my_xlim,
    ylim = my_ylim,
    xaxs = "i",
    yaxs = "i",
    asp = 1,
    axes = TRUE,
    xlab = "x image coordinate",
    ylab = "y image coordinate"
  )
  
  if (is.null(face_image_path)) {
    text(
      x = image_width / 2,
      y = image_height / 2,
      labels = "?",
      cex = 8,
      font = 2
    )
    
    return(invisible(NULL))
  }
  
  face_image <- read_face_image(face_image_path)
  
  rasterImage(
    image = face_image$rast,
    xleft = my_xleft,
    ybottom = my_ybottom,
    xright = my_xright,
    ytop = my_ytop
  )
  
  if (isTRUE(face_centered_on_screen)) {
    points(
      x = image_width / 2,
      y = image_height / 2,
      pch = 4,
      cex = 1.5,
      lwd = 2,
      col = "#FF0000"
    )
  }
  
  invisible(NULL)
}


