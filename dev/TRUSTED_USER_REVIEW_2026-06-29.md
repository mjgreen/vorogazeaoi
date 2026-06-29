# Trusted-User Review Notes

Status: current
Date: 2026-06-29
Applies to: VoroGaze AOI testing
Risk: read-only product/development notes

## Reviewers

- JH: non-specialist for face/eye-tracking AOI work.
- CL: eye-tracking expert, primarily reading rather than face work.

## Findings

- JH reported that bundled download and upload worked without noticeable
  issues.
- JH was able to assign fixations after further exploration.
- JH was unsure whether AOI Workbench was the intended place to work, but
  correctly inferred that it was.
- JH found the output box to the right of the face in AOI Workbench confusing.
- JH found the tabs not super intuitive and over-focused on them before finding
  the metric download route.
- CL reported that bundled downloads and uploading worked.
- CL found the tool self-explanatory for someone with some relevant expertise
  and described it as useful.

## Development Interpretation

- Core upload/download behavior is good enough to protect while iterating.
- The next development priority is user-facing guidance and workflow
  signposting.
- The main risk for unbriefed users is not failure to complete the task, but
  uncertainty about where to work and what output to attend to.

## Follow-Up

- Draft user-facing instructions in `dev/DOCUMENTATION.md` first.
- Keep the instructions in the Developer tab until the wording is stable.
- Later promote stable instructions to a visible Instructions or Guide tab.
- Make "download metrics" easier to discover from AOI Workbench.
- Clarify, rename, or reorder output tabs if users continue to over-focus on
  them.
- Rotate or remove temporary testing credentials after trusted-user testing.
