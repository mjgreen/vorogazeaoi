# How to use VoroGaze AOI

Draft user-facing instructions. This text is currently shown in the Developer
tab while the wording is being tested. Promote it to a visible Instructions or
Guide tab after another review pass.

## What the app is for

VoroGaze AOI helps you check where fixations fall relative to face images and
then assign those fixations to face regions of interest. The app is meant to
make the geometry visible before metrics are exported.

Use it when you want to:

- check that fixation coordinates, screen coordinates, and face-image placement
  line up;
- define AOI centres on a face image;
- assign fixations to those AOIs;
- download trial-level and AOI-level metrics.

## Which tab should I use?

- **AOI demo** is a small built-in example. Use it first if you want to see the
  idea without uploading anything.
- **Fixations** is for loading or checking a fixation report.
- **Screen** is for checking screen dimensions and coordinate origin.
- **Faces** is for loading or checking face images.
- **Sanity** shows fixation positions and the selected face together so you can
  spot obvious geometry problems.
- **AOI Workbench** is the main place to define AOIs, assign fixations, and
  download metrics.

If you only want to try the bundled data, you can go straight to **AOI
Workbench**.

## Quick workflow

1. Open **AOI Workbench**.
2. Select a face/trial/condition combination.
3. Click on the face image to add AOI centres.
4. Double-click near a centre if you need to remove it.
5. Use the assignment controls to assign fixations to AOIs.
6. Check the output briefly to make sure the result looks plausible.
7. Use the metric download buttons to save the output.

For a first test, do not worry about every output tab. The important endpoint is
the downloaded metrics.

## Uploading your own data

1. In **Fixations**, upload the fixation report.
2. Check the column mappings for participant, face, trial, condition, fixation
   coordinates, fixation duration, and image position.
3. In **Faces**, upload or browse the face-image folder.
4. Use **Sanity** to check that the face and fixations appear in the same
   coordinate space.
5. Move to **AOI Workbench** to define AOIs and export metrics.

The bundled fixation report and bundled face folder are useful for checking how
the app expects files to look.

## What the output area means

The output area is there to help you check what the app is doing. It may show
tables, summaries, assignments, or metric previews depending on the current
state of the workbench.

If you are testing the main user workflow, focus on these questions:

- Did my AOI centres appear where I clicked?
- Were fixations assigned to AOIs?
- Do the downloaded metrics contain the rows and columns I expected?

You can ignore detailed debug-style output if all you need is the exported
metrics.

## What to report back

Useful feedback includes:

- where you expected to click next;
- whether the app made it clear that AOI Workbench is the main analysis tab;
- whether the metric download route was easy to find;
- any point where the output tabs distracted you from the main task;
- whether uploads, bundled downloads, and metric downloads worked.
