# Proyecto: Sistema de Reconocimiento de Zapatos (Bata Manaco Cochabamba)

## Objetivo
Crear un modelo de IA (DL/ML) para reconocer modelos de zapatos mediante cámara y fotos, integrado en una app móvil Flutter. El sistema debe clasificar por tipo, color y reconocer el SKU exacto para consultar stock y sugerir modelos similares.

## MVP y Requerimientos
- **Funcionalidades:** Clasificación de modelos (Formal, Casual, Deportivo, Street), detección de color, reconocimiento de SKU ultra-preciso y sistema de recomendación de similares.
- **App:** Flutter (Multiplataforma Android/iOS), modo offline parcial.
- **Infraestructura:** Enfoque híbrido (Inferencia ligera on-device + modelo robusto en servidor para embeddings y SKU).
- **Datos:** Dataset inicial basado en fotos del usuario (3 vistas por modelo: 2 laterales, 1 frontal/girada). Requiere Data Augmentation para mejorar robustez.
- **Base de Datos:** Crear desde cero el catálogo de productos, tallas y stock.

## Plan de Implementación
1. **Taxonomía:** Definir tipos, colores, marcas y reglas de SKU.
2. **Dataset:** Guías de captura y recolección de imágenes.
3. **Infraestructura de Datos:** Pipeline de etiquetado y almacenamiento.
4. **Entrenamiento Baseline:** Modelos de clasificación de atributos y SKU.
5. **Búsqueda Visual:** Implementar Metric Learning / Vector Search para similitudes.
6. **Arquitectura Híbrida:** Configurar despliegue on-device y servidor.
7. **Backend:** API de catálogo y gestión de stock.
8. **Integración Flutter:** Implementar cámara, flujo de API y UI de resultados.
9. **MLOps:** Monitoreo y re-entrenamiento periódico.

## Verificación
- Precisión top-1/top-5 por SKU y categoría.
- Latencia de inferencia y respuesta de API.
- Flujo E2E: Foto -> SKU -> Stock -> Similares.
