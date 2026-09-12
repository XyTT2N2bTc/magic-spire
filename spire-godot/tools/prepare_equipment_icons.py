"""Remove the flat beige backing from the existing material icons, locally.

Reads the sibling project's originals without modifying them. Requires Pillow
and NumPy; no model, network request, or runtime chroma-key shader is used.
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "game-demo/public/assets/restraints"
DESTINATION = ROOT / "assets/ui/equipment"
FAMILIES = ("rope-", "fine-cord-", "leather-", "fine-belt-", "tape-", "cable-tie-")


def cutout(path: Path) -> Image.Image:
    rgba = np.array(Image.open(path).convert("RGBA"), dtype=np.float32)
    rgb = rgba[:, :, :3]
    background = np.median(np.concatenate((rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1])), axis=0)
    distance = np.max(np.abs(rgb - background), axis=2)
    similar = distance <= 7
    visited = np.zeros(similar.shape, dtype=bool)
    removed = np.zeros(similar.shape, dtype=bool)
    height, width = similar.shape
    # Include closed rope/belt holes, but keep tiny isolated highlights.
    for y, x in zip(*np.where(similar)):
        if visited[y, x]:
            continue
        pending = deque([(y, x)])
        visited[y, x] = True
        component = []
        while pending:
            cy, cx = pending.popleft()
            component.append((cy, cx))
            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if 0 <= ny < height and 0 <= nx < width and similar[ny, nx] and not visited[ny, nx]:
                    visited[ny, nx] = True
                    pending.append((ny, nx))
        if len(component) >= 8:
            for cy, cx in component:
                removed[cy, cx] = True
    edge = np.zeros_like(removed)
    edge[1:] |= removed[:-1]
    edge[:-1] |= removed[1:]
    edge[:, 1:] |= removed[:, :-1]
    edge[:, :-1] |= removed[:, 1:]
    alpha = np.where(removed, 0, np.where(edge, np.clip((distance - 7) / 19, 0, 1), 1))
    # Remove the beige contribution at antialiased edges, not just its opacity.
    foreground = np.clip((rgb - background * (1 - alpha[:, :, None])) / np.maximum(alpha[:, :, None], 0.001), 0, 255)
    rgba[:, :, :3] = foreground
    rgba[:, :, 3] *= alpha
    result = Image.fromarray(rgba.astype(np.uint8))
    box = result.getchannel("A").getbbox()
    if box is None:
        raise ValueError(f"Empty equipment icon: {path}")
    result = result.crop(box)
    result.thumbnail((112, 112), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (128, 128))
    canvas.alpha_composite(result, ((128 - result.width) // 2, (128 - result.height) // 2))
    return canvas


if __name__ == "__main__":
    paths = sorted((SOURCE / "icons").glob("*.png")) + sorted((SOURCE / "concepts/fine-belt").glob("*.png"))
    paths = [path for path in paths if path.name.startswith(FAMILIES)]
    for path in paths:
        cutout(path).save(DESTINATION / path.name)
    print(f"Prepared {len(paths)} transparent material icons in {DESTINATION}")
