"""
Shoe recognition service using a hybrid approach:
1. ORB feature matching (structural — lighting invariant)
2. Histogram comparison (colour — normalised to reduce lighting impact)

The combined score is weighted 70% structure + 30% colour.
"""

from pathlib import Path
import logging

logger = logging.getLogger(__name__)

try:
    import cv2
    import numpy as np
    _CV_READY = True
except ImportError:
    cv2 = None
    np = None
    _CV_READY = False

try:
    from PIL import Image
    _PIL_READY = True
except ImportError:
    _PIL_READY = False

# ────────────────────────────────────────────────
# Feature helpers
# ────────────────────────────────────────────────

# Reusable ORB detector and BF matcher
_orb = cv2.ORB_create(nfeatures=500) if _CV_READY else None
_bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False) if _CV_READY else None


def _load_grey(path: str, size: int = 320):
    """Load image as greyscale, resize, and apply CLAHE equalisation."""
    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None
    img = cv2.resize(img, (size, size))
    # CLAHE normalises brightness → very robust against lighting changes
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    img = clahe.apply(img)
    return img


def _orb_score(img_a, img_b) -> float:
    """
    Compare two greyscale images using ORB keypoints.
    Returns a 0-1 similarity score based on good matches.
    """
    if _orb is None or _bf is None:
        return 0.0

    kp_a, desc_a = _orb.detectAndCompute(img_a, None)
    kp_b, desc_b = _orb.detectAndCompute(img_b, None)

    if desc_a is None or desc_b is None or len(desc_a) < 2 or len(desc_b) < 2:
        return 0.0

    # KNN match + Lowe's ratio test
    matches = _bf.knnMatch(desc_a, desc_b, k=2)
    good = []
    for m_n in matches:
        if len(m_n) == 2:
            m, n = m_n
            if m.distance < 0.75 * n.distance:
                good.append(m)

    # Score = proportion of good matches relative to min keypoints
    max_possible = min(len(kp_a), len(kp_b))
    if max_possible == 0:
        return 0.0
    return min(len(good) / max_possible, 1.0)


def _histogram_score(path_a: str, path_b: str) -> float:
    """
    Compare two images using normalised HSV histograms.
    HSV is more robust than RGB because V channel absorbs lighting changes.
    """
    if not _CV_READY:
        return 0.0

    img_a = cv2.imread(path_a)
    img_b = cv2.imread(path_b)
    if img_a is None or img_b is None:
        return 0.0

    # Resize to same dimensions
    size = (128, 128)
    img_a = cv2.resize(img_a, size)
    img_b = cv2.resize(img_b, size)

    # Convert to HSV (hue is lighting-invariant)
    hsv_a = cv2.cvtColor(img_a, cv2.COLOR_BGR2HSV)
    hsv_b = cv2.cvtColor(img_b, cv2.COLOR_BGR2HSV)

    # Calculate histograms (H: 30 bins, S: 32 bins)
    hist_a = cv2.calcHist([hsv_a], [0, 1], None, [30, 32], [0, 180, 0, 256])
    hist_b = cv2.calcHist([hsv_b], [0, 1], None, [30, 32], [0, 180, 0, 256])

    # Normalise
    cv2.normalize(hist_a, hist_a)
    cv2.normalize(hist_b, hist_b)

    # Compare using correlation (1.0 = identical)
    score = cv2.compareHist(hist_a, hist_b, cv2.HISTCMP_CORREL)
    return max(score, 0.0)  # clamp to 0..1


# ────────────────────────────────────────────────
# Main service
# ────────────────────────────────────────────────

class RecognitionService:
    """Hybrid ORB + Histogram shoe recognition."""

    WEIGHT_ORB = 0.70
    WEIGHT_HIST = 0.30

    def __init__(self):
        self._ready = _CV_READY
        if not self._ready:
            logger.warning("OpenCV not available — recognition disabled")

    def recognize_multi_frame(
        self,
        image_paths: list[str],
        product_images_dir: str = "data/product_images",
    ) -> list[tuple[str, float]]:
        """
        Multi-frame consensus recognition.
        1. For each captured frame, compute ORB + histogram scores against
           every reference product image.
        2. Average scores across all frames for each product.
        3. Return top candidates sorted by combined score.
        """
        if not self._ready or not image_paths:
            return []

        ref_dir = Path(product_images_dir)
        if not ref_dir.exists():
            logger.warning("Product images dir not found: %s", ref_dir)
            return []

        # Collect reference images
        ref_images: list[tuple[str, str]] = []  # (sku, path)
        for img_file in ref_dir.iterdir():
            if img_file.suffix.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
                continue
            if img_file.parent.name == "thumbs":
                continue
            ref_images.append((img_file.stem, str(img_file)))

        if not ref_images:
            logger.warning("No reference images found in %s", ref_dir)
            return []

        # Pre-load greyscale versions of all reference images
        ref_greys = {}
        for sku, path in ref_images:
            grey = _load_grey(path)
            if grey is not None:
                ref_greys[sku] = grey

        # Score each frame against each reference
        # scores[sku] = list of combined scores from each frame
        scores: dict[str, list[float]] = {sku: [] for sku, _ in ref_images}

        for frame_path in image_paths:
            frame_grey = _load_grey(frame_path)
            if frame_grey is None:
                continue

            for sku, ref_path in ref_images:
                ref_grey = ref_greys.get(sku)
                if ref_grey is None:
                    continue

                orb = _orb_score(frame_grey, ref_grey)
                hist = _histogram_score(frame_path, ref_path)
                combined = (self.WEIGHT_ORB * orb) + (self.WEIGHT_HIST * hist)
                scores[sku].append(combined)

        # Average scores across all frames
        results: list[tuple[str, float]] = []
        for sku, score_list in scores.items():
            if score_list:
                avg = sum(score_list) / len(score_list)
                results.append((sku, round(avg, 4)))

        results.sort(key=lambda r: r[1], reverse=True)
        return results[:5]

    def sync_catalog(self):
        """No-op — features are computed on the fly."""
        pass


recognition_service = RecognitionService()
