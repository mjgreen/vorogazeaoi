# VoroGaze AOI

VoroGaze AOI is a Shiny prototype for inspecting eye-tracking fixation reports
against face images and screen geometry.

The current app focuses on making the spatial assumptions visible before they
become analysis numbers: which columns are being used, where fixations sit on
the screen, how face images are placed, and whether the selected trial/condition
combination has a coherent image position.

The longer-term project direction is landmark-based AOI analysis, including
Voronoi-style AOI regions derived from defensible face landmarks. That AOI layer
is still roadmap work; this repo currently contains the deployment-ready
geometry and data-checking workbench.

## Current Features

- Shiny app with tabs for an AOI demo, fixation data, screen geometry, face
  images, sanity checks, and developer/debug notes.
- One-face Lisa1 AOI demo with preloaded landmarks, live `deldir` Voronoi
  tessellation, nearest-landmark fixation assignment, and compact metrics.
- AOI Workbench for uploaded or bundled faces: click to add AOI centres,
  double-click to delete the nearest centre, assign fixations, commit
  face/condition sessions, export AOIs, and export unaggregated and aggregated
  metrics.
- Bundled demo fixation report and face images, so the app opens with data
  already loaded.
- Upload support for alternative fixation reports.
- Column mapping for participant, face, trial, condition, fixation position,
  fixation duration, and image position.
- Mapping validation for duplicate mappings, missing coordinates, numeric
  coercion failures, and fixation/image coordinate ranges.
- Support for delimited text fixation reports and first-sheet Excel workbooks.
- Face-folder browser upload for `.png`, `.jpg`, and `.jpeg` images.
- Screen-coordinate preview with common screen-size presets and custom bounds.
- Combined sanity-check plot showing screen, face image, and fixations together.
- Docker Compose deployment for the Elite host.

## Bundled Demo Data

The app defaults to the bundled demo assets:

```text
fixreps/combined_alex1_done_by_matt_fixrep.csv
faces/faces_300x350/
```

Uploaded fixation reports and uploaded face folders override the bundled data
for the active session.

The AOI demo uses a smaller self-contained Lisa1 fixture:

```text
demo/lisa1/fixrep_demo.csv
demo/lisa1/faces/001_03.jpg
```

See `demo/lisa1/README.md` for fixture provenance and attribution.

## Poster Screencast

The poster-friendly AOI demo screencast is served from:

```text
https://elite.tail2f3b09.ts.net/poster-aoi-demo.html
```

A rough QR-test poster mockup is served from:

```text
https://elite.tail2f3b09.ts.net/poster-qr-mockup.html
```

The mockup QR currently encodes the Funnel URL:

```text
https://elite.tail2f3b09.ts.net/poster-aoi-demo.html
```

The page embeds `www/aoi-demo-screencast.mp4`, a silent 30-second recording of
the Lisa1 AOI demo interaction. To regenerate it, start the app locally and run
the recorder script on a machine with Node, Playwright, Chrome, and ffmpeg:

```bash
node scripts/record_aoi_screencast.js --url=http://127.0.0.1:3840/
```

## Repository Layout

```text
ui.R                  Shiny UI entrypoint
server.R              Shiny server entrypoint
global.R              Shared app setup
R/                    App helper modules
demo/                 Curated AOI demo fixture data
www/                  App static assets and poster screencast page
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

From the repo root, restore packages and start the Shiny app:

```bash
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore(); shiny::runApp()"
```

Then open the URL printed by Shiny, usually:

```text
http://127.0.0.1:3838/
```

For day-to-day RStudio use, opening the project directory and pressing **Run
App** is also fine once `renv::restore()` has completed.

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

## Deploy To Elite

The authenticated external/testing URL is:

```text
https://elite.tail2f3b09.ts.net/
```

External conference/testing access is fronted by a small auth proxy that shows
a normal login page and then sets a signed session cookie before forwarding to
the Shiny app. The cookie is marked `Secure`, so use the HTTPS Funnel URL for
browser login testing.

After committing and pushing changes to GitHub, update Elite with:

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi && git pull --ff-only && { docker rm -f vorogazeaoi-funnel-proxy 2>/dev/null || true; } && docker compose up -d --build'
```

See [ELITE_DEPLOYMENT.md](ELITE_DEPLOYMENT.md) for the full Elite deployment
cheat sheet, including status checks and log-following commands.

## Development Notes

- The project uses `renv`; keep `renv.lock` updated when package dependencies
  change.
- The Docker image restores packages from `renv.lock` at build time.
- The app currently supports top-left and centre-style coordinate origins.
  "Other" origins are visible in the UI but intentionally not implemented yet.
- Fixation report imports preserve raw columns as text first, then standardise
  selected columns into the app's canonical fields.
- The AOI demo assigns fixations to nearest landmarks as the operational
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

The planned analysis layer is to let researchers define meaningful face
landmarks, derive reproducible AOI regions from those landmarks, assign
fixations to AOIs, and export defensible metrics. The present workbench is the
foundation for that: it validates data import, coordinate systems, image
placement, and fixation geometry before AOI metrics are computed.
