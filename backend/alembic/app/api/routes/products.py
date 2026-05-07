import io
from pathlib import Path

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
    update_product_image,
)
from backend.alembic.app.schemas.product import (
    PageMeta,
    ProductCreate,
    ProductFilters,
    ProductPage,
    ProductRead,
)

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

    images_dir = Path(settings.product_images_dir)
    images_dir.mkdir(parents=True, exist_ok=True)

    suffix = Path(image.filename or "image").suffix
    filename = f"{sku}{suffix}"
    file_path = images_dir / filename

    content = await image.read()
    file_path.write_bytes(content)

    base_url = str(request.base_url).rstrip("/")
    image_url = f"{base_url}/media/{filename}"
    return update_product_image(db, product, image_url)


@router.get("/{sku}/thumbnail")
async def get_product_thumbnail(sku: str):
    """Return a small, low-quality thumbnail of the product image."""
    images_dir = Path(settings.product_images_dir)
    # Try common extensions
    for ext in (".jpg", ".jpeg", ".png", ".webp"):
        candidate = images_dir / f"{sku}{ext}"
        if candidate.exists():
            # Check if cached thumbnail exists
            thumb_dir = images_dir / "thumbs"
            thumb_dir.mkdir(exist_ok=True)
            thumb_path = thumb_dir / f"{sku}_thumb.jpg"

            if not thumb_path.exists():
                try:
                    from PIL import Image
                    img = Image.open(candidate)
                    img.thumbnail((200, 200))
                    img = img.convert("RGB")
                    img.save(thumb_path, "JPEG", quality=60)
                except Exception:
                    # Fallback: return original
                    return Response(
                        content=candidate.read_bytes(),
                        media_type="image/jpeg",
                    )

            return Response(
                content=thumb_path.read_bytes(),
                media_type="image/jpeg",
                headers={"Cache-Control": "public, max-age=3600"},
            )

    raise HTTPException(status_code=404, detail="Imagen no encontrada")
