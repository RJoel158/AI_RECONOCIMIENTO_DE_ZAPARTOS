"""
Shoe recognition via CLIP embeddings + cosine similarity.

Uses HuggingFace Inference API for CLIP feature extraction.
Embeddings are stored in the database as JSON arrays.
Recognition compares scan embeddings against stored product embeddings
using cosine similarity — instant and highly accurate.
"""

import logging
from backend.alembic.app.services.clip_service import (
    get_embedding,
    cosine_similarity,
    json_to_embedding,
)

logger = logging.getLogger(__name__)


class RecognitionService:
    """CLIP-based shoe recognition."""

    def recognize_from_frames(
        self,
        frame_bytes_list: list[bytes],
        product_embeddings: list[tuple[str, str]],  # [(sku, embedding_json), ...]
    ) -> list[tuple[str, float]]:
        """
        Compare captured frames against product embeddings from the database.

        Strategy: Get CLIP embedding for the BEST frame (middle one),
        then compare against all product embeddings via cosine similarity.
        Using the middle frame because it's typically the most stable shot.

        Returns list of (sku, similarity_score) sorted desc.
        """
        if not frame_bytes_list or not product_embeddings:
            return []

        # Pick the middle frame (most stable shot) + first and last for consensus
        indices = [len(frame_bytes_list) // 2]
        if len(frame_bytes_list) >= 3:
            indices = [0, len(frame_bytes_list) // 2, len(frame_bytes_list) - 1]

        # Get embeddings for selected frames
        frame_embeddings: list[list[float]] = []
        for idx in indices:
            emb = get_embedding(frame_bytes_list[idx])
            if emb:
                frame_embeddings.append(emb)
            if len(frame_embeddings) >= 3:
                break

        if not frame_embeddings:
            logger.warning("Could not get CLIP embedding for any frame")
            return []

        # Parse product embeddings from JSON
        products: list[tuple[str, list[float]]] = []
        for sku, emb_json in product_embeddings:
            if not emb_json:
                continue
            try:
                emb = json_to_embedding(emb_json)
                products.append((sku, emb))
            except Exception:
                continue

        if not products:
            return []

        # Compare each product against all frame embeddings, take average
        results: list[tuple[str, float]] = []
        for sku, product_emb in products:
            similarities = [
                cosine_similarity(frame_emb, product_emb)
                for frame_emb in frame_embeddings
            ]
            avg_sim = sum(similarities) / len(similarities)
            results.append((sku, round(avg_sim, 4)))

        results.sort(key=lambda r: r[1], reverse=True)
        return results[:5]

    def sync_catalog(self):
        """No-op — embeddings are stored in the database."""
        pass


recognition_service = RecognitionService()
