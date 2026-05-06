FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY backend/requirements.txt /app/backend/requirements.txt
COPY ml/requirements.txt /app/ml/requirements.txt

RUN pip install --no-cache-dir -r /app/backend/requirements.txt -r /app/ml/requirements.txt

COPY backend /app/backend
COPY ml /app/ml
COPY data /app/data

ENV PYTHONPATH=/app

CMD ["uvicorn", "backend.alembic.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
