import base64
import io
import os
from functools import lru_cache
from pathlib import Path
from typing import Any

import cv2
import numpy as np
from fashn_human_parser import FashnHumanParser, IDS_TO_LABELS
from fastapi import FastAPI, File, HTTPException, Response, UploadFile
from PIL import Image, ImageOps
from rembg import new_session, remove
from starlette.concurrency import run_in_threadpool
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
MIN_GARMENT_AREA_RATIO = float(os.getenv("GARMENT_MIN_AREA_RATIO", "0.003"))
MIN_GARMENT_SIDE_PX = int(os.getenv("GARMENT_MIN_SIDE_PX", "28"))
MAX_GARMENTS_PER_IMAGE = int(os.getenv("GARMENT_MAX_ITEMS", "10"))
BACKGROUND_REMOVAL_MODEL = os.getenv(
    "BACKGROUND_REMOVAL_MODEL",
    "birefnet-general",
)
MAX_BACKGROUND_REMOVAL_BYTES = int(
    os.getenv("BACKGROUND_REMOVAL_MAX_BYTES", str(20 * 1024 * 1024))
)


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

PARSER_TO_APP_TYPE = {
    "top": "Top Wear",
    "pants": "Bottom Wear",
    "skirt": "Bottom Wear",
    "dress": "Others",
    "belt": "Accessories",
    "bag": "Accessories",
    "hat": "Accessories",
    "scarf": "Accessories",
    "glasses": "Accessories",
    "jewelry": "Accessories",
}

PARSER_TO_DISPLAY = {
    "top": "Top",
    "pants": "Pants",
    "skirt": "Skirt",
    "dress": "Dress",
    "belt": "Belt",
    "bag": "Bag",
    "hat": "Hat",
    "scarf": "Scarf",
    "glasses": "Glasses",
    "jewelry": "Jewelry",
}

PARSER_SUPPORTED_LABELS = set(PARSER_TO_APP_TYPE.keys())


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


@lru_cache(maxsize=1)
def get_human_parser() -> FashnHumanParser:
    return FashnHumanParser()


@lru_cache(maxsize=1)
def get_background_removal_session():
    return new_session(BACKGROUND_REMOVAL_MODEL)


def remove_image_background(image_bytes: bytes) -> bytes:
    output = remove(
        image_bytes,
        session=get_background_removal_session(),
        force_return_bytes=True,
    )
    if not isinstance(output, bytes):
        raise TypeError("Background remover returned an unexpected result.")
    return output


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


def transparent_crop_to_base64(image_rgb: np.ndarray, mask: np.ndarray) -> str:
    alpha = (mask.astype(np.uint8)) * 255
    rgba = np.dstack([image_rgb, alpha])
    pil_image = Image.fromarray(rgba, mode="RGBA")
    output = io.BytesIO()
    pil_image.save(output, format="PNG")
    return base64.b64encode(output.getvalue()).decode("utf-8")


def extract_masked_dominant_colors(
    image_rgb: np.ndarray, mask: np.ndarray, max_colors: int = 3
) -> list[str]:
    pixels = image_rgb[mask]
    if pixels.size == 0:
        return []

    if len(pixels) > 4096:
        step = max(1, len(pixels) // 4096)
        pixels = pixels[::step]

    rounded = (pixels // 32) * 32
    unique, counts = np.unique(rounded, axis=0, return_counts=True)
    sorted_indices = np.argsort(counts)[::-1][:max_colors]

    colors: list[str] = []
    for index in sorted_indices:
        r, g, b = unique[index].tolist()
        colors.append(f"#{r:02X}{g:02X}{b:02X}")
    return colors


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


def should_keep_garment(
    width: int,
    height: int,
    component_width: int,
    component_height: int,
    area: int,
) -> bool:
    if component_width < MIN_GARMENT_SIDE_PX or component_height < MIN_GARMENT_SIDE_PX:
        return False
    image_area = width * height
    area_ratio = area / image_area if image_area else 0
    return area_ratio >= MIN_GARMENT_AREA_RATIO


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/remove-background", response_class=Response)
async def remove_background(file: UploadFile = File(...)) -> Response:
    image_bytes = await file.read(MAX_BACKGROUND_REMOVAL_BYTES + 1)
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")
    if len(image_bytes) > MAX_BACKGROUND_REMOVAL_BYTES:
        raise HTTPException(
            status_code=413,
            detail=(
                "Uploaded image exceeds the background-removal size limit of "
                f"{MAX_BACKGROUND_REMOVAL_BYTES} bytes."
            ),
        )

    try:
        ImageOps.exif_transpose(Image.open(io.BytesIO(image_bytes))).verify()
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail="Uploaded file could not be decoded as an image.",
        ) from exc

    try:
        output_bytes = await run_in_threadpool(remove_image_background, image_bytes)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Background removal failed: {exc}",
        ) from exc

    return Response(
        content=output_bytes,
        media_type="image/png",
        headers={"Content-Disposition": 'inline; filename="background-removed.png"'},
    )


@app.post("/detect-clothes")
async def detect_clothes(file: UploadFile = File(...)) -> dict[str, Any]:
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    try:
        image = ImageOps.exif_transpose(Image.open(io.BytesIO(image_bytes))).convert("RGB")
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


@app.post("/extract-garments")
async def extract_garments(file: UploadFile = File(...)) -> dict[str, Any]:
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    try:
        image = ImageOps.exif_transpose(Image.open(io.BytesIO(image_bytes))).convert("RGB")
        image_np = np.array(image)
    except Exception as exc:
        filename = file.filename or "unknown"
        content_type = file.content_type or "unknown"
        raise HTTPException(
            status_code=400,
            detail=(
                "Uploaded file could not be decoded as an image. "
                f"filename={filename}, contentType={content_type}, error={exc}"
            ),
        ) from exc

    parser = get_human_parser()
    segmentation = parser.predict(image_np)
    height, width = segmentation.shape[:2]
    garments: list[dict[str, Any]] = []

    for label_id in np.unique(segmentation).tolist():
        label_name = IDS_TO_LABELS.get(int(label_id), "")
        if label_name not in PARSER_SUPPORTED_LABELS:
            continue

        binary_mask = (segmentation == label_id).astype(np.uint8)
        component_count, component_labels, stats, _ = cv2.connectedComponentsWithStats(
            binary_mask,
            connectivity=8,
        )

        for component_index in range(1, component_count):
            x, y, component_width, component_height, area = stats[component_index]
            if not should_keep_garment(
                width,
                height,
                component_width,
                component_height,
                int(area),
            ):
                continue

            component_mask = component_labels == component_index
            crop_rgb = image_np[y : y + component_height, x : x + component_width]
            crop_mask = component_mask[y : y + component_height, x : x + component_width]
            if crop_rgb.size == 0:
                continue

            garments.append(
                {
                    "parserLabel": label_name,
                    "type": PARSER_TO_APP_TYPE[label_name],
                    "displayLabel": PARSER_TO_DISPLAY[label_name],
                    "confidence": 0.9,
                    "bbox": {
                        "x1": int(x),
                        "y1": int(y),
                        "x2": int(x + component_width),
                        "y2": int(y + component_height),
                    },
                    "colors": extract_masked_dominant_colors(crop_rgb, crop_mask),
                    "cropBase64": transparent_crop_to_base64(crop_rgb, crop_mask),
                    "area": int(area),
                }
            )

    garments.sort(key=lambda item: item["area"], reverse=True)
    for garment in garments:
        garment.pop("area", None)

    return {
        "imageWidth": width,
        "imageHeight": height,
        "garments": garments[:MAX_GARMENTS_PER_IMAGE],
    }
