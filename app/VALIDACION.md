# Validación local · 22 de octubre de 2026

- Python 3.14.6, Flask 3.1.3; 30 pruebas pytest aprobadas.
- Instalador ejecutado dos veces: conserva configuración y crea Motovlogs.lnk.
- Servidor real en 127.0.0.1:8765: GET / devuelve 200.
- Corrección de escritorio: pywebview 6.2.1 con WebView2 abrió una ventana propia; comprobación dentro de la ventana: título Motovlogs, 6 pestañas y HTTP 200. Cerrar la ventana de prueba terminó su servidor interno.
- Plantilla cortos_gancho, primera salida corto_dahlonega, origen G:/Motovlog/2026-10-21, ejecutada mediante la cola de la app.
- Resultado: 1080×1920, H.264, yuv420p, SDR, 30 fps, 15,43 s, 93,2 MB; log LISTO y sin ERROR.
- Hoja completa revisada: grupo en curva y gancho al inicio, tomas derechas, cierre de lago. Suavidad del recorte de Osmo 1080p como limitación conocida. Las celdas negras posteriores son espacios sin usar de la hoja 8×3 del motor.
- Sin lectura de archivos de claves por el agente ni ejecución del adaptador de TikTok. Sin modificación de originales.
- Pendiente de comprobación con dispositivos físicos: copia SD/MTP y cancelación MTP. Descarga de ffmpeg en PC limpio no ejercitada porque ya estaba instalado. El envío a TikTok no se prueba por instrucción del usuario.
