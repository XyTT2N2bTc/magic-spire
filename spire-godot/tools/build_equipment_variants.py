"""Prepare supplied, aligned portrait variants and two source-derived face patches locally."""
import argparse
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

parser=argparse.ArgumentParser()
parser.add_argument("source_dir",type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
names=["00068-4048214563 (1).png","handsanylegs1 (2).png","00071-1333714550.png",
       "00073-1839265440.png","00075-1504326030 (1).png","00076-3734441362.png","00077-1312644243.png"]
crop=(390,90,1130,2304)
destinations=[root/f"assets/art/equipment-bound-legs{i}-v1.png" for i in range(5)]
destinations += [root/f"build/equipment-face-source-{i}.png" for i in (5,6)]

def extract(i):
    subprocess.run([sys.executable,str(root/"tools/extract_portrait.py"),str(args.source_dir/names[i]),
        str(destinations[i]),"--bounds",",".join(map(str,crop)),"--background-seed","677,480"],check=True)

with ThreadPoolExecutor(max_workers=3) as pool:
    list(pool.map(extract,range(7)))

for label,previous,current,box in [
    ("mouth",4,5,(655,374,950,479)),("eyes",5,6,(590,238,990,374))]:
    source=Image.open(args.source_dir/names[current]).convert("RGB").crop(box)
    before=Image.open(args.source_dir/names[previous]).convert("RGB").crop(box)
    delta=np.max(np.abs(np.array(source).astype(np.int16)-np.array(before).astype(np.int16)),axis=2)
    mask=Image.fromarray((delta>2).astype(np.uint8)*255).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(0.7))
    cutout=Image.open(destinations[current]).crop((box[0]-crop[0],box[1]-crop[1],box[2]-crop[0],box[3]-crop[1]))
    alpha=(np.array(mask).astype(np.uint16)*np.array(cutout.getchannel("A"))//255).astype(np.uint8)
    source.putalpha(Image.fromarray(alpha))
    output=root/f"assets/art/equipment-overlay-{label}-v1.png"
    source.save(output)
    print({"layer":label,"source_bounds":box,"output":str(output)})
