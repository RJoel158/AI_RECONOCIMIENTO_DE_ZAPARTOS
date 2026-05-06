from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from sqlalchemy.orm import Session

from backend.alembic.app.core.database import get_db
from backend.alembic.app.core.config import settings
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
