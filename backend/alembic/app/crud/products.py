from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from backend.alembic.app.models.product import Product
from backend.alembic.app.schemas.product import ProductCreate, ProductFilters

SORT_FIELDS = {
    "sku": Product.sku,
    "brand": Product.brand,
    "type": Product.type,
    "color_primary": Product.color_primary,
    "model_name": Product.model_name,
    "material": Product.material,
    "aisle": Product.aisle,
    "shelf": Product.shelf,
    "shelf_level": Product.shelf_level,
}


def create_product(db: Session, data: ProductCreate) -> Product:
    product = Product(**data.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def get_product_by_sku(db: Session, sku: str) -> Product | None:
    return db.query(Product).filter(Product.sku == sku).first()


def update_product_image(db: Session, product: Product, image_path: str) -> Product:
    product.image_path = image_path
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def update_product_image_data(
    db: Session,
    product: Product,
    image_path: str,
    image_data: str,
    image_hash: str,
) -> Product:
    """Store image as base64 in DB along with its pHash for recognition."""
    product.image_path = image_path
    product.image_data = image_data
    product.image_hash = image_hash
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def apply_product_filters(query, filters: ProductFilters | None):
    if not filters:
        return query

    if filters.sku:
        query = query.filter(Product.sku.ilike(f"%{filters.sku}%"))
    if filters.brand:
        query = query.filter(Product.brand.ilike(f"%{filters.brand}%"))
    if filters.type:
        query = query.filter(Product.type == filters.type)
    if filters.color_primary:
        query = query.filter(Product.color_primary == filters.color_primary)
    if filters.color_secondary:
        query = query.filter(Product.color_secondary == filters.color_secondary)
    if filters.material:
        query = query.filter(Product.material == filters.material)
    if filters.aisle:
        query = query.filter(Product.aisle == filters.aisle)
    if filters.shelf:
        query = query.filter(Product.shelf == filters.shelf)
    if filters.shelf_level:
        query = query.filter(Product.shelf_level == filters.shelf_level)
    if filters.q:
        query = query.filter(
            or_(
                Product.model_name.ilike(f"%{filters.q}%"),
                Product.brand.ilike(f"%{filters.q}%"),
                Product.sku.ilike(f"%{filters.q}%"),
            )
        )

    if filters.order_by in SORT_FIELDS:
        sort_col = SORT_FIELDS[filters.order_by]
        if (filters.order_dir or "").lower() == "desc":
            query = query.order_by(sort_col.desc())
        else:
            query = query.order_by(sort_col.asc())

    return query


def count_products(db: Session, filters: ProductFilters | None = None) -> int:
    query = db.query(func.count(Product.id))
    query = apply_product_filters(query, filters)
    return int(query.scalar() or 0)


def list_products(
    db: Session,
    filters: ProductFilters | None = None,
    skip: int = 0,
    limit: int = 50,
) -> list[Product]:
    query = db.query(Product)
    query = apply_product_filters(query, filters)
    return query.offset(skip).limit(limit).all()


def get_similar_products(db: Session, product: Product, limit: int = 5) -> list[Product]:
    return (
        db.query(Product)
        .filter(
            Product.type == product.type,
            Product.color_primary == product.color_primary,
            Product.brand == product.brand,
            Product.id != product.id,
        )
        .limit(limit)
        .all()
    )

