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
- Bundled demo fixation report and face images, so the app opens with data
  already loaded.
- Upload support for alternative fixation reports.
- Column mapping for participant, face, trial, condition, fixation position,
  fixation duration, and image position.
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
http://elite:3838/poster-aoi-demo.html
```

A rough QR-test poster mockup is served from:

```text
http://elite:3838/poster-qr-mockup.html
```

The mockup QR currently encodes the Elite LAN URL:

```text
http://192.168.8.209:3838/poster-aoi-demo.html
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
docker compose ps && docker logs --tail=80 vorogazeaoi3
```

Stop the local container:

```bash
docker compose down
```

## Deploy To Elite

Elite serves the app on the LAN at:

```text
http://elite:8088/
```

External conference/testing access is fronted by a small auth proxy that shows
a normal login page and then sets a signed session cookie before forwarding to
the Shiny app.

After committing and pushing changes to GitHub, update Elite with:

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi3 && git pull --ff-only && { docker rm -f vorogazeaoi3-funnel-proxy 2>/dev/null || true; } && docker compose up -d --build'
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
- The general workbench still initialises imported fixation reports with
  `AOI == "Not assigned"` until a wider AOI workflow is added there.

## Prior Deldir Implementation To Consult

The most useful prior implementation found in the local repos and on GitHub is
`mjgreen/vorogazeaoi/app3_human_refactored_by_codex`. It is a better reference
than the earlier single-file prototypes because the AOI centre creation,
validation, duplicate filtering, `deldir` input preparation, tessellation cache,
plot overlay, and fixation-to-nearest-centre assignment are already separated
into clearer pieces.

When adding `deldir` tessellation to this repo, consult:

- [app3_human_refactored_by_codex tree](https://github.com/mjgreen/vorogazeaoi/tree/1af9cd0fa24fc7df887bf2fc85b604547354f7e7/app3_human_refactored_by_codex)
- [R/helpers_aoi.R](https://github.com/mjgreen/vorogazeaoi/blob/1af9cd0fa24fc7df887bf2fc85b604547354f7e7/app3_human_refactored_by_codex/R/helpers_aoi.R)
  for AOI centre rows and `deldir`-ready point validation.
- [server.R](https://github.com/mjgreen/vorogazeaoi/blob/1af9cd0fa24fc7df887bf2fc85b604547354f7e7/app3_human_refactored_by_codex/server.R)
  for the guarded `deldir::deldir(...)` call, result caching, tessellation
  segment overlay, and AOI assignment flow.

That older implementation should be treated as a design reference rather than
copied wholesale: adapt it to this repo's current standardised fixation columns,
screen/image-origin handling, and Shiny module structure.

## Project Direction

The planned analysis layer is to let researchers define meaningful face
landmarks, derive reproducible AOI regions from those landmarks, assign
fixations to AOIs, and export defensible metrics. The present workbench is the
foundation for that: it validates data import, coordinate systems, image
placement, and fixation geometry before AOI metrics are computed.
