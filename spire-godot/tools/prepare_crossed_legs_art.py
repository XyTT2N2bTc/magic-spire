"""Reproduce the approved local cutout for 00094-2394729949.png, without generation.
Run with bundled Pillow/numpy and --opencv-path build/cutout-deps.
Coordinates below refer to the supplied 1536 x 2304 original.
"""
import argparse, ast, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

parser=argparse.ArgumentParser()
parser.add_argument("source",type=Path)
parser.add_argument("output",type=Path)
parser.add_argument("--opencv-path",type=Path,required=True)
args=parser.parse_args()
sys.path.insert(0,str(args.opencv_path.resolve()))
import cv2
source=Image.open(args.source).convert("RGB")
if source.size!=(1536,2304): raise ValueError("This inspected mask is only for the specified source dimensions")
rgb=np.array(source)
with tempfile.TemporaryDirectory(prefix="crossed-legs-") as temporary:
    draft=Path(temporary)/"draft.png"
    command=[sys.executable,str(Path(__file__).with_name("extract_bedded_portrait.py")),str(args.source),str(draft),"--opencv-path",str(args.opencv_path),"--background-seed","760,530","--background-seed","190,1290","--background-seed","1100,1500"]
    record=ast.literal_eval(subprocess.check_output(command,text=True).strip())
    alpha=Image.new("L",source.size)
    alpha.paste(Image.open(draft).getchannel("A"),tuple(record["crop"][:2]))
a=np.array(alpha)
# Keep the drink, transparent glass highlights and green straw from original pixels.
restore=Image.new("L",source.size);draw=ImageDraw.Draw(restore)
draw.polygon([(758,449),(760,443),(770,441),(826,471),(847,498),(930,602),(958,650),(950,659),(833,511),(816,480),(766,455)],fill=255)
draw.polygon([(831,500),(846,484),(870,472),(896,476),(918,484),(933,503),(954,534),(973,577),(1002,624),(1027,649),(1030,663),(1023,681),(1006,695),(985,706),(965,707),(944,695),(913,658),(887,621),(854,583),(833,558),(827,545),(828,523)],fill=255)
a[np.array(restore)>0]=255
r,g,b=rgb.astype(np.int16).transpose(2,0,1)
# Inspected seat/shadow components, restricted below the hand and hips; no global white removal.
neutral=((r-g<30)&(r-b<13)).astype(np.uint8)
roi=np.zeros_like(neutral);roi[1208:1440,:875]=1
_,labels,_,_=cv2.connectedComponentsWithStats(neutral*roi,8)
for x,y in [(10,1290),(335,1280),(720,1410),(862,1390)]:
    label=labels[y,x]
    if label>0: a[labels==label]=0
# A real background gap between forearm, torso and crossed thigh must stay open.
white=((rgb.min(axis=2)>231)&(np.ptp(rgb.astype(np.int16),axis=2)<22)).astype(np.uint8)
_,labels,_,_=cv2.connectedComponentsWithStats(white,8)
label=labels[942,765]
if label>0: a[labels==label]=0
foreground=a>0
edge=foreground&(cv2.erode(foreground.astype(np.uint8),np.ones((3,3),np.uint8))==0)
a[edge]=210
result=Image.fromarray(np.dstack([rgb,a]))
bounds=result.getbbox();crop=(0,max(0,bounds[1]-10),source.width,min(source.height,bounds[3]+10))
result=result.crop(crop)
args.output.parent.mkdir(parents=True,exist_ok=True);result.save(args.output)
print({"crop":crop,"size":result.size,"transparent":int((np.array(result)[:,:,3]==0).sum()),"output":str(args.output)})
