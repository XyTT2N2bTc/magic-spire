"""Extract supplied single-leg sleeve differences with local pixel operations.

The four inputs are aligned 1536x2304 illustrations.  No pixels are generated:
the script keeps only the changed leg components, removes the connected white
backdrop, and writes transparent overlays for the existing layered portrait.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOUND_CROP = (390, 90, 1130, 2304)
MIN_COMPONENT_AREA = 50_000
SINGLE_LEG_DRAW_ORDER = ["single_leg_upper", "single_leg_lower", "single_leg_long"]
COVERED_SLICES = {
    "single_leg_upper": ["thigh_root", "mid_thigh", "above_knee"],
    "single_leg_lower": ["below_knee", "mid_calf", "ankle"],
    "single_leg_long": ["thigh_root", "mid_thigh", "above_knee", "below_knee", "mid_calf", "ankle"],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def cutout(path: Path, cv2) -> Image.Image:
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
    count, labels, stats, _ = cv2.connectedComponentsWithStats((alpha > 0).astype(np.uint8), 8)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] < 1000:
            alpha[labels == label] = 0
    colors = rgb.copy()
    soft = (alpha > 0) & (alpha < 255)
    a = alpha[soft].astype(float)[:, None] / 255
    colors[soft] = np.clip((colors[soft].astype(float) - 255 * (1 - a)) / a, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([colors, alpha]))


def changed_components(target: np.ndarray, reference: np.ndarray, cv2):
    delta = np.max(np.abs(target.astype(np.int16) - reference.astype(np.int16)), axis=2)
    binary = (delta > 3).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    result = []
    for label in range(1, count):
        x, y, width, height, area = map(int, stats[label])
        if area >= MIN_COMPONENT_AREA and y >= 1100:
            result.append({"label": label, "bounds": (x, y, x + width, y + height), "area": area})
    return labels, sorted(result, key=lambda row: row["bounds"][1])


def component_mask(labels: np.ndarray, component: dict, cv2) -> np.ndarray:
    mask = np.where(labels == component["label"], 255, 0).astype(np.uint8)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(mask, contours, -1, 255, cv2.FILLED)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    mask = cv2.dilate(mask, np.ones((5, 5), np.uint8), iterations=1)
    return cv2.GaussianBlur(mask, (0, 0), 0.65)


def replacement_mask(labels: np.ndarray, component: dict, cv2) -> np.ndarray:
    """Hard replacement area that clears older silhouettes under the sleeve."""
    mask = np.where(labels == component["label"], 255, 0).astype(np.uint8)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(mask, contours, -1, 255, cv2.FILLED)
    # The nearest unrelated arm component is 31.98 pixels away in the supplied
    # aligned sources; a 10-pixel radius clears old leg edges without reaching it.
    return cv2.dilate(mask, np.ones((21, 21), np.uint8), iterations=1)


def overlay_from_mask(target: Image.Image, mask: np.ndarray, padding: int = 8):
    ys, xs = np.nonzero(mask > 1)
    if xs.size == 0:
        raise RuntimeError("No verified leg difference was found")
    x0, y0 = max(0, int(xs.min()) - padding), max(0, int(ys.min()) - padding)
    x1 = min(mask.shape[1], int(xs.max()) + padding + 1)
    y1 = min(mask.shape[0], int(ys.max()) + padding + 1)
    rgba = np.asarray(target.crop((x0, y0, x1, y1))).copy()
    rgba[:, :, 3] = np.rint(rgba[:, :, 3].astype(np.float32) * mask[y0:y1, x0:x1] / 255).astype(np.uint8)
    return Image.fromarray(rgba), (x0, y0), (x0, y0, x1, y1)


def replace_rgba(base: Image.Image, target: Image.Image, mask: np.ndarray, source_box) -> Image.Image:
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


def runtime_base(active: list[str], layers: dict, bases: dict, material: dict) -> Image.Image:
    base_key = single_leg_base_key(active)
    source = bases[base_key]["plain_bound"] if base_key else material["bases"]["plain"]["bound"]
    base = Image.open(ROOT / source.replace("res://", "")).convert("RGBA")
    for slice_id, row in material["legs"].items():
        selected = ""
        for key in SINGLE_LEG_DRAW_ORDER:
            if key in active and slice_id in layers[key].get("slices", {}):
                selected = key
        texture = layers[selected]["slices"][slice_id]["rope"] if selected else row["styles"]["plain"]["rope"]
        patch = Image.open(ROOT / texture.replace("res://", "")).convert("RGBA")
        base.alpha_composite(patch, (row["origin"][0] - BOUND_CROP[0], row["origin"][1] - BOUND_CROP[1]))
    return base


def single_leg_base_key(active: list[str]) -> str:
    if "single_leg_long" in active:
        return "single_leg_long"
    if "single_leg_upper" in active and "single_leg_lower" in active:
        return "single_leg_upper_lower"
    if "single_leg_upper" in active:
        return "single_leg_upper"
    if "single_leg_lower" in active:
        return "single_leg_lower"
    return ""


def backdrop(image: Image.Image) -> Image.Image:
    result = Image.new("RGBA", image.size, "#14232fff")
    result.alpha_composite(image)
    return result


parser = argparse.ArgumentParser()
parser.add_argument("reference", type=Path, help="Image 1 without a single-leg sleeve")
parser.add_argument("upper", type=Path, help="Image 2 with the short upper sleeve")
parser.add_argument("upper_lower", type=Path, help="Image 3 with upper and lower short sleeves")
parser.add_argument("long", type=Path, help="Image 4 with the long sleeve")
parser.add_argument("--opencv-path", type=Path, required=True)
args = parser.parse_args()
sys.path.insert(0, str(args.opencv_path.resolve()))
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

paths = [args.reference, args.upper, args.upper_lower, args.long]
raw = [np.asarray(Image.open(path).convert("RGB")) for path in paths]
if any(image.shape != (2304, 1536, 3) for image in raw):
    raise ValueError("All sources must be aligned 1536x2304 illustrations")

upper_labels, upper_components = changed_components(raw[1], raw[0], cv2)
both_labels, both_components = changed_components(raw[2], raw[0], cv2)
long_labels, long_components = changed_components(raw[3], raw[0], cv2)
if len(upper_components) != 1 or len(both_components) != 2 or len(long_components) != 1:
    raise RuntimeError(
        "Expected one upper-leg component, two short-sleeve components, and one long-sleeve component"
    )
upper_component = upper_components[0]
lower_component = both_components[1]
long_component = long_components[0]
if upper_component["bounds"][3] > 1650 or lower_component["bounds"][1] < 1600 or long_component["bounds"][3] < 2100:
    raise RuntimeError("Detected components do not match the verified upper/lower/long leg regions")

cutouts = {
    "single_leg_upper": cutout(args.upper, cv2),
    "single_leg_lower": cutout(args.upper_lower, cv2),
    "single_leg_long": cutout(args.long, cv2),
}
masks = {
    "single_leg_upper": component_mask(upper_labels, upper_component, cv2),
    "single_leg_lower": component_mask(both_labels, lower_component, cv2),
    "single_leg_long": component_mask(long_labels, long_component, cv2),
}
replacement_masks = {
    "single_leg_upper": replacement_mask(upper_labels, upper_component, cv2),
    "single_leg_lower": replacement_mask(both_labels, lower_component, cv2),
    "single_leg_long": replacement_mask(long_labels, long_component, cv2),
}

assets = {}
output_hashes = {}
for key in cutouts:
    overlay, origin, bounds = overlay_from_mask(cutouts[key], masks[key])
    output = ROOT / f"assets/art/equipment-overlay-{key.replace('_', '-')}-v1.png"
    overlay.save(output)
    output_hashes["res://" + output.relative_to(ROOT).as_posix()] = sha256(output)
    assets[key] = {
        "texture": "res://" + output.relative_to(ROOT).as_posix(),
        "origin": list(origin),
        "source_bounds": list(bounds),
        "sha256": sha256(output),
        "slices": {},
    }

legacy_leg_entries = {
    row["id"]: row
    for row in json.loads((ROOT / "assets/art/equipment-leg-layers.json").read_text(encoding="utf-8"))
}
material = json.loads((ROOT / "assets/art/equipment-material-layers.json").read_text(encoding="utf-8"))
for key in SINGLE_LEG_DRAW_ORDER:
    for slice_id in COVERED_SLICES[key]:
        legacy = legacy_leg_entries[slice_id]
        row = material["legs"][slice_id]
        sources = {}
        for style, source in row["styles"]["plain"].items():
            sources[style] = (source, row["origin"])
        if slice_id == "thigh_root":
            for style, source in row["styles"]["flat_lock"].items():
                sources["flat_lock_" + style] = (source, row["origin"])
        sources["single_glove_bound"] = (legacy["texture"], legacy["origin"])
        sources["single_glove_free"] = (legacy["free_texture"], legacy["origin"])
        if slice_id == "thigh_root":
            sources["single_glove_bound"] = (
                "res://assets/art/equipment-leg-thigh_root-single-glove-v1.png", legacy["origin"]
            )
            sources["single_glove_free"] = (
                "res://assets/art/equipment-leg-thigh_root-single-glove-free-v1.png", legacy["origin"]
            )
            sources["single_glove_flat_lock_bound"] = (
                "res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-v1.png",
                legacy["origin"],
            )
            sources["single_glove_flat_lock_free"] = (
                "res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-free-v1.png",
                legacy["origin"],
            )
        variants = {}
        for context, (source, origin) in sources.items():
            source_image = Image.open(ROOT / source.replace("res://", "")).convert("RGBA")
            source_bounds = (
                origin[0],
                origin[1],
                origin[0] + source_image.width,
                origin[1] + source_image.height,
            )
            output = ROOT / f"assets/art/equipment-leg-{slice_id}-{key.replace('_', '-')}-{context}-v1.png"
            replaced = replace_rgba(
                source_image,
                cutouts[key],
                replacement_masks[key],
                source_bounds,
            )
            replaced.save(output)
            output_hashes["res://" + output.relative_to(ROOT).as_posix()] = sha256(output)
            local = replacement_masks[key][source_bounds[1]:source_bounds[3], source_bounds[0]:source_bounds[2]] > 0
            expected = np.asarray(cutouts[key].crop(source_bounds))
            actual = np.asarray(replaced)
            visible = local & (expected[:, :, 3] > 0)
            if not np.array_equal(actual[:, :, 3][local], expected[:, :, 3][local]) or not np.array_equal(actual[:, :, :3][visible], expected[:, :, :3][visible]):
                raise RuntimeError(f"Slice replacement differs from supplied pixels: {key}/{slice_id}/{context}")
            variants[context] = "res://" + output.relative_to(ROOT).as_posix()
        assets[key]["slices"][slice_id] = variants

base_sources = {
    "plain_free": material["bases"]["plain"]["free"],
    "plain_bound": material["bases"]["plain"]["bound"],
    "plain_leather_free": material["bases"]["plain"]["leather_free"],
    "plain_leather_bound": material["bases"]["plain"]["leather_bound"],
    "flat_lock_free": material["bases"]["flat_lock"]["free"],
    "flat_lock_bound": material["bases"]["flat_lock"]["bound"],
    "flat_lock_leather_free": material["bases"]["flat_lock"]["leather_free"],
    "flat_lock_leather_bound": material["bases"]["flat_lock"]["leather_bound"],
    "single_glove": "res://assets/art/equipment-body-single-glove-v1.png",
    "single_glove_flat_lock": "res://assets/art/equipment-body-single-glove-flat-lock-v1.png",
}
base_steps = {
    "single_leg_upper": ["single_leg_upper"],
    "single_leg_lower": ["single_leg_lower"],
    "single_leg_upper_lower": ["single_leg_upper", "single_leg_lower"],
    "single_leg_long": ["single_leg_long"],
}
base_assets = {}
for base_key, steps in base_steps.items():
    base_assets[base_key] = {}
    for context, source in base_sources.items():
        replaced = Image.open(ROOT / source.replace("res://", "")).convert("RGBA")
        for key in steps:
            replaced = replace_rgba(replaced, cutouts[key], replacement_masks[key], BOUND_CROP)
        output = ROOT / f"assets/art/equipment-body-{base_key.replace('_', '-')}-{context}-v1.png"
        replaced.save(output)
        output_hashes["res://" + output.relative_to(ROOT).as_posix()] = sha256(output)
        base_assets[base_key][context] = "res://" + output.relative_to(ROOT).as_posix()

# Rebuild the exact runtime stack on a dark background for visual inspection.
panels = []
for keys in [[], ["single_leg_upper"], ["single_leg_lower"], ["single_leg_upper", "single_leg_lower"], ["single_leg_long"]]:
    panel = runtime_base(keys, assets, base_assets, material)
    for key in keys:
        texture = Image.open(ROOT / assets[key]["texture"].replace("res://", "")).convert("RGBA")
        origin = assets[key]["origin"]
        panel.alpha_composite(texture, (origin[0] - BOUND_CROP[0], origin[1] - BOUND_CROP[1]))
    panels.append(backdrop(panel))
base = panels[0]
preview = Image.new("RGBA", (base.width * 5 + 64, base.height), "#0e1720ff")
for index, panel in enumerate(panels):
    preview.alpha_composite(panel, (index * (base.width + 16), 0))
preview.thumbnail((1500, 1300), Image.Resampling.LANCZOS)
preview_path = ROOT / "build/equipment-single-leg-preview.png"
preview_path.parent.mkdir(parents=True, exist_ok=True)
preview.save(preview_path)

manifest = {
    "bound_crop": list(BOUND_CROP),
    "sources": {
        "reference": {"path": str(args.reference), "sha256": sha256(args.reference)},
        "upper": {"path": str(args.upper), "sha256": sha256(args.upper)},
        "upper_lower": {"path": str(args.upper_lower), "sha256": sha256(args.upper_lower)},
        "long": {"path": str(args.long), "sha256": sha256(args.long)},
    },
    "layers": assets,
    "bases": base_assets,
    "output_sha256": output_hashes,
    "variant_mapping": {
        "upper": ["single_leg_upper"],
        "lower": ["single_leg_lower"],
        "ankle": ["single_leg_long"],
        "toes": ["single_leg_long"],
    },
    "note": "The upper and lower overlays compose to reproduce image 3; arm differences are excluded.",
}
manifest_path = ROOT / "assets/art/equipment-single-leg-layers.json"
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(json.dumps({
    "components": {
        "upper": upper_component,
        "lower": lower_component,
        "long": long_component,
    },
    "preview": str(preview_path),
    "manifest": str(manifest_path),
}, ensure_ascii=False))
