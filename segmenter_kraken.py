"""
Pretrained, script-agnostic line segmentation using Kraken's `blla`
baseline-detection model, offered as an alternative to
`HybridAStarSegmenter` (segmenter.py) — NOT a replacement.

Setup (one-time):
    pip install kraken
    kraken get 10.5281/zenodo.14602569   # "General segmentation model for
                                          # print and handwriting" (multiscriptal)

"""

import os
import re
import subprocess
from functools import lru_cache

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image

from kraken import blla
from kraken.lib import vgsl


@lru_cache(maxsize=None)
def _resolve_model_path(doi: str) -> str:

    env = os.environ.copy()
    env["PYTHONUTF8"] = "1"

    result = subprocess.run(
        ["kraken", "get", doi], capture_output=True, text=True, check=True, env=env
    )
    output = result.stdout + result.stderr

    # Match either output style kraken/htrmopo have used across versions:
    #   "Model dir: /path/to/dir (model files: name.mlmodel)"
    #   "Model name: /path/to/dir"
    m = re.search(r"Model dir:\s*(\S+)\s*\(model files:\s*([^)]+)\)", output)
    if m:
        model_dir, files = m.group(1), m.group(2)
        first_file = files.split(",")[0].strip()
        return os.path.join(model_dir, first_file)

    m = re.search(r"Model name:\s*(\S+)", output)
    if m:
        model_dir = m.group(1)
        candidates = [f for f in os.listdir(model_dir) if f.endswith(".mlmodel")]
        if candidates:
            return os.path.join(model_dir, candidates[0])

    raise RuntimeError(
        f"Could not resolve local path for kraken model '{doi}'. "
        f"Run `kraken get {doi}` manually and check the output. "
        f"Raw output was:\n{output}"
    )


class KrakenLineSegmenter:
    
    DEBUG_OVERRIDE_COLOR = None

    PATH_COLOR_CYCLE = [
        (0, 255, 0),    # green
        (0, 0, 255),    # red
        (0, 255, 255),  # yellow
        (255, 0, 0),    # blue
    ]

    
    MODEL_DOI = "10.5281/zenodo.14602569"
    MODEL_LOCAL_PATH_OVERRIDE = None  

    def __init__(self):
        model_path = self.MODEL_LOCAL_PATH_OVERRIDE or _resolve_model_path(self.MODEL_DOI)
        self._model = vgsl.TorchVGSLModel.load_model(model_path)

    def process_image(self, image_path, output_dir):
        
        original = cv2.imread(image_path)
        if original is None:
            raise ValueError(f"Image not found at {image_path}")
        h, w = original.shape[:2]

        pil_im = Image.open(image_path).convert("RGB")
        segmentation = blla.segment(pil_im, model=self._model)

        
        lines = list(segmentation.lines)
        lines.sort(key=lambda ln: np.mean([p[1] for p in ln.baseline]))

        self.extract_and_mask(original, lines, output_dir)
        self.save_viz(original, lines, output_dir)

        vis_path = os.path.join(output_dir, "smoothed_separating_paths.jpg")
        return vis_path, output_dir

    def extract_and_mask(self, original, lines, output_dir):
       
        h, w = original.shape[:2]
        for i, ln in enumerate(lines):
            boundary = np.array(ln.boundary, dtype=np.int32)
            if boundary.ndim != 2 or len(boundary) < 3:
                continue  # skip degenerate polygons defensively

            mask = np.zeros((h, w), dtype=np.uint8)
            cv2.fillPoly(mask, [boundary], 255)

            fg = cv2.bitwise_and(original, original, mask=mask)
            bg = cv2.bitwise_and(np.ones_like(original) * 255, np.ones_like(original) * 255,
                                  mask=cv2.bitwise_not(mask))
            line_strip = cv2.add(fg, bg)

            x, y, bw, bh = cv2.boundingRect(boundary)
            crop = line_strip[max(0, y - 5):min(h, y + bh + 5), max(0, x - 5):min(w, x + bw + 5)]
            cv2.imwrite(os.path.join(output_dir, f"{i}.png"), crop)

    def save_viz(self, original, lines, output_dir):
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)

        save_path = os.path.join(output_dir, "smoothed_separating_paths.jpg")

        plt.figure(figsize=(10, 5))
        viz = original.copy()
        for i, ln in enumerate(lines):
            boundary = np.array(ln.boundary, dtype=np.int32)
            if boundary.ndim != 2 or len(boundary) < 3:
                continue
            color = self.DEBUG_OVERRIDE_COLOR or self.PATH_COLOR_CYCLE[i % len(self.PATH_COLOR_CYCLE)]
            cv2.polylines(viz, [boundary], True, color, 2)

        plt.imshow(cv2.cvtColor(viz, cv2.COLOR_BGR2RGB))
        plt.axis('off')
        plt.savefig(save_path, bbox_inches='tight')
        plt.close()
        print(f"Visualization Kraken saved to: {save_path}")
