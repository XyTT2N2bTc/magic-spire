"""Extract the supplied single-glove difference with local pixel operations.

The two inputs are aligned 1536x2304 illustrations.  No pixels are generated:
the script finds their changed arm region, removes the connected white backdrop,
and applies that replacement to the two existing bound-standing body bases.
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
DIFFERENCE_ROI = (450, 420, 1050, 1230)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def cutout(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGB")
    rgb = np.asarray(source)
    white = (rgb.min(axis=2) >= 242) & (np.ptp(rgb.astype(np.int16), axis=2) <= 14)
    flood = Image.fromarray(np.pad(white.astype(np.uint8) * 255, 1, constant_values=255)).copy()
    ImageDraw.floodfill(flood, (0, 0), 128, thresh=0)
    # This verified point opens the enclosed white gap between hair and torso.
    ImageDraw.floodfill(flood, (678, 481), 128, thresh=0)
    background = np.asarray(flood)[1:-1, 1:-1] == 128
    alpha = np.where(background, 0, 255).astype(np.uint8)
    near_background = np.asarray(
        Image.fromarray(background.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))
    ) > 0
    edge = ~background & near_background
    alpha[edge] = np.clip((255 - rgb[edge].min(axis=1).astype(float)) / 24, 0, 1) * 255
    count, labels, stats, _ = cv2.connectedComponentsWithStats((alpha > 0).astype(np.uint8), 8)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] < 1000:
            alpha[labels == label] = 0
    colors = rgb.copy()
    soft = (alpha > 0) & (alpha < 255)
    a = alpha[soft].astype(float)[:, None] / 255
    colors[soft] = np.clip((colors[soft].astype(float) - 255 * (1 - a)) / a, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([colors, alpha]))


def difference_mask(target: np.ndarray, reference: np.ndarray) -> np.ndarray:
    delta = np.max(np.abs(target.astype(np.int16) - reference.astype(np.int16)), axis=2)
    binary = np.zeros(delta.shape, np.uint8)
    x0, y0, x1, y1 = DIFFERENCE_ROI
    binary[y0:y1, x0:x1] = (delta[y0:y1, x0:x1] > 3).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    kept = np.zeros_like(binary)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] >= 20:
            kept[labels == label] = 255
    contours, _ = cv2.findContours(kept, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(kept, contours, -1, 255, cv2.FILLED)
    kept = cv2.morphologyEx(kept, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    kept = cv2.dilate(kept, np.ones((5, 5), np.uint8), iterations=1)
    return cv2.GaussianBlur(kept, (0, 0), 0.65)


def replace_rgba(
    base: Image.Image,
    target: Image.Image,
    mask: np.ndarray,
    source_box: tuple[int, int, int, int],
) -> Image.Image:
    x0, y0, x1, y1 = source_box
    local_mask = mask[y0:y1, x0:x1].astype(np.float32)[:, :, None] / 255
    base_px = np.asarray(base.convert("RGBA")).astype(np.float32) / 255
    target_px = np.asarray(target.crop(source_box)).astype(np.float32) / 255
    if base_px.shape != target_px.shape:
        raise ValueError(f"Replacement size mismatch: {base_px.shape} != {target_px.shape}")
    base_pre = base_px[:, :, :3] * base_px[:, :, 3:4]
    target_pre = target_px[:, :, :3] * target_px[:, :, 3:4]
    alpha = base_px[:, :, 3:4] * (1 - local_mask) + target_px[:, :, 3:4] * local_mask
    premul = base_pre * (1 - local_mask) + target_pre * local_mask
    rgb = np.divide(premul, alpha, out=np.zeros_like(premul), where=alpha > 0)
    return Image.fromarray(np.rint(np.concatenate([rgb, alpha], axis=2) * 255).astype(np.uint8))


def overlay_from_mask(target: Image.Image, mask: np.ndarray, padding: int = 8):
    ys, xs = np.nonzero(mask > 1)
    x0, y0 = max(0, int(xs.min()) - padding), max(0, int(ys.min()) - padding)
    x1 = min(mask.shape[1], int(xs.max()) + padding + 1)
    y1 = min(mask.shape[0], int(ys.max()) + padding + 1)
    rgba = np.asarray(target.crop((x0, y0, x1, y1))).copy()
    rgba[:, :, 3] = np.rint(rgba[:, :, 3].astype(np.float32) * mask[y0:y1, x0:x1] / 255).astype(np.uint8)
    return Image.fromarray(rgba), (x0, y0)


def backdrop(image: Image.Image) -> Image.Image:
    result = Image.new("RGBA", image.size, "#14232fff")
    result.alpha_composite(image)
    return result


parser = argparse.ArgumentParser()
parser.add_argument("single_glove", type=Path, help="Image 1 with the silver single glove")
parser.add_argument("reference", type=Path, help="Aligned image 2 with the ordinary rope-bound arm")
args = parser.parse_args()

raw_target = np.asarray(Image.open(args.single_glove).convert("RGB"))
raw_reference = np.asarray(Image.open(args.reference).convert("RGB"))
if raw_target.shape != (2304, 1536, 3) or raw_reference.shape != raw_target.shape:
    raise ValueError("Both sources must be aligned 1536x2304 illustrations")

target_cutout = cutout(args.single_glove)
mask = difference_mask(raw_target, raw_reference)
ys, xs = np.nonzero(mask > 1)
if xs.size == 0:
    raise RuntimeError("No verified single-glove difference was found")
difference_bounds = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]

overlay, overlay_origin = overlay_from_mask(target_cutout, mask)
overlay_path = ROOT / "assets/art/equipment-overlay-single-glove-v1.png"
overlay.save(overlay_path)

base_sources = {
    "plain": ROOT / "assets/art/equipment-body-sliced-v3.png",
    "flat_lock": ROOT / "assets/art/equipment-body-flat-lock-v1.png",
}
base_outputs = {
    "plain": ROOT / "assets/art/equipment-body-single-glove-v1.png",
    "flat_lock": ROOT / "assets/art/equipment-body-single-glove-flat-lock-v1.png",
}
for key, source_path in base_sources.items():
    replace_rgba(Image.open(source_path), target_cutout, mask, BOUND_CROP).save(base_outputs[key])

thigh_sources = {
    "bound": ROOT / "assets/art/equipment-leg-thigh_root-v3.png",
    "free": ROOT / "assets/art/equipment-leg-thigh_root-free-v3.png",
    "flat_lock_bound": ROOT / "assets/art/equipment-leg-thigh_root-flat-lock-v1.png",
    "flat_lock_free": ROOT / "assets/art/equipment-leg-thigh_root-flat-lock-free-v1.png",
}
thigh_outputs = {
    "bound": ROOT / "assets/art/equipment-leg-thigh_root-single-glove-v1.png",
    "free": ROOT / "assets/art/equipment-leg-thigh_root-single-glove-free-v1.png",
    "flat_lock_bound": ROOT / "assets/art/equipment-leg-thigh_root-single-glove-flat-lock-v1.png",
    "flat_lock_free": ROOT / "assets/art/equipment-leg-thigh_root-single-glove-flat-lock-free-v1.png",
}
for key, source_path in thigh_sources.items():
    replace_rgba(Image.open(source_path), target_cutout, mask, THIGH_CROP).save(thigh_outputs[key])

# Build an inspection sheet from the exact runtime pieces.  The second panel
# includes the selected free thigh segment because it is drawn over the base.
reference = Image.open(base_sources["plain"]).convert("RGBA")
single_glove = Image.open(base_outputs["plain"]).convert("RGBA")
single_glove.alpha_composite(
    Image.open(thigh_outputs["free"]).convert("RGBA"),
    (THIGH_CROP[0] - BOUND_CROP[0], THIGH_CROP[1] - BOUND_CROP[1]),
)
preview = Image.new("RGBA", (reference.width * 2 + 24, reference.height), "#0e1720ff")
preview.alpha_composite(backdrop(reference), (0, 0))
preview.alpha_composite(backdrop(single_glove), (reference.width + 24, 0))
preview.thumbnail((1000, 1500), Image.Resampling.LANCZOS)
preview_path = ROOT / "build/equipment-single-glove-preview.png"
preview_path.parent.mkdir(parents=True, exist_ok=True)
preview.save(preview_path)

manifest = {
    "bound_crop": list(BOUND_CROP),
    "difference_roi": list(DIFFERENCE_ROI),
    "difference_bounds": difference_bounds,
    "sources": {
        "single_glove": {"path": str(args.single_glove), "sha256": sha256(args.single_glove)},
        "reference": {"path": str(args.reference), "sha256": sha256(args.reference)},
    },
    "overlay": {
        "texture": "res://" + overlay_path.relative_to(ROOT).as_posix(),
        "origin": list(overlay_origin),
        "note": "Inspection asset; runtime uses replacement bases so removed rope and hand pixels stay transparent.",
    },
    "replacement_bases": {
        key: "res://" + path.relative_to(ROOT).as_posix() for key, path in base_outputs.items()
    },
    "thigh_root_textures": {
        key: "res://" + path.relative_to(ROOT).as_posix() for key, path in thigh_outputs.items()
    },
    "runtime_condition": "active composite root with kind == glove",
}
manifest_path = ROOT / "assets/art/equipment-single-glove-layer.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(json.dumps({
    "difference_bounds": difference_bounds,
    "overlay": [*overlay_origin, overlay.width, overlay.height],
    "preview": str(preview_path),
    "manifest": str(manifest_path),
}, ensure_ascii=False))
