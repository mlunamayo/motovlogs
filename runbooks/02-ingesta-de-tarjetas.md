# 02 · Ingesta: de las cámaras al disco

**Script:** `scripts/ingesta/nueva_grabacion.ps1` (botón "Grabar" del Stream Deck).
**Cancelar:** `scripts/ingesta/cancelar_grabacion.ps1` (botón "Cancelar").

## Qué hace

1. Crea `G:\Motovlog\<AAAA-MM-DD de hoy>\{Canon,Insta360,DJI}`.
2. Busca tarjetas SD (cualquier unidad extraíble con `DCIM`) y cámaras por USB sin letra (MTP:
   Canon/EOS, DJI/Osmo, Insta).
3. Clasifica por cámara: carpeta `CANON` → Canon; `DJI_*` → DJI; `.insv/.insp` o `Camera01` → Insta360.
4. Copia con barra de progreso a `*.copiando` y renombra al terminar. Conserva las fechas
   originales y salta lo que ya existe con el mismo tamaño, así que se puede repetir sin duplicar.
5. Al terminar abre la carpeta en el Explorador.

## Notas

- **La fecha de la carpeta es la de la copia, no la de la grabación.** La fecha real va en el
  nombre del archivo (`DJI_20261018102253_...` = 18 oct 10:22:53).
- Cancelar mata la copia, borra los `*.copiando` a medias y **no toca las cámaras**.
- Material 360 antiguo vive en la Mac (red): `Z:\` → `\\192.168.1.251\Videos insta 360`.
- Nunca borres nada de las tarjetas desde un script. Formatear es decisión de Martin.

## Comprobación

En el log o la pantalla: `LISTO: N archivos, X GB`. Compara contra lo que muestra la tarjeta.
