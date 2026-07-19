FROM rocker/shiny:4.5.1

ARG RELEASE_COMMIT

LABEL org.opencontainers.image.title="VoroGaze interactive worked example"
LABEL org.opencontainers.image.revision="${RELEASE_COMMIT}"
LABEL org.opencontainers.image.source="https://github.com/mjgreen/vorogazeaoi"

ENV HOME=/tmp \
    TMPDIR=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    MAGICK_TMPDIR=/tmp/imagemagick \
    VOROGAZE_EXAMPLE_FIXTURE_DIR=/app/demo/lisa1

RUN apt-get update \
    && apt-get install -y --no-install-recommends libmagick++-dev \
    && install2.r --error --skipinstalled bslib deldir magick png \
    && rm -rf /srv/shiny-server/* \
    && test -z "$(find /srv/shiny-server -mindepth 1 -print -quit)" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY public-example/app.R /app/app.R
COPY public-example/styles.css /app/www/styles.css
COPY R/aoi_demo.R R/face.R /app/R/
COPY demo/lisa1/fixrep_demo.csv /app/demo/lisa1/fixrep_demo.csv
COPY demo/lisa1/faces/001_03.jpg /app/demo/lisa1/faces/001_03.jpg
COPY public-container/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

RUN chown -R shiny:shiny /app

USER shiny
EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3838/ >/dev/null || exit 1

CMD ["R", "--vanilla", "-e", "dir.create(Sys.getenv('XDG_CACHE_HOME'), recursive = TRUE, showWarnings = FALSE); dir.create(Sys.getenv('MAGICK_TMPDIR'), recursive = TRUE, showWarnings = FALSE); shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
