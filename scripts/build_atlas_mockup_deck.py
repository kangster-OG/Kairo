#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path("/Users/donghokang/Developer/Atlas")
OUTPUT_DIR = ROOT / "output" / "mockup-deck-2026-04-23"
PASS_17 = ROOT / "output" / "mockup-screenshot-qa" / "continuation-pass-17"
EXPANDED = ROOT / "output" / "codex-fidelity-2026-04-23"


@dataclass(frozen=True)
class DeckScreen:
    slug: str
    title: str
    source: Path
    note: str


SCREENS: tuple[DeckScreen, ...] = (
    DeckScreen("today", "Today", PASS_17 / "today.png", "Approved root reference"),
    DeckScreen("log-shot", "Log Shot", PASS_17 / "log.png", "Approved root reference"),
    DeckScreen("companion", "Companion", PASS_17 / "companion.png", "Approved root reference"),
    DeckScreen("protocols-expanded", "Protocols", EXPANDED / "49-mockup-protocols-expanded.png", "Expanded mockup target"),
    DeckScreen("progress-expanded", "Progress", EXPANDED / "50-mockup-progress-expanded.png", "Expanded mockup target"),
    DeckScreen("supplies-expanded", "Supplies", EXPANDED / "51-mockup-inventory-expanded.png", "Expanded mockup target"),
    DeckScreen("protocol-detail", "Protocol Detail", PASS_17 / "protocol-detail.png", "Deep flow target"),
    DeckScreen("edit-protocol", "Edit Protocol", PASS_17 / "protocol-editor.png", "Deep flow target"),
    DeckScreen("inventory", "Inventory", PASS_17 / "inventory.png", "Deep flow target"),
    DeckScreen("calculator", "Calculator", PASS_17 / "calculator.png", "Deep flow target"),
    DeckScreen("weekly-review", "Weekly Review", PASS_17 / "weekly-review.png", "Deep flow target"),
    DeckScreen("evidence", "Evidence", PASS_17 / "progress-evidence.png", "Deep flow target"),
)


BACKGROUND = "#F6F1E8"
TEXT_PRIMARY = "#1A1F1D"
TEXT_SECONDARY = "#66706C"
CARD_FILL = "#FFFDF8"
CARD_STROKE = "#E3DDD2"

CARD_WIDTH = 560
CARD_RADIUS = 20
HEADER_H = 64
CAPTION_H = 58
INNER_PAD = 20
COLUMNS = 3
GAP_X = 28
GAP_Y = 30
OUTER_PAD = 36


def load_font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates: Iterable[str]
    if bold:
        candidates = (
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        )
    else:
        candidates = (
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica.ttc",
        )

    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


TITLE_FONT = load_font(20, bold=True)
NOTE_FONT = load_font(14)
BOARD_TITLE_FONT = load_font(34, bold=True)
BOARD_SUBTITLE_FONT = load_font(18)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        probe = f"{current} {word}"
        if draw.textlength(probe, font=font) <= max_width:
            current = probe
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def render_card(screen: DeckScreen) -> Image.Image:
    screenshot = Image.open(screen.source).convert("RGB")
    aspect = screenshot.height / screenshot.width
    screenshot_h = round(CARD_WIDTH * aspect)
    total_h = HEADER_H + CAPTION_H + screenshot_h + INNER_PAD

    card = Image.new("RGB", (CARD_WIDTH, total_h), CARD_FILL)
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle(
        (0, 0, CARD_WIDTH - 1, total_h - 1),
        radius=CARD_RADIUS,
        fill=CARD_FILL,
        outline=CARD_STROKE,
        width=1,
    )

    draw.text((INNER_PAD, 16), screen.title, fill=TEXT_PRIMARY, font=TITLE_FONT)
    note_lines = wrap_text(draw, screen.note, NOTE_FONT, CARD_WIDTH - INNER_PAD * 2)
    y = 40
    for line in note_lines[:2]:
        draw.text((INNER_PAD, y), line, fill=TEXT_SECONDARY, font=NOTE_FONT)
        y += 18

    resized = screenshot.resize((CARD_WIDTH, screenshot_h), Image.Resampling.LANCZOS)
    card.paste(resized, (0, HEADER_H))
    return card


def build_board() -> Path:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    cards = [render_card(screen) for screen in SCREENS]
    rows = [cards[index:index + COLUMNS] for index in range(0, len(cards), COLUMNS)]
    row_heights = [max(card.height for card in row) for row in rows]

    board_width = OUTER_PAD * 2 + (CARD_WIDTH * COLUMNS) + (GAP_X * (COLUMNS - 1))
    board_height = OUTER_PAD * 2 + 92 + sum(row_heights) + (GAP_Y * (len(rows) - 1))

    board = Image.new("RGB", (board_width, board_height), BACKGROUND)
    draw = ImageDraw.Draw(board)
    draw.text((OUTER_PAD, OUTER_PAD), "Atlas Full Mockup Deck", fill=TEXT_PRIMARY, font=BOARD_TITLE_FONT)
    draw.text(
        (OUTER_PAD, OUTER_PAD + 44),
        "Built from the approved Today / Log Shot / Companion language and expanded post-onboarding screens.",
        fill=TEXT_SECONDARY,
        font=BOARD_SUBTITLE_FONT,
    )

    y = OUTER_PAD + 92
    for row, row_h in zip(rows, row_heights):
        x = OUTER_PAD
        for card in row:
            board.paste(card, (x, y))
            x += CARD_WIDTH + GAP_X
        y += row_h + GAP_Y

    board_path = OUTPUT_DIR / "atlas-full-mockup-deck-board.png"
    board.save(board_path, quality=95)
    return board_path


def write_manifest() -> Path:
    lines = [
        "# Atlas Full Mockup Deck",
        "",
        "This deck consolidates the approved post-onboarding mockup language into one review set.",
        "",
        "| Screen | Source | Role |",
        "| --- | --- | --- |",
    ]
    for screen in SCREENS:
        lines.append(f"| {screen.title} | `{screen.source}` | {screen.note} |")

    manifest_path = OUTPUT_DIR / "README.md"
    manifest_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return manifest_path


def main() -> None:
    board_path = build_board()
    manifest_path = write_manifest()
    print(board_path)
    print(manifest_path)


if __name__ == "__main__":
    main()
