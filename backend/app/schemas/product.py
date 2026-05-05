from pydantic import BaseModel


class ProductBase(BaseModel):
    sku: str
    brand: str
    model_name: str
    type: str
    color_primary: str
    color_secondary: str | None = None
    material: str | None = None
    gender: str | None = None


class ProductCreate(ProductBase):
    pass


class ProductRead(ProductBase):
    id: int

    class Config:
        from_attributes = True


class ProductFilters(BaseModel):
    sku: str | None = None
    brand: str | None = None
    type: str | None = None
    color_primary: str | None = None
    color_secondary: str | None = None
    q: str | None = None


class PageMeta(BaseModel):
    total: int
    limit: int
    offset: int
    next_offset: int | None = None
    prev_offset: int | None = None


class ProductPage(BaseModel):
    items: list[ProductRead]
    meta: PageMeta
