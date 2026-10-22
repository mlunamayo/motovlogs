# Aprendizajes (léelo antes de trabajar)

## Cámaras y material

| Cámara | Montaje | Formato real | Ojo con |
|---|---|---|---|
| DJI Osmo Action | **casco** | 1920x1080, HEVC 10-bit **HLG**, 59.94 fps | 1080p limita el recorte vertical (607 px → 1080, ampliado 1.78x). Necesita `hdr: true`. Los clips `_0003_` y `_0005_` del 18-10-2026 están **de cabeza** (`rot180`). |
| Insta360 (360) | **manubrio** | `.insv` dual-fisheye; Studio exporta 3840x1920 a 50 fps | En crudo (`pano`): hacia delante `yaw 0, roll 90`; hacia ti `yaw 180, roll -90`. Mejor exportar con Studio (`runbooks/04`). |
| Canon | — | MTP por USB | Se copia por la ingesta; aún no se usa en TikToks. |

**Para las próximas grabaciones:** Osmo en **4K** (o en vertical 9:16 si el modelo lo permite).
Es la mejora de calidad más grande que queda.

## Viajes (no mezclar)

- **18-10-2026**: Dahlonega / Two Wheels of Suches (Georgia). Osmo en `G:\Motovlog\2026-10-21\DJI`
  (la carpeta lleva la fecha de la copia). Momentos: horquilla D3 1567 (rot180), pared de roca
  D3 1694 (rot180), grupo en curva D2 1146-1158 y D6 604, lago D2 1341-1350, salida en el
  semáforo D2 20/80.
- **18/19-10-2025**: Gatlinburg / Smoky Mountains (Tennessee), 360 en `Z:\`. El día 2 llovió.

## Edición

- Color `cine` aprobado por Martin; el ritmo de 6-7 s por toma también le gustó.
- Cámara lenta: `setpts` va **antes** de `fps` o se ve a saltos.
- Doble compresión (crf 16 veryfast + crf 18) se notaba; corregido a crf 11 → crf 15 slow.
- El grano sobre una imagen ampliada se vuelve manchas al recomprimir en TikTok, así que se quitó.
- Subtítulos con `fontsdir` en ruta con `:` fallan; se copian las fuentes a `fonts\` y se usa
  ruta relativa.
- No reutilizar nombres de variables PowerShell reservadas (`$in`, `$input`).
- Para no pisar versiones buenas, cada engine nuevo es un archivo nuevo (`motor_vN`) y las salidas
  llevan sufijo (`_v2`, `_hq`).

## TikTok

- Retención: los videos largos y lentos pierden a la gente en 5 s. Lo que hay que probar es un
  **corto con gancho** (`runbooks/06` A). Ver tabla en `runbooks/10`.
- Límite de unos 5 borradores pendientes por día en la API.
- La redirección de OAuth pierde el `code` en algunos sitios (Composio, YouTube); se saca del
  historial del navegador.
- Whisper (transcripción local) no se pudo descargar; quedó descartado por ahora.
- Insta360 Studio no tiene CLI; se maneja por GUI. CapCut sirve para rampas manuales, pero el motor ya
  hace rampas suaves; la música se pone en TikTok, no en CapCut.
