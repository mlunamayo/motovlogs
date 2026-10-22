# 00 · Instalar en un PC nuevo (Windows)

**Para qué:** dejar un Windows listo para que cualquier agente pueda editar los TikToks.
**Tiempo:** 15 minutos.

## Pasos

1. Clona este repo en `C:\Users\<usuario>\Documents\motovlog-ops`.
2. Crea la carpeta de trabajo del asistente: `C:\Users\<usuario>\Documents\StreamDeck\video\`
   con `cola\`, `hechos\` y `logs\` (el asistente las crea solo si no existen).
3. Copia `scripts\pc\asistente_videos.ps1` y `scripts\render\motor.ps1` a esa carpeta `video\`.
4. Instala ffmpeg: ejecuta `scripts\analisis\01_instalar_y_revisar.ps1` una vez. Descarga el
   build de BtbN en `StreamDeck\tools\ffmpeg\` si no está, y de paso revisa el material.
5. Crea en el escritorio `Asistente_videos.bat` con:
   ```bat
   powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\StreamDeck\video\asistente_videos.ps1"
   ```
6. Ingesta: copia `scripts\ingesta\*` a `Documents\StreamDeck\` y asigna `nueva_grabacion.bat`
   y `cancelar_grabacion.bat` a dos botones del Stream Deck (o accesos directos).
7. Opcional: instala **Insta360 Studio** (para el 360) y crea el disco/carpeta `G:\Motovlog\`.
8. TikTok (solo si se va a subir desde el PC): `runbooks/08`. Las llaves las pone el dueño
   de la cuenta en `video\tiktok\config.txt`, y nunca van a git.

## Comprobación

- `ffmpeg -hide_banner -filters | findstr "zscale v360 tonemap"` muestra los tres filtros.
- Con el asistente abierto, deja en `cola\` un `prueba.ps1` con `Get-Date`. A los pocos segundos
  pasa a `hechos\` y aparece `logs\prueba.log`.
