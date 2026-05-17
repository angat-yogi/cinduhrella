import base64
import io
import os
from functools import lru_cache
from pathlib import Path
from typing import Any

import cv2
import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image
from ultralytics import YOLO

app = FastAPI(title="Cinduhrella Closet Scanner")
PROJECT_ROOT = Path(__file__).resolve().parents[2]
MIN_CONFIDENCE = float(os.getenv("CLOSET_SCANNER_MIN_CONFIDENCE", "0.78"))
MIN_BOX_AREA_RATIO = float(os.getenv("CLOSET_SCANNER_MIN_BOX_AREA_RATIO", "0.02"))
MIN_BOX_SIDE_PX = int(os.getenv("CLOSET_SCANNER_MIN_BOX_SIDE_PX", "72"))
EDGE_MARGIN_RATIO = float(os.getenv("CLOSET_SCANNER_EDGE_MARGIN_RATIO", "0.03"))
EDGE_MIN_BOX_AREA_RATIO = float(
    os.getenv("CLOSET_SCANNER_EDGE_MIN_BOX_AREA_RATIO", "0.035")
)
MAX_DETECTIONS = int(os.getenv("CLOSET_SCANNER_MAX_DETECTIONS", "6"))


LABEL_NORMALIZATION = {
    "shirt": "top",
    "t-shirt": "top",
    "tshirt": "top",
    "longsleeve": "top",
    "pant": "bottoms",
    "pants": "bottoms",
    "half pant": "bottoms",
    "halfpant": "bottoms",
    "shorts": "bottoms",
    "shoes": "shoes",
    "jacket": "outerwear",
    "coat": "outerwear",
    "outwear": "outerwear",
    "outerwear": "outerwear",
    "hoodies": "outerwear",
    "hoodie": "outerwear",
    "sweatshirt": "outerwear",
    "dress": "dress",
    "skirt": "skirt",
    "bag": "bag",
    "hat": "hat",
    "glass-wear": "eyewear",
    "glass wear": "eyewear",
    "eyewear": "eyewear",
    "jwellery": "jewelry",
    "jewellery": "jewelry",
    "jewelry": "jewelry",
    "vest": "vest",
}


DISPLAY_LABELS = {
    "top": "Top",
    "bottoms": "Bottoms",
    "shoes": "Shoes",
    "outerwear": "Outerwear",
    "dress": "Dress",
    "skirt": "Skirt",
    "bag": "Bag",
    "hat": "Hat",
    "eyewear": "Eyewear",
    "jewelry": "Jewelry",
    "vest": "Vest",
}


def _model_path() -> str:
    candidates = [
        os.getenv("YOLO_MODEL_PATH", ""),
        str(PROJECT_ROOT / "models" / "best.pt"),
        str(PROJECT_ROOT / "backend" / "models" / "best.pt"),
        str(PROJECT_ROOT / "runs" / "detect" / "train" / "weights" / "best.pt"),
    ]
    for path in candidates:
        if path and os.path.exists(path):
            return path
    raise FileNotFoundError(
        "No YOLO model found. Expected models/best.pt or runs/detect/train/weights/best.pt."
    )


@lru_cache(maxsize=1)
def get_model() -> YOLO:
    return YOLO(_model_path())


def normalize_label(raw_label: str) -> tuple[str, str]:
    normalized_key = raw_label.strip().lower().replace("_", " ")
    category = LABEL_NORMALIZATION.get(normalized_key)
    if category is None:
        category = normalized_key.replace(" ", "-")
    display_label = DISPLAY_LABELS.get(category, raw_label.strip().title())
    return category, display_label


