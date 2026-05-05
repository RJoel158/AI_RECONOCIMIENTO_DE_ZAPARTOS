from sqlalchemy import Column, DateTime, Integer, String, func

from backend.alembic.app.core.database import Base


class Capture(Base):
    __tablename__ = "captures"

    id = Column(Integer, primary_key=True, index=True)
    sku = Column(String(64), nullable=False, index=True)
    image_path = Column(String(256), nullable=False)
    source = Column(String(32), nullable=True)
    note = Column(String(256), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
