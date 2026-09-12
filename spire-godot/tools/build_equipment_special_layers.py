"""Build local pixel-difference layers for the bound standing portrait.

The four inputs are aligned source illustrations.  No pixels are generated: this
script removes the edge-connected white backdrop and copies only the verified
local differences into the existing portrait compositor.
"""
import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BOUND_CROP = (390, 90, 1130, 2304)
THIGH_CROP = (390, 1180, 1130, 1300)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def cutout(path: Path, background_seeds: tuple[tuple[int, int], ...] = ()) -> Image.Image:
    source = Image.open(path).convert("RGB")
    rgb = np.asarray(source)
    white = (rgb.min(axis=2) >= 242) & (np.ptp(rgb.astype(np.int16), axis=2) <= 14)
    flood = Image.fromarray(np.pad(white.astype(np.uint8) * 255, 1, constant_values=255)).copy()
    ImageDraw.floodfill(flood, (0, 0), 128, thresh=0)
    for x, y in background_seeds:
        if not white[y, x]:
            raise ValueError(f"Background seed {(x, y)} is not in the verified white backdrop")
        ImageDraw.floodfill(flood, (x + 1, y + 1), 128, thresh=0)
    background = np.asarray(flood)[1:-1, 1:-1] == 128
    alpha = np.where(background, 0, 255).astype(np.uint8)
    near_background = np.asarray(
        Image.fromarray(background.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))
    ) > 0
    edge = ~background & near_background
    alpha[edge] = np.clip((255 - rgb[edge].min(axis=1).astype(float)) / 24, 0, 1) * 255
    # Source exports can contain a handful of isolated near-white specks.  They
    # are not part of the connected figure and would otherwise become visible
    # when a difference mask happens to cross them.
    count, labels, stats, _ = cv2.connectedComponentsWithStats((alpha > 0).astype(np.uint8), 8)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] < 1000:
            alpha[labels == label] = 0
    colors = rgb.copy()
    soft = (alpha > 0) & (alpha < 255)
    a = alpha[soft].astype(float)[:, None] / 255
    colors[soft] = np.clip((colors[soft].astype(float) - 255 * (1 - a)) / a, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([colors, alpha]))


def component_mask(a: np.ndarray, b: np.ndarray, roi: tuple[int, int, int, int], minimum: int = 20) -> np.ndarray:
    delta = np.max(np.abs(a.astype(np.int16) - b.astype(np.int16)), axis=2)
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


def replace_rgba(base: Image.Image, target: Image.Image, mask: np.ndarray, source_box: tuple[int, int, int, int]) -> Image.Image:
    bx0, by0, _, _ = source_box
    local_mask = mask[by0:source_box[3], bx0:source_box[2]].astype(np.float32)[:, :, None] / 255
    base_px = np.asarray(base).astype(np.float32) / 255
    target_px = np.asarray(target.crop(source_box)).astype(np.float32) / 255
    base_pre = base_px[:, :, :3] * base_px[:, :, 3:4]
    target_pre = target_px[:, :, :3] * target_px[:, :, 3:4]
    alpha = base_px[:, :, 3:4] * (1 - local_mask) + target_px[:, :, 3:4] * local_mask
    premul = base_pre * (1 - local_mask) + target_pre * local_mask
    rgb = np.divide(premul, alpha, out=np.zeros_like(premul), where=alpha > 0)
    return Image.fromarray(np.rint(np.concatenate([rgb, alpha], axis=2) * 255).astype(np.uint8))


def overlay_from_mask(target: Image.Image, mask: np.ndarray, padding: int = 8) -> tuple[Image.Image, tuple[int, int]]:
    ys, xs = np.nonzero(mask > 1)
    x0, y0 = max(0, int(xs.min()) - padding), max(0, int(ys.min()) - padding)
    x1, y1 = min(mask.shape[1], int(xs.max()) + padding + 1), min(mask.shape[0], int(ys.max()) + padding + 1)
    rgba = np.asarray(target.crop((x0, y0, x1, y1))).copy()
    rgba[:, :, 3] = np.rint(rgba[:, :, 3].astype(np.float32) * mask[y0:y1, x0:x1] / 255).astype(np.uint8)
    return Image.fromarray(rgba), (x0, y0)


parser = argparse.ArgumentParser()
parser.add_argument("flat_lock", type=Path, help="Source with the flat lock")
parser.add_argument("unlocked", type=Path, help="Aligned source without the flat lock")
parser.add_argument("reinforced", type=Path, help="Aligned source with reinforcement strap")
parser.add_argument("urethral_rod", type=Path, help="Aligned source with the rod visible")
args = parser.parse_args()

paths = [args.flat_lock, args.unlocked, args.reinforced, args.urethral_rod]
raw = [np.asarray(Image.open(path).convert("RGB")) for path in paths]
if any(image.shape != (2304, 1536, 3) for image in raw):
    raise ValueError("All four source images must be aligned 1536x2304 illustrations")
cutouts = [cutout(paths[0], ((1074, 1041),))] + [cutout(path) for path in paths[1:]]

