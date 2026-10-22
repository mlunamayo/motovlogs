# 07 · Control de calidad antes de entregar

Nada se entrega sin pasar esto.

1. **Log del render:** cada salida dice `LISTO: <name>.mp4 (X MB)`. Si dice `ERROR`, no se entrega.
2. **Hoja de control** `_analisis\render_<Salida>\<name>_check.jpg`: mírala entera.
   - ¿Primer cuadro fuerte? ¿Se ve el gancho y está bien escrito?
   - ¿Hay clips de cabeza (falta `rot180`)? ¿Tomas de otro viaje? ¿Final en estacionamiento?
   - ¿Hay demasiado tablero o cielo en el 360? (ajusta `pitch`)
3. **Ficha técnica** (`scripts/analisis/probar_calidad.ps1`): 1080x1920, h264, yuv420p, 30 fps,
   bitrate de unos 20-50 Mbps.
4. **Tamaño:** un video de 15 s pesa unos 90 MB; uno de 38 s, entre 120 y 250 MB. Si pesa muy
   poco, algo se comprimió de más.
5. Al entregar, di en una línea qué viste en la hoja de control y qué limitaciones quedan
   (p. ej. "la Osmo grabó en 1080p y el recorte vertical se ve algo suave").
