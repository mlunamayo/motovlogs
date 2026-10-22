# 03 · Analizar el material y elegir momentos

**Objetivo:** saber qué hay en horas de grabación sin verlas enteras, y anotar los segundos
exactos de los buenos momentos.

## Paso 1: ficha técnica (`scripts/analisis/01_instalar_y_revisar.ps1`)

ffprobe a cada video → `_analisis\probe\<archivo>.json` y una foto a los 20 s.
Revisa resolución, fps, HDR y orientación (ver `conocimiento/aprendizajes.md`).

## Paso 2: hojas de contacto y audio (`scripts/analisis/02_miniaturas_y_audio.ps1`)

- Una miniatura cada 10 s, en mosaicos de 6x5 → `_analisis\hojas\<archivo>_NN.jpg`.
  Hoja NN, celda k (0-29) ≈ segundo `((NN-1)*30 + k) * 10`.
- Audio comprimido (16 kHz, opus) → `_analisis\audio\` por si hay que transcribir.
- Ajusta los filtros de nombre (`DJI_202610*`, `VID_...`) a la fecha de la grabación.

## Paso 3: elegir momentos

Mira las hojas y apunta, por archivo, segundo de inicio + qué pasa:

| Qué buscar | Por qué |
|---|---|
| El grupo entrando a una curva, moto inclinada | mejor primer cuadro (gancho) |
| Curvas cerradas (horquillas, pared de roca) | cámara lenta en el vértice |
| Paisaje abierto: lago, valle, árboles de otoño | cierre o respiro |
| Tú en cámara (360 hacia atrás) | variedad, cara humana |
| Semáforos, gasolineras, ciudad | casi nunca sirve para abrir |

Afina con una hoja más densa del tramo (`fps=1`, 30 s) antes de fijar el segundo exacto.

## Paso 4: 360 en la red (Mac)

Para `.insv` en `Z:\` usa hojas con `v360` (POV y vista trasera). El mejor camino es exportar
antes con Insta360 Studio (`runbooks/04`) y usar `scripts/analisis/hojas_360_studio.ps1`
sobre las exportaciones (`fps=1/3`, 10x3, vistas yaw 0 y 180).

## Registro

Anota los momentos elegidos en el plan JSON (`runbooks/05`). Ese plan es el registro.
