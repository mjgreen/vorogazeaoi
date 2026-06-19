#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const { chromium } = require("playwright");

const repoRoot = path.resolve(__dirname, "..");

function readArg(name, fallback) {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((arg) => arg.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

const appUrl = readArg("url", process.env.VOROGAZE_AOI_URL || "http://127.0.0.1:3840/");
const outputPath = path.resolve(
  repoRoot,
  readArg("output", process.env.VOROGAZE_AOI_VIDEO || "www/aoi-demo-screencast.mp4")
);
const chromePath = readArg(
  "chrome",
  process.env.CHROME_PATH || "/usr/bin/google-chrome-stable"
);
const viewport = { width: 1600, height: 1000 };
const imageSize = { width: 350, height: 466 };
const targetFps = Number(readArg("fps", process.env.VOROGAZE_AOI_FPS || "12"));

const landmarks = [
  { label: "left_eye", x: 130, y: 224 },
  { label: "right_eye", x: 230, y: 224 },
  { label: "nose", x: 174, y: 258 },
  { label: "mouth", x: 174, y: 325 },
  { label: "chin", x: 177, y: 388 },
];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function injectVideoOverlays(page) {
  await page.addStyleTag({
    content: `
      .poster-video-callout {
        position: fixed;
        left: 50%;
        bottom: 96px;
        z-index: 2147483000;
        transform: translateX(-50%);
        max-width: min(760px, calc(100vw - 64px));
        padding: 10px 16px;
        border-radius: 999px;
        background: rgba(0, 35, 44, 0.88);
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.22);
        color: #ffffff;
        font: 700 22px/1.2 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        letter-spacing: 0;
        opacity: 0;
        transition: opacity 180ms ease, transform 180ms ease;
        pointer-events: none;
      }

      .poster-video-callout.is-visible {
        opacity: 1;
        transform: translateX(-50%) translateY(-4px);
      }

      .poster-video-cursor {
        position: fixed;
        left: 0;
        top: 0;
        z-index: 2147483001;
        width: 22px;
        height: 22px;
        border: 3px solid #ffffff;
        border-radius: 999px;
        background: rgba(0, 153, 184, 0.9);
        box-shadow: 0 0 0 2px rgba(0, 35, 44, 0.75), 0 4px 14px rgba(0, 0, 0, 0.3);
        transform: translate(-80px, -80px);
        transition: transform 320ms ease;
        pointer-events: none;
      }

      .poster-video-click-ring {
        position: fixed;
        z-index: 2147483000;
        width: 18px;
        height: 18px;
        border: 3px solid rgba(247, 208, 96, 0.95);
        border-radius: 999px;
        pointer-events: none;
        transform: translate(-50%, -50%) scale(0.4);
        animation: poster-click-ring 540ms ease-out forwards;
      }

      @keyframes poster-click-ring {
        to {
          opacity: 0;
          transform: translate(-50%, -50%) scale(3.4);
        }
      }

      .poster-video-metrics-focus {
        border-radius: 8px;
        box-shadow: 0 0 0 4px rgba(247, 208, 96, 0.8), 0 10px 28px rgba(0, 35, 44, 0.18);
        transition: box-shadow 180ms ease;
      }
    `,
  });

  await page.evaluate(() => {
    const callout = document.createElement("div");
    callout.className = "poster-video-callout";
    document.body.appendChild(callout);

    const cursor = document.createElement("div");
    cursor.className = "poster-video-cursor";
    document.body.appendChild(cursor);

    window.__aoiPosterVideo = {
      showCallout(text) {
        callout.textContent = text;
        callout.classList.add("is-visible");
      },
      hideCallout() {
        callout.classList.remove("is-visible");
      },
      moveCursor(x, y) {
        cursor.style.transform = `translate(${x - 11}px, ${y - 11}px)`;
      },
      clickRing(x, y) {
        const ring = document.createElement("div");
        ring.className = "poster-video-click-ring";
        ring.style.left = `${x}px`;
        ring.style.top = `${y}px`;
        document.body.appendChild(ring);
        setTimeout(() => ring.remove(), 620);
      },
      focusMetrics() {
        const metrics = document.querySelector("#aoi_demo_metrics table");
        if (metrics) metrics.classList.add("poster-video-metrics-focus");
      },
    };
  });
}

async function showCallout(page, text) {
  await page.evaluate((value) => window.__aoiPosterVideo.showCallout(value), text);
}

async function moveCursor(page, x, y) {
  await page.evaluate(({ x: nextX, y: nextY }) => {
    window.__aoiPosterVideo.moveCursor(nextX, nextY);
  }, { x, y });
  await page.mouse.move(x, y);
  await sleep(360);
}

async function clickAt(page, x, y) {
  await moveCursor(page, x, y);
  await page.mouse.click(x, y);
  await page.evaluate(({ x: clickX, y: clickY }) => {
    window.__aoiPosterVideo.clickRing(clickX, clickY);
  }, { x, y });
  await sleep(420);
}

async function clickSelector(page, selector) {
  const box = await page.locator(selector).boundingBox();
  if (!box) throw new Error(`Missing clickable selector: ${selector}`);
  await clickAt(page, box.x + box.width / 2, box.y + box.height / 2);
}

async function clickImageCoord(page, coord) {
  const box = await page.locator("#aoi_demo_plot img").boundingBox();
  if (!box) throw new Error("AOI plot image is not available.");

  const pageX = box.x + (coord.x / imageSize.width) * box.width;
  const pageY = box.y + (coord.y / imageSize.height) * box.height;
  await clickAt(page, pageX, pageY);
}

async function setLandmarkLabel(page, label) {
  await page.fill("#aoi_demo_label", label);
  await sleep(260);
}

async function record() {
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  const frameDir = fs.mkdtempSync(path.join(os.tmpdir(), "vorogaze-aoi-frames-"));

  const browser = await chromium.launch({
    headless: true,
    executablePath: chromePath,
    args: ["--no-sandbox"],
  });

  const context = await browser.newContext({
    viewport,
  });

  const page = await context.newPage();
  await page.goto(appUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
  await page.waitForSelector("#aoi_demo_plot img", { timeout: 30000 });
  await page.waitForSelector("#aoi_demo_metrics >> text=TOTAL_FIX_DUR", { timeout: 30000 });
  await page.waitForSelector("#aoi_demo_landmarks >> text=left_eye", { timeout: 30000 });
  await injectVideoOverlays(page);

  let frameIndex = 0;
  let capture = true;
  let captureError = null;
  const captureStartedAt = Date.now();
  const frameInterval = 1000 / targetFps;
  const captureFrames = (async () => {
    while (capture) {
      const started = Date.now();
      const framePath = path.join(frameDir, `frame-${String(frameIndex).padStart(5, "0")}.jpg`);
      try {
        await page.screenshot({
          path: framePath,
          type: "jpeg",
          quality: 88,
          fullPage: false,
        });
        frameIndex += 1;
      } catch (error) {
        captureError = error;
        capture = false;
        break;
      }

      const elapsed = Date.now() - started;
      await sleep(Math.max(0, frameInterval - elapsed));
    }
  })();

  await showCallout(page, "Interactive AOI demo");
  await sleep(3000);

  await clickSelector(page, "#aoi_demo_clear");
  await showCallout(page, "Start from fixations on one face");
  await page.waitForFunction(() => {
    const metrics = document.querySelector("#aoi_demo_metrics");
    const landmarks = document.querySelector("#aoi_demo_landmarks");
    return metrics && landmarks && !metrics.innerText.trim() && !landmarks.innerText.trim();
  }, null, { timeout: 5000 });
  await sleep(1400);

  await showCallout(page, "Click landmarks");
  await setLandmarkLabel(page, landmarks[0].label);
  await clickImageCoord(page, landmarks[0]);
  await sleep(900);

  await setLandmarkLabel(page, landmarks[1].label);
  await clickImageCoord(page, landmarks[1]);
  await showCallout(page, "Voronoi AOIs update live");
  await sleep(1500);

  await showCallout(page, "Click landmarks");
  for (const landmark of landmarks.slice(2)) {
    await setLandmarkLabel(page, landmark.label);
    await clickImageCoord(page, landmark);
    await sleep(980);
  }

  await showCallout(page, "Assign fixations to AOIs");
  await clickSelector(page, "#aoi_demo_assign");
  await page.waitForSelector("#aoi_demo_metrics >> text=TOTAL_FIX_DUR", { timeout: 5000 });
  await sleep(3000);

  await page.evaluate(() => window.__aoiPosterVideo.focusMetrics());
  await showCallout(page, "TOTAL_FIX_DUR summarizes dwell time by AOI");
  await sleep(9500);

  capture = false;
  await captureFrames;

  if (captureError) {
    throw captureError;
  }

  await context.close();
  await browser.close();

  const captureSeconds = (Date.now() - captureStartedAt) / 1000;
  const inputFps = frameIndex / captureSeconds;

  execFileSync("ffmpeg", [
    "-y",
    "-framerate",
    inputFps.toFixed(4),
    "-i",
    path.join(frameDir, "frame-%05d.jpg"),
    "-an",
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-r",
    "30",
    "-preset",
    "veryfast",
    "-crf",
    "24",
    "-movflags",
    "+faststart",
    outputPath,
  ], { stdio: "inherit" });

  fs.rmSync(frameDir, { recursive: true, force: true });
  console.log(`Wrote ${outputPath}`);
  console.log(`Captured ${frameIndex} frames over ${captureSeconds.toFixed(1)} seconds.`);
}

record().catch((error) => {
  console.error(error);
  process.exit(1);
});
