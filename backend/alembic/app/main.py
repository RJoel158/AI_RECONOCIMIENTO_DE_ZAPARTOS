from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from backend.alembic.app.api.routes.health import router as health_router
from backend.alembic.app.api.routes.products import router as products_router
from backend.alembic.app.api.routes.recognition import router as recognition_router
from backend.alembic.app.api.routes.stock import router as stock_router
from backend.alembic.app.api.routes.captures import router as captures_router
from backend.alembic.app.core.config import settings

app = FastAPI(title=settings.api_title, version=settings.api_version)

product_images_dir = Path(settings.product_images_dir)
product_images_dir.mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=product_images_dir), name="media")

app.include_router(health_router)
app.include_router(products_router)
app.include_router(recognition_router)
app.include_router(stock_router)
app.include_router(captures_router)
