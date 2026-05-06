from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from backend.alembic.app.core.config import settings
from backend.alembic.app.core.database import get_db
from backend.alembic.app.crud.captures import create_capture, list_captures
from backend.alembic.app.schemas.capture import CaptureRead
from backend.alembic.app.services.recognition import recognition_service

router = APIRouter(prefix="/captures", tags=["captures"])


@router.post("", response_model=list[CaptureRead])
async def create_capture_endpoint(
    sku: str = Form(...),
    source: str | None = Form(None),
    note: str | None = Form(None),
    images: list[UploadFile] = File(...),
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
):
    captures_dir = Path(settings.captures_dir)
    captures_dir.mkdir(parents=True, exist_ok=True)

    captures: list[CaptureRead] = []
    for index, image in enumerate(images):
        if image.content_type and not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail=f"Archivo {index} no es imagen"
            )

        suffix = Path(image.filename or "image").suffix
        filename = f"{sku}_{uuid4().hex}{suffix}"
        file_path = captures_dir / filename

        content = await image.read()
        file_path.write_bytes(content)

        capture = create_capture(
            db,
            sku=sku,
            image_path=str(file_path),
            source=source,
            note=note,
        )
        captures.append(capture)

    # Auto-sync embeddings after new capture (async).
    if background_tasks is not None:
        background_tasks.add_task(recognition_service.sync_catalog)

    return captures


@router.get("", response_model=list[CaptureRead])
def list_captures_endpoint(
    sku: str | None = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    return list_captures(db, sku=sku, skip=skip, limit=limit)
