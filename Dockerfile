FROM rocker/r-ver:4.6.0

ENV DEBIAN_FRONTEND=noninteractive \
    RENV_CONFIG_SANDBOX_ENABLED=false \
    RENV_PATHS_LIBRARY=/opt/renv/library \
    SHINY_HOST=0.0.0.0 \
    SHINY_PORT=3838

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    curl \
    file \
    fonts-dejavu-core \
    g++ \
    git \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libicu-dev \
    libjpeg-dev \
    libmagick++-dev \
    libpng-dev \
    libssl-dev \
    libtiff-dev \
    libuv1-dev \
    libxml2-dev \
    make \
    pandoc \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY renv.lock ./
COPY renv/activate.R renv/settings.json ./renv/

RUN Rscript --vanilla -e "install.packages('renv', repos = 'https://cloud.r-project.org')" \
  && Rscript --vanilla -e "renv::restore(project = '/app', prompt = FALSE)"

COPY . ./

EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${SHINY_PORT}/" >/dev/null || exit 1

CMD ["Rscript", "--vanilla", "-e", "host <- Sys.getenv('SHINY_HOST', '0.0.0.0'); port <- as.integer(Sys.getenv('SHINY_PORT', '3838')); Sys.unsetenv('SHINY_PORT'); options(shiny.host = host, shiny.port = port); shiny::runApp('/app')"]
