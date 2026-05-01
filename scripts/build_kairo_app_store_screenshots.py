#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-raw-alternating-20260430"
OUT_DIR = ROOT / "output/app-store-screenshots/iphone-6-5-reference-match-v6-tight-bezel-20260430"

CANVAS_W = 1284
CANVAS_H = 2778

TITLE_Y = 238
PHONE_W = 984
PHONE_H = 2096
PHONE_X = (CANVAS_W - PHONE_W) // 2
PHONE_Y = 536
PHONE_SCREEN_X = 0.017
PHONE_SCREEN_Y = 0.008
PHONE_SCREEN_W = 0.966
PHONE_SCREEN_H = 0.984
PHONE_SCREEN_RADIUS = 0.084

TITLE_MAX_W = 1150
TITLE_START_SIZE = 78
TITLE_MIN_SIZE = 62


@dataclass(frozen=True)
class Shot:
    index: int
    title: str
    raw_name: str

    @property
    def output_name(self) -> str:
        return self.raw_name


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


def font(path: str, size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size, index=index)


TITLE_FONT_PATH = "/System/Library/Fonts/HelveticaNeue.ttc"
TITLE_FONT_INDEX = 1


def text_size(draw: ImageDraw.ImageDraw, text: str, font_obj: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=font_obj)
    return box[2] - box[0], box[3] - box[1]


def fit_title(draw: ImageDraw.ImageDraw, title: str) -> ImageFont.FreeTypeFont:
    for size in range(TITLE_START_SIZE, TITLE_MIN_SIZE - 1, -2):
        font_obj = font(TITLE_FONT_PATH, size, TITLE_FONT_INDEX)
        width, _ = text_size(draw, title, font_obj)
        if width <= TITLE_MAX_W:
            return font_obj
    return font(TITLE_FONT_PATH, TITLE_MIN_SIZE, TITLE_FONT_INDEX)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    x, y, w, h = box
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    base.alpha_composite(shadow)


def draw_phone(base: Image.Image, raw_path: Path) -> None:
    draw = ImageDraw.Draw(base)
    outer_radius = int(round(PHONE_W * 0.125))
    paste_shadow(base, (PHONE_X + 1, PHONE_Y + 14, PHONE_W - 2, PHONE_H - 10), outer_radius)

    # iPhone 15/16-style geometry: thin near-black hardware rim, side buttons,
    # clipped screen, and Dynamic Island. The dimensions follow the public
    # 433 x 882 iPhone mockup proportions rather than the old generic slab.
    draw.rounded_rectangle(
        (PHONE_X, PHONE_Y, PHONE_X + PHONE_W, PHONE_Y + PHONE_H),
        radius=outer_radius,
        fill=(12, 11, 11, 255),
    )
    draw.rounded_rectangle(
        (PHONE_X + 4, PHONE_Y + 4, PHONE_X + PHONE_W - 4, PHONE_Y + PHONE_H - 4),
        radius=outer_radius - 4,
        outline=(45, 39, 39, 255),
        width=3,
    )

    raw = Image.open(raw_path).convert("RGBA")
    screen_x = int(round(PHONE_X + PHONE_W * PHONE_SCREEN_X))
    screen_y = int(round(PHONE_Y + PHONE_H * PHONE_SCREEN_Y))
    screen_w = int(round(PHONE_W * PHONE_SCREEN_W))
    screen_h = int(round(PHONE_H * PHONE_SCREEN_H))
    screen = raw.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    screen_mask = rounded_mask((screen_w, screen_h), int(round(screen_w * PHONE_SCREEN_RADIUS)))
    base.paste(screen, (screen_x, screen_y), screen_mask)

    draw.rounded_rectangle(
        (screen_x - 1, screen_y - 1, screen_x + screen_w + 1, screen_y + screen_h + 1),
        radius=int(round(screen_w * PHONE_SCREEN_RADIUS)) + 2,
        outline=(12, 11, 11, 255),
        width=3,
    )

    island_w = int(round(screen_w * 0.275))
    island_h = int(round(screen_w * 0.062))
    island_x = screen_x + (screen_w - island_w) // 2
    island_y = screen_y + int(round(screen_w * 0.025))
    draw.rounded_rectangle(
        (island_x, island_y, island_x + island_w, island_y + island_h),
        radius=island_h // 2,
        fill=(0, 0, 0, 255),
    )
    lens_r = max(5, int(round(island_h * 0.16)))
    lens_x = island_x + island_w - int(round(island_h * 0.55))
    lens_y = island_y + island_h // 2
    draw.ellipse((lens_x - lens_r, lens_y - lens_r, lens_x + lens_r, lens_y + lens_r), fill=(6, 11, 10, 255))
    glint_r = max(2, lens_r // 3)
    draw.ellipse((lens_x - glint_r, lens_y - glint_r, lens_x + glint_r, lens_y + glint_r), fill=(29, 90, 76, 185))


def draw_title(base: Image.Image, title: str) -> None:
    draw = ImageDraw.Draw(base)
    title_font = fit_title(draw, title)
    width, height = text_size(draw, title, title_font)
    x = (CANVAS_W - width) // 2
    draw.text((x, TITLE_Y), title, font=title_font, fill=(23, 23, 28, 255))


def build_shot(shot: Shot) -> Path:
    raw_path = RAW_DIR / shot.raw_name
    base = Image.new("RGBA", (CANVAS_W, CANVAS_H), (255, 255, 255, 255))
    draw_title(base, shot.title)
    draw_phone(base, raw_path)
    output_path = OUT_DIR / shot.output_name
    base.convert("RGB").save(output_path, quality=96)
    return output_path


def make_contact_sheet(paths: Iterable[Path]) -> Path:
    images = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 250
    thumb_h = int(round(thumb_w * CANVAS_H / CANVAS_W))
    gutter = 18
    cols = 5
    rows = 2
    sheet_w = (thumb_w * cols) + (gutter * (cols + 1))
    sheet_h = (thumb_h * rows) + (gutter * (rows + 1))
    sheet = Image.new("RGB", (sheet_w, sheet_h), (18, 18, 18))
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
    outputs = [build_shot(shot) for shot in SHOTS]
    contact = make_contact_sheet(outputs)
    print(contact)
    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
