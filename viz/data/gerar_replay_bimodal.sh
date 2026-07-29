#!/bin/sh
# Replay visual ao vivo (fio 4 do backlog, ROADMAP "Backlog especulativo") —
# metade "bimodalidade" da nota 23. NAO e uma nota nova: nao testa hipotese,
# nao gera achado — ilustra com uma corrida fresca um fenomeno ja estabelecido
# em 8/8 seeds (nota 23, delta=0.90/0.95/0.96) e ja confirmado ao vivo dentro
# do main.c (nota 26, E3). Por isso o script vive em viz/, nao em papers/notes/.
#
# Reaproveita a TECNICA da nota 23 (patch textual sobre o main.c: pino
# desconto/urgencia/peso_espaco/estrategia — "uni_h_livre" — deixando so o
# horizonte mutar em 1..12), com DUAS diferencas:
#   1) as ancoras sao as do main.c de HOJE, nao as de 079a3ce — desde a nota 23
#      main.c ganhou os tracos `escuta` (nota 29) e `peso_arrependimento`
#      (nota 30); eles ficam livres aqui (nao fazem parte do fundo pregado da
#      nota 20/23), entao os numeros desta corrida NAO reproduzem os da nota 23
#      (RNG desloca — ver viz/README.md e datasets/README.md) — e nao
#      precisam: isto ilustra o fenomeno, nao re-mede o dataset.
#   2) em vez de acumular o histograma numa janela e despejar UMA linha no
#      final (o que a nota 23 precisava para reduzir ruido de amostragem),
#      aqui despeja-se um SNAPSHOT instantaneo (sem acumulacao) a cada
#      SNAP_STRIDE ticks, direto num CSV — e disso que a animacao precisa
#      (a forma se separando ao longo do tempo, nao so o estado final).
#
# Leitura pura: nao consome rng01(), nao escreve estado da simulacao — so
# conta blocos[i].horizonte vivos e fprintf. Confirmado abaixo (sem SNAP_ARQ,
# CSV --log bit a bit identico ao vanilla).
#
#   sh viz/data/gerar_replay_bimodal.sh              # gera viz/data/replay_bimodal.csv
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEED=${SEED:-1}
DELTA=${DELTA:-0.95}
TICKS=${TICKS:-30000}
SNAP_STRIDE=${SNAP_STRIDE:-200}
SAIDA="$RAIZ/viz/data/replay_bimodal.csv"

python3 - "$MAINC" "$TMP" "$SNAP_STRIDE" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]
stride = int(sys.argv[3])

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO_SNAP = f"""
/* ====== SNAPSHOT DO HISTOGRAMA DE HORIZONTE (replay da nota 23) ========== */
/* Leitura pura: so conta blocos[i].horizonte vivos a cada SNAP_STRIDE ticks
 * e escreve. Nao consome rng01(), nao muda estado da simulacao. */
#define SNAP_STRIDE {stride}
static FILE *snap_fp = NULL;

static void snap_tick(long t) {{
    const char *arq = getenv("SNAP_ARQ");
    if (!arq) return;
    if (t % SNAP_STRIDE != 0) return;
    if (!snap_fp) {{
        snap_fp = fopen(arq, "w");
        if (!snap_fp) return;
        fprintf(snap_fp, "tick,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12\\n");
    }}
    long conta[13] = {{0}};
    for (int i = 0; i < n_blocos; i++)
        if (blocos[i].vivo) conta[blocos[i].horizonte]++;
    fprintf(snap_fp, "%ld", t);
    for (int h = 1; h <= 12; h++) fprintf(snap_fp, ",%ld", conta[h]);
    fprintf(snap_fp, "\\n");
}}

static void snap_despeja(void) {{
    if (snap_fp) {{ fclose(snap_fp); snap_fp = NULL; }}
}}
/* ========================== fim da sonda ================================= */
"""

def snap(s):
    s = troca(s, "/*  PART 3", BLOCO_SNAP + "\n/*  PART 3")
    s = troca(s,
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);",
      "            snap_tick(t);\n"
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    snap_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

# ---- "resto pregado" da nota 20/23 (delta+urgencia+peso_espaco+estrategia
# pregados, mutacao off NELES), horizonte LIVRE (semeio 1..12 + mutacao normal)
def uni_h_livre(s):
    s = troca(s,
      "static void semear_blocos(void) {\n    n_blocos = 0;",
      "static float TORN_DESC = DESCONTO;\n"
      "static void semear_blocos(void) {\n"
      "    { const char *d = getenv(\"TORN_DESC\"); if (d) TORN_DESC = (float)atof(d); }\n"
      "    n_blocos = 0;")
    s = troca(s, "b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->urgencia    = (rng01(), URGENCIA);")
    s = troca(s, "b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->peso_espaco = (rng01(), PESO_ESPACO);")
    s = troca(s, "b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
                  "b->desconto    = (rng01(), TORN_DESC);")
    s = troca(s, "b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */",
                  "b->estrategia  = (rng01(), SIN_HONESTO);")
    s = troca(s, "cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);",
                  "cria->urgencia    = pai->urgencia;")
    s = troca(s, "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
                  "cria->peso_espaco = pai->peso_espaco;")
    s = troca(s, "cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
                  "cria->desconto    = pai->desconto;")
    s = troca(s, "cria->estrategia  = muta_estrategia(pai->estrategia);",
                  "cria->estrategia  = pai->estrategia;")
    return s   # horizonte: b->horizonte e cria->horizonte seguem 100% vanilla

open(f"{tmp}/snap_only.c", "w").write(snap(src))
open(f"{tmp}/uni_h.c", "w").write(uni_h_livre(snap(src)))
PY

gcc -std=c11 -O2 -o "$TMP/snap_only" "$TMP/snap_only.c" 2>"$TMP/gcc1.err" \
  || { echo "gcc falhou (snap_only):"; cat "$TMP/gcc1.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/uni_h" "$TMP/uni_h.c" 2>"$TMP/gcc2.err" \
  || { echo "gcc falhou (uni_h):"; cat "$TMP/gcc2.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# sanidade: a sonda SOZINHA (sem o pino uni_h_livre), sem SNAP_ARQ, nao muda o
# vanilla — leitura pura de verdade. O pino em si MUDA o comportamento por
# desenho (e o ponto do uni_h_livre); nao faz sentido compara-lo ao vanilla.
"$TMP/vanilla"   7 2000 0 --log "$TMP/van.csv" >/dev/null 2>&1
"$TMP/snap_only" 7 2000 0 --log "$TMP/snap.csv" >/dev/null 2>&1
cmp -s "$TMP/van.csv" "$TMP/snap.csv" \
  || { echo "SANIDADE FALHOU: a sonda sozinha mudou o vanilla (CSV difere). PARAR."; exit 1; }
echo "   sanidade ok: a sonda (sem SNAP_ARQ) e CSV --log bit a bit identico ao vanilla"

echo "== gerando replay bimodal: seed=$SEED delta=$DELTA ticks=$TICKS stride=$SNAP_STRIDE =="
TORN_DESC="$DELTA" SNAP_ARQ="$SAIDA" "$TMP/uni_h" "$SEED" "$TICKS" 0 >/dev/null 2>&1
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"
