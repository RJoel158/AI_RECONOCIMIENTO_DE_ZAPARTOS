"""
Image embedding service via HuggingFace Inference API.

Uses google/vit-base-patch16-224 for image feature extraction.
This model is natively supported by HuggingFace's serverless API
and returns 768-dimensional embeddings for any image.
"""

import io
import json
import math
import time
from typing import Optional

import requests
from PIL import Image

from backend.alembic.app.core.config import settings

# google/vit-base-patch16-224 — supported for image feature extraction
HF_API_URL = "https://api-inference.huggingface.co/models/google/vit-base-patch16-224"


def _get_headers() -> dict:
    """Build auth headers for HuggingFace API."""
    token = settings.hf_api_token
    if not token:
        print("[CLIP] ERROR: HF_API_TOKEN not set")
        return {}
    print(f"[CLIP] Token: {token[:10]}...")
    return {"Authorization": f"Bearer {token}"}


def _prepare_image(image_bytes: bytes, max_size: int = 384) -> bytes:
    """Resize and convert image to JPEG for consistent API input."""
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img = img.convert("RGB")

        w, h = img.size
        if max(w, h) > max_size:
            ratio = max_size / max(w, h)
            img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

        buf = io.BytesIO()
        img.save(buf, "JPEG", quality=85)
        buf.seek(0)
        result = buf.read()
        print(f"[CLIP] Image prepared: {img.size}, {len(result)} bytes")
        return result
    except Exception as e:
        print(f"[CLIP] Image prep failed: {e}")
        return image_bytes


def get_embedding(image_bytes: bytes) -> Optional[list[float]]:
    """
    Get image embedding via HuggingFace Inference API.
    Returns a list of floats (embedding vector), or None on failure.
    """
    headers = _get_headers()
    if not headers:
        return None

    prepared = _prepare_image(image_bytes)

    for attempt in range(3):
        try:
            print(f"[CLIP] Attempt {attempt + 1}: POST {HF_API_URL}")
            response = requests.post(
                HF_API_URL,
                headers=headers,
                data=prepared,
                timeout=60,
            )
            print(f"[CLIP] Status: {response.status_code}")

            if response.status_code == 503:
                body = response.json()
                wait = min(body.get("estimated_time", 20), 30)
                print(f"[CLIP] Model loading, waiting {wait}s...")
                time.sleep(wait)
                continue

            if response.status_code == 429:
                print("[CLIP] Rate limited, waiting 10s...")
                time.sleep(10)
                continue

            if response.status_code != 200:
                print(f"[CLIP] Error: {response.text[:300]}")
                continue

            result = response.json()
            print(f"[CLIP] Response type: {type(result).__name__}")

            embedding = _extract_embedding(result)
            if embedding:
                print(f"[CLIP] SUCCESS: {len(embedding)}-dim embedding")
                return embedding
            else:
                print(f"[CLIP] Could not extract embedding. Preview: {str(result)[:200]}")
                return None

        except requests.exceptions.Timeout:
            print(f"[CLIP] Timeout attempt {attempt + 1}")
            continue
        except Exception as e:
            print(f"[CLIP] Error attempt {attempt + 1}: {e}")
            continue

    print("[CLIP] All attempts failed")
    return None


def _extract_embedding(result) -> Optional[list[float]]:
    """
    Extract a 1D embedding vector from HuggingFace response.

    ViT returns: [[patch_1_768, patch_2_768, ...]] — list of patch embeddings.
    We use the FIRST token ([CLS] token) as the global image representation.
    If it's just a 1D vector, use it directly.
    """
    if not result:
        return None

    if isinstance(result, dict):
        if "error" in result:
            print(f"[CLIP] API error: {result['error']}")
        return None

    if isinstance(result, list):
        # Case 1: [float, float, ...] — direct 1D vector
        if len(result) > 0 and isinstance(result[0], (int, float)):
            return [float(x) for x in result]

        # Case 2: [[float, float, ...]] — one embedding wrapped
        if len(result) > 0 and isinstance(result[0], list):
            inner = result[0]

            # [[float, float, ...]] — 1D vector wrapped
            if len(inner) > 0 and isinstance(inner[0], (int, float)):
                return [float(x) for x in inner]

            # [[[float, ...], [float, ...], ...]] — patch tokens
            # Use first token (CLS) as global representation
            if len(inner) > 0 and isinstance(inner[0], list):
                cls_token = inner[0]
                print(f"[CLIP] Using CLS token: {len(inner)} patches, dim={len(cls_token)}")
                return [float(x) for x in cls_token]

    return None


def cosine_similarity(a: list[float], b: list[float]) -> float:
    """Compute cosine similarity between two vectors. Returns 0.0-1.0."""
    if len(a) != len(b) or not a:
        return 0.0

    dot = sum(x * y for x, y in zip(a, b))
    mag_a = math.sqrt(sum(x * x for x in a))
    mag_b = math.sqrt(sum(x * x for x in b))

    if mag_a == 0 or mag_b == 0:
        return 0.0

    sim = dot / (mag_a * mag_b)
    return max(0.0, min(1.0, sim))


def embedding_to_json(embedding: list[float]) -> str:
    """Serialize embedding to compact JSON string for DB storage."""
    return json.dumps([round(v, 6) for v in embedding])


def json_to_embedding(json_str: str) -> list[float]:
    """Deserialize embedding from JSON string."""
    return json.loads(json_str)
