# AI Reconocimiento de Zapatos

Objetivo: construir un sistema de reconocimiento de zapatos (tipo, color y SKU) con busqueda de similares y stock por tallas. El MVP prioriza un flujo hibrido: inferencia ligera en dispositivo para prefiltrado y un modelo en servidor para identificacion de SKU y recomendaciones.

## Alcance MVP (propuesta)

- 50 SKUs iniciales (se puede ajustar)
- Tipos: formal, casual, deportivo, street
- Colores: blanco, negro, gris, rojo, verde (primario y secundario)
- Resultados: top-1 y top-5 con sugerencias similares
- Offline parcial: tipo/color sin internet; SKU y similares via API

## Estructura del repo

- docs/ Documentacion del MVP, dataset y etiquetas
- data/ Dataset y metadatos (no subir imagenes al repo)
- ml/ Entrenamiento, evaluacion y exportacion de modelos
- backend/ API y base de datos de catalogo/stock
- app/ App Flutter (camara y UI de resultados)

## Proximos pasos

1. Validar alcance del MVP y numero de SKUs.
2. Preparar dataset con guias de captura.
3. Implementar baseline ML y API base.
