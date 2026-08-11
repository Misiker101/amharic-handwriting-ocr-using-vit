from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import shutil
import uuid
import os
from segmenter_factory import SEGMENTER_REGISTRY, DEFAULT_ALGORITHM
from recognizer import AmharicRecognizerAPI

app = FastAPI(title="Amharic OCR API")

# Initialize models globally so they don't reload on every request
# One instance per available segmentation algorithm ("astar", "kraken"),
# keyed the same way SEGMENTER_REGISTRY is, so a request can pick either.
segmenters = {name: cls() for name, cls in SEGMENTER_REGISTRY.items()}
recognizer_api = AmharicRecognizerAPI("best_model_true_hybrid_vit.pth", "vocab.txt")

@app.post("/segment")
async def upload_and_segment(file: UploadFile = File(...), algorithm: str = Form(DEFAULT_ALGORITHM)):
    session_id = str(uuid.uuid4())
    session_dir = os.path.join("temp_sessions", session_id)
    os.makedirs(session_dir, exist_ok=True)
    
    # Save the incoming full page image from the phone
    file_location = os.path.join(session_dir, "original.jpg")
    with open(file_location, "wb+") as buffer:
        shutil.copyfileobj(file.file, buffer)

    segmenter_api = segmenters.get(algorithm, segmenters[DEFAULT_ALGORITHM])

    # FIX: Pass 'session_dir' instead of 'session_id' so line images 
    # and the visualization save into 'temp_sessions/{session_id}/'
    vis_path, _ = segmenter_api.process_image(file_location, session_dir)
    
    # Return the visualization image. We pass the session_id in the headers 
    # so the Flutter app knows which batch to recognize later.
    return FileResponse(vis_path, headers={"X-Session-ID": session_id})

@app.post("/recognize/{session_id}")
async def recognize_lines(session_id: str):
    lines_dir = os.path.join("temp_sessions", session_id)
    
    if not os.path.exists(lines_dir):
        return {"error": "Session not found"}
        
    # Perform batch recognition on all cropped lines in that folder
    final_text = recognizer_api.recognize_batch(lines_dir)
    
    return {"text": final_text}

# Run the server using:
# uvicorn main:app --host 0.0.0.0 --port 8000