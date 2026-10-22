# 08 · Entrega al teléfono y subida a TikTok

## Al teléfono (lo normal)

- Manda el `.mp4` tal cual (descarga directa desde el chat del agente, AirDrop, Google Drive o
  cable). **No por WhatsApp**: comprime.
- En TikTok: **+** → elegir video → **sonido desde TikTok** (en tendencia, con un golpe al inicio
  para el primer corte) → pegar la descripción (`runbooks/09`) → activar la subida en **alta
  calidad** → publicar o guardar en borradores.

## A borradores desde el PC (API de TikTok)

Scripts: `scripts/tiktok/subir_tiktok.ps1` (interactivo) y `subir_lista2.ps1` (lista fija).

- Usa la Content Posting API en modo **inbox**: el video llega como notificación de "borrador
  listo" en la app y Martin lo publica desde ahí.
- App de TikTok Developers en **Sandbox** con los permisos `user.info.basic` y `video.upload`.
  Redirect URI: `https://www.youtube.com/@Marto_1709`. El `code` se copia de la barra o del
  historial del navegador.
- Las llaves van en `video\tiktok\config.txt` (`client_key`, `client_secret`, `redirect_uri`) y
  el token en `token.json`. **Los llena Martin. Un agente nunca los lee ni los pide.**
- Límite: unos **5 pendientes por día** (`spam_risk_too_many_pending_share`). Si sale ese error,
  reintenta al día siguiente. Un 503 en la subida de partes se reintenta solo (4 intentos).
- `subidos.txt` registra lo ya enviado para no repetir.
- **Solo se ejecuta cuando Martin lo pide.**
