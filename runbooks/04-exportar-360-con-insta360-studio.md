# 04 · Exportar 360 con Insta360 Studio

**Por qué:** Studio estabiliza (FlowState), nivela el horizonte y cose las dos lentes mucho
mejor que hacerlo directo con ffmpeg sobre el `.insv`. Se exporta solo el tramo que interesa.
Studio **no tiene línea de comandos**, así que se usa por GUI: lo hace Martin o un agente con
control de pantalla.

## Pasos

1. Abrir Insta360 Studio y maximizarlo. **Import** → en el cuadro "Nombre de archivo" escribe la
   carpeta (`Z:\`) + Enter, y luego hasta 4 nombres entre comillas por vez (el cuadro corta los
   textos largos).
2. Doble clic en el clip. La barra de tiempo ocupa todo el clip: x ≈ inicio + ancho × (t / duración).
   Haz clic, lee el tiempo (`hh:mm:ss:ff`, ff = cuadros a 50 fps) y ajusta.
3. **Trim beginning** (I) en el inicio del tramo; mueve el cursor al final; **Trim end** (O).
   Deja 5-10 s de margen a cada lado.
4. **Export** → **360 Video** (sale 3840x1920 equirectangular, H.264, ~70 Mbps).
   - Ruta: `G:\Motovlog\<fecha>` (no el Escritorio, que se sincroniza con OneDrive).
   - Nombre: `st_<num>_s<segundo de inicio>.mp4`, p. ej. `st_002_s1397.mp4`. El segundo de
     inicio en el nombre permite ubicar luego los momentos del original.
   - **Add to Queue** (no Export) y sigue con el siguiente clip.
5. Al final: **Task Center** → **Start All**. Va a ~1x tiempo real; 7 clips de 30-80 s tardan ~5 min.

## Después

- Hojas de contacto: `scripts/analisis/hojas_360_studio.ps1`.
- En el plan usa `layout: "equi"` (`runbooks/05`). Hacia delante: `yaw 0, pitch 4`.
  Hacia ti: `yaw 180, pitch -3`.
