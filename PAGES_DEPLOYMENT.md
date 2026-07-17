# VoroGaze Pages Site

The public static site is deliberately separate from the upload-capable Shiny
workbench. It presents conference context, the existing silent screencast and
the Lisa1 fixture attribution; it does not accept uploads or expose participant
data.

Build with:

```text
npm run build:pages
```

The output is written to `pages-dist/`. Set `VOROGAZE_STATIC_REVISION` to the
immutable source revision used for a deployment. Run `npm run test:pages` before
uploading the directory to Cloudflare Pages.

The public dynamic origin is `https://vorogaze-demo.mjgreen.uk/`. Its immutable
image version is recorded as `dynamicDemoImage` in `release-manifest.json`.
The image copies only the bundled Lisa1 fixture and the AOI-demo helpers; the
upload-capable workbench is not present in that image.
