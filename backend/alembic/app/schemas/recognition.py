from pydantic import BaseModel
from pydantic import ConfigDict
from backend.alembic.app.schemas.product import ProductRead

class RecognitionCandidate(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    sku: str
    score: float

class SimilarProduct(ProductRead):
    model_config = ConfigDict(protected_namespaces=())

class ShoeDetailsResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    product: ProductRead
    stock: list[dict]
    total_stock: int
    aisle: str | None = None
    shelf: str | None = None
    shelf_level: str | None = None
    similar_products: list[SimilarProduct] | None = None
    is_out_of_stock: bool = False

class RecognitionResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    candidates: list[RecognitionCandidate] | None = None
    details: ShoeDetailsResponse | None = None
    message: str
    confidence_avg: float | None = None

