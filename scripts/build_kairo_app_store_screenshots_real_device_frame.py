#!/usr/bin/env python3
from __future__ import annotations

import math
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-raw-alternating-20260430"
OUT_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-real-device-frame-v2-20260430"
FRAME_DIR = ROOT / "output/app-store-screenshots/_frames"
FRAME_PATH = FRAME_DIR / "Apple-iPhone-16-Pro-Max-Black-Titanium.png"
FRAME_URL = (
    "https://raw.githubusercontent.com/fastlane/frameit-frames/gh-pages/latest/"
    "Apple%20iPhone%2016%20Pro%20Max%20Black%20Titanium.png"
)

CANVAS_W = 1284
CANVAS_H = 2778

# Calibrated against the attached App Store reference: copy in the upper band,
# large un-squished device, and the phone bottom landing close to the card foot.
TITLE_Y = 246
TITLE_SIZE = 78
PHONE_FRAME_W = 1016
PHONE_Y = 520

# Fastlane frameit offsets for Apple iPhone 16 Pro Max Black Titanium.
FRAME_W = 1470
FRAME_H = 3000
SCREEN_X = 75
SCREEN_Y = 66
SCREEN_W = 1320
SCREEN_H = 2868
SCREEN_RADIUS = 132

# Dynamic Island proportions derived from the iPhone 15 Pro Max screen geometry
# used by FrameUp-Free. The frameit PNG provides the physical body; this keeps
# the Island aligned to the screen cutout rather than the canvas.
ISLAND_X_FRAC = 0.35465
ISLAND_Y_FRAC = 0.01216
ISLAND_W_FRAC = 0.29070
ISLAND_H_FRAC = 0.03935


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


def ensure_frame() -> None:
    FRAME_DIR.mkdir(parents=True, exist_ok=True)
    if FRAME_PATH.exists():
        return
    with urllib.request.urlopen(FRAME_URL) as response:
        FRAME_PATH.write_bytes(response.read())


def load_title_font() -> ImageFont.FreeTypeFont:
    candidates = [
        ("/System/Library/Fonts/HelveticaNeue.ttc", 1),
        ("/System/Library/Fonts/Helvetica.ttc", 1),
        ("/System/Library/Fonts/SFNS.ttf", 0),
        ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
    ]
    for candidate, index in candidates:
        try:
            return ImageFont.truetype(candidate, TITLE_SIZE, index=index)
        except OSError:
            continue
    return ImageFont.load_default()


def resize_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    scaled_w = math.ceil(image.width * scale)
    scaled_h = math.ceil(image.height * scale)
    scaled = image.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
    left = max(0, (scaled_w - target_w) // 2)
    top = max(0, (scaled_h - target_h) // 2)
    return scaled.crop((left, top, left + target_w, top + target_h))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def paste_with_alpha(base: Image.Image, layer: Image.Image, xy: tuple[int, int]) -> None:
    base.alpha_composite(layer, dest=xy)


def make_shadow(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A")
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(28))
    shadow = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha.point(lambda value: int(value * 0.28)))
    return shadow


def draw_title(canvas: Image.Image, title: str, font: ImageFont.FreeTypeFont) -> None:
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((0, 0), title, font=font)
    text_w = bbox[2] - bbox[0]
    draw.text(((CANVAS_W - text_w) / 2, TITLE_Y), title, font=font, fill=(23, 23, 29, 255))


def draw_dynamic_island(device_layer: Image.Image, scale: float) -> None:
    draw = ImageDraw.Draw(device_layer)
    screen_x = SCREEN_X * scale
    screen_y = SCREEN_Y * scale
    screen_w = SCREEN_W * scale
    screen_h = SCREEN_H * scale

    x = screen_x + screen_w * ISLAND_X_FRAC
    y = screen_y + screen_h * ISLAND_Y_FRAC
    w = screen_w * ISLAND_W_FRAC
    h = screen_h * ISLAND_H_FRAC
    radius = h / 2
    draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=(0, 0, 0, 255))

    lens_r = h * 0.14
    lens_x = x + w - h * 0.62
    lens_y = y + h / 2
    draw.ellipse(
        (lens_x - lens_r, lens_y - lens_r, lens_x + lens_r, lens_y + lens_r),
        fill=(3, 8, 6, 230),
    )
    inner_r = lens_r * 0.36
    draw.ellipse(
        (lens_x - inner_r, lens_y - inner_r, lens_x + inner_r, lens_y + inner_r),
        fill=(18, 80, 72, 135),
    )


def build_shot(shot: Shot, frame: Image.Image, font: ImageFont.FreeTypeFont) -> Path:
    raw = Image.open(RAW_DIR / shot.raw_name).convert("RGBA")
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (255, 255, 255, 255))
    draw_title(canvas, shot.title, font)

    scale = PHONE_FRAME_W / FRAME_W
    frame_h = round(FRAME_H * scale)
    frame_scaled = frame.resize((PHONE_FRAME_W, frame_h), Image.Resampling.LANCZOS)

    screen_box = (
        round(SCREEN_X * scale),
        round(SCREEN_Y * scale),
        round(SCREEN_W * scale),
        round(SCREEN_H * scale),
    )
    screen = resize_cover(raw, (screen_box[2], screen_box[3]))
    screen.putalpha(rounded_mask(screen.size, round(SCREEN_RADIUS * scale)))

    device = Image.new("RGBA", frame_scaled.size, (0, 0, 0, 0))
    paste_with_alpha(device, screen, (screen_box[0], screen_box[1]))
    paste_with_alpha(device, frame_scaled, (0, 0))
    draw_dynamic_island(device, scale)

    x = (CANVAS_W - PHONE_FRAME_W) // 2
    shadow = make_shadow(device)
    paste_with_alpha(canvas, shadow, (x, PHONE_Y + 22))
    paste_with_alpha(canvas, device, (x, PHONE_Y))

    output_path = OUT_DIR / shot.raw_name
    canvas.convert("RGB").save(output_path, quality=96)
    return output_path


def make_contact_sheet(paths: list[Path]) -> Path:
    images = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 250
    thumb_h = round(thumb_w * CANVAS_H / CANVAS_W)
    gutter = 18
    cols = 5
    rows = 2
    sheet = Image.new(
        "RGB",
        ((thumb_w * cols) + (gutter * (cols + 1)), (thumb_h * rows) + (gutter * (rows + 1))),
        (18, 18, 18),
    )
    for i, image in enumerate(images):
        thumb = image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gutter + (i % cols) * (thumb_w + gutter)
        y = gutter + (i // cols) * (thumb_h + gutter)
        sheet.paste(thumb, (x, y))
    output_path = OUT_DIR / "contact-sheet.jpg"
    sheet.save(output_path, quality=94)
    return output_path


def main() -> None:
    ensure_frame()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    frame = Image.open(FRAME_PATH).convert("RGBA")
    font = load_title_font()
    outputs = [build_shot(shot, frame, font) for shot in SHOTS]
    contact = make_contact_sheet(outputs)
    print(contact)
    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
