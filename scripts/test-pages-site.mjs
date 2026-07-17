import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
execFileSync(process.execPath, [path.join(root, "scripts/build-pages-site.mjs")], {
  cwd: root,
  env: {
    ...process.env,
    VOROGAZE_STATIC_REVISION: "test-preview",
    VOROGAZE_DEMO_URL: "https://vorogaze-demo.mjgreen.uk/",
    VOROGAZE_DEMO_IMAGE_VERSION: "ghcr.io/mjgreen/vorogaze-demo:test"
  },
  stdio: "pipe",
});

const output = path.join(root, "pages-dist");
const index = readFileSync(path.join(output, "index.html"), "utf8");
const manifest = JSON.parse(readFileSync(path.join(output, "release-manifest.json"), "utf8"));
const robots = readFileSync(path.join(output, "robots.txt"), "utf8");

assert.match(index, /Bundled data only/);
assert.match(index, /10\.6084\/m9\.figshare\.5047666/);
assert.match(index, /aoi-demo-screencast\.mp4/);
assert.ok(statSync(path.join(output, "aoi-demo-screencast.mp4")).size > 100_000);
assert.equal(manifest.staticRevision, "test-preview");
assert.equal(manifest.publicBoundary, "bundled-conference-data-only");
assert.equal(manifest.dynamicDemo, "https://vorogaze-demo.mjgreen.uk/");
assert.equal(
  manifest.dynamicDemoImage,
  "ghcr.io/mjgreen/vorogaze-demo:test"
);
assert.match(robots, /User-agent: \*\nAllow: \//);

console.log("Verified conference copy, attribution, bundled-data boundary, video, crawler policy, and release manifest.");