def extract_dominant_colors(image_bgr: np.ndarray, max_colors: int = 3) -> list[str]:
    if image_bgr.size == 0:
        return []

    image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    small = cv2.resize(image_rgb, (48, 48), interpolation=cv2.INTER_AREA)
    pixels = small.reshape(-1, 3)

    rounded = (pixels // 32) * 32
    unique, counts = np.unique(rounded, axis=0, return_counts=True)
    sorted_indices = np.argsort(counts)[::-1][:max_colors]

    colors: list[str] = []
    for index in sorted_indices:
        r, g, b = unique[index].tolist()
        colors.append(f"#{r:02X}{g:02X}{b:02X}")
    return colors


def crop_to_base64(image_bgr: np.ndarray) -> str:
    success, buffer = cv2.imencode(".jpg", image_bgr)
    if not success:
        raise ValueError("Failed to encode crop image.")
    return base64.b64encode(buffer.tobytes()).decode("utf-8")


def safe_bbox(x1: float, y1: float, x2: float, y2: float, width: int, height: int) -> tuple[int, int, int, int]:
    left = max(0, min(int(x1), width - 1))
    top = max(0, min(int(y1), height - 1))
    right = max(left + 1, min(int(x2), width))
    bottom = max(top + 1, min(int(y2), height))
    return left, top, right, bottom


def should_keep_detection(
    left: int,
    top: int,
    right: int,
    bottom: int,
    width: int,
    height: int,
    confidence: float,
) -> bool:
    if confidence < MIN_CONFIDENCE:
        return False

    box_width = right - left
    box_height = bottom - top
    if box_width < MIN_BOX_SIDE_PX or box_height < MIN_BOX_SIDE_PX:
        return False

    image_area = width * height
    box_area = box_width * box_height
    area_ratio = box_area / image_area if image_area else 0
    if area_ratio < MIN_BOX_AREA_RATIO:
        return False

    edge_margin_x = width * EDGE_MARGIN_RATIO
    edge_margin_y = height * EDGE_MARGIN_RATIO
    touches_edge = (
        left <= edge_margin_x
        or top <= edge_margin_y
        or right >= width - edge_margin_x
        or bottom >= height - edge_margin_y
    )
    if touches_edge and area_ratio < EDGE_MIN_BOX_AREA_RATIO:
        return False

    return True


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/detect-clothes")
async def detect_clothes(file: UploadFile = File(...)) -> dict[str, Any]:
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        image_np = np.array(image)
        image_bgr = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
    except Exception as exc:  # pragma: no cover - defensive parse guard
        filename = file.filename or "unknown"
        content_type = file.content_type or "unknown"
        raise HTTPException(
            status_code=400,
            detail=(
                "Uploaded file could not be decoded as an image. "
                f"filename={filename}, contentType={content_type}, error={exc}"
            ),
        ) from exc

    model = get_model()
    results = model.predict(source=image_np, conf=MIN_CONFIDENCE, verbose=False)
    detections: list[dict[str, Any]] = []

    height, width = image_bgr.shape[:2]

    for result in results:
        boxes = result.boxes
        if boxes is None:
            continue

        for box in boxes:
            cls_index = int(box.cls.item())
            raw_label = str(result.names.get(cls_index, "unknown"))
            normalized_category, display_label = normalize_label(raw_label)
            confidence = float(box.conf.item())
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            left, top, right, bottom = safe_bbox(x1, y1, x2, y2, width, height)
            if not should_keep_detection(
                left,
                top,
                right,
                bottom,
                width,
                height,
                confidence,
            ):
                continue
            crop = image_bgr[top:bottom, left:right]
            if crop.size == 0:
                continue

            detections.append(
                {
                    "rawLabel": raw_label,
                    "normalizedCategory": normalized_category,
                    "displayLabel": display_label,
                    "confidence": round(confidence, 4),
                    "bbox": {
                        "x1": left,
                        "y1": top,
                        "x2": right,
                        "y2": bottom,
                    },
                    "colors": extract_dominant_colors(crop),
                    "cropBase64": crop_to_base64(crop),
                }
            )

    detections.sort(key=lambda item: item["confidence"], reverse=True)

    return {
        "imageWidth": width,
        "imageHeight": height,
        "detections": detections[:MAX_DETECTIONS],
    }
