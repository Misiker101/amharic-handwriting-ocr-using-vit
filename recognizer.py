import os
import torch
import torch.nn as nn
import cv2
import math
import torchvision.models as models

# 1. Math Utility
class PositionalEncoding1D(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        self.register_buffer('pe', pe.unsqueeze(0))

    def forward(self, x):
        return x + self.pe[:, :x.size(1)]

# 2. The Model Class
class TrueHybridViT_NoGRU(nn.Module):
    def __init__(self, num_classes, hidden_dim=256):
        super(TrueHybridViT_NoGRU, self).__init__()
        self.cnn = nn.Sequential(
            nn.Conv2d(1, 64, kernel_size=3, padding=1), nn.ReLU(), nn.MaxPool2d(2, 2),
            nn.Conv2d(64, 128, kernel_size=3, padding=1), nn.ReLU(), nn.MaxPool2d(2, 2),
            nn.Conv2d(128, 256, kernel_size=3, padding=1), nn.ReLU(), nn.MaxPool2d((2, 1), (2, 1)),
            nn.Conv2d(256, hidden_dim, kernel_size=3, padding=1), nn.ReLU(), nn.MaxPool2d((2, 1), (2, 1))
        )
        self.bridge = nn.Linear(hidden_dim * 4, 768)
        self.pos_encoder = PositionalEncoding1D(768)
        vit = models.vit_b_16(weights=None) 
        self.vit_layers = vit.encoder.layers
        self.vit_ln = vit.encoder.ln
        self.classifier = nn.Linear(768, num_classes)

    def forward(self, x):
        features = self.cnn(x) 
        b, c, h, w = features.size()
        features = features.view(b, c * h, w).permute(0, 2, 1) 
        features = self.bridge(features)
        features = self.pos_encoder(features)
        trans_out = self.vit_layers(features)
        trans_out = self.vit_ln(trans_out)
        return self.classifier(trans_out)

# 3. The API Wrapper
class AmharicRecognizerAPI:
    def __init__(self, weights_path: str, vocab_path: str):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"Loading HybridViT on {self.device}...")
        
        # Load vocab to get num_classes
        with open(vocab_path, "r", encoding="utf-8") as f:
            self.vocab = [line.strip() for line in f.readlines()]
            self.idx_to_char = {i: char for i, char in enumerate(self.vocab)}
        
        self.model = TrueHybridViT_NoGRU(num_classes=len(self.vocab))
        
        # Load weights
        checkpoint = torch.load(weights_path, map_location=self.device)
        self.model.load_state_dict(checkpoint['model_state_dict'] if 'model_state_dict' in checkpoint else checkpoint)
        
        self.model.eval()
        self.model.to(self.device)

    def preprocess_image(self, img_path: str, img_height=64):
        img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        if img is None: raise ValueError(f"Could not read image: {img_path}")
        h, w = img.shape
        new_w = int(w * (img_height / h))
        img = cv2.resize(img, (new_w, img_height))
        img = img.astype('float32') / 255.0
        # Returns a clean 4D Tensor [1, 1, H, W] sent directly to target device
        return torch.from_numpy(img).unsqueeze(0).unsqueeze(0).to(self.device)

    def recognize_batch(self, lines_dir: str) -> str:
        # Get only files that end in .png and represent an integer line number
        line_files = []
        for f in os.listdir(lines_dir):
            name, ext = os.path.splitext(f)
            if ext.lower() == '.png' and name.isdigit():
                line_files.append(f)
        
        # Sort numerically
        line_files.sort(key=lambda x: int(os.path.splitext(x)[0]))
        
        results = []
        with torch.no_grad():
            for file in line_files:
                img_path = os.path.join(lines_dir, file)
                
                # FIX: Removed the extra .unsqueeze(0) to maintain a proper 4D tensor structure
                img_tensor = self.preprocess_image(img_path)
                
                # Inference
                output = self.model(img_tensor)
                pred_idx = torch.argmax(output[0], dim=-1)
                
                # CTC Greedy Decoding
                decoded_text = []
                for i in range(len(pred_idx)):
                    if pred_idx[i] != 0 and (i == 0 or pred_idx[i] != pred_idx[i-1]):
                        char = self.idx_to_char.get(pred_idx[i].item(), '<UNK>')
                        if char == '<SPACE>': decoded_text.append(' ')
                        elif char != '<UNK>': decoded_text.append(char)
                
                results.append("".join(decoded_text))
                
        return "\n".join(results)