#!/usr/bin/env python3
from __future__ import annotations

import html
import subprocess
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-raw-alternating-20260430"
OUT_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-browser-device-frame-v2-20260430"
HTML_DIR = OUT_DIR / "_html"

CANVAS_W = 1284
CANVAS_H = 2778
TITLE_Y = 236
PHONE_W = 988
PHONE_X = (CANVAS_W - PHONE_W) // 2
PHONE_Y = 536

# iPhone 15 Pro Max frame geometry from FrameUp-Free's MIT-licensed device data.
# It gives the screenshot a true screen mask and overlays a vector device frame,
# which is the workflow used by premium App Store screenshot generators.
DEVICE_W = 460
DEVICE_H = 962
SCREEN_X = 15
SCREEN_Y = 15
SCREEN_W = 430
SCREEN_H = 932
SCREEN_R = 55
ISLAND_X = 167.5
ISLAND_Y = 26.33
ISLAND_W = 125
ISLAND_H = 36.67


@dataclass(frozen=True)
class Shot:
    index: int
    title: str
    raw_name: str


SHOTS: tuple[Shot, ...] = (
    Shot(1, "Never Miss What’s Due", "01-today-light.png"),
    Shot(2, "Shot Logging, Zero Friction", "02-log-dark.png"),
    Shot(3, "Ditch the Spreadsheet", "03-protocols-light.png"),
    Shot(4, "See What’s Actually Changing", "04-progress-dark.png"),
    Shot(5, "Meet your companion", "05-companion-light.png"),
    Shot(6, "Never Guess What’s Left", "06-inventory-dark.png"),
    Shot(7, "Proof Beyond the Scale", "07-evidence-light.png"),
    Shot(8, "Private. Locked. Yours.", "08-privacy-dark.png"),
    Shot(9, "Stay On Track Anywhere", "09-widgets-light.png"),
    Shot(10, "Turn Weeks Into Wins", "10-weekly-review-dark.png"),
)


def file_url(path: Path) -> str:
    return path.resolve().as_uri()


def render_html(shot: Shot) -> str:
    raw_path = RAW_DIR / shot.raw_name
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width={CANVAS_W}, initial-scale=1">
  <style>
    * {{ box-sizing: border-box; }}
    html, body {{
      margin: 0;
      width: {CANVAS_W}px;
      height: {CANVAS_H}px;
      overflow: hidden;
      background: #fff;
    }}
    body {{
      font-family: "Helvetica Neue", -apple-system, BlinkMacSystemFont, "SF Pro Display", Arial, sans-serif;
    }}
    .canvas {{
      position: relative;
      width: {CANVAS_W}px;
      height: {CANVAS_H}px;
      background: #fff;
    }}
    .title {{
      position: absolute;
      top: {TITLE_Y}px;
      left: 0;
      width: 100%;
      text-align: center;
      color: #17171d;
      font-size: 78px;
      line-height: 0.98;
      font-weight: 800;
      letter-spacing: 0;
      white-space: nowrap;
    }}
    .device {{
      position: absolute;
      left: {PHONE_X}px;
      top: {PHONE_Y}px;
      width: {PHONE_W}px;
      aspect-ratio: {DEVICE_W} / {DEVICE_H};
      filter: drop-shadow(0 24px 28px rgba(0,0,0,0.20));
    }}
    .screen {{
      position: absolute;
      left: calc({SCREEN_X} / {DEVICE_W} * 100%);
      top: calc({SCREEN_Y} / {DEVICE_H} * 100%);
      width: calc({SCREEN_W} / {DEVICE_W} * 100%);
      height: calc({SCREEN_H} / {DEVICE_H} * 100%);
      border-radius: calc({SCREEN_R} / {SCREEN_W} * 100%) / calc({SCREEN_R} / {SCREEN_H} * 100%);
      overflow: hidden;
      background: #f8f6f1;
      transform: translateZ(0);
    }}
    .screen img {{
      display: block;
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: top center;
    }}
    .frame {{
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
    }}
  </style>
</head>
<body>
  <main class="canvas" id="ready">
    <div class="title">{html.escape(shot.title)}</div>
    <div class="device">
      <div class="screen"><img src="{file_url(raw_path)}" alt=""></div>
      <svg class="frame" viewBox="0 0 {DEVICE_W} {DEVICE_H}" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="{ISLAND_X}" y="{ISLAND_Y}" width="{ISLAND_W}" height="{ISLAND_H}" rx="{ISLAND_H / 2}" fill="black"/>
        <circle cx="{ISLAND_X + ISLAND_W - 20}" cy="{ISLAND_Y + ISLAND_H / 2}" r="5.8" fill="#030806"/>
        <circle cx="{ISLAND_X + ISLAND_W - 20}" cy="{ISLAND_Y + ISLAND_H / 2}" r="2.0" fill="#0c6b56" opacity="0.7"/>
        <rect x="10" y="10" width="440" height="942" rx="63" stroke="#090707" stroke-width="10"/>
        <rect x="3" y="3" width="454" height="956" rx="70" stroke="#211917" stroke-opacity="0.9" stroke-width="4"/>
      </svg>
    </div>
  </main>
</body>
</html>
"""


def make_contact_sheet(paths: list[Path]) -> Path:
    images = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 250
    thumb_h = round(thumb_w * CANVAS_H / CANVAS_W)
    gutter = 18
    cols = 5
    rows = 2
    sheet = Image.new("RGB", ((thumb_w * cols) + (gutter * (cols + 1)), (thumb_h * rows) + (gutter * (rows + 1))), (18, 18, 18))
    for i, image in enumerate(images):
        thumb = image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gutter + (i % cols) * (thumb_w + gutter)
        y = gutter + (i // cols) * (thumb_h + gutter)
        sheet.paste(thumb, (x, y))
    output_path = OUT_DIR / "contact-sheet.jpg"
    sheet.save(output_path, quality=94)
    return output_path


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    HTML_DIR.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for shot in SHOTS:
        html_path = HTML_DIR / f"{shot.index:02d}.html"
        html_path.write_text(render_html(shot), encoding="utf-8")
        output_path = OUT_DIR / shot.raw_name
        subprocess.run(
            [
                "npx",
                "playwright",
                "screenshot",
                "--viewport-size",
                f"{CANVAS_W},{CANVAS_H}",
                "--wait-for-selector",
                "#ready",
                file_url(html_path),
                str(output_path),
            ],
            check=True,
        )
        outputs.append(output_path)
    contact = make_contact_sheet(outputs)
    print(contact)
    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
