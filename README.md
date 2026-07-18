# Multi-Line Amharic Handwritten Document OCR Using Hybrid Vision Transformers (ViT)

An end-to-end, high-performance Client-Server system designed for unconstrained Amharic handwritten text recognition. This project decouples heavy deep learning inference from mobile hardware by utilizing a lightweight mobile client for document acquisition and a GPU-accelerated server backend to execute layout segmentation and sequence transcription.

## 🏛️ System Architecture Overview

The system is structured into three discrete execution phases to optimize throughput and preserve mobile device battery efficiency:


* **Frontend Acquisition (Flutter):** Captures documents via a specialized camera interface powered by `google_mlkit_document_scanner` which performs native border tracking, perspective deskewing, and contrast normalization.
* **Layout Segmentation (FastAPI + Uvicorn):** Processes the image on the server using a **Hybrid A* Path-Planning algorithm** combined with an energy cost map (derived from a Distance Transform). The algorithm snakes dynamically between lines, safely bypassing overlapping ascenders and descenders and extracts isolated line images.
* **Sequence Recognition (PyTorch + CUDA):** Leverages a customized **HybridViT** network architecture. A CNN front-end extracts highly detailed, localized spatial character features, which are then serialized and passed directly into a Core **Vision Transformer (ViT)** to model global context across the Ethiopic character sequence. Final strings are decoded using CTC Greedy Decoding.

## Usage

To run this project, follow these steps:

Ensure a Python 3.9+, a standard virtual environment framework configured alongside an active CUDA runtime.

1.  Navigate to the root directory `cd ocr_backend`
2.  **Install Dependencies:** Ensure you have the required libraries installed. You can install them using pip:
    ```bash
    pip install fastapi uvicorn torch torchvision opencv-python numpy
    ```
3. transfer the model weight (`hybrid_vit.pth`) directly inside the `ocr_backend/` root directory.
4.  Initialize your local ASGI server node via `Uvicorn`:
    ```bash
    uvicorn main:app --host 0.0.0.0 --port 8000
    ```
5.  **Client Mobile Setup (Flutter Application):** Ensure the Flutter SDK is installed and configured on your development path. Open `ocr_mobile_client/lib/main.dart` and modify the server endpoint configuration string to point to your laptop's assigned wireless IPv4 address:
    ```bash
    final String serverUrl = "http://10.140.163.42:8000"; // Swap with your Uvicorn host network IP
    ```
    Fetch dependencies and launch the application on your physical testing device or local system emulator instance:
    ```bash
    flutter pub get
    flutter run
    ```

## 📱 Interactive Execution Flow

* **Step 1 - Acquisition & Deskewing:** Click Scan Handwritten Document on your phone. The camera module auto-frames your paper, corrects skewed angles, and transfers the clean page to the server via an `HTTP POST /segment` multipart file binary stream.
* **Step 2 - Segment Review:** The server runs the Hybrid A* algorithm, breaks the page into distinct single-line slices, and outputs a visual representation file tracking the extracted rows. Review this line-mapping trace directly on your mobile screen.
* **Step 3 - Vision Inference Transcribe:** Tap **Approve & Recognize**. The phone initiates a call targeting `/recognize/{session_id}`. The backend runs the line crops through the TrueHybridViT encoder stack and returns a clean, structured JSON multi-line string displayed within a selectable text box for effortless editing, copying, or digital archiving.


## 📂 Repository Structure

```text
├── ocr_backend/                # Python FastAPI Backend Server
│   ├── main.py                 # API Controller Routing & Session State Logic
│   ├── segmenter.py            # Hybrid A* Path-Planning Segmentation Implementation
│   ├── recognizer.py           # PyTorch HybridViT Engine & CTC Decoder
│   ├── vocab.txt               # Amharic Character Vocabulary Mapping Token File
│   └── temp_sessions/          # [Ignored] Runtime directory for temporary line crops
│
├── ocr_mobile_client/          # Flutter Cross-Platform Application
│   ├── lib/
│   │   └── main.py             # State-driven UI & HTTP Network Communication Layer
│   ├── pubspec.yaml            # Project Dependencies Configuration
│   └── ...
│
└── .gitignore                  # Configured to filter out heavy model files (*.pth)