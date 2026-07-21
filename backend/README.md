# Closet Scanner Backend

Minimal FastAPI service for the Cinduhrella closet scanner MVP.

It now supports:

- `POST /detect-clothes` for YOLO closet scanning
- `POST /extract-garments` for multi-item garment extraction using FASHN Human Parser

## Expected model path

The service looks for the YOLO model in this order:

1. `YOLO_MODEL_PATH` environment variable
2. `models/best.pt`
3. `runs/detect/train/weights/best.pt`

If you trained the model at `runs/detect/train/weights/best.pt`, the service will use it directly.

## Run locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Endpoint

`POST /detect-clothes`

Multipart form field:

- `file`: image upload

The response includes normalized labels, confidence, bbox, dominant colors, and a base64 crop for each detected clothing item.

`POST /extract-garments`

Multipart form field:

- `file`: image upload

The response includes one transparent PNG crop per garment region, along with parser labels, app type mapping, bbox, and dominant colors.
