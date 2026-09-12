"""Extract edge-connected white backdrop without changing the source illustration."""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--background-seed", action="append", default=[], help="Verified enclosed backdrop point, source x,y")
parser.add_argument("--white-floor", type=int, default=242, help="Minimum RGB channel for the source backdrop")
parser.add_argument("--clear-border", action="store_true", help="Remove isolated edge artifacts when all source borders are known background")
parser.add_argument("--bounds", help="Shared crop x0,y0,x1,y1 for aligned image variants")
args = parser.parse_args()
source = Image.open(args.source).convert("RGB")
rgb = np.asarray(source)
# Flood only near-white pixels connected to the outside. Enclosed white clothes stay.
white = (rgb.min(axis=2) >= args.white_floor) & (np.ptp(rgb.astype(np.int16), axis=2) <= 14)
flood = Image.fromarray(np.pad(white.astype(np.uint8)*255, 1, constant_values=255)).copy()
ImageDraw.floodfill(flood, (0, 0), 128, thresh=0)
for raw in args.background_seed:
    x,y = map(int, raw.split(","))
    if not white[y,x]:
        raise ValueError(f"Seed {raw} is not near-white background")
    ImageDraw.floodfill(flood, (x+1,y+1), 128, thresh=0)
background = np.asarray(flood)[1:-1, 1:-1] == 128
alpha = np.where(background, 0, 255).astype(np.uint8)
near_background = np.asarray(Image.fromarray(background.astype(np.uint8)*255).filter(ImageFilter.MaxFilter(3))) > 0
edge = ~background & near_background
alpha[edge] = np.clip((255-rgb[edge].min(axis=1).astype(float))/24, 0, 1)*255
if args.clear_border:
    alpha[[0,-1],:]=0
    alpha[:,[0,-1]]=0
# Remove white matte only on antialiased edge pixels; opaque source pixels stay exact.
colors = rgb.copy()
soft = (alpha > 0) & (alpha < 255)
a = alpha[soft].astype(float)[:, None]/255
colors[soft] = np.clip((colors[soft].astype(float)-255*(1-a))/a, 0, 255).astype(np.uint8)
result = Image.fromarray(np.dstack([colors, alpha]))
bounds = result.getbbox()
if bounds is None:
    raise RuntimeError("No subject remained after background extraction")
x0,y0,x1,y1 = bounds
padding = 14
bounds = (max(0,x0-padding),max(0,y0-padding),min(source.width,x1+padding),min(source.height,y1+padding))
if args.bounds:
    bounds=tuple(map(int,args.bounds.split(",")))
result = result.crop(bounds)
args.output.parent.mkdir(parents=True, exist_ok=True)
result.save(args.output)
print({"output": str(args.output), "source": source.size, "crop": bounds, "size": result.size,
       "transparent_pixels": int((np.asarray(result)[:,:,3] == 0).sum()),
       "opaque_white_preserved": int(((alpha==255) & (rgb.min(axis=2)>=242)).sum())})
