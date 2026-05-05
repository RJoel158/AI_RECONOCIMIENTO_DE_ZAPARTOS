from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.crud.products import (
    count_products,
    create_product,
    get_product_by_sku,
    list_products,
)
from app.schemas.product import (
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
