from pydantic import BaseModel


class StockBase(BaseModel):
    size: str
    quantity: int


class StockCreate(StockBase):
    sku: str


class StockRead(StockBase):
    id: int
    product_id: int

    class Config:
        from_attributes = True
