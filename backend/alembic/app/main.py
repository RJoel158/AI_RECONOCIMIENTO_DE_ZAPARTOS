from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import subprocess
import logging

from backend.alembic.app.api.routes.health import router as health_router
from backend.alembic.app.api.routes.products import router as products_router
from backend.alembic.app.api.routes.recognition import router as recognition_router
from backend.alembic.app.api.routes.stock import router as stock_router
from backend.alembic.app.api.routes.captures import router as captures_router
from backend.alembic.app.core.config import settings

logger = logging.getLogger(__name__)

# Run migrations automatically on startup
try:
    backend_dir = str(Path(__file__).resolve().parent.parent.parent)  # backend/
    print(f"[STARTUP] Running alembic upgrade head from {backend_dir}")
    result = subprocess.run(
        ["alembic", "upgrade", "head"],
        cwd=backend_dir,
        capture_output=True,
        text=True,
        timeout=30,
    )
    print(f"[STARTUP] Migration stdout: {result.stdout}")
    if result.returncode != 0:
        print(f"[STARTUP] Migration stderr: {result.stderr}")
except Exception as e:
    print(f"[STARTUP] Migration error: {e}")

app = FastAPI(title=settings.api_title, version=settings.api_version)

# CORS — allow all origins so Flutter app can connect from any host
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Images are now served from the database (GET /products/{sku}/image)
# The /media mount is kept for backwards compatibility but is optional
try:
    product_images_dir = Path(settings.product_images_dir)
    product_images_dir.mkdir(parents=True, exist_ok=True)
    from fastapi.staticfiles import StaticFiles
    app.mount("/media", StaticFiles(directory=product_images_dir), name="media")
except Exception:
    pass  # Not critical — images are served from DB now

app.include_router(health_router)
app.include_router(products_router)
app.include_router(recognition_router)
app.include_router(stock_router)
app.include_router(captures_router)
