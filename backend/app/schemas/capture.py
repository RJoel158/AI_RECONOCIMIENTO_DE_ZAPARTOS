from datetime import datetime

from pydantic import BaseModel


class CaptureBase(BaseModel):
    sku: str
    source: str | None = None
    note: str | None = None


class CaptureRead(CaptureBase):
    id: int
    image_path: str
    created_at: datetime

    class Config:
        from_attributes = True
