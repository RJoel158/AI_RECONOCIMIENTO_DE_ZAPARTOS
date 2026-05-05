from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.crud.stock import create_stock, get_stock_by_sku
from app.schemas.stock import StockCreate, StockRead

router = APIRouter(prefix="/stock", tags=["stock"])


@router.post("", response_model=StockRead)
def create_stock_endpoint(payload: StockCreate, db: Session = Depends(get_db)):
    try:
        return create_stock(db, payload)
    except ValueError:
        raise HTTPException(status_code=404, detail="Producto no encontrado")


@router.get("/{sku}", response_model=list[StockRead])
def get_stock_endpoint(sku: str, db: Session = Depends(get_db)):
    return get_stock_by_sku(db, sku)
