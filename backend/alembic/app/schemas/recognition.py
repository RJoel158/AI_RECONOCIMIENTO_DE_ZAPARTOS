from pydantic import BaseModel
from backend.alembic.app.schemas.product import ProductRead

class RecognitionCandidate(BaseModel):
    sku: str
    score: float

class SimilarProduct(ProductRead):
    pass

class ShoeDetailsResponse(BaseModel):
    product: ProductRead
    stock: list[dict]
    total_stock: int
    aisle: str | None = None
    shelf: str | None = None
    shelf_level: str | None = None
    similar_products: list[SimilarProduct] | None = None
    is_out_of_stock: bool = False

class RecognitionResponse(BaseModel):
    candidates: list[RecognitionCandidate] | None = None
    details: ShoeDetailsResponse | None = None
    message: str
    confidence_avg: float | None = None

