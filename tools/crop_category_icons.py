"""Crop the 12 Safeer category icons from the reference sheet.

1) Erases Arabic label bands (incl. descenders into the next row).
2) Crops each icon cell (pastel blob + 3D objects only).
3) Flood-fills sheet background from the edges to alpha=0 with a feathered rim.
4) Scrubs residual ink / ghost pixels from the top & bottom edges.
5) Verifies transparent corners and no label ink in the outer 15px bands.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "categories" / "_reference_sheet.png"
OUT = ROOT / "assets" / "images" / "categories"

CELLS: list[tuple[int, int, str]] = [
    (0, 0, "dairy"),
    (0, 1, "sweets"),
    (0, 2, "drinks"),
    (0, 3, "meat"),
    (1, 0, "bakery"),
    (1, 1, "pasta-rice"),
    (1, 2, "pantry"),
    (1, 3, "attara"),
    (2, 0, "cleaning"),
    (2, 1, "personal-care"),
    (2, 2, "baby"),
    (2, 3, "home"),
]

COLS, ROWS = 4, 3
TEXT_FRACTION = 0.34
INSET_X = 0.045
BG_MIN = 228
BG_CHROMA_MAX = 30
FEATHER_PX = 2
CORNER_PAD = 4


def is_dark_text(r: int, g: int, b: int) -> bool:
    return (
        r < 90
        and g < 90
        and b < 90
        and abs(r - g) < 30
        and abs(g - b) < 30
        and abs(r - b) < 30
    )


def is_label_ink(r: int, g: int, b: int) -> bool:
    return r < 50 and g < 50 and b < 50 and max(r, g, b) - min(r, g, b) < 20


def is_sheet_bg(r: int, g: int, b: int) -> bool:
    mx, mn = max(r, g, b), min(r, g, b)
    return mn >= BG_MIN and (mx - mn) <= BG_CHROMA_MAX


def is_ghost_fringe(r: int, g: int, b: int) -> bool:
    """Gray / near-white anti-aliased letter fringes left after a wipe."""
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) <= 22 and mn >= 90 and mx <= 250


def erase_label_bands(sheet: Image.Image) -> Image.Image:
    rgb = sheet.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    cell_h = h / ROWS

    for row in range(ROWS):
        y0 = int(row * cell_h + cell_h * (1.0 - TEXT_FRACTION))
        y1 = int((row + 1) * cell_h)
        # Arabic descenders spill into the next row — wipe deep into it.
        y1_ext = min(h, y1 + 28)
        for y in range(y0, y1_ext):
            for x in range(w):
                r, g, b = px[x, y]
                if y < y1 or is_dark_text(r, g, b) or is_ghost_fringe(r, g, b):
                    px[x, y] = (255, 255, 255)

    # Boundary scrub between rows.
    for row in range(1, ROWS):
        y_mid = int(row * cell_h)
        for y in range(max(0, y_mid - 30), min(h, y_mid + 16)):
            for x in range(w):
                r, g, b = px[x, y]
                if is_dark_text(r, g, b) or is_ghost_fringe(r, g, b):
                    px[x, y] = (255, 255, 255)
    return rgb


def content_seed_mask(rgb: Image.Image) -> list[list[bool]]:
    w, h = rgb.size
    px = rgb.load()
    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if is_sheet_bg(r, g, b) or is_dark_text(r, g, b) or is_ghost_fringe(r, g, b):
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            chroma = mx - mn
            if chroma >= 16 or mn < 205 or (mn < 235 and chroma >= 6):
                mask[y][x] = True
    dilated = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if not mask[y][x]:
                continue
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w:
                        dilated[yy][xx] = True
    return dilated


def flood_transparent(rgb: Image.Image) -> Image.Image:
    w, h = rgb.size
    px = rgb.load()
    protect = content_seed_mask(rgb)
    visited = [[False] * w for _ in range(h)]
    bg = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def try_push(x: int, y: int) -> None:
        if not (0 <= x < w and 0 <= y < h) or visited[y][x]:
            return
        if protect[y][x]:
            return
        r, g, b = px[x, y]
        if not (is_sheet_bg(r, g, b) or is_ghost_fringe(r, g, b)):
            return
        visited[y][x] = True
        bg[y][x] = True
        q.append((x, y))

    for x in range(w):
        try_push(x, 0)
        try_push(x, h - 1)
    for y in range(h):
        try_push(0, y)
        try_push(w - 1, y)

    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            try_push(x + dx, y + dy)

    rgba = Image.new("RGBA", (w, h))
    out = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if is_dark_text(r, g, b):
                out[x, y] = (255, 255, 255, 0)
                continue
            if not bg[y][x]:
                out[x, y] = (r, g, b, 255)
                continue
            near = False
            for dy in range(-FEATHER_PX, FEATHER_PX + 1):
                for dx in range(-FEATHER_PX, FEATHER_PX + 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and not bg[yy][xx]:
                        near = True
                        break
                if near:
                    break
            out[x, y] = (r, g, b, 65) if near else (255, 255, 255, 0)

    alpha = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(0.7))
    r_ch, g_ch, b_ch, _ = rgba.split()
    return Image.merge("RGBA", (r_ch, g_ch, b_ch, alpha))


def scrub_edge_artifacts(im: Image.Image, band: int = 22) -> Image.Image:
    """Remove leftover label ink / gray ghosts from the outer bands."""
    out = im.copy()
    px = out.load()
    w, h = out.size
    band = min(band, max(8, h // 3))
    for y in list(range(band)) + list(range(h - band, h)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_dark_text(r, g, b) or is_label_ink(r, g, b) or is_ghost_fringe(r, g, b):
                px[x, y] = (255, 255, 255, 0)
                continue
            # Orphan light pixel with no colorful neighbour → ghost.
            colorful_near = False
            for dy in range(-4, 5):
                for dx in range(-4, 5):
                    yy, xx = y + dy, x + dx
                    if not (0 <= yy < h and 0 <= xx < w):
                        continue
                    rr, gg, bb, aa = px[xx, yy]
                    if aa < 40:
                        continue
                    if max(rr, gg, bb) - min(rr, gg, bb) >= 20:
                        colorful_near = True
                        break
                if colorful_near:
                    break
            if not colorful_near and min(r, g, b) >= 200:
                px[x, y] = (255, 255, 255, 0)
    return out


def trim_and_pad(im: Image.Image, pad: int = 2) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(im.width, r + pad)
    b = min(im.height, b + pad)
    cropped = im.crop((l, t, r, b))
    canvas = Image.new(
        "RGBA",
        (cropped.width + CORNER_PAD * 2, cropped.height + CORNER_PAD * 2),
        (0, 0, 0, 0),
    )
    canvas.paste(cropped, (CORNER_PAD, CORNER_PAD), cropped)
    return canvas


def verify(name: str, im: Image.Image) -> None:
    px = im.load()
    w, h = im.size
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if px[x, y][3] != 0:
            raise SystemExit(f"{name}: corner ({x},{y}) alpha={px[x, y][3]} != 0")
    band = min(15, h)
    for y in list(range(band)) + list(range(h - band, h)):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 40 and is_label_ink(r, g, b):
                raise SystemExit(
                    f"{name}: dark text remnant at ({x},{y}) rgba=({r},{g},{b},{a})"
                )
    print(f"OK  {name}: {w}x{h}")


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"Missing reference sheet: {SRC}")

    cleaned = erase_label_bands(Image.open(SRC))
    w, h = cleaned.size
    cell_w, cell_h = w / COLS, h / ROWS
    OUT.mkdir(parents=True, exist_ok=True)

    for row, col, name in CELLS:
        left = int(col * cell_w + cell_w * INSET_X)
        right = int((col + 1) * cell_w - cell_w * INSET_X)
        # Rows below the first start lower to skip wiped descender zone.
        top_inset = 0.10 if row > 0 else 0.02
        top = int(row * cell_h + cell_h * top_inset)
        bottom = int(row * cell_h + cell_h * (1.0 - TEXT_FRACTION))
        cell = cleaned.crop((left, top, right, bottom))
        icon = trim_and_pad(scrub_edge_artifacts(flood_transparent(cell)))
        dest = OUT / f"{name}.png"
        icon.save(dest, "PNG")
        jpg = OUT / f"{name}.jpg"
        if jpg.exists():
            jpg.unlink()
        verify(name, icon)


if __name__ == "__main__":
    main()
