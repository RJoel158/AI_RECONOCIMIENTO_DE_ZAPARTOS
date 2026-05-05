from sqlalchemy import Column, Integer, String, UniqueConstraint

from app.core.database import Base


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (UniqueConstraint("sku", name="uq_products_sku"),)

    id = Column(Integer, primary_key=True, index=True)
    sku = Column(String(64), nullable=False, index=True)
    brand = Column(String(64), nullable=False, index=True)
    model_name = Column(String(128), nullable=False)
    type = Column(String(32), nullable=False, index=True)
    color_primary = Column(String(32), nullable=False, index=True)
    color_secondary = Column(String(32), nullable=True, index=True)
    material = Column(String(64), nullable=True)
    gender = Column(String(32), nullable=True)
