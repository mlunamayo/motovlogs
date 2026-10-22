# 06 · Estilos de video (recetas)

Los planes de ejemplo están en `plantillas/planes/`.

## A. Corto con gancho (el que se publica por defecto)

`cortos_gancho.json`. Es el formato a probar primero según los datos (`runbooks/10`).
- **12-18 s**, 5 tomas de 2.6-3.6 s, color `cine`, sin audio original.
- **El primer cuadro es la mejor toma** (grupo inclinado en curva), **sin fundido de entrada**.
- Frase de gancho arriba durante 0-2.8 s (estilo `Hook`), en minúsculas y concreta, por ejemplo
  "¿la carretera más bonita de georgia?" o "pov: rodando en manada por las montañas de georgia".
- Firma en los últimos 2.6 s, **sin fundido a negro**, para que el bucle se vea natural.

## B. Serie cinematográfica (larga)

`serie_cine.json`. Unos 38 s, 6 tomas de 6-7 s a velocidad normal, `grade: cine`, fundido de
entrada y de salida, título fino ("dahlonega · suches · 18.10") de 0.6 a 3.8 s y firma al final.
Referencia de estilo: POV sobre el manubrio, tomas largas, sin texto encima, fundido a negro.
**Aviso:** retuvo poco en TikTok (5.5 s de 38 s). Úsalo para YouTube Shorts o como pieza de
portafolio; en TikTok usa la versión A.

## C. Curvas con velocidad

`curvas_velocidad.json`. Por curva: acercamiento 2.5 s a 1.8x → vértice 2 s a 0.5x → salida 2 s
a 1.8x, con texto que invite a comentar ("califica la horquilla"). La cámara lenta queda fluida
porque la Osmo graba a 60 fps.

## D. Rampa (sin texto)

`rampa_velocidad.json`. La misma idea que C, con cambios graduales de velocidad. Unos 20 s.

## E. 360 con Insta360 Studio

`equi_360_studio.json`. Alterna hacia delante (`yaw 0`) con hacia ti (`yaw 180`). Encuadre
`hfov 80 / vfov 112`: más cerrado deforma menos y se ve más cinematográfico.

## Reglas comunes

- **Un video = un solo viaje.** No mezcles Dahlonega con Gatlinburg.
- Los títulos dicen el lugar correcto. Confírmalo con Martin: el 18.10.2026 fue Dahlonega / Two
  Wheels of Suches; Gatlinburg / Smokies es oct-2025 (360).
- Nada de semáforos, gasolineras ni estacionamientos al inicio. Al final, solo si cierran la historia.
