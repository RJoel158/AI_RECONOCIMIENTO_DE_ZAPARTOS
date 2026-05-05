from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from backend.alembic.app.core.config import settings
from backend.alembic.app.core.database import get_db
from backend.alembic.app.crud.captures import create_capture, list_captures
from backend.alembic.app.schemas.capture import CaptureRead

router = APIRouter(prefix="/captures", tags=["captures"])


@router.post("", response_model=CaptureRead)
async def create_capture_endpoint(
    sku: str,
    source: str | None = None,
    note: str | None = None,
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Archivo no es imagen")

    captures_dir = Path(settings.captures_dir)
    captures_dir.mkdir(parents=True, exist_ok=True)

    suffix = Path(image.filename or "image").suffix
    filename = f"{sku}_{uuid4().hex}{suffix}"
    file_path = captures_dir / filename

    content = await image.read()
    file_path.write_bytes(content)

    return create_capture(
        db,
        sku=sku,
        image_path=str(file_path),
        source=source,
        note=note,
    )


@router.get("", response_model=list[CaptureRead])
def list_captures_endpoint(
    sku: str | None = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    return list_captures(db, sku=sku, skip=skip, limit=limit)
