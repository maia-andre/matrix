#!/usr/bin/env python3
"""Gera o banner animado (GIF) estilo "digital rain" do README.

No espirito do projeto: o banner inteiro e f(seed) — mesma seed, mesmo GIF —
e o loop e perfeito (o frame T emenda no frame 0). Glifos: katakana
half-width espelhado (como no filme), digitos e os simbolos do proprio
jogo (@ . : *).
"""
import os
import random
from PIL import Image, ImageDraw, ImageFont

SEED = 20260628          # a seed default do universo do main.c
W, H = 800, 200
CELL_W, CELL_H = 13, 16
COLS = W // CELL_W       # 61
ROWS = H // CELL_H       # 12
T = 96                   # frames; 80 ms cada -> loop de ~7.7 s
DELAY_MS = 80

FONTE = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"
GLIFOS = list("ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"
              "0123456789" "@:.*@:.*")   # simbolos do jogo, com peso dobrado

# Periodos possiveis do ciclo de uma coluna (head percorre P celulas e
# recomeca). Todos dividem T (velocidade cheia) ou T/2 (meia velocidade),
# entao o loop fecha exato.
P_CHEIA = [16, 24, 32, 48]
P_MEIA = [16, 24, 48]

rng = random.Random(SEED)
fonte = ImageFont.truetype(FONTE, 15)

# --- pre-renderiza tiles: glifo espelhado x nivel de brilho ---------------
NIVEIS = 14  # tons de verde do rastro
def cor(nivel):
    if nivel == NIVEIS:                      # cabeca: branco-esverdeado
        return (200, 255, 200)
    g = int(40 + (255 - 40) * (nivel / (NIVEIS - 1)) ** 1.4)
    return (0, g, int(g * 0.25))

tiles = {}
for gi, ch in enumerate(GLIFOS):
    for nivel in list(range(NIVEIS)) + [NIVEIS]:
        tile = Image.new("RGB", (CELL_W, CELL_H), (0, 0, 0))
        d = ImageDraw.Draw(tile)
        bb = d.textbbox((0, 0), ch, font=fonte)
        d.text(((CELL_W - (bb[2] - bb[0])) // 2 - bb[0],
                (CELL_H - (bb[3] - bb[1])) // 2 - bb[1]),
               ch, font=fonte, fill=cor(nivel))
        tiles[(gi, nivel)] = tile.transpose(Image.FLIP_LEFT_RIGHT)

# --- estado das colunas (sorteado uma vez; tudo deterministico) -----------
colunas = []
for c in range(COLS):
    meia = rng.random() < 0.4
    P = rng.choice(P_MEIA if meia else P_CHEIA)
    colunas.append({
        "P": P,
        "meia": meia,                        # anda 1 celula a cada 2 frames
        "off": rng.randrange(P),
        "rastro": rng.randint(5, 11),
        "base": [rng.randrange(len(GLIFOS)) for _ in range(ROWS)],
        "pisca": [rng.randrange(6) == 0 for _ in range(ROWS)],
    })

def glifo(col, c, r, t):
    """Glifo da celula; os marcados como 'pisca' trocam a cada 6 frames."""
    if col["pisca"][r]:
        return (col["base"][r] + (t % T) // 6 * (c * 7 + r * 13 + 1)) % len(GLIFOS)
    return col["base"][r]

frames = []
for t in range(T):
    img = Image.new("RGB", (W, H), (0, 0, 0))
    for c, col in enumerate(colunas):
        passo = (t // 2 if col["meia"] else t)
        head = (col["off"] + passo) % col["P"]
        for r in range(ROWS):
            atras = head - r          # distancia atras da cabeca (com wrap)
            if atras < 0:
                atras += col["P"]
            if atras == 0:
                nivel = NIVEIS
            elif atras <= col["rastro"]:
                nivel = max(0, NIVEIS - 1 - (atras - 1) * (NIVEIS - 1) // col["rastro"])
            else:
                continue
            img.paste(tiles[(glifo(col, c, r, t), nivel)],
                      (c * CELL_W, r * CELL_H))
    frames.append(img)

# --- paleta global unica (frames pequenos e cores estaveis) ---------------
amostra = Image.new("RGB", (W, H * 2))
amostra.paste(frames[0], (0, 0))
amostra.paste(frames[T // 2], (0, H))
paleta = amostra.quantize(colors=64)
frames_p = [f.quantize(palette=paleta, dither=Image.Dither.NONE) for f in frames]

saida = os.path.join(os.path.dirname(os.path.abspath(__file__)), "matrix-rain.gif")
frames_p[0].save(
    saida,
    save_all=True, append_images=frames_p[1:],
    duration=DELAY_MS, loop=0, optimize=True,
)
print("ok:", saida)
