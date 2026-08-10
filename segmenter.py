import cv2
import numpy as np
import matplotlib.pyplot as plt
from heapq import heappush, heappop
from scipy.signal import savgol_filter, find_peaks
import os

class HybridAStarSegmenter:
    DEBUG_OVERRIDE_COLOR = None

    PATH_COLOR_CYCLE = [
        (0, 255, 0),    # green
        (0, 0, 255),    # red
        (0, 255, 255),  # yellow
        (255, 0, 0),    # blue
    ]

    def __init__(self):
        self.debug_maps = {}

    def process_image(self, image_path, output_dir):
        """
        Processes a single image for the API.
        output_dir is passed from main.py as a specific session folder.
        """
        # Load & Preprocess
        original = cv2.imread(image_path)
        if original is None: raise ValueError(f"Image not found at {image_path}")
        gray = cv2.cvtColor(original, cv2.COLOR_BGR2GRAY)
        h, w = gray.shape
        
        # Binarization
        binary = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                       cv2.THRESH_BINARY_INV, 31, 12)
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, np.ones((2,2), np.uint8))

        # Advanced Line Detection
        hpp = np.sum(binary, axis=1)
        hpp_smoothed = np.convolve(hpp, np.ones(20)/20, mode='same')
        line_centers, _ = find_peaks(hpp_smoothed, height=np.mean(hpp_smoothed)*0.3, distance=45)
        
        # Cost Map Generation
        dist = cv2.distanceTransform(255 - binary, cv2.DIST_L2, 5)
        dist = cv2.normalize(dist, None, 0, 1.0, cv2.NORM_MINMAX)
        cost_map = (binary/255.0 * 100) + ((1.0 - dist) * 10) + 1

        # Path Planning
        paths = []
        paths.append(np.zeros(w, dtype=int)) 
        for i in range(len(line_centers) - 1):
            start_y = (line_centers[i] + line_centers[i+1]) // 2
            min_y = line_centers[i] + 5
            max_y = line_centers[i+1] - 5
            path = self.astar_path(cost_map, start_y, min_y, max_y)
            paths.append(self.smooth_path(path))
        paths.append(np.full(w, h-1, dtype=int))

        # Extraction
        self.extract_and_mask(original, binary, paths, output_dir)
        
        # Save visualization as 'smoothed_separating_paths.jpg' for the API
        self.save_viz(original, paths, output_dir)
        
        vis_path = os.path.join(output_dir, "smoothed_separating_paths.jpg")
        return vis_path, output_dir

    def astar_path(self, cost_map, start_y, limit_top, limit_bot):
        h, w = cost_map.shape
        pq = [(0, 0, start_y)]
        cost_so_far = {(0, start_y): 0}
        came_from = {}
        final_node = (0, start_y)
        while pq:
            curr_cost, cx, cy = heappop(pq)
            if cx == w - 1:
                final_node = (cx, cy)
                break
            for dy in [-1, 0, 1]:
                nx, ny = cx + 1, cy + dy
                if limit_top <= ny <= limit_bot:
                    move_penalty = 10 if dy != 0 else 0
                    new_cost = curr_cost + cost_map[ny, nx] + move_penalty
                    if new_cost < cost_so_far.get((nx, ny), float('inf')):
                        cost_so_far[(nx, ny)] = new_cost
                        heappush(pq, (new_cost, nx, ny))
                        came_from[(nx, ny)] = (cx, cy)
        path = np.zeros(w, dtype=int)
        curr = final_node
        while curr:
            path[curr[0]] = curr[1]
            curr = came_from.get(curr)
        return path

    def smooth_path(self, path):
        return savgol_filter(path, 51, 3).astype(int)

    def extract_and_mask(self, original, binary, paths, output_dir):
        h, w = original.shape[:2]
        for i in range(len(paths) - 1):
            top_y, bot_y = paths[i], paths[i+1]
            mask = np.zeros((h, w), dtype=np.uint8)
            pts = np.concatenate([np.column_stack((np.arange(w), top_y)),
                                 np.column_stack((np.arange(w)[::-1], bot_y[::-1]))]).astype(np.int32)
            cv2.fillPoly(mask, [pts], 255)
            
            fg = cv2.bitwise_and(original, original, mask=mask)
            bg = cv2.bitwise_and(np.ones_like(original)*255, np.ones_like(original)*255, mask=cv2.bitwise_not(mask))
            line_strip = cv2.add(fg, bg)
            content_mask = cv2.bitwise_and(binary, binary, mask=mask)
            coords = cv2.findNonZero(content_mask)
            if coords is not None:
                x, y, bw, bh = cv2.boundingRect(coords)
                crop = line_strip[max(0, y-5):min(h, y+bh+5), max(0, x-5):min(w, x+bw+5)]
                # Explicitly save as .png
                cv2.imwrite(os.path.join(output_dir, f"{i}.png"), crop)

    def save_viz(self, original, paths, output_dir):
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            
        # 2. Define the absolute path
        save_path = os.path.join(output_dir, "smoothed_separating_paths.jpg")

        plt.figure(figsize=(10, 5))
        viz = original.copy()
        for i, p in enumerate(paths):
            pts = np.column_stack((np.arange(len(p)), p)).astype(np.int32)
            color = self.DEBUG_OVERRIDE_COLOR or self.PATH_COLOR_CYCLE[i % len(self.PATH_COLOR_CYCLE)]
            cv2.polylines(viz, [pts], False, color, 2)

        plt.imshow(cv2.cvtColor(viz, cv2.COLOR_BGR2RGB))
        plt.axis('off')
        
        plt.savefig(save_path, bbox_inches='tight')
        plt.close()
        print(f"Visualization saved to: {save_path}")