# The lock is a replacement: it removes the exposed shape and adds the plate.
lock_mask = component_mask(raw[0], raw[1], (790, 990, 1130, 1235), 200)
bound_base = Image.open(ROOT / "assets/art/equipment-body-sliced-v3.png").convert("RGBA")
lock_base = replace_rgba(bound_base, cutouts[0], lock_mask, BOUND_CROP)
lock_base_path = ROOT / "assets/art/equipment-body-flat-lock-v1.png"
lock_base.save(lock_base_path)

# The top thigh slice is drawn over the body base. Give it the same replacement
# so the lower rim of the plate cannot be covered by the ordinary slice.
thigh_outputs = {}
for suffix in ["", "-free"]:
    source_path = ROOT / f"assets/art/equipment-leg-thigh_root{suffix}-v3.png"
    output_path = ROOT / f"assets/art/equipment-leg-thigh_root-flat-lock{suffix}-v1.png"
    replace_rgba(Image.open(source_path).convert("RGBA"), cutouts[0], lock_mask, THIGH_CROP).save(output_path)
    thigh_outputs["bound" if suffix == "" else "free"] = "res://" + output_path.relative_to(ROOT).as_posix()

# Image 3 differs from image 2 by both the already handled lock and the strap.
# Comparing the aligned lock source to image 3 leaves just the reinforcement.
reinforcement_mask = component_mask(raw[2], raw[0], (630, 900, 970, 1235), 20)
reinforcement, reinforcement_origin = overlay_from_mask(cutouts[2], reinforcement_mask)
reinforcement_path = ROOT / "assets/art/equipment-overlay-flat-lock-reinforcement-v1.png"
reinforcement.save(reinforcement_path)

rod_mask = component_mask(raw[3], raw[2], (860, 1135, 930, 1220), 8)
rod, rod_origin = overlay_from_mask(cutouts[3], rod_mask)
rod_path = ROOT / "assets/art/equipment-overlay-urethral-rod-v1.png"
rod.save(rod_path)

# Recompose the free thigh choices exactly as the runtime does and compare them
# on the game's dark backdrop. This catches visible horizontal slice seams;
# differences in RGB values of fully transparent pixels are intentionally ignored.
expected_full = replace_rgba(
    Image.open(ROOT / "assets/art/equipment-bound-legs0-v1.png").convert("RGBA"),
    cutouts[0], lock_mask, BOUND_CROP,
)
actual_full = lock_base.copy()
leg_manifest = json.loads((ROOT / "assets/art/equipment-leg-layers.json").read_text(encoding="utf-8"))
for entry in leg_manifest:
    layer_path = thigh_outputs["free"] if entry["id"] == "thigh_root" else entry["free_texture"]
    layer = Image.open(ROOT / layer_path.removeprefix("res://")).convert("RGBA")
    actual_full.alpha_composite(layer, (entry["origin"][0] - BOUND_CROP[0], entry["origin"][1] - BOUND_CROP[1]))

def against_backdrop(image: Image.Image) -> np.ndarray:
    backdrop = Image.new("RGBA", image.size, "#14232fff")
    backdrop.alpha_composite(image)
    return np.asarray(backdrop.convert("RGB"))

seam_delta = np.max(np.abs(against_backdrop(expected_full).astype(np.int16) - against_backdrop(actual_full).astype(np.int16)), axis=2)
if np.count_nonzero(seam_delta > 3) > 32:
    raise RuntimeError("Bound portrait slice reconstruction introduced a visible seam")

manifest = {
    "bound_crop": list(BOUND_CROP),
    "sources": {
        "flat_lock": {"path": str(args.flat_lock), "sha256": sha256(args.flat_lock)},
        "unlocked": {"path": str(args.unlocked), "sha256": sha256(args.unlocked)},
        "reinforced": {"path": str(args.reinforced), "sha256": sha256(args.reinforced)},
        "urethral_rod": {"path": str(args.urethral_rod), "sha256": sha256(args.urethral_rod)},
    },
    "flat_lock": {
        "texture": "res://assets/art/equipment-body-flat-lock-v1.png",
        "thigh_textures": thigh_outputs,
        "source_pair": ["flat_lock", "unlocked"],
    },
    "layers": [
        {
            "id": "flat_lock_reinforcement",
            "texture": "res://assets/art/equipment-overlay-flat-lock-reinforcement-v1.png",
            "origin": list(reinforcement_origin),
            "source_pair": ["unlocked", "reinforced"],
            "note": "flat-lock replacement removed before extracting the reinforcement",
        },
        {
            "id": "urethral_rod",
            "texture": "res://assets/art/equipment-overlay-urethral-rod-v1.png",
            "origin": list(rod_origin),
            "source_pair": ["reinforced", "urethral_rod"],
        },
    ],
}
manifest_path = ROOT / "assets/art/equipment-special-layers.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(json.dumps({
    "flat_lock_base": [lock_base.width, lock_base.height],
    "reinforcement": [*reinforcement_origin, reinforcement.width, reinforcement.height],
    "urethral_rod": [*rod_origin, rod.width, rod.height],
    "visible_seam_pixels": int(np.count_nonzero(seam_delta > 3)),
    "manifest": str(manifest_path),
}, ensure_ascii=False))
