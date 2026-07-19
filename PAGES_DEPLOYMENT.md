# VoroGaze Pages Site

The public static site is the chooser for three clearly labelled browser
experiences:

- the complete VoroGaze Research Workbench with session-only uploads;
- an interactive worked example using bundled data;
- the existing silent 30-second screencast.

The static site itself does not accept uploads or expose participant data.

Build with:

```text
npm run build:pages
```

The output is written to `pages-dist/`. Authenticate the official Wrangler CLI
with `npx wrangler login`; `npx wrangler whoami` must then list the Cloudflare
account that owns the `vorogaze` Pages project.

The two interactive origins are:

```text
https://vorogaze-example.mjgreen.uk/
https://vorogaze-workbench.mjgreen.uk/
```

Set `VOROGAZE_WORKED_EXAMPLE_URL`,
`VOROGAZE_WORKED_EXAMPLE_IMAGE_VERSION`,
`VOROGAZE_RESEARCH_WORKBENCH_URL` and
`VOROGAZE_RESEARCH_WORKBENCH_IMAGE_VERSION` when building an immutable release.
Schema version 2 of `release-manifest.json` records them as `workedExample`,
`workedExampleImage`, `researchWorkbench` and `researchWorkbenchImage`.

Use the immutable repository revision and the two deployed GHCR digests:

```text
export VOROGAZE_STATIC_REVISION="$(git rev-parse HEAD)"
export VOROGAZE_WORKED_EXAMPLE_URL="https://vorogaze-example.mjgreen.uk/"
export VOROGAZE_WORKED_EXAMPLE_IMAGE_VERSION="ghcr.io/mjgreen/vorogaze-example@sha256:<64-hex-digest>"
export VOROGAZE_RESEARCH_WORKBENCH_URL="https://vorogaze-workbench.mjgreen.uk/"
export VOROGAZE_RESEARCH_WORKBENCH_IMAGE_VERSION="ghcr.io/mjgreen/vorogaze-workbench@sha256:<64-hex-digest>"
npm run build:pages && npm run test:pages
```

The two `@sha256:` values must be the digests reported by the successful
`Publish public VoroGaze images` workflow, not mutable tags.

Confirm that the existing project still owns the custom domain:

```text
npx wrangler pages project list
```

The `vorogaze` row must include both `vorogaze.pages.dev` and
`vorogaze.mjgreen.uk`. If the custom domain is absent, add
`vorogaze.mjgreen.uk` under **Workers & Pages – vorogaze – Custom domains**
before deploying.

Deploy the already-tested directory:

```text
npx wrangler pages deploy pages-dist --project-name vorogaze --branch main --commit-hash "$VOROGAZE_STATIC_REVISION"
```

After Wrangler reports success, verify the custom domain, all three route
links, the screencast, and `release-manifest.json`. The manifest revision and
both image fields must match the deployed commit and GHCR digests.

The worked-example image contains only the bundled DeBruine et al face and
prepared fixation data. The Research Workbench accepts supported uploads only
for the current browser session and warns users not to submit identifiable or
sensitive participant data.
