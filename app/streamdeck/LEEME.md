# Botones del Stream Deck para Motovlogs

Cada `.bat` es un botón. En la app Stream Deck: arrastra **Sistema → Abrir** a una tecla y elige el `.bat`.

| Botón | Qué hace |
|---|---|
| `Motovlogs_Abrir.bat` | abre la app (o la trae al frente) |
| `Motovlogs_Copiar.bat` | copia lo nuevo de tarjetas/cámaras (sustituye al antiguo "Grabar") |
| `Motovlogs_Cancelar.bat` | cancela la copia en marcha (sustituye al antiguo "Cancelar") |
| `Motovlogs_Analizar.bat` | analiza la grabación más reciente |
| `Motovlogs_Estado.bat` | muestra en una ventanita qué está haciendo la app y el % |

Si la app está cerrada, cualquier botón la abre primero. Ruta de la app por defecto:
`%USERPROFILE%\Documents\motovlogs\app` (cámbiala con `-App` en `motovlogs_sd.ps1`).
Crear video y Publicar siguen en la ventana de la app porque necesitan elegir tomas y confirmar.
