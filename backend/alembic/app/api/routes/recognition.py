from fastapi import APIRouter, File, HTTPException, UploadFile, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.alembic.app.schemas.recognition import RecognitionResponse, ShoeDetailsResponse
from backend.alembic.app.core.database import get_db
from backend.alembic.app.crud.products import get_product_by_sku, get_similar_products
from backend.alembic.app.crud.stock import get_stock_by_sku

router = APIRouter(prefix="/recognize", tags=["recognition"])


@router.post("", response_model=RecognitionResponse)
async def recognize_shoe(image: UploadFile = File(...), db: Session = Depends(get_db)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Archivo no es imagen")

    # --- INTEGRACIÓN ML (Placeholder) ---
    # Aquí se llamará al modelo de IA para obtener el SKU
    detected_sku = "DEMO-SKU-123" # Simulación de reconocimiento
    # -----------------------------------

    product = get_product_by_sku(db, detected_sku)
    if not product:
        return RecognitionResponse(message=f"No se encontró el producto con SKU {detected_sku}", candidates=[])

    stock_items = get_stock_by_sku(db, detected_sku)
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
        message="Reconocimiento exitoso"
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
