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

plot_face_image <- function() {
  
  face_image = read_face_image("B_F 01.jpg")
  
  my_xlim = c(0, 600)
  my_ylim = c(800, 0)
  
  my_xleft = 0
  my_xright = 600
  my_ytop = 0
  my_ybottom = 800
  
  plot(
    x = 0, y = 0, 
    #type = "n",
    xlim = my_xlim, ylim = my_ylim,
    xaxs = "i", yaxs = "i",
    #axes = FALSE, xlab = NA, ylab = NA,
    asp = 1
  )
  
  rasterImage(face_image$rast, xleft = my_xleft, ybottom = my_ybottom, xright = my_xright, ytop = my_ytop)
  
}


