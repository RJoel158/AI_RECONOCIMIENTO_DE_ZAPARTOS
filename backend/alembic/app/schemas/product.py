from pydantic import BaseModel
from pydantic import ConfigDict


class ProductBase(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    sku: str
    brand: str
    model_name: str
    type: str
    color_primary: str
    color_secondary: str | None = None
    material: str | None = None
    aisle: str | None = None
    shelf: str | None = None
    shelf_level: str | None = None
    image_path: str | None = None


class ProductCreate(ProductBase):
    pass


class ProductRead(ProductBase):
    id: int

    model_config = ConfigDict(from_attributes=True, protected_namespaces=())


class ProductFilters(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    sku: str | None = None
    brand: str | None = None
    type: str | None = None
    color_primary: str | None = None
    color_secondary: str | None = None
    material: str | None = None
    aisle: str | None = None
    shelf: str | None = None
    shelf_level: str | None = None
    q: str | None = None
    order_by: str | None = None
    order_dir: str | None = None


class PageMeta(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    total: int
    limit: int
    offset: int
    next_offset: int | None = None
    prev_offset: int | None = None


class ProductPage(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    items: list[ProductRead]
    meta: PageMeta
