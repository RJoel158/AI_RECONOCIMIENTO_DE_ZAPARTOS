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
