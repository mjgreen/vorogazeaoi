# Optional face alignment/preprocessing helpers.
#
# This file preserves the useful idea from the early VoroGaze prototypes without
# adding webmorphR, reticulate, or Python/dlib to the deployed Shiny runtime.
# Source and call these helpers only in a local development environment where
# those tools have already been installed.

require_optional_face_prep_packages <- function() {
  required <- c("webmorphR", "webmorphR.dlib", "reticulate")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing) > 0) {
    stop(
      "Optional face preprocessing packages are missing: ",
      paste(missing, collapse = ", "),
      ". Install them in a development environment before using this script.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

align_and_resize_faces_optional <- function(
    input_dir,
    output_dir,
    python = "~/.virtualenvs/r-reticulate/bin/python",
    x1 = 125,
    x2 = 225,
    y1 = 225,
    y2 = 225,
    width = 350,
    height = 466,
    log_path = file.path(output_dir, "bad_jpgs.csv")
) {
  require_optional_face_prep_packages()

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)

  reticulate::use_python(path.expand(python), required = FALSE)

  stimuli <- webmorphR::read_stim(input_dir)
  failures <- tibble::tibble(index = integer(), name = character(), error = character())

  for (i in seq_along(stimuli)) {
    message(i, " of ", length(stimuli), ": ", names(stimuli)[[i]])

    tryCatch(
      {
        stimuli[i] |>
          webmorphR.dlib::auto_delin("dlib7", replace = TRUE) |>
          webmorphR::align(
            pt1 = 0,
            pt2 = 1,
            x1 = x1,
            x2 = x2,
            y1 = y1,
            y2 = y2,
            width = width,
            height = height
          ) |>
          webmorphR::write_stim(output_dir, overwrite = TRUE, format = "jpeg")
      },
      error = function(e) {
        failures <<- dplyr::bind_rows(
          failures,
          tibble::tibble(
            index = i,
            name = names(stimuli)[[i]],
            error = conditionMessage(e)
          )
        )
        readr::write_csv(failures, log_path)
      }
    )
  }

  invisible(failures)
}
