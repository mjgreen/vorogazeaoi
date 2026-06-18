# Lisa1 AOI Demo Fixture

This folder contains the small one-face fixture used by the first AOI/Voronoi
conference prototype.

Source on Matt's machine:

```text
/home/matt/gits/vorogaze/inputs/lisa1
```

Included files:

```text
faces/001_03.jpg
fixrep_demo.csv
```

`fixrep_demo.csv` was generated from `fixrep_lisa.csv` by filtering to
`FACE == "001_03"` and rewriting the fixation report to the app's canonical
demo columns:

```text
SUBJECT, TRIAL_ID, FACE, FIX_INDEX, CONDITION, IMG_X, IMG_Y, FIX_X, FIX_Y, FIX_DUR
```

Expected fixture shape:

- 20 fixation rows
- 1 face: `001_03`
- 2 subjects/sessions
- image centre: `(175, 233)`
- image size: `350 x 466`

## Face Image Provenance

The face image is from the Face Research Lab London Set:

```text
DeBruine, L., & Jones, B. (2017). Face Research Lab London Set. figshare.
https://figshare.com/articles/dataset/Face_Research_Lab_London_Set/5047666
DOI: 10.6084/m9.figshare.5047666
Licence: CC BY 4.0
```

The dataset record states that individuals gave signed consent for use in
lab-based and web-based studies and to illustrate research, including
presentations. Keep this attribution with any public demo or conference
materials using the fixture.
