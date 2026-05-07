"""
CLIP embedding service via HuggingFace Inference API.

Sends images to HuggingFace's hosted CLIP model and receives
512-dimensional embeddings that capture the semantic visual content.
These embeddings are invariant to lighting, angle, and camera quality.
"""

import io
import json
import math
import logging
from typing import Optional

import requests
from PIL import Image

from backend.alembic.app.core.config import settings

logger = logging.getLogger(__name__)

HF_API_URL = (
    "https://api-inference.huggingface.co/pipeline/feature-extraction/"
    "openai/clip-vit-base-patch32"
)


def _get_headers() -> dict:
    """Build auth headers for HuggingFace API."""
    token = settings.hf_api_token
    if not token:
        logger.warning("HF_API_TOKEN not set — CLIP embeddings disabled")
        return {}
    return {"Authorization": f"Bearer {token}"}


def _prepare_image(image_bytes: bytes, max_size: int = 512) -> bytes:
    """
    Resize and convert image to JPEG for consistent API input.
    Smaller images = faster API response and less bandwidth.
    """
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img = img.convert("RGB")

        # Resize maintaining aspect ratio
        w, h = img.size
        if max(w, h) > max_size:
            ratio = max_size / max(w, h)
            img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

        buf = io.BytesIO()
        img.save(buf, "JPEG", quality=85)
        buf.seek(0)
        return buf.read()
    except Exception as e:
        logger.error("Image prep failed: %s", e)
        return image_bytes


def get_embedding(image_bytes: bytes) -> Optional[list[float]]:
    """
    Get CLIP embedding for an image via HuggingFace API.
    Returns a list of 512 floats, or None on failure.
    """
    headers = _get_headers()
    if not headers:
        return None

    prepared = _prepare_image(image_bytes)

    try:
        response = requests.post(
            HF_API_URL,
            headers=headers,
            data=prepared,
            timeout=30,
        )

        if response.status_code == 503:
            # Model is loading — retry once after waiting
            logger.info("CLIP model loading, retrying...")
            import time
            time.sleep(5)
            response = requests.post(
                HF_API_URL,
                headers=headers,
                data=prepared,
                timeout=30,
            )

        if response.status_code != 200:
            logger.error(
                "HuggingFace API error %d: %s",
                response.status_code,
                response.text[:200],
            )
            return None

        result = response.json()

        # The API returns a nested list — flatten to 1D
        if isinstance(result, list):
            if len(result) > 0 and isinstance(result[0], list):
                # result is [[...512 floats...]]
                return result[0]
            return result

        return None

    except requests.exceptions.Timeout:
        logger.error("HuggingFace API timeout")
        return None
    except Exception as e:
        logger.error("CLIP embedding error: %s", e)
        return None


def cosine_similarity(a: list[float], b: list[float]) -> float:
    """
    Compute cosine similarity between two vectors.
    Returns 0.0-1.0 where 1.0 = identical direction.
    """
    if len(a) != len(b) or not a:
        return 0.0

    dot = sum(x * y for x, y in zip(a, b))
    mag_a = math.sqrt(sum(x * x for x in a))
    mag_b = math.sqrt(sum(x * x for x in b))

    if mag_a == 0 or mag_b == 0:
        return 0.0

    sim = dot / (mag_a * mag_b)
    # Clamp to [0, 1]
    return max(0.0, min(1.0, sim))


def embedding_to_json(embedding: list[float]) -> str:
    """Serialize embedding to compact JSON string for DB storage."""
    # Round to 6 decimals to save space (still very precise)
    return json.dumps([round(v, 6) for v in embedding])


def json_to_embedding(json_str: str) -> list[float]:
    """Deserialize embedding from JSON string."""
    return json.loads(json_str)
