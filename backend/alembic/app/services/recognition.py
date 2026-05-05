import torch
import numpy as np
from pathlib import Path
from ml.scripts.extractor import ShoeFeatureExtractor
from ml.scripts.sync_embeddings import sync_embeddings

class RecognitionService:
    def __init__(self):
        # Paths to ML assets
        self.model_path = Path("ml/models/shoe_extractor.pth")
        self.embeddings_path = Path("ml/models/embeddings.npy")
        self.map_path = Path("ml/models/sku_map.json")
        
        # Initialize Extractor
        self.extractor = ShoeFeatureExtractor(pretrained=True)
        self.extractor.eval()
        
        # Load reference library
        self.embeddings = np.load(self.embeddings_path) if self.embeddings_path.exists() else None
        self.sku_map = {}
        if self.map_path.exists():
            import json
            with open(self.map_path, 'r') as f:
                self.sku_map = json.load(f)

    def sync_catalog(self):
        """
        Trigger a re-sync of embeddings if new photos were uploaded.
        """
        sync_embeddings("data/captures")

    def recognize(self, image_path: str):
        """
        Main recognition logic: Image -> Vector -> Nearest SKU
        """
        if self.embeddings is None:
            return None, "Library not initialized. Please run sync first."

        # 1. Extract vector from the uploaded image
        target_vector = self.extractor.extract_vector(image_path)
        
        # 2. Calculate Cosine Similarity against all reference vectors
        # (Distance = 1 - similarity)
        distances = np.linalg.norm(self.embeddings - target_vector, axis=1)
        
        # 3. Get the index of the closest vector
        best_match_idx = np.argmin(distances)
        best_score = 1 - distances[best_match_idx]
        
        # 4. Map index back to SKU
        # We reverse the map {sku: idx} to {idx: sku}
        inv_map = {v: k for k, v in self.sku_map.items()}
        best_sku = inv_map.get(best_match_idx)
        
        return best_sku, best_score

recognition_service = RecognitionService()
