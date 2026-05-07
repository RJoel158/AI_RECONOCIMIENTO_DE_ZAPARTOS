from pathlib import Path
from collections import Counter

try:
    from PIL import Image
    _PIL_READY = True
except ImportError:
    _PIL_READY = False


def _histogram_vector(image_path: str, bins: int = 32) -> list[float] | None:
    """Extract a normalised RGB histogram from an image file."""
    if not _PIL_READY:
        return None
    try:
        img = Image.open(image_path).convert("RGB").resize((128, 128))
        hist = img.histogram()  # 256*3 = 768 values (R, G, B)
        # Downsample into `bins` buckets per channel
        bucket_size = 256 // bins
        vec: list[float] = []
        for channel in range(3):
            offset = channel * 256
            for b in range(bins):
                start = offset + b * bucket_size
                end = start + bucket_size
                vec.append(sum(hist[start:end]))
        # Normalise so the total sums to 1.0
        total = sum(vec) or 1.0
        return [v / total for v in vec]
    except Exception:
        return None


def _cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    mag_a = sum(x * x for x in a) ** 0.5
    mag_b = sum(x * x for x in b) ** 0.5
    if mag_a == 0 or mag_b == 0:
        return 0.0
    return dot / (mag_a * mag_b)


class RecognitionService:
    def __init__(self):
        self._pil_ready = _PIL_READY

    def recognize_multi_frame(
        self,
        image_paths: list[str],
        product_images_dir: str = "data/product_images",
    ) -> list[tuple[str, float]]:
        """
        Compare captured frames against stored product reference images.
        Returns a list of (sku, similarity_score) sorted by score descending.
        """
        if not self._pil_ready or not image_paths:
            return []

        # 1. Build average histogram from all captured frames
        histograms = []
        for p in image_paths:
            h = _histogram_vector(p)
            if h:
                histograms.append(h)

        if not histograms:
            return []

        dim = len(histograms[0])
        avg_hist = [
            sum(h[i] for h in histograms) / len(histograms) for i in range(dim)
        ]

        # 2. Compare against every product reference image on disk
        ref_dir = Path(product_images_dir)
        if not ref_dir.exists():
            return []

        results: list[tuple[str, float]] = []
        for img_file in ref_dir.iterdir():
            if img_file.suffix.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
                continue

            ref_hist = _histogram_vector(str(img_file))
            if not ref_hist:
                continue

            score = _cosine_similarity(avg_hist, ref_hist)
            # SKU is the filename without extension
            sku = img_file.stem
            results.append((sku, score))

        # Sort best matches first
        results.sort(key=lambda r: r[1], reverse=True)
        return results[:5]  # top 5 candidates

    def sync_catalog(self):
        """No-op for histogram approach (no pre-computed embeddings needed)."""
        pass


recognition_service = RecognitionService()
