"""Resize & compress category assets in place (max edge 500px)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = ROOT / "assets" / "images" / "categories"
MAX_EDGE = 500
JPEG_QUALITY = 80
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tif", ".tiff"}


def resize_max_edge(image: Image.Image, max_edge: int) -> Image.Image:
    width, height = image.size
    longest = max(width, height)
    if longest <= max_edge:
        return image
    scale = max_edge / longest
    new_size = (max(1, round(width * scale)), max(1, round(height * scale)))
    return image.resize(new_size, Image.Resampling.LANCZOS)


def save_compressed(image: Image.Image, path: Path) -> None:
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg"}:
        if image.mode not in {"RGB", "L"}:
            image = image.convert("RGB")
        image.save(
            path,
            format="JPEG",
            optimize=True,
            quality=JPEG_QUALITY,
            progressive=True,
        )
        return

    if suffix == ".png":
        if image.mode not in {"RGB", "RGBA", "L", "LA", "P"}:
            image = image.convert("RGBA")
        image.save(path, format="PNG", optimize=True)
        return

    if suffix == ".webp":
        image.save(path, format="WEBP", quality=JPEG_QUALITY, method=6)
        return

    image.save(path, optimize=True)


def main() -> None:
    if not CATEGORIES.is_dir():
        raise SystemExit(f"Missing folder: {CATEGORIES}")

    files = sorted(
        p
        for p in CATEGORIES.iterdir()
        if p.is_file() and p.suffix.lower() in EXTENSIONS
    )
    if not files:
        raise SystemExit(f"No images found in {CATEGORIES}")

    before_total = 0
    after_total = 0
    print(f"Compressing {len(files)} image(s) in {CATEGORIES}")
    print(f"Max edge: {MAX_EDGE}px | JPEG quality: {JPEG_QUALITY}")
    print("-" * 64)

    for path in files:
        before = path.stat().st_size
        before_total += before
        with Image.open(path) as img:
            img.load()
            original_size = img.size
            out = resize_max_edge(img, MAX_EDGE)
            save_compressed(out, path)
            new_size = out.size

        after = path.stat().st_size
        after_total += after
        print(
            f"{path.name:22} {original_size[0]}x{original_size[1]:>4} "
            f"-> {new_size[0]}x{new_size[1]:<4} | "
            f"{before / 1024:8.1f} KB -> {after / 1024:7.1f} KB "
            f"({100 * after / before:5.1f}%)"
        )

    print("-" * 64)
    print(
        f"Total: {before_total / (1024 * 1024):.2f} MB -> "
        f"{after_total / (1024 * 1024):.2f} MB "
        f"({100 * after_total / before_total:.1f}%)"
    )


if __name__ == "__main__":
    main()
