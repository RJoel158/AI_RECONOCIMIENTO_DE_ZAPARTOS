"""
Image embedding service via HuggingFace Inference API.

Uses a two-step pipeline:
1. ViT image classification → semantic labels describing the image
2. Text embedding of labels → 384-dimensional vector

The labels serve as a semantic fingerprint of the image content.
Two photos of the same shoe produce similar labels → similar embeddings.
"""

import io
import json
import math
import time
from typing import Optional

import requests
from PIL import Image

from backend.alembic.app.core.config import settings

# Step 1: Image → labels (top 5 classification labels from ViT)
VIT_URL = "https://router.huggingface.co/hf-inference/models/google/vit-base-patch16-224"
# Step 2: Labels text → embedding vector (384 dims)
EMBED_URL = "https://router.huggingface.co/hf-inference/models/BAAI/bge-small-en-v1.5"


def _get_headers() -> dict:
    token = settings.hf_api_token
    if not token:
        print("[EMBED] ERROR: HF_API_TOKEN not set")
        return {}
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
        print(f"[EMBED] Image prepared: {img.size}, {len(result)} bytes")
        return result
    except Exception as e:
        print(f"[EMBED] Image prep failed: {e}")
        return image_bytes


def _classify_image(image_bytes: bytes, headers: dict) -> Optional[str]:
    """
    Step 1: Use ViT to classify the image and get semantic labels.
    Returns a text description like 'running shoe, sneaker, loafer'.
    """
    for attempt in range(3):
        try:
            r = requests.post(
                VIT_URL,
                headers={**headers, "Content-Type": "image/jpeg"},
                data=image_bytes,
                timeout=60,
            )
            print(f"[EMBED] ViT status: {r.status_code}")

            if r.status_code == 503:
                wait = min(r.json().get("estimated_time", 20), 30)
                print(f"[EMBED] Model loading, waiting {wait}s...")
                time.sleep(wait)
                continue

            if r.status_code == 429:
                print("[EMBED] Rate limited, waiting 10s...")
                time.sleep(10)
                continue

            if r.status_code != 200:
                print(f"[EMBED] ViT error: {r.text[:200]}")
                continue

            result = r.json()
            if isinstance(result, list) and result:
                labels = [item["label"] for item in result if "label" in item]
                desc = ", ".join(labels)
                print(f"[EMBED] Labels: {desc}")
                return desc

        except Exception as e:
            print(f"[EMBED] ViT attempt {attempt + 1} error: {e}")
            continue

    return None


def _text_to_embedding(text: str, headers: dict) -> Optional[list[float]]:
    """
    Step 2: Convert text labels to a 384-dimensional embedding vector
    using sentence-transformers/all-MiniLM-L6-v2.
    """
    for attempt in range(3):
        try:
            r = requests.post(
                EMBED_URL,
                headers={**headers, "Content-Type": "application/json"},
                json={"inputs": text},
                timeout=30,
            )
            print(f"[EMBED] Text embed status: {r.status_code}")

            if r.status_code == 503:
                wait = min(r.json().get("estimated_time", 20), 30)
                print(f"[EMBED] Embed model loading, waiting {wait}s...")
                time.sleep(wait)
                continue

            if r.status_code != 200:
                print(f"[EMBED] Text embed error: {r.text[:200]}")
                continue

            result = r.json()
            # Response: [float, float, ...] or [[float, ...]]
            if isinstance(result, list):
                if result and isinstance(result[0], (int, float)):
                    return [float(x) for x in result]
                if result and isinstance(result[0], list):
                    return [float(x) for x in result[0]]

        except Exception as e:
            print(f"[EMBED] Text embed attempt {attempt + 1} error: {e}")
            continue

    return None


def get_embedding(image_bytes: bytes) -> Optional[list[float]]:
    """
    Get image embedding via two-step HuggingFace pipeline:
    1. ViT classifies image → semantic labels
    2. MiniLM embeds labels → 384-dim vector
    """
    headers = _get_headers()
    if not headers:
        return None

    prepared = _prepare_image(image_bytes)

    # Step 1: Image → labels
    labels = _classify_image(prepared, headers)
    if not labels:
        print("[EMBED] FAILED: Could not classify image")
        return None

    # Step 2: Labels → embedding
    embedding = _text_to_embedding(labels, headers)
    if not embedding:
        print("[EMBED] FAILED: Could not get text embedding")
        return None

    print(f"[EMBED] SUCCESS: {len(embedding)}-dim embedding")
    return embedding


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
    """Serialize embedding to compact JSON for DB storage."""
    return json.dumps([round(v, 6) for v in embedding])


def json_to_embedding(json_str: str) -> list[float]:
    """Deserialize embedding from JSON."""
    return json.loads(json_str)
