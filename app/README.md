# Motovlogs

Con Python 3.11 o superior instalado, abre PowerShell en el repositorio y ejecuta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\app\instalar.ps1
```

Abre **Motovlogs** en el escritorio: aparece una ventana propia, sin navegador ni consola. Repetir la instalación conserva la configuración. Al cerrar la ventana termina su servidor interno; si hay trabajos en marcha, la app espera a que terminen o canceles la copia. Un segundo clic en el acceso directo trae la ventana existente al frente. Windows necesita Microsoft Edge WebView2 Runtime (incluido en la mayoría de los PC actuales).

1. **Cámaras**: busca tarjetas con DCIM y cámaras USB, copia lo nuevo y consulta archivo, velocidad y tiempo restante en Trabajos. Cancelar conserva los originales y quita el archivo parcial local. En MTP, la transferencia del dispositivo puede terminar en la carpeta temporal; no desconectes hasta que se detenga.
2. **Grabaciones**: actualiza las fechas, pulsa Analizar y toca una celda de la hoja para añadir ese segundo al editor. Se reutilizan las hojas ya generadas por la app. La ficha muestra tamaño, duración, resolución, fps y HDR.
3. **Crear video**: elige grabación, estilo y salida de la plantilla; edita las tomas. Los campos adicionales de la plantilla se conservan. Tres textos vacíos conservan los subtítulos originales. Renderizar llama al motor existente, en una carpeta nueva por trabajo.
4. **Revisar**: mira el video y la hoja completa; comprueba el log y marca las revisiones visuales. Los controles automáticos muestran formato, fps, tamaño y bitrate orientativo.
5. **Publicar**: copia descripción con máximo cinco hashtags, descarga el MP4 y añade música en TikTok. Enviar a borradores exige confirmar el archivo; no publica en el perfil. Martin configura y conecta previamente su cuenta con los scripts existentes, fuera de la app. Nunca pegues llaves en la página. Las respuestas de TikTok se ocultan para protegerlas.
6. **Analíticas**: registra las métricas a las 24 horas; con menos de 100 vistas el resultado queda pendiente. Verde requiere 8 segundos de promedio y 5 % completo.

Las rutas se cambian en `app/config.json`: destino, ffmpeg, red360, usuario y cola externa. Configuración, datos, logs, entorno y credenciales están excluidos de git. El asistente existente puede seguir consumiendo su carpeta `cola`; no arranques simultáneamente renders externos y de la app si quieres evitar competencia por recursos.

Pruebas: `app\.venv\Scripts\python.exe -m pytest app/tests -q`. No necesitan cámaras, discos G:/Z: ni credenciales. La validación real de MTP y del render del viaje requiere los dispositivos/material correspondientes; ninguna prueba publica en TikTok.
