# App "Motovlogs": especificación v1

## Objetivo

Una sola app local, con una sola ventana y un solo acceso directo, que haga lo que hoy
hacen varios botones y scripts sueltos: detectar las cámaras, copiar, analizar, crear el video,
revisarlo, preparar la publicación y registrar las analíticas. Debe instalarse en cualquier PC
con un solo comando y no depender de ningún agente de IA para funcionar.

Lee antes `AGENTS.md`, `conocimiento/aprendizajes.md` y `runbooks/02` a `runbooks/10`. La app
**envuelve** lo que describen esos runbooks; no inventa otro flujo.

## Stack (decidido, no cambiar sin preguntar)

- **Python 3.11+** con **Flask** y una página HTML/JS sin paso de compilación (sin React, sin Node).
- Por corrección explícita de Martin, se abre como **app de escritorio**, en una ventana propia con pywebview y WebView2 en Windows, sin barra ni pestañas del navegador. Flask queda como servidor interno en `http://127.0.0.1:8765`, solo en localhost; termina al cerrar la ventana.
- Usa los scripts existentes donde ya funcionan (PowerShell + ffmpeg en `scripts/`). Lo nuevo,
  en Python. Rutas con `pathlib`, para que más adelante corra en Mac.
- Configuración en `app/config.json` (se crea desde `app/config.ejemplo.json` al instalar):
  destino de grabaciones (`G:\Motovlog`), ruta de ffmpeg, carpeta 360 de red (`Z:\`) y
  usuario de TikTok. **Nada de secretos en el repo.** Las llaves de TikTok siguen en
  `config.txt` / `token.json` fuera de git; la app no las muestra nunca.

## Instalación

- `app/instalar.ps1`: comprueba Python (si falta, indica cómo instalarlo), crea `.venv`,
  instala `requirements.txt`, descarga ffmpeg si no existe (misma fuente que
  `scripts/analisis/01_instalar_y_revisar.ps1`), crea `config.json` y deja en el escritorio el
  acceso directo **"Motovlogs"**, que abre la ventana de escritorio y su servidor interno.
- Correr `instalar.ps1` dos veces no rompe nada (idempotente).

## Pantalla única: 6 pestañas

1. **Cámaras**
   - Botón **"Buscar cámaras"**: lista tarjetas SD (unidades extraíbles con `DCIM`) y cámaras por
     USB/MTP (Canon/EOS, DJI/Osmo, Insta360), con la cámara detectada, el número de archivos
     nuevos y los GB. Misma lógica de clasificación que `scripts/ingesta/nueva_grabacion.ps1`.
   - Botón **"Copiar todo"** con barra de progreso (archivo actual, MB/s, tiempo restante) y botón
     **"Cancelar"** (misma limpieza que `cancelar_grabacion.ps1`). Destino:
     `<destino>\<AAAA-MM-DD>\<Cámara>`, saltando lo ya copiado.
2. **Grabaciones**
   - Lista de carpetas por fecha con cuántos clips hay por cámara y su ficha (resolución, fps,
     HDR, duración) desde ffprobe.
   - Botón **"Analizar"**: genera las hojas de contacto (`runbooks/03`) y las muestra en la página.
     Al hacer clic en una miniatura se ve el archivo y el segundo exacto, y un botón
     "+ añadir toma" la pasa al editor de la pestaña 3.
3. **Crear video**
   - Elegir estilo: Corto con gancho (por defecto), Serie cine, Curvas con velocidad, Rampa, 360.
     Cada uno carga su plan de `plantillas/planes/`.
   - Tabla de tomas editable: archivo, inicio, duración, velocidad, de cabeza (`rot180`),
     encuadre (`layout`, `cx`, `yaw`/`pitch`). Más los campos de texto: gancho, título y firma.
   - Botón **"Renderizar"**: guarda el plan JSON + `.ass`, llama a `scripts/render/motor.ps1` y
     muestra el progreso y el log en vivo. Al terminar muestra el video y la hoja de control.
4. **Revisar**: el checklist de `runbooks/07` con lo que se puede medir automáticamente ya marcado
   (resolución, códec, fps, peso, que el log diga LISTO) y lo visual para que lo marque el usuario.
5. **Publicar**
   - Descripción y hashtags con **límite duro de 5 hashtags** (el botón se bloquea si hay más) y
     botón "Copiar". Sugerencia del tipo de sonido.
   - Botón **"Enviar a borradores de TikTok"** con un diálogo de confirmación. Usa la lógica de
     `scripts/tiktok/subir_tiktok.ps1`. Si falta `config.txt`, explica qué llenar sin mostrar ni
     pedir los valores. Avisa del límite de unos 5 por día.
6. **Analíticas**: formulario (video, horas desde que se publicó, vistas, tiempo promedio, % que
   lo vio completo). Guarda en `app/datos/analiticas.csv` (fuera de git) y muestra la tabla con
   el umbral de `runbooks/10` (≥ 8 s y ≥ 5% a las 24 h) en verde o rojo.

## Trabajos en segundo plano

- Una cola interna: **un trabajo pesado a la vez** (copiar, analizar, renderizar). Los demás
  esperan en fila. Cada trabajo tiene log en `app/datos/logs/` y estado visible en la página
  (cola, corriendo, terminado o error).
- Compatibilidad: la carpeta `cola\` del asistente (`runbooks/01`) sigue funcionando, para que
  un agente de IA pueda seguir dejando scripts.

## Reglas que la app no puede romper

- No borra ni modifica archivos originales de las cámaras ni de `Z:\`.
- No sobrescribe un video terminado: si el nombre existe, añade `_v2`, `_v3`, etc.
- No publica nada sin confirmación explícita en el diálogo.
- No escribe secretos en logs ni en pantalla.

## Pruebas (pytest, en `app/tests/`)

- Clasificación de cámaras a partir de nombres de carpeta y archivo (los casos de `runbooks/02`).
- Validación del plan: campos obligatorios, `dur > 0`, `speed > 0` y archivo existente.
- Límite de 5 hashtags.
- Nombre de salida sin sobrescribir (`_v2`).
- Cálculo de umbral de analíticas.
- Un test de humo que arranca el servidor y pide `/` → 200.

## Hecho cuando

1. `instalar.ps1` en limpio deja el acceso directo y la app abre.
2. "Buscar cámaras" sin cámaras conectadas dice "no hay cámaras" sin error.
3. Con el plan `plantillas/planes/cortos_gancho.json` (ajustado a `-Src G:\Motovlog\2026-10-21`),
   "Renderizar" produce el mismo video que hoy hace `motor.ps1`.
4. `pytest` pasa.
5. `app/README.md` explica en español sencillo cómo instalar y usar, en una pantalla.
