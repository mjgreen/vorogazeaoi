import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const workedExampleUrl = "https://worked-example.test/";
const researchWorkbenchUrl = "https://research-workbench.test/";
execFileSync(process.execPath, [path.join(root, "scripts/build-pages-site.mjs")], {
  cwd: root,
  env: {
    ...process.env,
    VOROGAZE_STATIC_REVISION: "test-preview",
    VOROGAZE_WORKED_EXAMPLE_URL: workedExampleUrl,
    VOROGAZE_WORKED_EXAMPLE_IMAGE_VERSION:
      "ghcr.io/mjgreen/vorogaze-example:test",
    VOROGAZE_RESEARCH_WORKBENCH_URL: researchWorkbenchUrl,
    VOROGAZE_RESEARCH_WORKBENCH_IMAGE_VERSION:
      "ghcr.io/mjgreen/vorogaze-workbench:test",
  },
  stdio: "pipe",
});

const output = path.join(root, "pages-dist");
const index = readFileSync(path.join(output, "index.html"), "utf8");
const manifest = JSON.parse(readFileSync(path.join(output, "release-manifest.json"), "utf8"));
const robots = readFileSync(path.join(output, "robots.txt"), "utf8");
const styles = readFileSync(path.join(output, "styles.css"), "utf8");

assert.match(index, /VoroGaze Research Workbench/);
assert.match(index, /Interactive worked example/);
assert.match(index, /30-second screencast/);
assert.match(index, /Interactive – temporary uploads/);
assert.match(index, /Interactive – bundled data/);
assert.match(index, /Video – 30 seconds/);
assert.match(index, new RegExp(researchWorkbenchUrl));
assert.match(index, new RegExp(workedExampleUrl));
assert.doesNotMatch(index, /href="https:\/\/vorogaze-workbench\.mjgreen\.uk\//);
assert.doesNotMatch(index, /href="https:\/\/vorogaze-example\.mjgreen\.uk\//);
assert.match(index, /href="#screencast"/);
assert.match(index, /temporary uploads for the current browser session only/i);
assert.match(index, /Do not upload identifiable or sensitive participant data/);
assert.match(index, /bundled DeBruine et al face/i);
assert.doesNotMatch(index, /Lisa1/i);
assert.doesNotMatch(index, /vorogaze-demo/i);
assert.doesNotMatch(index, /public[ -]demo/i);
assert.match(index, /10\.6084\/m9\.figshare\.5047666/);
assert.match(index, /aoi-demo-screencast\.mp4/);
assert.ok(statSync(path.join(output, "aoi-demo-screencast.mp4")).size > 100_000);
assert.equal(manifest.schemaVersion, 2);
assert.equal(manifest.staticRevision, "test-preview");
assert.equal(
  manifest.publicBoundary,
  "landing-screencast-and-external-interactive-routes",
);
assert.equal(manifest.workedExample, workedExampleUrl);
assert.equal(
  manifest.workedExampleImage,
  "ghcr.io/mjgreen/vorogaze-example:test",
);
assert.equal(
  manifest.researchWorkbench,
  researchWorkbenchUrl,
);
assert.equal(
  manifest.researchWorkbenchImage,
  "ghcr.io/mjgreen/vorogaze-workbench:test",
);
assert.match(styles, /grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/);
assert.match(styles, /@media \(max-width: 900px\)/);
assert.match(styles, /min-height:\s*44px/);
assert.match(styles, /overflow-wrap:\s*anywhere/);
assert.match(styles, /:focus-visible\s*\{\s*outline:\s*3px solid var\(--ink\)/);
assert.match(robots, /User-agent: \*\nAllow: \//);

console.log("Verified route naming and links, privacy copy, attribution, responsive/touch CSS, video, crawler policy, and schema-v2 release manifest.");
