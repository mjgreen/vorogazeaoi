library(shiny)
library(bslib)

Sys.setenv(
  VOROGAZE_PUBLIC_MODE = "true",
  VOROGAZE_ENABLE_DEVELOPER = "false",
  VOROGAZE_EXAMPLE_FIXTURE_DIR = file.path(getwd(), "demo", "lisa1"),
  VOROGAZE_DEFAULT_FIXREP = file.path(getwd(), "demo", "lisa1", "fixrep_demo.csv"),
  VOROGAZE_BUNDLED_FACE_DIR = file.path(getwd(), "demo", "lisa1", "faces")
)

source("global.R")

public_modules <- c(
  "R/aoi_demo.R",
  "R/aoi_workbench.R",
  "R/face.R",
  "R/fixrep.R",
  "R/sanity.R",
  "R/screen.R",
  "R/server_helpers.R",
  "R/ui_helpers.R"
)

for (module in public_modules) {
  source(module)
}

source("server.R")

ui <- page_fillable(
  title = "VoroGaze Research Workbench",
  public_workbench_notice(),
  navset_card_pill(
    aoi_demo_panel(),
    fixations_panel(),
    screen_panel(),
    faces_panel(),
    sanity_panel(),
    aoi_workbench_panel()
  )
)
ui_html <- as.character(ui)

stopifnot(
  vorogaze_public_mode(),
  !vorogaze_developer_enabled(),
  !exists("developer_panel", inherits = FALSE),
  all(vapply(
    c("Worked Example", "Fixations", "Screen", "Faces", "Sanity", "AOI Workbench"),
    grepl,
    logical(1),
    x = ui_html,
    fixed = TRUE
  )),
  !grepl(">Developer<", ui_html, fixed = TRUE),
  grepl("Temporary uploads", ui_html, fixed = TRUE),
  grepl("identifiable or sensitive participant data", ui_html, fixed = TRUE),
  grepl("DeBruine et al", ui_html, fixed = TRUE)
)

fixture <- read_fixrep(default_fixrep_path())
faces <- list_face_image_files(bundled_face_dir_path())

stopifnot(
  nrow(fixture) == 20,
  length(faces) == 1,
  identical(basename(faces), "001_03.jpg")
)

fixrep_upload <- data.frame(
  name = "fixations.csv",
  size = file.info(default_fixrep_path())$size,
  datapath = default_fixrep_path(),
  stringsAsFactors = FALSE
)
face_upload <- data.frame(
  name = "faces/001_03.jpg",
  size = file.info(faces[[1]])$size,
  datapath = faces[[1]],
  stringsAsFactors = FALSE
)

stopifnot(
  length(public_fixrep_upload_errors(fixrep_upload)) == 0,
  length(public_face_upload_errors(face_upload)) == 0
)

oversized_fixrep <- fixrep_upload
oversized_fixrep$size <- 25 * 1024^2 + 1
bad_extension <- fixrep_upload
bad_extension$name <- "fixations.exe"
too_many_faces <- face_upload[rep(1, 26), , drop = FALSE]

stopifnot(
  any(grepl("25 MiB", public_fixrep_upload_errors(oversized_fixrep), fixed = TRUE)),
  any(grepl("CSV", public_fixrep_upload_errors(bad_extension), fixed = TRUE)),
  any(grepl("25 face images", public_face_upload_errors(too_many_faces), fixed = TRUE))
)

malformed_path <- tempfile(fileext = ".jpg")
writeLines("not an image", malformed_path)
malformed_face <- data.frame(
  name = "broken.jpg",
  size = file.info(malformed_path)$size,
  datapath = malformed_path,
  stringsAsFactors = FALSE
)
stopifnot(any(grepl("not a valid", public_face_upload_errors(malformed_face), fixed = TRUE)))
unlink(malformed_path, force = TRUE)

wide_path <- tempfile(fileext = ".png")
magick::image_write(magick::image_blank(4097, 1), wide_path, format = "png")
wide_face <- data.frame(
  name = "wide.png",
  size = file.info(wide_path)$size,
  datapath = wide_path,
  stringsAsFactors = FALSE
)
stopifnot(any(grepl("4096 x 4096", public_face_upload_errors(wide_face), fixed = TRUE)))
unlink(wide_path, force = TRUE)

store <- new_public_session_upload_store(NULL)
staged_fixrep <- stage_public_fixrep_upload(fixrep_upload, store)
staged_faces <- stage_public_face_uploads(face_upload, store)

stopifnot(
  file.exists(staged_fixrep),
  file.exists(unname(staged_faces)),
  startsWith(staged_fixrep, store$root),
  startsWith(unname(staged_faces), store$root)
)

cleanup_callback <- NULL
fake_session <- list(
  onSessionEnded = function(callback) {
    cleanup_callback <<- callback
  }
)
cleanup_store <- new_public_session_upload_store(fake_session)

stopifnot(is.function(cleanup_callback), dir.exists(cleanup_store$root))
cleanup_callback()

unlink(store$root, recursive = TRUE, force = TRUE)
stopifnot(!dir.exists(store$root), !dir.exists(cleanup_store$root))

cat("Public Research Workbench smoke and upload-boundary tests passed\n")
