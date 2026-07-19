# VoroGaze AOI

VoroGaze AOI is a browser-based Shiny research workbench for inspecting
eye-tracking fixation reports against face images and screen geometry.

The current Research Workbench focuses on making the spatial assumptions
visible before they become analysis numbers: which columns are being used,
where fixations sit on the screen, how face images are placed, and whether the
selected trial/condition combination has a coherent image position.

The current implementation includes landmark-based AOI analysis: researchers
can define defensible centres, inspect bounded Voronoi-style regions, assign
fixations, and export unaggregated and aggregated metrics. Longer-term work is
empirical validation, broader landmark conventions, and refinement with
research users.

## Current Features

- Shiny Research Workbench with tabs for an AOI worked example, fixation data,
  screen geometry, face images, sanity checks, and AOI construction.
- One-face DeBruine et al worked example with preloaded landmarks, live `deldir`
  Voronoi tessellation, nearest-landmark fixation assignment, and compact
  metrics.
- AOI Workbench for uploaded or bundled faces: click to add AOI centres,
  double-click to delete the nearest centre, assign fixations, commit
  face/condition sessions, export AOIs, and export unaggregated and aggregated
  metrics.
- Bundled fixation report and face images, so the Research Workbench opens with
  data already loaded.
- Upload support for alternative fixation reports.
- Column mapping for participant, face, trial, condition, fixation position,
  fixation duration, and image position.
- Mapping validation for duplicate mappings, missing coordinates, numeric
  coercion failures, and fixation/image coordinate ranges.
- Support for delimited text fixation reports and first-sheet Excel workbooks.
- Face-folder browser upload for `.png`, `.jpg`, and `.jpeg` images.
- Screen-coordinate preview with common screen-size presets and custom bounds.
- Combined sanity-check plot showing screen, face image, and fixations together.
- Docker Compose deployment for the Beelink LAN service.

## Bundled Data

The Research Workbench defaults to these bundled assets:

```text
fixreps/combined_alex1_done_by_matt_fixrep.csv
faces/faces_300x350/
```

Uploaded fixation reports and uploaded face folders override the bundled data
for the active session.

The interactive worked example uses a smaller self-contained DeBruine et al
face fixture:

```text
demo/lisa1/fixrep_demo.csv
demo/lisa1/faces/001_03.jpg
```

See `demo/lisa1/README.md` for fixture provenance and attribution.

## Poster Screencast

The poster-friendly 30-second screencast is served from:

```text
https://vorogaze.mjgreen.uk/#screencast
```

The complete public Research Workbench and bundled-data interactive worked
example are:

```text
https://vorogaze-workbench.mjgreen.uk/
https://vorogaze-example.mjgreen.uk/
```

The landing page embeds `www/aoi-demo-screencast.mp4`, a silent 30-second
recording of the bundled DeBruine et al face workflow. To regenerate it, start
the Research Workbench locally and run the recorder script on a machine with
Node, Playwright, Chrome, and ffmpeg:

```bash
node scripts/record_aoi_screencast.js --url=http://127.0.0.1:3838/
```

## Repository Layout

```text
ui.R                  Shiny UI entrypoint
server.R              Shiny server entrypoint
global.R              Shared Shiny setup
R/                    Research Workbench helper modules
demo/                 Curated worked-example fixture data
www/                  Static assets and poster screencast
fixreps/              Bundled fixation-report data
faces/                Bundled face-image data
ascs/                 Example/source eye-tracking exports
scripts/              Data-preparation scripts
tests/                Lightweight R smoke tests
dev/                  Draft developer notes and TODOs
Dockerfile            Container image used by the Elite deployment
compose.yaml          Docker Compose service definition
ELITE_DEPLOYMENT.md   Elite update and troubleshooting commands
renv.lock             Reproducible R package lockfile
```

## Run Locally With R

From the repo root, restore packages and start the Research Workbench:

```bash
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore(); shiny::runApp()"
```

Then open the URL printed by Shiny, usually:

```text
http://127.0.0.1:3838/
```

For day-to-day RStudio use, opening the project directory and pressing
RStudio’s **Run App** control is also fine once `renv::restore()` has completed.

## Run Locally With Docker

Build and start the container:

```bash
docker compose up -d --build
```

Open:

```text
http://localhost:3838/
```

Check status and recent logs:

```bash
docker compose ps && docker logs --tail=80 vorogazeaoi
```

Stop the local container:

```bash
docker compose down
```

## Deployment

The canonical Beelink checkout is:

```text
/home/matt/CodexWork/repos/vorogazeaoi
```

Its authenticated LAN route is:

```text
http://192.168.8.205/vorogazeaoi
```

The deployment uses the private credential file
selected by `VOROGAZEAOI_AUTH_ENV_FILE`. On Beelink it defaults to
`/home/matt/CodexWork/private/vorogazeaoi/auth.env`, which must remain outside
Git and readable only by Matt. Rebuild the LAN project from this repository
with `docker compose up -d --build`.

Z440 is authoritative for the public interactive worked example at
`https://vorogaze-example.mjgreen.uk/` and the complete Research Workbench at
`https://vorogaze-workbench.mjgreen.uk/`. The static chooser and screencast at
`https://vorogaze.mjgreen.uk/` remain separate from Beelink LAN work.
`ELITE_DEPLOYMENT.md` is retained as historical deployment evidence only.

## Development Notes

- The project uses `renv`; keep `renv.lock` updated when package dependencies
  change.
- The Docker image restores packages from `renv.lock` at build time.
- The Research Workbench currently supports top-left and centre-style
  coordinate origins.
  "Other" origins are visible in the UI but intentionally not implemented yet.
- Fixation report imports preserve raw columns as text first, then standardise
  selected columns into the Research Workbench’s canonical fields.
- The AOI worked example assigns fixations to nearest landmarks as the operational
  equivalent of Voronoi-cell assignment for this prototype.
- The AOI Workbench commits one face/condition at a time into a session table.
  Empty AOIs are retained in the metrics with zero counts.
- Optional face alignment/preprocessing code lives in
  `scripts/align_faces_optional.R`; it is development-only and intentionally not
  part of the deployed Shiny runtime.
- Legacy consolidation notes are in `dev/LEGACY_CONSOLIDATION.md`.

## Legacy Deldir Lineage

The AOI Workbench absorbed the useful `deldir` implementation from the older
`mjgreen/vorogazeaoi/app3_human_refactored_by_codex` prototype: AOI centre
creation, validation, duplicate filtering, bounded tessellation, plot overlay,
nearest-centre fixation assignment, session tables, metrics, and downloads.

## Project Direction

The implemented analysis layer lets researchers define meaningful face
landmarks, derive reproducible AOI regions, assign fixations to AOIs, and export
inspectable metrics. The next phase is to evaluate those choices empirically,
document defensible landmark conventions, and refine the workflow with a wider
range of eye-tracking study designs.
