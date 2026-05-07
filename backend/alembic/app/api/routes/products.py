import base64
import io
import json

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from backend.alembic.app.core.database import get_db
from backend.alembic.app.core.config import settings
from backend.alembic.app.models.product import Product
from backend.alembic.app.crud.products import (
    count_products,
    create_product,
    get_product_by_sku,
    list_products,
    update_product_image_data,
)
from backend.alembic.app.schemas.product import (
    PageMeta,
    ProductCreate,
    ProductFilters,
    ProductPage,
    ProductRead,
)
from backend.alembic.app.services.clip_service import get_embedding, embedding_to_json

router = APIRouter(prefix="/products", tags=["products"])


@router.post("", response_model=ProductRead)
def create_product_endpoint(payload: ProductCreate, db: Session = Depends(get_db)):
    existing = get_product_by_sku(db, payload.sku)
    if existing:
        raise HTTPException(status_code=409, detail="SKU ya existe")
    return create_product(db, payload)


@router.get("", response_model=ProductPage)
def list_products_endpoint(
    filters: ProductFilters = Depends(),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    total = count_products(db, filters=filters)
    items = list_products(db, filters=filters, skip=skip, limit=limit)
    next_offset = skip + limit if skip + limit < total else None
    prev_offset = skip - limit if skip - limit >= 0 else None
    meta = PageMeta(
        total=total,
        limit=limit,
        offset=skip,
        next_offset=next_offset,
        prev_offset=prev_offset,
    )
    return ProductPage(items=items, meta=meta)


ALLOWED_DISTINCT_FIELDS = {
    "brand": Product.brand,
    "type": Product.type,
    "color_primary": Product.color_primary,
    "color_secondary": Product.color_secondary,
    "material": Product.material,
    "aisle": Product.aisle,
    "shelf": Product.shelf,
    "shelf_level": Product.shelf_level,
}


@router.get("/distinct/{field}")
def get_distinct_values(field: str, db: Session = Depends(get_db)):
    col = ALLOWED_DISTINCT_FIELDS.get(field)
    if col is None:
        raise HTTPException(status_code=400, detail=f"Campo '{field}' no válido")
    values = (
        db.query(col)
        .filter(col.isnot(None), col != "")
        .distinct()
        .order_by(col)
        .all()
    )
    return [v[0] for v in values]


@router.get("/distinct-all", response_model=None)
def get_all_distinct_values(db: Session = Depends(get_db)):
    """Return distinct values for ALL filterable fields in one request."""
    result = {}
    for field_name, col in ALLOWED_DISTINCT_FIELDS.items():
        values = (
            db.query(col)
            .filter(col.isnot(None), col != "")
            .distinct()
            .order_by(col)
            .all()
        )
        result[field_name] = [v[0] for v in values]
    return result


@router.get("/{sku}", response_model=ProductRead)
def get_product_endpoint(sku: str, db: Session = Depends(get_db)):
    product = get_product_by_sku(db, sku)
    if not product:
        raise HTTPException(status_code=404, detail="SKU no encontrado")
    return product


@router.post("/{sku}/image", response_model=ProductRead)
async def upload_product_image(
    sku: str,
    request: Request,
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    product = get_product_by_sku(db, sku)
    if not product:
        raise HTTPException(status_code=404, detail="SKU no encontrado")

    if image.content_type and not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Archivo no es imagen")

    # Read image bytes
    content = await image.read()

    # Get CLIP embedding from HuggingFace (async-safe since it's I/O)
    embedding = get_embedding(content)
    embedding_json = embedding_to_json(embedding) if embedding else ""

    # Encode as base64 for DB storage
    b64 = base64.b64encode(content).decode("utf-8")

    # Build the URL that will serve this image
    base_url = str(request.base_url).rstrip("/")
    image_url = f"{base_url}/products/{sku}/image"

    return update_product_image_data(db, product, image_url, b64, embedding_json)


@router.get("/{sku}/image")
async def get_product_image(sku: str, db: Session = Depends(get_db)):
    """Serve product image from database (base64 decoded)."""
    product = get_product_by_sku(db, sku)
    if not product or not product.image_data:
        raise HTTPException(status_code=404, detail="Imagen no encontrada")

    image_bytes = base64.b64decode(product.image_data)
    return Response(
        content=image_bytes,
        media_type="image/jpeg",
        headers={"Cache-Control": "public, max-age=3600"},
    )


@router.get("/{sku}/thumbnail")
async def get_product_thumbnail(sku: str, db: Session = Depends(get_db)):
    """Serve a low-quality thumbnail generated on-the-fly from DB data."""
    product = get_product_by_sku(db, sku)
    if not product or not product.image_data:
        raise HTTPException(status_code=404, detail="Imagen no encontrada")

    try:
        from PIL import Image

        image_bytes = base64.b64decode(product.image_data)
        img = Image.open(io.BytesIO(image_bytes))
        img.thumbnail((200, 200))
        img = img.convert("RGB")

        buf = io.BytesIO()
        img.save(buf, "JPEG", quality=55)
        buf.seek(0)

        return Response(
            content=buf.read(),
            media_type="image/jpeg",
            headers={"Cache-Control": "public, max-age=3600"},
        )
    except Exception:
        # Fallback: return full image
        image_bytes = base64.b64decode(product.image_data)
        return Response(content=image_bytes, media_type="image/jpeg")
