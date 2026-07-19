import { cp, mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const output = path.join(root, "pages-dist");
const defaultWorkedExample = "https://vorogaze-example.mjgreen.uk/";
const defaultResearchWorkbench = "https://vorogaze-workbench.mjgreen.uk/";
const revision = process.env.VOROGAZE_STATIC_REVISION || "development";
const workedExample =
  process.env.VOROGAZE_WORKED_EXAMPLE_URL ||
  defaultWorkedExample;
const workedExampleImage =
  process.env.VOROGAZE_WORKED_EXAMPLE_IMAGE_VERSION || "unversioned";
const researchWorkbench =
  process.env.VOROGAZE_RESEARCH_WORKBENCH_URL ||
  defaultResearchWorkbench;
const researchWorkbenchImage =
  process.env.VOROGAZE_RESEARCH_WORKBENCH_IMAGE_VERSION || "unversioned";

if (!/^[A-Za-z0-9._/-]+$/.test(revision)) {
  throw new Error("VOROGAZE_STATIC_REVISION contains unsupported characters");
}
for (const [name, value] of Object.entries({
  workedExample,
  workedExampleImage,
  researchWorkbench,
  researchWorkbenchImage,
})) {
  if (
    !value ||
    value.length > 240 ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    throw new Error(`${name} must be a short printable value`);
  }
}
for (const [name, value] of Object.entries({
  VOROGAZE_WORKED_EXAMPLE_URL: workedExample,
  VOROGAZE_RESEARCH_WORKBENCH_URL: researchWorkbench,
})) {
  if (!/^https:\/\/[A-Za-z0-9.-]+\/$/.test(value)) {
    throw new Error(`${name} must be an HTTPS origin ending in /`);
  }
}

const video = path.join(root, "www/aoi-demo-screencast.mp4");
if ((await stat(video)).size === 0) throw new Error("Conference screencast is empty");

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(path.join(root, "pages-src"), output, { recursive: true });
await cp(video, path.join(output, "aoi-demo-screencast.mp4"));

const indexPath = path.join(output, "index.html");
const index = (await readFile(indexPath, "utf8"))
  .replaceAll(defaultWorkedExample, workedExample)
  .replaceAll(defaultResearchWorkbench, researchWorkbench);
await writeFile(indexPath, index);

await writeFile(
  path.join(output, "release-manifest.json"),
  `${JSON.stringify(
    {
      schemaVersion: 2,
      product: "vorogaze",
      staticRevision: revision,
      publicBoundary: "landing-screencast-and-external-interactive-routes",
      workedExample,
      workedExampleImage,
      researchWorkbench,
      researchWorkbenchImage,
    },
    null,
    2,
  )}\n`,
);

console.log(`Built VoroGaze Pages site revision ${revision}`);
