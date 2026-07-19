FROM rocker/shiny:4.5.1

ARG RELEASE_COMMIT

LABEL org.opencontainers.image.title="VoroGaze Research Workbench"
LABEL org.opencontainers.image.revision="${RELEASE_COMMIT}"
LABEL org.opencontainers.image.source="https://github.com/mjgreen/vorogazeaoi"

ENV HOME=/tmp \
    TMPDIR=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    MAGICK_TMPDIR=/tmp/imagemagick \
    VOROGAZE_PUBLIC_MODE=true \
    VOROGAZE_ENABLE_DEVELOPER=false \
    VOROGAZE_EXAMPLE_FIXTURE_DIR=/app/demo/lisa1 \
    VOROGAZE_DEFAULT_FIXREP=/app/demo/lisa1/fixrep_demo.csv \
    VOROGAZE_BUNDLED_FACE_DIR=/app/demo/lisa1/faces

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      libcurl4-openssl-dev \
      libjpeg-dev \
      libmagick++-dev \
      libpng-dev \
      libssl-dev \
      libtiff-dev \
      libxml2-dev \
      zip \
    && install2.r --error --skipinstalled \
      bslib \
      deldir \
      dplyr \
      DT \
      magick \
      markdown \
      png \
      readr \
      readxl \
      stringr \
      tibble \
    && rm -rf /srv/shiny-server/* \
    && test -z "$(find /srv/shiny-server -mindepth 1 -print -quit)" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY public-workbench/app.R /app/app.R
COPY public-workbench/styles.css /app/www/public-workbench.css
COPY www/styles.css /app/www/styles.css
COPY global.R /app/global.R
COPY server.R /app/R/workbench_server.R
COPY R/aoi_demo.R /app/R/aoi_demo.R
COPY R/aoi_workbench.R /app/R/aoi_workbench.R
COPY R/face.R /app/R/face.R
COPY R/fixrep.R /app/R/fixrep.R
COPY R/sanity.R /app/R/sanity.R
COPY R/screen.R /app/R/screen.R
COPY R/server_helpers.R /app/R/server_helpers.R
COPY R/ui_helpers.R /app/R/ui_helpers.R
COPY demo/lisa1/fixrep_demo.csv /app/demo/lisa1/fixrep_demo.csv
COPY demo/lisa1/faces/001_03.jpg /app/demo/lisa1/faces/001_03.jpg
COPY public-container/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

RUN chown -R shiny:shiny /app

USER shiny
EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3838/ >/dev/null || exit 1

CMD ["R", "--vanilla", "-e", "dir.create(Sys.getenv('XDG_CACHE_HOME'), recursive = TRUE, showWarnings = FALSE); dir.create(Sys.getenv('MAGICK_TMPDIR'), recursive = TRUE, showWarnings = FALSE); shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
