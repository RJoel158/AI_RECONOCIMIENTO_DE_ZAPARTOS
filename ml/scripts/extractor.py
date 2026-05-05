import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from PIL import Image
import numpy as np
from pathlib import Path

class ShoeFeatureExtractor(nn.Module):
    """
    Feature extractor for shoes. 
    Uses EfficientNet-B0 as a backbone to capture:
    - Colors (Low-level layers)
    - Shapes/Curves (Mid-level layers)
    - Crucial details/textures (High-level layers)
    """
    def __init__(self, pretrained=True):
        super(ShoeFeatureExtractor, self).__init__()
        # EfficientNet-B0 is lightweight and powerful for mobile/server hybrid apps
        self.backbone = models.efficientnet_b0(pretrained=pretrained)
        
        # Remove the final classification layer to get the 1280-dimensional embedding
        self.backbone.classifier = nn.Identity()
        
        # Optional: Add a projection head to compress the 1280 vector into 
        # a smaller, more discriminative embedding (e.g., 512)
        self.projection = nn.Sequential(
            nn.Linear(1280, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Linear(512, 512)
        )

    def forward(self, x):
        # x: Batch of images (B, 3, 224, 224)
        features = self.backbone(x) # Output: (B, 1280)
        embedding = self.projection(features) # Output: (B, 512)
        # L2 Normalization to make embeddings comparable via Cosine Similarity
        return F.normalize(embedding, p=2, dim=1)

    def extract_vector(self, image_path):
        """
        Helper to convert a single image file into a normalized feature vector.
        """
        self.eval()
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])
        
        image = Image.open(image_path).convert("RGB")
        img_tensor = transform(image).unsqueeze(0) # Add batch dimension
        
        with torch.no_grad():
            vector = self.forward(img_tensor)
        
        return vector.squeeze().numpy()

def save_model(model, path="ml/models/shoe_extractor.pth"):
    torch.save(model.state_dict(), path)
    print(f"Model saved to {path}")

def load_model(path="ml/models/shoe_extractor.pth"):
    model = ShoeFeatureExtractor(pretrained=False)
    model.load_state_dict(torch.load(path))
    model.eval()
    return model

if __name__ == "__main__":
    # Quick test
    extractor = ShoeFeatureExtractor()
    print("Extractor initialized. Backbone: EfficientNet-B0")
    print("Output Vector Size: 512")
