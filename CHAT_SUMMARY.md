# VoroGaze AOI Planning Summary

Date: 2026-06-14

## Current App State

- `vorogazeaoi` is the current clean working repo.
- The app now opens with bundled demo data preloaded:
  - fixation report: `fixreps/combined_alex1_done_by_matt_fixrep.csv`
  - faces: `faces/faces_300x350`
- Uploaded fixation reports and face folders still override the bundled demo data.
- A local Shiny test ran successfully after this change.

## Product Framing

The strongest framing so far:

> VoroGaze AOI supports defensible spatial analysis: make the geometry visible, make AOI definition reproducible, then compute the metrics.

Two equal selling points:

- **Validity checking:** make hidden spatial assumptions visible before they become numbers, including screen origin, image placement, off-screen fixations, face matching, and coordinate-system mistakes.
- **Landmark-based AOIs:** replace subjective hand-drawn AOI rectangles with Voronoi tessellations based on meaningful landmark clicks. The researcher chooses points that are easy to justify; AOI boundaries follow mathematically.

## Demo Strategy

- Conference attendees will mostly scan the QR code on phones.
- The QR route should open a quick, phone-friendly demo rather than the full analyst workbench.
- The full workbench can be desktop-first because uploads, column mapping, detailed geometry checks, AOI editing, and table inspection are not naturally phone workflows.
- A good structure is one app with two entry paths:
  - demo mode: fast, guided, mobile-safe
  - workbench mode: full researcher tool

## Deployment Priority

Deployment should move earlier than originally planned because it is the least familiar/riskier part.

Target path:

`conference QR -> public HTTPS URL -> tunnel -> P330 Docker container -> Shiny app`

The university server should be treated as a bonus, not the plan, because the available internal-facing server does not solve access for non-university conference attendees.

## Older Repos Worth Mining

Useful prior implementation evidence was consolidated into this repository.
The retired local checkout paths no longer exist.

Reusable pieces found:

- click-to-add AOI centres
- double-click delete nearest centre
- `deldir` Voronoi tessellation and plotting
- fixation assignment by nearest AOI centre
- early metrics and download handlers
- extracted AOI helper functions in `helpers_aoi.R`

Important dependency note:

- `vorogazeaoi` does not yet include `deldir` in `renv.lock`.
- Older repos do include `deldir`.

## Revised 8-Week Shape

1. Prove deployment early with Docker/Shiny Server on the P330 and a public tunnel.
2. Make the public demo mode safe, bundled, and self-contained.
3. Import AOI centre editing and live Voronoi display.
4. Implement fixation-to-AOI assignment against validated geometry.
5. Build and polish metric outputs and downloads.
6. Polish the phone demo, desktop workbench, poster story, and backup plan.
