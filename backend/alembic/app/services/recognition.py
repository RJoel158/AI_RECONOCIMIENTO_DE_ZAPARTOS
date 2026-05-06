from pathlib import Path
from collections import Counter

try:
    import numpy as np
    from ml.scripts.extractor import ShoeFeatureExtractor
    from ml.scripts.sync_embeddings import sync_embeddings
    _ML_READY = True
except Exception:
    np = None
    ShoeFeatureExtractor = None
    sync_embeddings = None
    _ML_READY = False

class RecognitionService:
    def __init__(self):
        # Paths to ML assets
        self.model_path = Path("ml/models/shoe_extractor.pth")
        self.embeddings_path = Path("ml/models/embeddings.npy")
        self.map_path = Path("ml/models/sku_map.json")
        
        self._ml_ready = _ML_READY
        self.extractor = None

        if self._ml_ready:
            self.extractor = ShoeFeatureExtractor(pretrained=True)
            self.extractor.eval()
        
        # Load reference library
        self.embeddings = (
            np.load(self.embeddings_path)
            if self._ml_ready and self.embeddings_path.exists()
            else None
        )
        self.sku_map = {}
        if self.map_path.exists():
            import json
            with open(self.map_path, 'r') as f:
                self.sku_map = json.load(f)

    def sync_catalog(self):
        if not self._ml_ready or not sync_embeddings:
            return
        sync_embeddings("data/captures")

    def _get_best_sku(self, image_path):
        """Internal helper to get the best SKU for a single image"""
        if not self._ml_ready or self.embeddings is None or not self.extractor:
            return None, 0.0
            
        target_vector = self.extractor.extract_vector(image_path)
        distances = np.linalg.norm(self.embeddings - target_vector, axis=1)
        best_match_idx = np.argmin(distances)
        best_score = 1 - distances[best_match_idx]
        
        inv_map = {v: k for k, v in self.sku_map.items()}
        return inv_map.get(best_match_idx), best_score

    def recognize_multi_frame(self, image_paths: list[str]):
        """
        Implements Consensus Logic:
        Processes multiple frames and returns the SKU with the highest 
        combined confidence and frequency.
        """
        if not image_paths or not self._ml_ready:
            return None, 0.0

        results = []
        for path in image_paths:
            sku, score = self._get_best_sku(path)
            if sku:
                results.append((sku, score))

        if not results:
            return None, 0.0

        # Voting: Count frequency of each SKU
        skus = [r[0] for r in results]
        counts = Counter(skus)
        
        # We want the SKU that appeared most often, but also has the best avg score
        # Tie-break: Highest average confidence among the most frequent SKUs
        most_common_sku, freq = counts.most_common(1)[0]
        
        # Calculate average confidence for the winning SKU
        scores_for_winner = [r[1] for r in results if r[0] == most_common_sku]
        avg_confidence = np.mean(scores_for_winner)

        return most_common_sku, avg_confidence

recognition_service = RecognitionService()
