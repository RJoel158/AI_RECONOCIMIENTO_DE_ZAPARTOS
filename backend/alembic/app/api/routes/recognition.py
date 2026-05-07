from fastapi import APIRouter, File, HTTPException, UploadFile, Depends
from sqlalchemy.orm import Session
from pathlib import Path
import shutil
from typing import List

from backend.alembic.app.schemas.recognition import (
    RecognitionCandidate,
    RecognitionResponse,
    ShoeDetailsResponse,
)
from backend.alembic.app.core.database import get_db
from backend.alembic.app.core.config import settings
from backend.alembic.app.crud.products import get_product_by_sku, get_similar_products
from backend.alembic.app.crud.stock import get_stock_by_sku
from backend.alembic.app.services.recognition import recognition_service

router = APIRouter(prefix="/recognize", tags=["recognition"])

DIRECT_MATCH_THRESHOLD = 0.80


@router.post("", response_model=RecognitionResponse)
async def recognize_shoe(
    images: List[UploadFile] = File(...), db: Session = Depends(get_db)
):
    # 1. Save frames to temp dir
    temp_paths = []
    temp_dir = Path("data/temp_recognize")
    temp_dir.mkdir(parents=True, exist_ok=True)

    try:
        for i, image in enumerate(images):
            if image.content_type and not image.content_type.startswith("image/"):
                raise HTTPException(
                    status_code=400, detail=f"Archivo {i} no es imagen"
                )

            img_path = temp_dir / f"frame_{i}.jpg"
            with open(img_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            temp_paths.append(str(img_path))

        # 2. Run histogram-based recognition
        results = recognition_service.recognize_multi_frame(
            temp_paths,
            product_images_dir=settings.product_images_dir,
        )

        if not results:
            return RecognitionResponse(
                message="No se encontraron coincidencias. Asegúrate de tener productos registrados.",
                candidates=[],
            )

        # 3. Build candidates list
        candidates = []
        for sku, score in results:
            product = get_product_by_sku(db, sku)
            if product:
                candidates.append(RecognitionCandidate(sku=sku, score=round(score, 4)))

        if not candidates:
            return RecognitionResponse(
                message="Las imágenes de referencia no coinciden con productos en el catálogo.",
                candidates=[],
            )

        # 4. If top candidate is a strong match, return full details
        best_sku = candidates[0].sku
        best_score = candidates[0].score
        details = None

        if best_score >= DIRECT_MATCH_THRESHOLD:
            product = get_product_by_sku(db, best_sku)
            stock_items = get_stock_by_sku(db, best_sku)
            total_stock = sum(item.quantity for item in stock_items)
            is_out = total_stock == 0
            similar = get_similar_products(db, product) if is_out else None

            details = ShoeDetailsResponse(
                product=product,
                stock=[{"size": s.size, "quantity": s.quantity} for s in stock_items],
                total_stock=total_stock,
                aisle=product.aisle,
                shelf=product.shelf,
                shelf_level=product.shelf_level,
                similar_products=similar,
                is_out_of_stock=is_out,
            )

        return RecognitionResponse(
            candidates=candidates,
            details=details,
            message=(
                f"Match directo: {best_sku} ({best_score:.0%})"
                if best_score >= DIRECT_MATCH_THRESHOLD
                else f"Se encontraron {len(candidates)} candidato(s)"
            ),
            confidence_avg=best_score,
        )
    finally:
        for p in temp_paths:
            Path(p).unlink(missing_ok=True)


@router.get("/{sku}", response_model=RecognitionResponse)
async def recognize_shoe_by_sku(sku: str, db: Session = Depends(get_db)):
    product = get_product_by_sku(db, sku)
    if not product:
        raise HTTPException(status_code=404, detail="SKU no encontrado")

    stock_items = get_stock_by_sku(db, sku)
    total_stock = sum(item.quantity for item in stock_items)

    is_out_of_stock = total_stock == 0
    similar_products = None

    if is_out_of_stock:
        similar_products = get_similar_products(db, product)

    return RecognitionResponse(
        details=ShoeDetailsResponse(
            product=product,
            stock=[{"size": s.size, "quantity": s.quantity} for s in stock_items],
            total_stock=total_stock,
            aisle=product.aisle,
            shelf=product.shelf,
            shelf_level=product.shelf_level,
            similar_products=similar_products,
            is_out_of_stock=is_out_of_stock,
        ),
        message="Producto recuperado por SKU",
    )
