for (file in sort(list.files("R", pattern = "[.]R$", full.names = TRUE))) {
  source(file)
}

raw <- read_fixrep(default_fixrep_path())
raw <- prepare_fixrep_for_standardisation(raw)
cols <- names(raw)
map <- list(
  participant = choose_col(cols, c("unique_pp", "RECORDING_SESSION_LABEL")),
  face = choose_col(cols, c("file_b1", "face", "file", "which_face", "FACE")),
  trial = choose_col(cols, c("TRIAL_INDEX")),
  condition = choose_col(cols, c("position", "condition")),
  fix_x = choose_col(cols, c("CURRENT_FIX_X")),
  fix_y = choose_col(cols, c("CURRENT_FIX_Y")),
  fix_dur = choose_col(cols, c("CURRENT_FIX_DURATION")),
  image_position = choose_col(c(screen_central_choice, cols), c("location_b1", "face_location", screen_central_choice))
)

screen <- list(left = 0, right = 1600, top = 0, bottom = 900, origin = "computed")
fixrep <- standardise_fixrep(raw = raw, map = map, screen = screen)
files <- list_face_image_files(bundled_face_dir_path())
face <- fixrep$FACE[[1]]
condition <- fixrep$CONDITION[[1]]
face_path <- find_face_file(face, files)

stopifnot(
  nrow(raw) > 0,
  nrow(fixrep) > 0,
  !is.null(face_path),
  file.exists(unname(face_path))
)

face_info <- read_face_image(unname(face_path))
fixrep_one <- filter_sanity_fixrep(fixrep, face = face, condition = condition)

centres <- aoi_workbench_empty_centres()
centres <- aoi_workbench_upsert_centre(centres, face, "left_eye", 110, 130)
centres <- aoi_workbench_upsert_centre(centres, face, "right_eye", 210, 130)
centres <- aoi_workbench_upsert_centre(centres, face, "mouth", 160, 240)
centres <- aoi_workbench_upsert_centre(centres, face, "mouth", 160, 245)

stopifnot(
  nrow(centres) == 3,
  any(centres$aoi_name == "mouth" & centres$y == 245)
)

centres_deleted <- aoi_workbench_delete_nearest(
  centres = centres,
  face_key = aoi_workbench_face_key(face),
  x = 210,
  y = 130
)

stopifnot(nrow(centres_deleted) == 2)

dd <- aoi_workbench_deldir(centres, face_info$width, face_info$height)
stopifnot(!is.null(dd), nrow(dd$input_pts) == 3)

geometry <- aoi_workbench_image_geometry(
  fixrep = fixrep_one,
  width = face_info$width,
  height = face_info$height,
  screen = screen,
  image_origin = "center"
)

stopifnot(identical(geometry$status, "valid"))

assigned <- aoi_workbench_assign_fixations(
  fixrep = fixrep_one,
  centres = centres,
  width = face_info$width,
  height = face_info$height,
  geometry = geometry
)

commit_key <- paste(aoi_workbench_face_key(face), condition, sep = "|")
defs <- aoi_workbench_aoi_defs(
  centres = centres,
  face_key = aoi_workbench_face_key(face),
  face = face,
  condition = condition,
  commit_key = commit_key
)
annotated <- aoi_workbench_annotate_assignments(
  assignments = assigned,
  defs = defs,
  face_key = aoi_workbench_face_key(face),
  commit_key = commit_key
)
metrics <- aoi_workbench_metrics_unaggregated(annotated, defs)
by_subject <- aoi_workbench_metrics_over_subjects(metrics)
by_face <- aoi_workbench_metrics_over_faces(by_subject)

stopifnot(
  nrow(assigned) > 0,
  nrow(annotated) == nrow(assigned),
  all(c("AOI_ID", "AOI_NAME", "AOI_LABEL") %in% names(annotated)),
  all(c("N_FIX", "TOTAL_FIX_DUR", "MEAN_FIX_DUR") %in% names(metrics)),
  any(metrics$N_FIX == 0),
  any(is.na(metrics$MEAN_FIX_DUR[metrics$N_FIX == 0])),
  nrow(by_subject) > 0,
  nrow(by_face) > 0
)

validation_ui <- fixrep_validation_summary_ui(raw, map, fixrep)
stopifnot(inherits(validation_ui, "shiny.tag"))

cat("AOI workbench smoke test passed\n")
