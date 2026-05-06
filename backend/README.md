# Backend (FastAPI + PostgreSQL)

## Estructura

- app/main.py: punto de entrada
- app/core: configuracion y base de datos
- app/models: modelos SQLAlchemy
- app/schemas: esquemas Pydantic
- app/crud: operaciones de base de datos
- app/api/routes: endpoints

## Ejecutar (local)

1. Copiar .env.example a .env y ajustar DATABASE_URL
2. Instalar dependencias:
   - pip install -r requirements.txt
3. Ejecutar:
   - uvicorn app.main:app --reload

## Cargar catalogo inicial (CSV)

1. Editar data/products.csv y data/stock.csv
2. Ejecutar:
   - python tools/import_catalog.py

## Notas

- El endpoint /health sirve para validar estado
- CRUD basico de productos y stock

## Captura de imagenes (dataset)

- POST /captures (multipart) con campos: sku, source, note, image
- GET /captures?sku=BAT-CA-0001

## Reconocimiento (placeholder)

- POST /recognize (multipart) con campo: image

## Ejecutar con Docker (recomendado para hosting)

Desde la raiz del repo:

1. Construir imagen:
   - docker build -t zapatos-api -f backend/Dockerfile .
2. Ejecutar:
   - docker run -p 8000:8000 --env-file backend/.env zapatos-api
