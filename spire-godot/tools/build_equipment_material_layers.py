"""Slice aligned user-supplied leather/rope artwork without generating pixels."""
import ast
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "build/cutout-deps"))
import cv2
import numpy as np
from PIL import Image

# Reuse the established cutout/replacement helpers without executing their CLI.
helper_path = ROOT / "tools/build_equipment_special_layers.py"
tree = ast.parse(helper_path.read_text(encoding="utf-8-sig"))
helpers = {"__file__": str(helper_path)}
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n, (ast.Import, ast.ImportFrom, ast.FunctionDef))], type_ignores=[]), str(helper_path), "exec"), helpers)
art = ROOT / "assets/art"
leather_path, rope_path = map(Path, sys.argv[1:3])
raw_leather, raw_rope = [np.asarray(Image.open(p).convert("RGB")) for p in [leather_path, rope_path]]
if raw_leather.shape != (2304,1536,3) or raw_rope.shape != raw_leather.shape:
    raise ValueError("Expected aligned 1536x2304 sources")
target = helpers["cutout"](leather_path)
# The two supplied renders use slightly different skin tones. Replacing their
# full horizontal bands makes mixed rope/leather equipment expose that color
# change as a dark seam. Keep only the nine large dark leather components and
# a narrow antialiased rim, so every slice retains the same canonical skin.
delta = np.max(np.abs(raw_leather.astype(np.int16)-raw_rope.astype(np.int16)),axis=2)
dark_change = ((delta>12)&(np.max(raw_leather,axis=2)<190)).astype(np.uint8)
dark_change = cv2.morphologyEx(dark_change,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))
count, labels, stats, _ = cv2.connectedComponentsWithStats(dark_change,8)
leather_core = np.zeros(dark_change.shape,np.uint8)
kept_components = []
for label in range(1,count):
    x,y,w,h,area = map(int,stats[label])
    if area<1000:
        continue
    leather_core[labels==label] = 255
    kept_components.append((x,y,x+w,y+h,area))
if len(kept_components)!=9:
    raise RuntimeError(f"Expected nine leather restraint components, found {len(kept_components)}")
mask = cv2.dilate(leather_core,np.ones((9,9),np.uint8))
mask = cv2.GaussianBlur(mask,(0,0),0.65)
crop = (390,90,1130,2304)
leg_entries = json.loads((art / "equipment-leg-layers.json").read_text(encoding="utf-8"))
boundaries = [1180,1325,1480,1625,1800,1965,2135,2304]
for boundary in boundaries[:-1]:
    if np.any(mask[boundary-2:boundary+3]):
        raise RuntimeError(f"Leather mask reaches horizontal slice boundary {boundary}")
original_bases = {
    "plain": {"free":"equipment-body-plain-no-crotch-rope-v1.png", "bound":"equipment-body-sliced-v3.png"},
    "flat_lock": {"free":"equipment-body-flat-lock-no-crotch-rope-v1.png", "bound":"equipment-body-flat-lock-v1.png"},
}
manifest = {"sources": {}, "bound_crop":list(crop), "bases":{}, "legs":{}, "outputs":{}}
for key,path in [("leather",leather_path),("rope",rope_path)]:
    manifest["sources"][key] = {"path":str(path),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}

