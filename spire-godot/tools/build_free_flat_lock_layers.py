"""Extract free-standing flat-lock differences from three aligned user images.

No pixels are generated or painted. The two output layers copy RGB pixels from
the supplied lock and reinforcement variants and derive alpha from their local
pixel differences against the preceding aligned image.
"""
import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
FREE_CROP = (349, 60, 1138, 2268)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def cutout(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGB")
    rgb = np.asarray(source)
    white = (rgb.min(axis=2) >= 242) & (np.ptp(rgb.astype(np.int16), axis=2) <= 14)
    flood = Image.fromarray(np.pad(white.astype(np.uint8) * 255, 1, constant_values=255)).copy()
    ImageDraw.floodfill(flood, (0, 0), 128, thresh=0)
    background = np.asarray(flood)[1:-1, 1:-1] == 128
    alpha = np.where(background, 0, 255).astype(np.uint8)
    near_background = np.asarray(
        Image.fromarray(background.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))
    ) > 0
    edge = ~background & near_background
    alpha[edge] = np.clip((255 - rgb[edge].min(axis=1).astype(float)) / 24, 0, 1) * 255
    colors = rgb.copy()
    soft = (alpha > 0) & (alpha < 255)
    a = alpha[soft].astype(float)[:, None] / 255
    colors[soft] = np.clip((colors[soft].astype(float) - 255 * (1 - a)) / a, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([colors, alpha]))


def difference_mask(current: np.ndarray, previous: np.ndarray, roi: tuple[int, int, int, int], minimum: int) -> np.ndarray:
    delta = np.max(np.abs(current.astype(np.int16) - previous.astype(np.int16)), axis=2)
    binary = np.zeros(delta.shape, np.uint8)
    x0, y0, x1, y1 = roi
    binary[y0:y1, x0:x1] = (delta[y0:y1, x0:x1] > 3).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    kept = np.zeros_like(binary)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] >= minimum:
            kept[labels == label] = 255
    contours, _ = cv2.findContours(kept, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(kept, contours, -1, 255, cv2.FILLED)
    kept = cv2.morphologyEx(kept, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    kept = cv2.dilate(kept, np.ones((5, 5), np.uint8), iterations=1)
    return cv2.GaussianBlur(kept, (0, 0), 0.65)


def layer(target: Image.Image, mask: np.ndarray, destination: Path, padding: int = 8) -> tuple[int, int, int, int]:
    ys, xs = np.nonzero(mask > 1)
    x0, y0 = max(0, int(xs.min()) - padding), max(0, int(ys.min()) - padding)
    x1, y1 = min(mask.shape[1], int(xs.max()) + padding + 1), min(mask.shape[0], int(ys.max()) + padding + 1)
    rgba = np.asarray(target.crop((x0, y0, x1, y1))).copy()
    rgba[:, :, 3] = np.rint(rgba[:, :, 3].astype(np.float32) * mask[y0:y1, x0:x1] / 255).astype(np.uint8)
    destination.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba).save(destination)
    return x0, y0, x1 - x0, y1 - y0


parser = argparse.ArgumentParser()
parser.add_argument("free", type=Path, help="Aligned free-standing source without a flat lock")
parser.add_argument("flat_lock", type=Path, help="Aligned free-standing source with a flat lock")
parser.add_argument("reinforced", type=Path, help="Aligned source with the same lock and reinforcement strap")
args = parser.parse_args()

paths = [args.free, args.flat_lock, args.reinforced]
raw = [np.asarray(Image.open(path).convert("RGB")) for path in paths]
if any(image.shape != (2304, 1536, 3) for image in raw):
    raise ValueError("All three source images must be aligned 1536x2304 illustrations")
cutouts = [cutout(path) for path in paths]

lock_mask = difference_mask(raw[1], raw[0], (755, 875, 935, 1195), 20)
strap_mask = difference_mask(raw[2], raw[1], (615, 935, 1045, 1160), 20)
lock_path = ROOT / "assets/art/hero-overlay-flat-lock-free-v1.png"
strap_path = ROOT / "assets/art/hero-overlay-flat-lock-reinforcement-free-v1.png"
lock_box = layer(cutouts[1], lock_mask, lock_path)
strap_box = layer(cutouts[2], strap_mask, strap_path)

base = Image.open(ROOT / "assets/art/hero-stand-cutout-v2.png").convert("RGBA")
preview = base.copy()
preview.alpha_composite(Image.open(lock_path).convert("RGBA"), (lock_box[0] - FREE_CROP[0], lock_box[1] - FREE_CROP[1]))
preview.alpha_composite(Image.open(strap_path).convert("RGBA"), (strap_box[0] - FREE_CROP[0], strap_box[1] - FREE_CROP[1]))
backdrop = Image.new("RGBA", preview.size, "#14232fff")
backdrop.alpha_composite(preview)
(ROOT / "build").mkdir(exist_ok=True)
backdrop.save(ROOT / "build/hero-free-flat-lock-preview.png")

manifest = {
    "free_crop": list(FREE_CROP),
    "sources": {
        "free": {"path": str(args.free), "sha256": sha256(args.free)},
        "flat_lock": {"path": str(args.flat_lock), "sha256": sha256(args.flat_lock)},
        "reinforced": {"path": str(args.reinforced), "sha256": sha256(args.reinforced)},
    },
    "layers": [
        {"id": "flat_lock", "texture": "res://assets/art/hero-overlay-flat-lock-free-v1.png", "origin": list(lock_box[:2]), "size": list(lock_box[2:]), "source_pair": ["free", "flat_lock"]},
        {"id": "flat_lock_reinforcement", "texture": "res://assets/art/hero-overlay-flat-lock-reinforcement-free-v1.png", "origin": list(strap_box[:2]), "size": list(strap_box[2:]), "source_pair": ["flat_lock", "reinforced"]},
    ],
}
manifest_path = ROOT / "assets/art/hero-stand-special-layers.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"flat_lock": lock_box, "reinforcement": strap_box, "manifest": str(manifest_path)}, ensure_ascii=False))
