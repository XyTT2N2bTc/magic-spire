"""Local color-seeded GrabCut for a supplied portrait against pale bedding; no generation.

Requires Pillow, numpy and opencv-python-headless. Source pixels are preserved.
"""
import argparse
import sys
from pathlib import Path
import numpy as np
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--opencv-path", type=Path)
parser.add_argument("--background-seed", action="append", default=[], help="Visually verified bedding point x,y")
parser.add_argument(
    "--clear-neutral-shadow",
    action="store_true",
    help="Remove a low-chroma cast-shadow component touching the lowest foreground edge",
)
args = parser.parse_args()
if args.opencv_path:
    sys.path.insert(0, str(args.opencv_path))
import cv2

source = Image.open(args.source).convert("RGB")
rgb = np.array(source)
channels = rgb.astype(np.int16)
r,g,b = channels[:,:,0], channels[:,:,1], channels[:,:,2]
pink = (r-g>8) & (r-b>4)
mask = np.where(pink, cv2.GC_PR_FGD, cv2.GC_PR_BGD).astype(np.uint8)
mask[(rgb.min(axis=2)>247) | (b-r>8)] = cv2.GC_BGD
strong = ((r-g>20) & (r-b>12)).astype(np.uint8)
mask[cv2.erode(strong,np.ones((7,7),np.uint8))>0] = cv2.GC_FGD
background_seeds=[tuple(map(int,point.split(","))) for point in args.background_seed]
for point in background_seeds:
    cv2.circle(mask,point,8,cv2.GC_BGD,-1)
mask[:3,:]=0;mask[-3:,:]=0;mask[:,:3]=0;mask[:,-3:]=0
cv2.setRNGSeed(42)
cv2.grabCut(rgb,mask,None,np.zeros((1,65)),np.zeros((1,65)),5,cv2.GC_INIT_WITH_MASK)
foreground = ((mask==cv2.GC_FGD)|(mask==cv2.GC_PR_FGD)).astype(np.uint8)
# Keep the main connected figure; disconnected bedding/shadow specks are background.
count,labels,stats,_ = cv2.connectedComponentsWithStats(foreground,8)
largest = 1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
alpha = (labels==largest).astype(np.uint8)*255
# Restore enclosed highlights mistakenly classified as backdrop, keeping large real gaps.
holes,hole_labels,hole_stats,_ = cv2.connectedComponentsWithStats((alpha==0).astype(np.uint8),8)
for i in range(1,holes):
    x,y,w,h,area=hole_stats[i]
    known_background=any(hole_labels[py,px]==i for px,py in background_seeds)
    if x>0 and y>0 and x+w<source.width and y+h<source.height and area<6000 and not known_background:
        alpha[hole_labels==i]=255
# Pale reflected bedding can share pink tones with the figure. Refine only small,
# explicitly inspected connected gaps; never apply this color rule across clothing.
neutral=((r-g<26)&(r-b<14)).astype(np.uint8)
_,gap_labels,gap_stats,_=cv2.connectedComponentsWithStats(neutral,8)
for x,y in background_seeds:
    label=gap_labels[y,x]
    if label>0 and gap_stats[label,cv2.CC_STAT_AREA]<10000:
        alpha[gap_labels==label]=0
if args.clear_neutral_shadow:
    # A soft grey cast shadow can touch the figure and survive GrabCut as part of
    # the main component.  Only remove a neutral component that reaches the
    # lowest foreground row; enclosed pale skin and clothing remain untouched.
    foreground_rows=np.flatnonzero(alpha.any(axis=1))
    if foreground_rows.size:
        lowest=int(foreground_rows[-1])
        low_chroma=(channels.max(axis=2)-channels.min(axis=2)<=18) & (alpha>0)
        count,labels,stats,_=cv2.connectedComponentsWithStats(low_chroma.astype(np.uint8),8)
        for i in range(1,count):
            _x,y,_w,h,area=stats[i]
            if y+h-1>=lowest and area>=64:
                alpha[labels==i]=0
result = Image.fromarray(np.dstack((rgb,alpha)))
bounds = result.getbbox()
x0,y0,x1,y1=bounds
bounds=(max(0,x0-14),max(0,y0-14),min(source.width,x1+14),min(source.height,y1+14))
result=result.crop(bounds)
args.output.parent.mkdir(parents=True,exist_ok=True)
result.save(args.output)
print({"source":source.size,"crop":bounds,"output":str(args.output),"size":result.size})
