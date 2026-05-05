from fastapi import APIRouter, File, HTTPException, UploadFile, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from pathlib import Path
import shutil

from backend.alembic.app.schemas.recognition import RecognitionResponse, ShoeDetailsResponse
from backend.alembic.app.core.database import get_db
from backend.alembic.app.crud.products import get_product_by_sku, get_similar_products
from backend.alembic.app.crud.stock import get_stock_by_sku
from backend.alembic.app.services.recognition import recognition_service

router = APIRouter(prefix="/recognize", tags=["recognition"])


@router.post("", response_model=RecognitionResponse)
async def recognize_shoe(image: UploadFile = File(...), db: Session = Depends(get_db)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Archivo no es imagen")

    # 1. Temporarily save the image to process it
    temp_path = Path("data/temp_rec.jpg")
    temp_path.parent.mkdir(parents=True, exist_ok=True)
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    # 2. Use AI service to recognize SKU
    sku, score = recognition_service.recognize(str(temp_path))
    
    if not sku:
        return RecognitionResponse(
            message=f"Error: {score}", # Here 'score' contains the error message
            candidates=[]
        )

    # 3. Business logic: fetch product, stock and similar models
    product = get_product_by_sku(db, sku)
    if not product:
        return RecognitionResponse(
            message=f"AI recognized SKU {sku}, but it's not in the database.",
            candidates=[]
        )

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
            is_out_of_stock=is_out_of_stock
        ),
        message=f"Reconocimiento exitoso (Confianza: {score:.2%})"
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
            is_out_of_stock=is_out_of_stock
        ),
        message="Producto recuperado por SKU"
    )
