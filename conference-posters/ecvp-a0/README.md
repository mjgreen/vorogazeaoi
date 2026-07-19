# VoroGaze AOI – ECVP A0 poster

This folder contains the editable source and print artifacts for an A0 portrait
research-methods poster about VoroGaze AOI.

## Files

- `poster.svg` – editable vector source at exactly 841 × 1189 mm.
- `qr-destination.txt` – canonical landing-page URL encoded by the QR.
- `render.sh` – reproducible local render.
- `assets/vorogaze-landing-qr.svg` – generated vector QR.
- `output/vorogaze-aoi-ecvp-a0.pdf` – print-ready PDF.
- `output/vorogaze-aoi-ecvp-a0-preview.png` – raster preview at 90 dpi.

Run the build from this directory:

```text
./render.sh
```

The poster uses the bundled DeBruine et al face and descriptive outputs produced
by the current VoroGaze AOI worked-example helpers. It deliberately describes a
research-methods prototype and worked example, not a completed empirical
validation study.

## Content grounding

- The current product scope, public endpoints and implemented features are
  documented in the repository `README.md`, `PAGES_DEPLOYMENT.md` and
  `R/aoi_demo.R`.
- The fixture contains 20 fixation rows, two subjects/sessions, one 350 × 466 px
  face and five default landmarks. The displayed metrics are the direct output
  of `aoi_demo_metrics()` for that fixture.
- The two-person early review is documented in
  `dev/TRUSTED_USER_REVIEW_2026-06-29.md`.
- The face is from DeBruine and Jones (2017), *Face Research Lab London Set*,
  DOI `10.6084/m9.figshare.5047666`, licensed CC BY 4.0.
- The author affiliation is supported by the current Bournemouth University
  staff profile for Dr Matthew Green.
- The ECVP 2025 presentation guidance specifies A0 (841 × 1189 mm), portrait
  only:
  `https://ecvp2025.uni-mainz.de/presentation-guidelines-2`

The QR visibly targets the public chooser page:

```text
https://vorogaze.mjgreen.uk/
```

The poster also prints and embeds clickable PDF links for:

```text
https://vorogaze-workbench.mjgreen.uk/
https://vorogaze-example.mjgreen.uk/
https://vorogaze.mjgreen.uk/#screencast
https://github.com/mjgreen/vorogazeaoi
https://doi.org/10.6084/m9.figshare.5047666
```
