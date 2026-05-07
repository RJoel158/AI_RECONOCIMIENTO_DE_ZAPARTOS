from fastapi import APIRouter, File, HTTPException, UploadFile, Depends
from sqlalchemy.orm import Session
from typing import List

from backend.alembic.app.schemas.recognition import (
    RecognitionCandidate,
    RecognitionResponse,
    ShoeDetailsResponse,
)
from backend.alembic.app.core.database import get_db
from backend.alembic.app.models.product import Product
from backend.alembic.app.crud.products import get_product_by_sku, get_similar_products
from backend.alembic.app.crud.stock import get_stock_by_sku
from backend.alembic.app.services.recognition import recognition_service

router = APIRouter(prefix="/recognize", tags=["recognition"])

# pHash similarity: 1.0 = identical, 0.92 ≈ Hamming distance 5/64
DIRECT_MATCH_THRESHOLD = 0.85


@router.post("", response_model=RecognitionResponse)
async def recognize_shoe(
    images: List[UploadFile] = File(...), db: Session = Depends(get_db)
):
    # 1. Read all frame bytes (no filesystem writes)
    frame_bytes_list: list[bytes] = []
    for i, image in enumerate(images):
        if image.content_type and not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail=f"Archivo {i} no es imagen"
            )
        content = await image.read()
        frame_bytes_list.append(content)

    # 2. Get all product hashes from DB
    products_with_hash = (
        db.query(Product.sku, Product.image_hash)
        .filter(Product.image_hash.isnot(None), Product.image_hash != "")
        .all()
    )

    if not products_with_hash:
        return RecognitionResponse(
            message="No hay productos con imagen registrada para comparar.",
            candidates=[],
        )

    product_hashes = [(p.sku, p.image_hash) for p in products_with_hash]

    # 3. Run pHash recognition
    results = recognition_service.recognize_from_frames(
        frame_bytes_list, product_hashes
    )

    if not results:
        return RecognitionResponse(
            message="No se pudo procesar las imágenes capturadas.",
            candidates=[],
        )

    # 4. Build candidates list
    candidates = []
    for sku, score in results:
        product = get_product_by_sku(db, sku)
        if product:
            candidates.append(RecognitionCandidate(sku=sku, score=round(score, 4)))

    if not candidates:
        return RecognitionResponse(
            message="No se encontraron coincidencias.",
            candidates=[],
        )

    # 5. If top candidate is a strong match, return full details
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
            f"Match: {best_sku} ({best_score:.0%})"
            if best_score >= DIRECT_MATCH_THRESHOLD
            else f"Se encontraron {len(candidates)} candidato(s)"
        ),
        confidence_avg=best_score,
    )


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
