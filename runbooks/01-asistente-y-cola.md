# 01 · Asistente y cola: cómo un agente ejecuta cosas en el PC

**Idea:** el agente no teclea en la terminal de Martin. Escribe un `.ps1` en la carpeta `cola\`
y el **asistente** (`asistente_videos.ps1`, una ventana de PowerShell abierta) lo ejecuta.

## Cómo funciona

- Revisa `cola\` cada 3 s y ejecuta **un script a la vez, en orden alfabético**.
- Mueve el script a `hechos\` y guarda la salida en `logs\<nombre>.log` (UTF-16 en Windows
  PowerShell 5; léelo con `iconv -f UTF-16` o `Get-Content`).
- Al final del log escribe `##TERMINADO <fecha>`. Si no está esa línea, el script sigue corriendo.

## Reglas para el agente

1. **Nombre = orden.** Usa numeración creciente con prefijo, por ejemplo `0371_cortos.ps1`. Mira
   `hechos\` para saber el último número.
2. **Un script, una tarea.** Para un render: una línea que llama a `motor.ps1 -Plan <ruta>`.
3. **Escribe primero los datos y al final el script de la cola.** Plan JSON y `.ass` primero;
   el `.ps1` de la cola al último, porque el asistente puede tomarlo en cuanto aparece.
4. **Si la cola no avanza**, el asistente está cerrado: ábrelo con `Asistente_videos.bat` en el
   escritorio, o pídeselo a Martin.
5. **Si un script espera a que exista algo** (por ejemplo exportaciones de Insta360), pon un
   bucle con tope de tiempo. Nunca dejes un bucle sin límite.
6. Nunca pongas en la cola nada que borre originales, use credenciales o publique en internet sin
   permiso explícito de Martin.

## Ejemplo

```powershell
# cola\0370_serie_hq.ps1
& "C:\Users\tinlu\Documents\StreamDeck\video\motor.ps1" -Plan "C:\Users\tinlu\Documents\StreamDeck\video\plan_cine\plan_hq.json"
```
