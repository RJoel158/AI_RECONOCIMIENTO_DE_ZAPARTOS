from fastapi import FastAPI

from app.api.routes.health import router as health_router
from app.api.routes.products import router as products_router
from app.api.routes.stock import router as stock_router
from app.core.config import settings

app = FastAPI(title=settings.api_title, version=settings.api_version)

app.include_router(health_router)
app.include_router(products_router)
app.include_router(stock_router)
