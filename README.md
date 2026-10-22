# motovlog-ops

Runbooks y scripts para convertir las grabaciones de moto en TikToks: leer las tarjetas,
separar por cámara, analizar, recortar, renderizar con el look de la serie, revisar la
calidad, subir a borradores de TikTok y medir cómo les va.

Está escrito para que **cualquier agente** (Claude, ChatGPT/Codex, Gemini) o una persona
pueda seguirlo sin haber visto las conversaciones anteriores. Empieza por `AGENTS.md`.

## Mapa

```
AGENTS.md                 reglas y router para agentes (CLAUDE.md y GEMINI.md lo importan)
runbooks/                 un runbook por tarea, en el orden del flujo
  00-instalar-en-un-pc.md       montar todo en un Windows nuevo
  01-asistente-y-cola.md        cómo un agente ejecuta cosas en el PC (cola de .ps1)
  02-ingesta-de-tarjetas.md     copiar tarjetas/cámaras a G:\Motovlog\<fecha>\<cámara>
  03-analisis-del-material.md   probe, hojas de contacto, audio, elegir momentos
  04-exportar-360-con-insta360-studio.md
  05-plan-y-render.md           el plan JSON y el motor de render
  06-estilos-de-video.md        serie cine, cortos con gancho, curvas, rampa
  07-control-de-calidad.md      revisar antes de entregar
  08-entrega-y-subida-tiktok.md al teléfono y a borradores de TikTok
  09-descripciones-y-hashtags.md
  10-analiticas-y-decisiones.md
scripts/                  lo que corre en el PC (PowerShell + ffmpeg)
plantillas/               planes JSON, subtítulos .ass y la página de descripciones
conocimiento/             lo aprendido (qué funcionó, qué no, por qué)
```

## Flujo en una línea

Tarjetas → `nueva_grabacion.ps1` → análisis (hojas de contacto) → plan JSON → `motor.ps1`
→ revisión (hoja de control) → teléfono / borradores TikTok → analíticas a las 24 h.
