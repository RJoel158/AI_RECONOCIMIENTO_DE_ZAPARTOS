from sqlalchemy.orm import Session

from backend.alembic.app.models.product import Product
from backend.alembic.app.models.stock import Stock
from backend.alembic.app.schemas.stock import StockCreate


def create_stock(db: Session, data: StockCreate) -> Stock:
    product = db.query(Product).filter(Product.sku == data.sku).first()
    if not product:
        raise ValueError("Producto no encontrado")

    payload = data.model_dump(exclude={"sku"})
    item = Stock(product_id=product.id, **payload)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def get_stock_by_sku(db: Session, sku: str) -> list[Stock]:
    return (
        db.query(Stock)
        .join(Stock.product)
        .filter(Stock.product.has(sku=sku))
        .all()
    )
