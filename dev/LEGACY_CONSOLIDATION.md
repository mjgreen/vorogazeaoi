# Legacy VoroGaze Consolidation

This repo is the canonical VoroGaze home. The older local/GitHub repos were
reviewed so their useful concepts could be folded into `vorogazeaoi` before
the old repos were archived and deleted.

The legacy row named `vorogazeaoi` below refers to the deleted pre-consolidation
repo. After that archive was verified, the canonical repo was renamed from
`vorogazeaoi3` to `vorogazeaoi`.

## Legacy Inputs Reviewed

| Repo/folder | HEAD | Archive file | What was absorbed |
| --- | --- | --- | --- |
| `gazev` | `0f541c5514cd` | `gazev.bundle` | Early screen/face geometry and click-to-place AOI centre sketch. |
| `vorogaze` | `001f5589a95d` | `vorogaze.bundle` | Upload/mapping flow, AOI assignment outputs, summary metrics, and London Face Set provenance notes. |
| `vorogaze2-sanity-checking` | `e7b94bd8ef3c` | `vorogaze2-sanity-checking.bundle` | Sanity-check idea of viewing screen, face image, and fixations together. |
| `vorogazeaoi` | `5f0ad5522135` | `vorogazeaoi.bundle` | Best refactored AOI workbench: click landmarks, delete nearest, `deldir`, fixation assignment, session metrics, downloads. |
| `vorogazeaoi2` | `cbec89585364` | `vorogazeaoi2.bundle` | Improved mapping validation and screen-parameter checking ideas. |
| `vorotest` | local folder | `vorotest.tar.gz` | Early synthetic fixation/image-placement prototype. |

## Carried Forward

- `vorogazeaoi` now contains the runnable AOI Workbench for landmark editing,
  live Voronoi display, fixation assignment, committed session tables, metrics,
  and CSV downloads.
- Mapping validation now flags duplicate column mappings, missing fixation/image
  coordinates, numeric coercion failures, and coordinate ranges.
- Optional face preprocessing/alignment ideas were preserved in
  `scripts/align_faces_optional.R` as development-only tooling.
- The existing authenticated deployment, poster assets, bundled demo data, and
  sanity-check workflow remain in this repo.

## Intentionally Not Copied

- Duplicate historical face-image folders and large redundant data files were
  not copied into the canonical repo.
- `webmorphR`, `webmorphR.dlib`, `reticulate`, and Python/dlib are not runtime
  dependencies of the Shiny app or Docker deployment.
- Early single-file app layouts were not retained as user-facing entrypoints.

## Recovery Location

The deletion run writes verified bundles and checksums under:

```text
/home/matt/gits/_archive/vorogaze-consolidation-20260623/
```

Use the bundle files there if a deleted legacy repo ever needs to be inspected
or restored.
