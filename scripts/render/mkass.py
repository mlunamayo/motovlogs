"""Genera archivos .ass (titulos + subtitulos) para los TikToks."""

HEAD = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Titulo,Arial Black,72,&H00FFFFFF,&H00FFFFFF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,6,2,8,60,60,190,1
Style: Sub,Arial Black,58,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,5,1,2,80,80,420,1
Style: Texto,Arial Black,60,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,5,1,5,80,80,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
AMARILLO = r'{\c&H00D7FF&}'
BLANCO = r'{\c&HFFFFFF&}'


def ts(t):
    t = max(0, t)
    h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f'{h}:{m:02d}:{s:05.2f}'


def ev(start, end, style, text, extra=''):
    return f'Dialogue: 0,{ts(start)},{ts(end)},{style},,0,0,0,,{extra}{text}\n'


def titulo(start, end, linea1, linea2=None):
    t = linea1
    if linea2:
        t += r'\N{\fs52}' + AMARILLO + linea2
    return ev(start, end, 'Titulo', t, r'{\fad(250,300)}')


def texto(start, end, txt, y=None, size=None):
    extra = r'{\fad(200,200)'
    if y:
        extra += rf'\pos(540,{y})'
    if size:
        extra += rf'\fs{size}'
    extra += '}'
    return ev(start, end, 'Texto', txt, extra)


def sub(start, end, txt):
    return ev(start, end, 'Sub', txt)


def write(path, events):
    with open(path, 'w', encoding='utf-8-sig') as f:
        f.write(HEAD + ''.join(events))
