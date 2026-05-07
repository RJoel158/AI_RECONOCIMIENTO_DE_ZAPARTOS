"""
CLIP embedding service via HuggingFace Inference API.

Sends images to HuggingFace's hosted CLIP model and receives
512-dimensional embeddings that capture the semantic visual content.
"""

import io
import json
import math
import time
from typing import Optional

import requests
from PIL import Image

from backend.alembic.app.core.config import settings

# Use the /models/ endpoint (NOT /pipeline/)
HF_API_URL = "https://api-inference.huggingface.co/models/openai/clip-vit-base-patch32"


def _get_headers() -> dict:
    """Build auth headers for HuggingFace API."""
    token = settings.hf_api_token
    if not token:
        print("[CLIP] ERROR: HF_API_TOKEN not set")
        return {}
    print(f"[CLIP] Token present: {token[:10]}...")
    return {
        "Authorization": f"Bearer {token}",
    }


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
        print(f"[CLIP] Image prepared: {img.size}, {buf.getbuffer().nbytes} bytes")
        return buf.read()
    except Exception as e:
        print(f"[CLIP] Image prep failed: {e}")
        return image_bytes


def get_embedding(image_bytes: bytes) -> Optional[list[float]]:
    """
    Get image embedding via HuggingFace Inference API.

    Tries the feature-extraction approach first.
    Returns a list of floats (embedding vector), or None on failure.
    """
    headers = _get_headers()
    if not headers:
        return None

    prepared = _prepare_image(image_bytes)

    # Attempt 1: Send image as binary for feature extraction
    for attempt in range(3):
        try:
            print(f"[CLIP] Attempt {attempt + 1}: POST to {HF_API_URL}")
            response = requests.post(
                HF_API_URL,
                headers=headers,
                data=prepared,
                timeout=60,
            )

            print(f"[CLIP] Response status: {response.status_code}")

            if response.status_code == 503:
                # Model loading
                body = response.json()
                wait_time = body.get("estimated_time", 20)
                print(f"[CLIP] Model loading, waiting {wait_time}s...")
                time.sleep(min(wait_time, 30))
                continue

            if response.status_code == 429:
                print("[CLIP] Rate limited, waiting 10s...")
                time.sleep(10)
                continue

            if response.status_code != 200:
                print(f"[CLIP] Error {response.status_code}: {response.text[:500]}")
                # Try alternative URL on first failure
                if attempt == 0:
                    print("[CLIP] Trying alternative pipeline URL...")
                    alt_url = "https://api-inference.huggingface.co/pipeline/feature-extraction/openai/clip-vit-base-patch32"
                    response = requests.post(
                        alt_url,
                        headers=headers,
                        data=prepared,
                        timeout=60,
                    )
                    print(f"[CLIP] Alt response: {response.status_code}")
                    if response.status_code != 200:
                        print(f"[CLIP] Alt error: {response.text[:500]}")
                        continue
                else:
                    continue

            result = response.json()
            print(f"[CLIP] Response type: {type(result).__name__}, preview: {str(result)[:200]}")

            # Parse the embedding from the response
            embedding = _extract_embedding(result)
            if embedding:
                print(f"[CLIP] SUCCESS: Got {len(embedding)}-dim embedding")
                return embedding
            else:
                print(f"[CLIP] Could not extract embedding from response")
                return None

        except requests.exceptions.Timeout:
            print(f"[CLIP] Timeout on attempt {attempt + 1}")
            continue
        except Exception as e:
            print(f"[CLIP] Error on attempt {attempt + 1}: {e}")
            continue

    print("[CLIP] All attempts failed")
    return None


def _extract_embedding(result) -> Optional[list[float]]:
    """
    Extract a 1D embedding vector from various HuggingFace response formats.

    The API can return different formats:
    - [float, float, ...] — direct 1D vector
    - [[float, float, ...]] — wrapped in an outer list
    - [[[float, ...]]] — doubly wrapped (patch tokens)
    """
    if not result:
        return None

    if isinstance(result, dict):
        # Error response
        if "error" in result:
            print(f"[CLIP] API error: {result['error']}")
            return None
        return None

    if isinstance(result, list):
        # Case: [float, float, ...]
        if len(result) > 0 and isinstance(result[0], (int, float)):
            return [float(x) for x in result]

        # Case: [[float, float, ...]]
        if len(result) > 0 and isinstance(result[0], list):
            inner = result[0]
            if len(inner) > 0 and isinstance(inner[0], (int, float)):
                return [float(x) for x in inner]

            # Case: [[[float, ...]]] — average all patch tokens into one vector
            if len(inner) > 0 and isinstance(inner[0], list):
                print(f"[CLIP] Got {len(inner)} patch tokens of dim {len(inner[0])}, averaging...")
                dim = len(inner[0])
                avg = [0.0] * dim
                for patch in inner:
                    for i, v in enumerate(patch):
                        avg[i] += float(v)
                n = len(inner)
                avg = [v / n for v in avg]
                return avg

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
