from sqlalchemy.orm import Session

from backend.alembic.app.models.capture import Capture


def create_capture(
    db: Session,
    sku: str,
    image_path: str,
    source: str | None = None,
    note: str | None = None,
) -> Capture:
    capture = Capture(sku=sku, image_path=image_path, source=source, note=note)
    db.add(capture)
    db.commit()
    db.refresh(capture)
    return capture


def list_captures(
    db: Session,
    sku: str | None = None,
    skip: int = 0,
    limit: int = 50,
) -> list[Capture]:
    query = db.query(Capture)
    if sku:
        query = query.filter(Capture.sku == sku)
    return query.order_by(Capture.created_at.desc()).offset(skip).limit(limit).all()
