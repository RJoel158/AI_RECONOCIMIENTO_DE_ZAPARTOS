from sqlalchemy import Column, Integer, String, UniqueConstraint, Table, ForeignKey
from sqlalchemy.orm import relationship

from backend.alembic.app.core.database import Base


product_materials = Table(
    "product_materials",
    Base.metadata,
    Column("product_id", Integer, ForeignKey("products.id"), primary_key=True),
    Column("material_id", Integer, ForeignKey("materials.id"), primary_key=True),
)


class Material(Base):
    __tablename__ = "materials"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(64), nullable=False, unique=True, index=True)


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
    gender = Column(String(32), nullable=True)
    aisle = Column(String(32), nullable=True)
    shelf = Column(String(32), nullable=True)
    shelf_level = Column(String(32), nullable=True)

    materials = relationship("Material", secondary=product_materials, backref="products")

