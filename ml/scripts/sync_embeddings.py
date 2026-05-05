import torch
import numpy as np
from pathlib import Path
import json
from tqdm import tqdm
from ml.scripts.extractor import ShoeFeatureExtractor

def sync_embeddings(captures_dir, model_path="ml/models/shoe_extractor.pth", 
                   embeddings_path="ml/models/embeddings.npy", 
                   map_path="ml/models/sku_map.json"):
    """
    Generates a reference library of shoe vectors from the captures folder.
    """
    # 1. Load the model
    extractor = ShoeFeatureExtractor(pretrained=True) # Using pretrained weights for now
    # If we had a custom trained model: extractor.load_state_dict(torch.load(model_path))
    extractor.eval()

    captures_path = Path(captures_dir)
    image_files = list(captures_path.glob("*.jpg")) + list(captures_path.glob("*.png")) + list(captures_path.glob("*.jpeg"))
    
    if not image_files:
        print("No images found to sync.")
        return

    # Map to store all vectors per SKU: {sku: [vector1, vector2, ...]}
    sku_vectors = {}

    print(f"Processing {len(image_files)} images to create reference embeddings...")
    for img_file in tqdm(image_files):
        # Get SKU from filename (e.g., SKU123_abc.jpg -> SKU123)
        sku = img_file.name.split('_')[0]
        
        vector = extractor.extract_vector(str(img_file))
        
        if sku not in sku_vectors:
            sku_vectors[sku] = []
        sku_vectors[sku].append(vector)

    # 2. Create the "Global Average Vector" for each SKU
    # Because a shoe has multiple photos, we average them for better stability.
    final_embeddings = []
    sku_to_idx = {}

    for idx, (sku, vectors) in enumerate(sku_vectors.items()):
        avg_vector = np.mean(vectors, axis=0)
        final_embeddings.append(avg_vector)
        sku_to_idx[sku] = idx

    # 3. Save the embedding matrix and the mapping file
    embeddings_matrix = np.array(final_embeddings)
    np.save(embeddings_path, embeddings_matrix)
    
    with open(map_path, 'w') as f:
        json.dump(sku_to_idx, f)

    print(f"Sync complete. Indexed {len(sku_to_idx)} unique shoes.")

if __name__ == "__main__":
    # Path based on backend config
    CAP_DIR = "data/captures" 
    sync_embeddings(CAP_DIR)
