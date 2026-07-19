dockerfiles <- c(
  example = "public-example/Dockerfile",
  workbench = "public-workbench/Dockerfile"
)

contents <- lapply(dockerfiles, readLines, warn = FALSE)

stopifnot(
  all(vapply(contents, function(lines) any(trimws(lines) == "USER shiny"), logical(1))),
  all(vapply(contents, function(lines) any(grepl("127.0.0.1:3838", lines, fixed = TRUE)), logical(1))),
  all(vapply(contents, function(lines) !any(grepl("^COPY[[:space:]]+[.][[:space:]]", lines)), logical(1)))
)

workbench <- paste(contents$workbench, collapse = "\n")
forbidden_copies <- c(
  "COPY dev",
  "COPY fixreps",
  "COPY faces/faces_300x350",
  "COPY .git",
  "COPY README"
)

stopifnot(
  !any(vapply(forbidden_copies, grepl, logical(1), x = workbench, fixed = TRUE)),
  !grepl("COPY global.R server.R /app/", workbench, fixed = TRUE),
  grepl("COPY server.R /app/R/workbench_server.R", workbench, fixed = TRUE),
  grepl("COPY demo/lisa1/fixrep_demo.csv", workbench, fixed = TRUE),
  grepl("COPY demo/lisa1/faces/001_03.jpg", workbench, fixed = TRUE),
  !grepl("COPY demo/lisa1 /app", workbench, fixed = TRUE),
  !grepl("R/developer.R", workbench, fixed = TRUE)
)

workflow <- readLines(".github/workflows/publish-public-images.yml", warn = FALSE)
workflow_text <- paste(workflow, collapse = "\n")

stopifnot(
  grepl("ghcr.io/mjgreen/vorogaze-example", workflow_text, fixed = TRUE),
  grepl("ghcr.io/mjgreen/vorogaze-workbench", workflow_text, fixed = TRUE),
  grepl("${{ github.sha }}", workflow_text, fixed = TRUE),
  !grepl(":latest", workflow_text, fixed = TRUE)
)

cat("Public image allow-list and immutable-tag contract checks passed\n")
