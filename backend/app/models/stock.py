from sqlalchemy import Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base


class Stock(Base):
    __tablename__ = "stock"
    __table_args__ = (
        UniqueConstraint("product_id", "size", name="uq_stock_product_size"),
    )

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False, index=True)
    size = Column(String(16), nullable=False)
    quantity = Column(Integer, nullable=False, default=0)

    product = relationship("Product", backref="stock_items")
