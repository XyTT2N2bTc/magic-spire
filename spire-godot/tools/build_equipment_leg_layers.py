"""Replace whole leg slices (skin, stockings and rope) from the supplied images."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("unbound_legs", type=Path)
parser.add_argument("matte", type=Path, help="Existing source cutout at common crop (390,90)")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = Image.open(args.source).convert("RGB")
base = Image.open(args.unbound_legs).convert("RGB")
matte = Image.open(args.matte).convert("RGBA")
assert source.size == base.size == (1536, 2304)
assert matte.size == (740, 2214)
groups = [
    ("thigh_root", "大腿根", "points", "thigh_root", (590, 1180, 895, 1300)),
    ("mid_thigh", "大腿中部", "points", "mid_thigh", (600, 1350, 870, 1448)),
    ("above_knee", "膝盖上方", "points", "above_knee", (610, 1508, 845, 1610)),
    ("below_knee", "膝盖下方", "points", "below_knee", (600, 1638, 823, 1760)),
    ("mid_calf", "小腿中间", "points", "mid_calf", (600, 1827, 803, 1920)),
    ("ankle", "脚踝", "points", "ankle", (635, 2007, 817, 2127)),
    ("foot", "脚掌", "points", "foot", (662, 2142, 862, 2273)),
]
manifest = []
free_cutout = Image.open(root / "assets/art/equipment-bound-legs0-v1.png").convert("RGBA")
sliced_base = free_cutout.copy()
for name, label, field, value, region in groups:
    # Replace the full silhouette across this height, including rope pressure on the leg.
    # Clearing the interior prevents old outlines behind the new one. Keep two rows
    # under each cut edge so linear texture sampling cannot open a transparent seam.
    box = (390, region[1], 1130, region[3])
    local = (0, box[1]-90, 740, box[3]-90)
    bound_patch = matte.crop(local)
    free_patch = free_cutout.crop(local)
    # Blend only the two cut edges into the original leg. The middle is the full
    # supplied slice, including skin/stocking compression, not a rope-color mask.
    bound = np.array(bound_patch).astype(np.float32)/255
    free = np.array(free_patch).astype(np.float32)/255
    y = np.arange(bound_patch.height, dtype=np.float32)
    weight = np.minimum(np.minimum(y/11, (bound_patch.height-1-y)/11), 1)[:, None, None]
    alpha = bound[:, :, 3:4]*weight + free[:, :, 3:4]*(1-weight)
    color = bound[:, :, :3]*bound[:, :, 3:4]*weight + free[:, :, :3]*free[:, :, 3:4]*(1-weight)
    rgb = np.divide(color, alpha, out=np.zeros_like(color), where=alpha>0)
    bound_patch = Image.fromarray(np.rint(np.concatenate([rgb, alpha], axis=2)*255).astype(np.uint8))
    sliced_base.paste((0, 0, 0, 0), (local[0], local[1]+2, local[2], local[3]-2))
    asset = f"assets/art/equipment-leg-{name}-v3.png"
    free_asset = f"assets/art/equipment-leg-{name}-free-v3.png"
    bound_patch.save(root / asset)
    free_patch.save(root / free_asset)
    manifest.append({"id": name, "label": label, "field": field, "value": value,
                     "texture": "res://"+asset, "free_texture": "res://"+free_asset,
                     "origin": list(box[:2]), "source_bounds": list(box)})
    print(f"{name}: whole-leg section {bound_patch.size}")
sliced_base.save(root / "assets/art/equipment-body-sliced-v3.png")
(root / "assets/art/equipment-leg-layers.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
# The seven unbound slices must reconstruct the existing base exactly, including alpha.
rebuilt = sliced_base.copy()
for row in manifest:
    patch = Image.open(root / row["free_texture"].replace("res://", ""))
    rebuilt.paste(patch, (row["origin"][0]-390, row["origin"][1]-90))
assert np.array_equal(np.array(rebuilt), np.array(free_cutout))
print("PASS: unbound slices reconstruct the original base pixel-for-pixel")
