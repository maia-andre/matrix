#!/bin/sh
# Replay visual ao vivo (fio 4 do backlog, ROADMAP "Backlog especulativo") —
# metade "detector de colapso" da nota 24. NAO e uma nota nova: nao testa
# hipotese, nao gera achado — ilustra com uma corrida fresca um mecanismo ja
# validado (nota 24: 0/8 falsos positivos, 6/8 deteccoes reais, 6/6
# recuperacoes). Por isso o script vive em viz/, nao em papers/notes/.
#
# Reaproveita a TECNICA da nota 24 (patch textual: imposto pigouviano das
# notas 15/21 ligando/desligando em ticks controlados por env vars, + o
# detector janela-recente-vs-referencia), com DUAS diferencas:
#   1) as ancoras sao as do main.c de HOJE, nao as de 079a3ce — desde a nota 24
#      main.c ganhou `atualizar_remorso()` entre resolver() e aplicar_e_comer()
#      (nota 30) — o patch injeta o imposto no mesmo lugar de sempre
#      (aplicar_e_comer, custo por bloco) e o col_tick() logo apos, so que
#      contornando essa nova linha. Como a corrida e fresca (nao reproduz um
#      numero ja publicado), o deslocamento de RNG dos tracos novos nao importa.
#   2) em vez de despejar UMA linha de resumo no final (disparou/tick_disparo/
#      queda_max), aqui despeja a SERIE INTEIRA (tick,pop,recente,referencia,
#      ativo) direto num CSV — e disso que a animacao precisa.
#
# Leitura pura: col_tick() so le populacao e historico proprio, nao consome
# rng01(), nao escreve estado da simulacao. Confirmado abaixo (sem imposto,
# CSV --log bit a bit identico ao vanilla).
#
#   sh viz/data/gerar_replay_colapso.sh              # gera viz/data/replay_colapso.csv
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEED=${SEED:-2}
CUSTO_H=${CUSTO_H:-0.30}
INICIO=${INICIO:-2000}
FIM=${FIM:-5000}
TICKS=${TICKS:-8000}
SAIDA="$RAIZ/viz/data/replay_colapso.csv"

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO_DETECTOR = r"""
static long imp_t = 0;

/* ============ DETECTOR DE COLAPSO (replay da nota 24) — serie temporal === */
/* So ve a propria historia de populacao por tick — nada privilegiado. Pura
 * leitura: nao consome RNG, nao escreve estado da simulacao. */
#define COL_JANELA  250
#define COL_VAO     500
#define COL_LIMIAR  0.20
#define COL_TAM     (COL_JANELA * 2 + COL_VAO)
static int  col_hist[COL_TAM];
static long col_n = 0;
static FILE *col_fp = NULL;

static void col_tick(long t, int pop) {
    col_hist[t % COL_TAM] = pop;
    col_n++;
    int pronto = (col_n >= COL_TAM);
    double recente = 0.0, referencia = 0.0;
    if (pronto) {
        for (long k = t - COL_JANELA; k < t; k++)
            recente += col_hist[((k % COL_TAM) + COL_TAM) % COL_TAM];
        recente /= COL_JANELA;
        for (long k = t - COL_JANELA - COL_VAO - COL_JANELA; k < t - COL_VAO - COL_JANELA; k++)
            referencia += col_hist[((k % COL_TAM) + COL_TAM) % COL_TAM];
        referencia /= COL_JANELA;
    }
    int ativo = 0;
    if (pronto && referencia > 0.0) {
        double queda = (referencia - recente) / referencia;
        ativo = (queda >= COL_LIMIAR) ? 1 : 0;
    }
    const char *arq = getenv("COL_TS_ARQ");
    if (!arq) return;
    if (!col_fp) {
        col_fp = fopen(arq, "w");
        if (!col_fp) return;
        fprintf(col_fp, "tick,pop,recente,referencia,ativo\n");
    }
    fprintf(col_fp, "%ld,%d,%.3f,%.3f,%d\n", t, pop, recente, referencia, ativo);
}

static void col_despeja(void) {
    if (col_fp) { fclose(col_fp); col_fp = NULL; }
}
/* ========================== fim do detector =============================== */
"""

def detector(s):
    s = troca(s, "/*  PART 3", BLOCO_DETECTOR + "\n/*  PART 3")
    s = troca(s,
      "        blocos[i].energia -= METABOLISMO;   /* existir custa               */",
      "        { static int lido=0; static float custo_h=0.0f;\n"
      "          static long inicio=0, fim=0;\n"
      "          if (!lido) { const char *e=getenv(\"CUSTO_H\"); if (e) custo_h=(float)atof(e);\n"
      "            const char *ii=getenv(\"CUSTO_H_INICIO\"); if (ii) inicio=atol(ii);\n"
      "            const char *ff=getenv(\"CUSTO_H_FIM\"); if (ff) fim=atol(ff); lido=1; }\n"
      "          int liga = (imp_t >= inicio) && (fim <= 0 || imp_t < fim);\n"
      "          float ch = liga ? custo_h : 0.0f;\n"
      "          float ed = 1.0f/(1.0f - blocos[i].desconto);\n"
      "          if ((float)blocos[i].horizonte < ed) ed = (float)blocos[i].horizonte;\n"
      "          float imp = ch * ed;\n"
      "          blocos[i].energia -= METABOLISMO + imp;   /* imposto pigouviano */\n"
      "        }")
    s = troca(s,
      "            resolver();\n"
      "            atualizar_remorso();   /* §4.3: le reivindicado[][] antes que suma */\n"
      "            aplicar_e_comer();",
      "            imp_t = t;\n"
      "            resolver();\n"
      "            atualizar_remorso();   /* §4.3: le reivindicado[][] antes que suma */\n"
      "            aplicar_e_comer();\n"
      "            { int pop = 0; for (int i = 0; i < n_blocos; i++) if (blocos[i].vivo) pop++;\n"
      "              col_tick(t, pop); }")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    col_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

open(f"{tmp}/colapso.c", "w").write(detector(src))
PY

gcc -std=c11 -O2 -o "$TMP/colapso" "$TMP/colapso.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# sanidade: sem imposto (CUSTO_H nao setado => 0) e sem COL_TS_ARQ, o detector
# nao muda a simulacao — leitura pura de verdade.
"$TMP/vanilla" 7 2000 0 --log "$TMP/van.csv" >/dev/null 2>&1
"$TMP/colapso" 7 2000 0 --log "$TMP/col.csv" >/dev/null 2>&1
cmp -s "$TMP/van.csv" "$TMP/col.csv" \
  || { echo "SANIDADE FALHOU: o detector mudou o vanilla (CSV difere). PARAR."; exit 1; }
echo "   sanidade ok: sem imposto/COL_TS_ARQ, CSV --log bit a bit identico ao vanilla"

echo "== gerando replay colapso: seed=$SEED custo=$CUSTO_H inicio=$INICIO fim=$FIM ticks=$TICKS =="
CUSTO_H="$CUSTO_H" CUSTO_H_INICIO="$INICIO" CUSTO_H_FIM="$FIM" COL_TS_ARQ="$SAIDA" \
  "$TMP/colapso" "$SEED" "$TICKS" 0 >/dev/null 2>&1
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"
