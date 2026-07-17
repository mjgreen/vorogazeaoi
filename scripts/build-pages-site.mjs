import { cp, mkdir, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const output = path.join(root, "pages-dist");
const revision = process.env.VOROGAZE_STATIC_REVISION || "development";
const dynamicDemo =
  process.env.VOROGAZE_DEMO_URL || "https://vorogaze-demo.mjgreen.uk/";
const dynamicDemoImage =
  process.env.VOROGAZE_DEMO_IMAGE_VERSION || "unversioned";

if (!/^[A-Za-z0-9._/-]+$/.test(revision)) {
  throw new Error("VOROGAZE_STATIC_REVISION contains unsupported characters");
}
for (const [name, value] of Object.entries({ dynamicDemo, dynamicDemoImage })) {
  if (
    !value ||
    value.length > 240 ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    throw new Error(`${name} must be a short printable value`);
  }
}
if (!/^https:\/\/[A-Za-z0-9.-]+\/$/.test(dynamicDemo)) {
  throw new Error("VOROGAZE_DEMO_URL must be an HTTPS origin ending in /");
}

const video = path.join(root, "www/aoi-demo-screencast.mp4");
if ((await stat(video)).size === 0) throw new Error("Conference screencast is empty");

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(path.join(root, "pages-src"), output, { recursive: true });
await cp(video, path.join(output, "aoi-demo-screencast.mp4"));

await writeFile(
  path.join(output, "release-manifest.json"),
  `${JSON.stringify(
    {
      schemaVersion: 1,
      product: "vorogaze",
      staticRevision: revision,
      publicBoundary: "bundled-conference-data-only",
      dynamicDemo,
      dynamicDemoImage,
    },
    null,
    2,
  )}\n`,
);

console.log(`Built VoroGaze Pages site revision ${revision}`);
