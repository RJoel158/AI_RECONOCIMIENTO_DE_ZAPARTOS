"""
Shoe recognition via Perceptual Hashing (pHash).

pHash converts an image into a 64-bit fingerprint based on DCT
(Discrete Cosine Transform) of the grayscale image.  It is invariant
to changes in lighting, minor rotations, scale, and JPEG compression.

Recognition compares Hamming distance between the scan's pHash and
every stored product hash in the database.
"""

import io
import logging
from collections import Counter

logger = logging.getLogger(__name__)

try:
    import imagehash
    from PIL import Image
    _READY = True
except ImportError:
    imagehash = None
    Image = None
    _READY = False


def compute_phash(image_bytes: bytes) -> str | None:
    """Compute the perceptual hash of an image and return as hex string."""
    if not _READY:
        return None
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("L")  # grayscale
        h = imagehash.phash(img, hash_size=8)  # 64-bit hash
        return str(h)
    except Exception as e:
        logger.error("Failed to compute pHash: %s", e)
        return None


def hamming_distance(hash_a: str, hash_b: str) -> int:
    """
    Compute Hamming distance between two hex-encoded pHash strings.
    Lower = more similar.  0 = identical.  Max = 64.
    """
    try:
        h1 = imagehash.hex_to_hash(hash_a)
        h2 = imagehash.hex_to_hash(hash_b)
        return h1 - h2  # imagehash overloads __sub__ to return Hamming distance
    except Exception:
        return 64  # max distance = completely different


class RecognitionService:
    """pHash-based shoe recognition."""

    # Hamming distance thresholds (out of 64 bits)
    IDENTICAL = 5       # 0-5   → almost certainly the same shoe
    VERY_SIMILAR = 10   # 6-10  → very likely the same
    SIMILAR = 18        # 11-18 → possibly the same
    MAX_DISTANCE = 64

    def __init__(self):
        self._ready = _READY
        if not self._ready:
            logger.warning("imagehash not available — recognition disabled")

    def recognize_from_frames(
        self,
        frame_bytes_list: list[bytes],
        product_hashes: list[tuple[str, str]],  # [(sku, hash_hex), ...]
    ) -> list[tuple[str, float]]:
        """
        Compare captured frames against product hashes from the database.

        Args:
            frame_bytes_list: Raw JPEG bytes from each captured frame.
            product_hashes: List of (sku, image_hash) from the products table.

        Returns:
            List of (sku, similarity_score) sorted by score descending.
            Score is 0.0-1.0 where 1.0 = identical.
        """
        if not self._ready or not frame_bytes_list or not product_hashes:
            return []

        # 1. Compute pHash for each captured frame
        frame_hashes: list[str] = []
        for fb in frame_bytes_list:
            h = compute_phash(fb)
            if h:
                frame_hashes.append(h)

        if not frame_hashes:
            logger.warning("Could not compute pHash for any frame")
            return []

        # 2. For each product, compute average distance across all frames
        results: list[tuple[str, float]] = []
        for sku, product_hash in product_hashes:
            if not product_hash:
                continue

            distances = [
                hamming_distance(fh, product_hash) for fh in frame_hashes
            ]
            avg_distance = sum(distances) / len(distances)

            # Convert distance to similarity score (0-1, higher = better)
            similarity = max(0.0, 1.0 - (avg_distance / self.MAX_DISTANCE))
            results.append((sku, round(similarity, 4)))

        # 3. Sort by similarity descending
        results.sort(key=lambda r: r[1], reverse=True)
        return results[:5]

    def sync_catalog(self):
        """No-op — hashes are stored in the database."""
        pass


recognition_service = RecognitionService()
