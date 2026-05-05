# MVP Scope

## Objetivo

Reconocimiento de zapatos para identificar tipo, color y SKU, y recomendar modelos similares.

## Propuesta de alcance inicial

- 50 SKUs (ajustable)
- 4 tipos: formal, casual, deportivo, street
- Colores: blanco, negro, gris, rojo, verde
- Marcas: las que se definan en el catalogo inicial

## Metricas objetivo

- Clasificacion de tipo: >= 85% top-1
- Clasificacion de color: >= 90% top-1
- SKU: >= 70% top-1, >= 90% top-5

## Restricciones

- Offline parcial: tipo/color sin internet; SKU y similares via API
- Dataset inicial con 15-30 fotos por SKU
