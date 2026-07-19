#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "${here}"

mkdir -p assets output
qr_url=$(tr -d '\r\n' < qr-destination.txt)

qrencode -t SVG -l H -m 4 -s 12 -o assets/vorogaze-landing-qr.svg "${qr_url}"
inkscape poster.svg \
  --export-area-page \
  --export-filename=output/vorogaze-aoi-ecvp-a0.pdf

exiftool -overwrite_original \
  -Title="VoroGaze AOI: From facial landmarks to defensible areas of interest" \
  -Author="Matthew J. Green" \
  -Subject="A0 portrait research-methods poster for the European Conference on Visual Perception" \
  -Keywords="eye tracking, areas of interest, Voronoi, face perception, research methods, VoroGaze" \
  output/vorogaze-aoi-ecvp-a0.pdf >/dev/null

pdftoppm -png -r 90 -singlefile \
  output/vorogaze-aoi-ecvp-a0.pdf \
  output/vorogaze-aoi-ecvp-a0-preview >/dev/null
