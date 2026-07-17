FROM rocker/shiny:4.5.1

ARG RELEASE_COMMIT

LABEL org.opencontainers.image.title="VoroGaze bundled-data demo"
LABEL org.opencontainers.image.revision="${RELEASE_COMMIT}"
LABEL org.opencontainers.image.source="https://github.com/mjgreen/vorogazeaoi"

RUN apt-get update \
    && apt-get install -y --no-install-recommends libmagick++-dev \
    && install2.r --error --skipinstalled bslib deldir magick png \
    && rm -rf /srv/shiny-server/* \
    && test -z "$(find /srv/shiny-server -mindepth 1 -print -quit)" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY public-demo/app.R /app/app.R
COPY public-demo/styles.css /app/www/styles.css
COPY R/aoi_demo.R R/face.R /app/R/
COPY demo/lisa1 /app/demo/lisa1/

RUN chown -R shiny:shiny /app

USER shiny
EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3838/ >/dev/null || exit 1

CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
