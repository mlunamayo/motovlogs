# 05 · Plan JSON y motor de render

**Motor:** `scripts/render/motor.ps1 -Plan <plan.json> [-Src G:\Motovlog\<fecha>] [-Salida TikTok_cine]`
Saca videos verticales 1080x1920 a 30 fps en `<Src>\<Salida>\<name>.mp4` y una hoja de control
`<Src>\_analisis\render_<Salida>\<name>_check.jpg` (una foto cada 2 s).

## Estructura del plan

```json
{
  "only": ["corto_dahlonega"],
  "outputs": [
    { "name": "corto_dahlonega", "ass": "k1.ass",
      "segments": [
        { "file": "DJI\\DJI_20261018120241_0006_D.MP4", "start": 604, "dur": 3.2,
          "layout": "full", "hdr": true, "grade": "cine", "vol": 0.0 }
      ] }
  ]
}
```

`only` es opcional: si está, renderiza solo esos nombres. `ass` son los subtítulos (ruta relativa
a la carpeta del plan).

## Campos de cada segmento

| Campo | Qué hace |
|---|---|
| `file` | relativo a `-Src`, o ruta absoluta (`Z:\...`, `G:\...`) |
| `start`, `dur` | segundo de inicio y duración **en el original** |
| `speed` | 0.5 = cámara lenta, 1.8 = acelerado (dura `dur/speed`) |
| `vol` | volumen del audio original (0 = silencio; la música se pone en TikTok) |
| `hdr` | `true` para la Osmo (HLG 10-bit → SDR) |
| `rot180` | clip grabado de cabeza |
| `cx` | dónde recortar en horizontal (0 izq, 0.5 centro, 1 der) |
| `layout` | `full` recorte 9:16 · `band` 4:5 con fondo desenfocado · `pano` .insv crudo · `equi` export de Studio · `lens` una lente del .insv |
| `yaw`, `pitch`, `roll`, `hfov`, `vfov` | ángulo de cámara en `pano`/`equi`/`lens` |
| `grade` | `"cine"`: color de la serie (contraste, verde-azulado/naranja, viñeta) |
| `fadein`, `fadeout` | fundido de/a negro en ese segmento |

## Subtítulos (.ass)

Ejemplos junto a los planes en `plantillas/planes/` (k1/k2 = gancho, c0Nb = título). Estilos: `Titulo` (letra fina, abajo), `Firma`
(`@marto_1709`), `Hook` (frase de gancho arriba). Formato de tiempo `0:00:00.00`. `\N` = salto
de línea. `scripts/render/mkass.py` ayuda a generarlos. Las fuentes (Segoe UI / Light, Arial
Black) se copian solas a `fonts\`.

## Calidad (ya en el motor)

Partes a crf 11 (preset medium) y final a crf 15 (preset slow), con perfil high, yuv420p y
`+faststart`. Sin grano y con enfoque suave tras escalar (`unsharp`). No vuelvas a crf 18 ni a
`veryfast`: era una doble compresión visible.

## Rampa de velocidad suave

En vez de saltar de 1.8x a 0.5x, parte el tramo en trozos cortos con velocidades graduales
(`1.8 → 1.5 → 1.2 → 0.9 → 0.7 → 0.5 … → 1.8`). Ejemplo: `plantillas/planes/rampa_velocidad.json`.