def save(image, filename):
    path = art / filename
    image.save(path)
    resource = "res://" + path.relative_to(ROOT).as_posix()
    manifest["outputs"][resource] = {"size":list(image.size), "sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
    return resource

def reconstruct(base, locked, free):
    result = base.copy()
    for entry in leg_entries:
        file = entry["free_texture" if free else "texture"]
        if locked and entry["id"] == "thigh_root":
            file = "res://assets/art/equipment-leg-thigh_root-flat-lock" + ("-free" if free else "") + "-v1.png"
        layer = Image.open(ROOT / file.removeprefix("res://")).convert("RGBA")
        x,y = entry["origin"]
        result.alpha_composite(layer,(x-crop[0],y-crop[1]))
    return result

upper_mask = mask.copy()
upper_mask[1180:] = 0
previews = []
for kind, states in original_bases.items():
    manifest["bases"][kind] = {}
    for rope_state, name in states.items():
        base = Image.open(art/name).convert("RGBA")
        for material in ["rope","leather"]:
            changed = helpers["replace_rgba"](base,target,upper_mask,crop) if material=="leather" else base.copy()
            pixels = np.asarray(changed).copy()
            pixels[1180-crop[1]:] = 0
            key = ("leather_" if material=="leather" else "") + rope_state
            manifest["bases"][kind][key] = save(Image.fromarray(pixels), f"equipment-material-body-{kind.replace('_','-')}-{material}-{rope_state}-v1.png")
    # Full-height slices erase old edges; no new belt is clipped to old rope bounds.
    base = Image.open(art/states["free"]).convert("RGBA")
    full_rope = reconstruct(base,kind=="flat_lock",False)
    full_free = reconstruct(base,kind=="flat_lock",True)
    lower_mask = mask.copy()
    lower_mask[:1180] = 0
    material_mask = lower_mask.copy()
    # A supplied no-lock source must not replace the adjacent metal plate.
    if kind=="flat_lock":
        plain_base = Image.open(art/original_bases["plain"]["free"]).convert("RGBA")
        plain_full = reconstruct(plain_base,False,False)
        lock_pixels = np.max(np.abs(np.asarray(full_rope).astype(np.int16)-np.asarray(plain_full).astype(np.int16)),axis=2)>3
        local_mask = material_mask[crop[1]:crop[3],crop[0]:crop[2]]
        local_mask[lock_pixels] = 0
    full_leather = helpers["replace_rgba"](full_free,target,material_mask,crop)
    for index,entry in enumerate(leg_entries):
        if kind=="flat_lock" and entry["id"]!="thigh_root":continue
        key = entry["id"]
        box=(0,boundaries[index]-crop[1],740,boundaries[index+1]-crop[1])
        row=manifest["legs"].setdefault(key,{"origin":[390,boundaries[index]],"styles":{}})
        row["styles"][kind]={}
        for style,full in [("rope",full_rope),("free",full_free),("leather",full_leather)]:
            row["styles"][kind][style]=save(full.crop(box),f"equipment-material-leg-{key}-{kind.replace('_','-')}-{style}-v1.png")
    if kind=="plain":
        upper = Image.open(ROOT / manifest["bases"][kind]["leather_free"].removeprefix("res://")).convert("RGBA")
        for key,row in manifest["legs"].items():
            layer=Image.open(ROOT/row["styles"][kind]["leather"].removeprefix("res://")).convert("RGBA")
            upper.alpha_composite(layer,(row["origin"][0]-crop[0],row["origin"][1]-crop[1]))
        previews.append(upper)
    # Splitting then recomposing must reproduce the existing rope/free art exactly.
    for free,expected in [(False,full_rope),(True,full_free)]:
        rebuilt = Image.open(ROOT/manifest["bases"][kind]["free"].removeprefix("res://")).convert("RGBA")
        for key,row in manifest["legs"].items():
            styles=row["styles"].get(kind,row["styles"]["plain"])
            layer=Image.open(ROOT/styles["free" if free else "rope"].removeprefix("res://")).convert("RGBA")
            rebuilt.alpha_composite(layer,(row["origin"][0]-crop[0],row["origin"][1]-crop[1]))
        a,b=np.asarray(rebuilt),np.asarray(expected)
        visible=(a[:,:,3]>0)|(b[:,:,3]>0)
        assert np.array_equal(a[visible],b[visible]), "Slice reconstruction changed existing artwork"
manifest["policy"]="Outer leather takes precedence; otherwise leather count must exceed rope count. Ties/neither use rope. Upper body totals unique physical pieces. All single-glove compositions keep original art."
(art/"equipment-material-layers.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
preview=Image.new("RGBA",previews[0].size,"#25303b")
preview.alpha_composite(previews[0])
preview.resize((370,1107)).save(ROOT/"build/equipment-leather-reconstruction-v1.png")
print(json.dumps({"outputs":len(manifest["outputs"]),"reconstruction":"exact visible RGBA","metadata":"fresh pixel-only PNGs"}))
