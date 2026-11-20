#!/usr/bin/env python3
"""Builds the web/PWA icons from assets/images/logo_source.png.

The source is the circular badge on a dark navy background with a second
"SAFEER MARKET" line underneath. This script

1. finds the outer white ring (ignoring the white text below the circle),
2. crops a square around it and masks everything outside the circle, so the
   navy background and the bottom text become fully transparent,
3. writes the icon sizes the manifest / index.html point to.

Usage (from the repo root):  python tools/generate_web_icons.py
Requires Pillow (pip install pillow) and numpy.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "images" / "logo_source.png"
WEB = ROOT / "web"
ICONS = WEB / "icons"

# A pixel counts as "ring white" when every channel is at least this bright.
WHITE_MIN = 225
# Pixels shaved off the detected edge, so no navy anti-aliasing fringe stays.
EDGE_INSET = 1.5
# Supersampling factor for a smooth circular mask.
SS = 4
# The maskable "safe zone" is a circle of 80 % of the icon's size.
MASKABLE_SCALE = 0.80


def find_ring_box(image: Image.Image) -> tuple[int, int, int, int]:
    """Bounding box (x0, y0, x1, y1) of the outer white ring."""
    rgb = np.asarray(image.convert("RGB"))
    white = rgb.min(axis=2) >= WHITE_MIN
    height, width = white.shape

    # The ring is the first white shape from the top; the bottom text is a
    # second one, separated by a band of navy rows. Stop at that band.
    rows_with_white = white.any(axis=1)
    top = int(np.argmax(rows_with_white))
    bottom = top
    y = top
    while y < height:
        if rows_with_white[y]:
            bottom = y
        elif y - bottom > 8 and y > height * 0.5:
            break
        y += 1

    ring = white[top : bottom + 1]
    cols = np.where(ring.any(axis=0))[0]
    return int(cols.min()), top, int(cols.max()) + 1, bottom + 1


def circular_badge(image: Image.Image) -> Image.Image:
    """Square RGBA crop of the ring with everything outside it transparent."""
    x0, y0, x1, y1 = find_ring_box(image)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    radius = max(x1 - x0, y1 - y0) / 2 - EDGE_INSET
    side = int(round(radius * 2 + 2 * EDGE_INSET))

    left = int(round(cx - side / 2))
    top = int(round(cy - side / 2))
    crop = image.convert("RGBA").crop((left, top, left + side, top + side))

    # Circle mask, drawn big and scaled down for smooth edges.
    mask = Image.new("L", (side * SS, side * SS), 0)
    centre = side * SS / 2
    r = radius * SS
    ImageDraw.Draw(mask).ellipse(
        (centre - r, centre - r, centre + r, centre + r), fill=255
    )
    mask = mask.resize((side, side), Image.LANCZOS)

    crop.putalpha(mask)
    return crop


def scaled(badge: Image.Image, size: int) -> Image.Image:
    return badge.resize((size, size), Image.LANCZOS)


def maskable(badge: Image.Image, size: int) -> Image.Image:
    """The badge inside the maskable safe zone, on a transparent canvas."""
    inner = int(round(size * MASKABLE_SCALE))
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - inner) // 2
    canvas.paste(scaled(badge, inner), (offset, offset))
    return canvas


def main() -> None:
    badge = circular_badge(Image.open(SOURCE))
    ICONS.mkdir(parents=True, exist_ok=True)

    outputs = {
        ICONS / "Icon-512.png": scaled(badge, 512),
        ICONS / "Icon-192.png": scaled(badge, 192),
        ICONS / "Icon-maskable-512.png": maskable(badge, 512),
        ICONS / "Icon-maskable-192.png": maskable(badge, 192),
        WEB / "favicon.png": scaled(badge, 64),
    }
    for path, image in outputs.items():
        image.save(path, optimize=True)
        print(f"wrote {path.relative_to(ROOT)} {image.size}")


if __name__ == "__main__":
    main()
