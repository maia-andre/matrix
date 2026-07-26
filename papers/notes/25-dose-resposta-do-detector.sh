#!/bin/sh
# Nota 25 (eixo microscopio): A DOSE-RESPOSTA DO DETECTOR — onde fica o limiar
# entre "colapso sobrevivivel" e "silencio rapido demais para a regua".
#
# A nota 24 construiu o detector de colapso (janela recente x referencia sobre
# a propria historia de populacao) e achou um limite honesto: em c=0,30 (o
# imposto pigouviano das notas 15/21, ligado no meio de uma corrida ja
# estavel), 2 das 8 seeds sofreram EXTINCAO TOTAL em 11-14 ticks — rapido
# demais para a janela de 250 ticks refletir a queda antes do mundo acabar.
# As outras 6 seeds foram detectadas limpo, em ~54 ticks.
#
# Esta nota aprofunda essa fronteira em duas direcoes, ambas pre-registradas
# ANTES de rodar (dois pilotos nao commitados, 1 seed cada, decidiram os
# parametros abaixo):
#
#   D1 (dose-resposta): custos mais brandos causam o MESMO colapso sem
#      extinguir? Testado nas DUAS seeds que a nota 24 viu se extinguirem
#      (1 e 8) em c={0,04; 0,08; 0,15; 0,20; 0,25}, e confirmado: nenhuma
#      extingue, todas disparam o detector em 45-115 ticks. So em c=0,30 as
#      duas se extinguem. O piloto sugere um LIMIAR ESTREITO entre 0,25 e
#      0,30 — nao uma dose-resposta suave, uma transicao de fase. Esta nota
#      testa isso nas 8 seeds completas.
#   D2 (trade-off de janela): uma janela mais CURTA (30 ticks, contra os 250
#      da nota 24) capturaria a extincao antes dela acontecer — ao custo de
#      mais falsos positivos em populacao saudavel? O piloto (seed 1, extinta
#      em 2013): janela=250 nunca disparou (queda_max=0,05); janela=30
#      disparou em t=2010 (3 ticks ANTES da extincao completa) e ficou ativo
#      ate o fim. Falsos positivos no piloto (4 seeds vanilla, janela=30):
#      ZERO — o ruido so cresceu de ~3-9% (ainda bem abaixo do limiar de 20%).
#
# PRE-REGISTRO:
#   D0 (sanidade): o detector parametrizavel (janela/vao/limiar por env var)
#       reproduz a nota 24 EXATAMENTE com os mesmos parametros — CSV --log
#       bit a bit identico ao vanilla sem imposto; extincao das seeds 1 e 8
#       em c=0,30/janela=250 reproduzida nos mesmos ticks (2013/2011 no core,
#       "Silencio" reportado um tick depois pelo main loop).
#   D1 (a transicao e ESTREITA, nao suave): com janela padrao (250/500/0,20),
#       CUSTO_H em {0,04; 0,08; 0,15; 0,20; 0,25; 0,30}, onset em t=2000,
#       8 seeds: a fracao de seeds extintas e 0/8 em TODO custo <= 0,25, e
#       sobe para o patamar ja medido na nota 24 (2/8) so em c=0,30. Se a
#       fracao subir gradualmente entre 0,15 e 0,25, a leitura "transicao de
#       fase" cai e vira "dose-resposta suave que a nota 24 pegou na cauda".
#   D2 (janela curta pega o que a longa perde, sem inflar falso-positivo):
#       em c=0,30 (o choque letal), janela=30 detecta (dispara OU fica ativo
#       no momento da extincao) em >= 7/8 seeds — incluindo as que a janela
#       de 250 nao pegava. Em vanilla (sem imposto), janela=30 mantem
#       <= 2/8 falsos positivos (o ruido de curto prazo e maior mas ainda
#       longe do limiar de 20%).
#
# Custo: D1 = 6 custos x 8 seeds = 48 corridas; D2 = 2 janelas x 2 condicoes
# x 8 seeds = 32 corridas (a janela=250/c=0,30 e janela=250/vanilla ja tem
# dados equivalentes na nota 24, mas re-rodadas aqui para manter o dataset
# desta nota autocontido). Total 80 corridas de 6000 ticks, ~1-3 min cada
# => ~5-10 min com NPROC=16.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/dose-detector.csv
# (D1) e datasets/janela-detector.csv (D2).
#   git log -1 --oneline -- datasets/dose-detector.csv
#
#   sh papers/notes/25-dose-resposta-do-detector.sh                 # lote completo
#   SEEDS_LISTA="1 8" sh papers/notes/25-dose-resposta-do-detector.sh   # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
CUSTOS=${CUSTOS:-"0.04 0.08 0.15 0.20 0.25 0.30"}

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

/* ============ DETECTOR DE COLAPSO (nota 24/25) — janela/limiar via env ==== */
#define COL_MAXBUF 4000
static int    col_janela = 250, col_vao = 500;
static double col_limiar = 0.20;
static int    col_tam = 1000;
static int    col_hist[COL_MAXBUF];
static long   col_n = 0;
static int    col_disparou = 0;
static long   col_tick_disparo = -1;
static double col_queda_max = 0.0;
static long   col_tick_queda_max = -1;
static int    col_ativo_agora = 0;
static int    col_lido = 0;
static int    col_extinta = 0;
static long   col_tick_extincao = -1;

static void col_tick(long t, int pop) {
    if (!col_lido) {
        const char *j = getenv("COL_JANELA"); if (j) col_janela = atoi(j);
        const char *v = getenv("COL_VAO");    if (v) col_vao    = atoi(v);
        const char *l = getenv("COL_LIMIAR"); if (l) col_limiar = atof(l);
        col_tam = col_janela * 2 + col_vao;
        if (col_tam > COL_MAXBUF) col_tam = COL_MAXBUF;
        col_lido = 1;
    }
    col_hist[t % col_tam] = pop;
    col_n++;
    if (col_n < col_tam) { col_ativo_agora = 0; return; }
    double recente = 0.0, referencia = 0.0;
    for (long k = t - col_janela; k < t; k++)
        recente += col_hist[((k % col_tam) + col_tam) % col_tam];
    recente /= col_janela;
    for (long k = t - col_janela - col_vao - col_janela; k < t - col_vao - col_janela; k++)
        referencia += col_hist[((k % col_tam) + col_tam) % col_tam];
    referencia /= col_janela;
    if (referencia <= 0.0) { col_ativo_agora = 0; return; }
    double queda = (referencia - recente) / referencia;
    col_ativo_agora = (queda >= col_limiar) ? 1 : 0;
    if (col_ativo_agora && !col_disparou) { col_disparou = 1; col_tick_disparo = t; }
    if (queda > col_queda_max) { col_queda_max = queda; col_tick_queda_max = t; }
}

static void col_despeja(void) {
    const char *arq = getenv("COL_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim,extinta,tick_extincao\n");
    fprintf(fp, "%d,%ld,%.4f,%ld,%d,%d,%ld\n",
        col_disparou, col_tick_disparo, col_queda_max, col_tick_queda_max, col_ativo_agora,
        col_extinta, col_tick_extincao);
    fclose(fp);
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
      "            aplicar_e_comer();",
      "            imp_t = t;\n"
      "            resolver();\n"
      "            aplicar_e_comer();\n"
      "            { int pop = 0; for (int i = 0; i < n_blocos; i++) if (blocos[i].vivo) pop++;\n"
      "              if (pop == 0 && !col_extinta) { col_extinta = 1; col_tick_extincao = t; }\n"
      "              col_tick(t, pop); }")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    col_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

open(f"{tmp}/detector.c", "w").write(detector(src))
PY

gcc -std=c11 -O2 -o "$TMP/detector" "$TMP/detector.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# D0a: sem imposto, o detector NAO muda a simulacao (parametros default).
"$TMP/vanilla"  7 2000 0 --log "$TMP/d0a_van.csv" >/dev/null 2>&1
"$TMP/detector" 7 2000 0 --log "$TMP/d0a_det.csv" >/dev/null 2>&1
cmp -s "$TMP/d0a_van.csv" "$TMP/d0a_det.csv" \
  || { echo "D0a FALHOU: o detector mudou a simulacao. PARAR."; exit 1; }
echo "   D0a ok: CSV bit a bit identico ao vanilla"

# D0b: reproduz a nota 24 - seeds 1 e 8 se extinguem em c=0,30/janela padrao.
COL_JANELA=250 COL_VAO=500 CUSTO_H=0.30 CUSTO_H_INICIO=2000 COL_ARQ="$TMP/d0b_s1" "$TMP/detector" 1 6000 0 >/dev/null 2>&1
COL_JANELA=250 COL_VAO=500 CUSTO_H=0.30 CUSTO_H_INICIO=2000 COL_ARQ="$TMP/d0b_s8" "$TMP/detector" 8 6000 0 >/dev/null 2>&1
awk -F, 'NR==2 && $6!=1 { print "D0b FALHOU: seed nao se extinguiu como a nota 24"; exit 1 }' "$TMP/d0b_s1" || exit 1
awk -F, 'NR==2 && $6!=1 { print "D0b FALHOU: seed nao se extinguiu como a nota 24"; exit 1 }' "$TMP/d0b_s8" || exit 1
echo "   D0b ok: seeds 1 e 8 reproduzem a extincao da nota 24 em c=0,30/janela=250"

mkdir -p "$TMP/rows_d1" "$TMP/rows_d2"
export TMP

echo "== D1: dose-resposta (6 custos x $(echo $SEEDS | wc -w) seeds), janela padrao =="
{
  for c in $CUSTOS; do for s in $SEEDS; do echo "$c $s"; done; done
} | xargs -P "$NPROC" -n 2 sh -c '
    c=$1; s=$2
    raw="$TMP/raw_d1_${c}_${s}"
    COL_JANELA=250 COL_VAO=500 CUSTO_H="$c" CUSTO_H_INICIO=2000 COL_ARQ="$raw" \
      "$TMP/detector" "$s" 6000 0 >/dev/null 2>&1 \
      || { echo "d1 $c $s" >> "$TMP/falhas"; exit 0; }
    tail -n 1 "$raw" | awk -F, -v C="$c" -v SEED="$s" '"'"'{print C","SEED","$0}'"'"' > "$TMP/rows_d1/${c}_${s}.row"
    rm -f "$raw"
  ' _

echo "== D2: trade-off de janela (2 janelas x 2 condicoes x $(echo $SEEDS | wc -w) seeds) =="
{
  for s in $SEEDS; do echo "250 500 0.30 $s"; done
  for s in $SEEDS; do echo "250 500 0    $s"; done
  for s in $SEEDS; do echo "30  60  0.30 $s"; done
  for s in $SEEDS; do echo "30  60  0    $s"; done
} | xargs -P "$NPROC" -n 4 sh -c '
    j=$1; v=$2; c=$3; s=$4
    raw="$TMP/raw_d2_${j}_${c}_${s}"
    if [ "$c" = "0" ]; then
      COL_JANELA="$j" COL_VAO="$v" COL_ARQ="$raw" "$TMP/detector" "$s" 6000 0 >/dev/null 2>&1 \
        || { echo "d2 $j $c $s" >> "$TMP/falhas"; exit 0; }
    else
      COL_JANELA="$j" COL_VAO="$v" CUSTO_H="$c" CUSTO_H_INICIO=2000 COL_ARQ="$raw" \
        "$TMP/detector" "$s" 6000 0 >/dev/null 2>&1 \
        || { echo "d2 $j $c $s" >> "$TMP/falhas"; exit 0; }
    fi
    tail -n 1 "$raw" | awk -F, -v J="$j" -v C="$c" -v SEED="$s" '"'"'{print J","C","SEED","$0}'"'"' > "$TMP/rows_d2/${j}_${c}_${s}.row"
    rm -f "$raw"
  ' _

if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows_d1/"*.row | wc -l) corridas D1 + $(ls "$TMP/rows_d2/"*.row | wc -l) corridas D2 convertidas"

SAIDA1=${FUMACA:+"$TMP/dose-detector.csv"}
SAIDA1=${SAIDA1:-"$RAIZ/datasets/dose-detector.csv"}
{
echo "custo,seed,disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim,extinta,tick_extincao"
cat "$TMP/rows_d1/"*.row
} > "$SAIDA1"

SAIDA2=${FUMACA:+"$TMP/janela-detector.csv"}
SAIDA2=${SAIDA2:-"$RAIZ/datasets/janela-detector.csv"}
{
echo "janela,custo,seed,disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim,extinta,tick_extincao"
cat "$TMP/rows_d2/"*.row
} > "$SAIDA2"
echo "   datasets: $SAIDA1 ($(wc -l < "$SAIDA1") linhas), $SAIDA2 ($(wc -l < "$SAIDA2") linhas)"

echo ""
echo "== D1: fracao extinta e fracao detectada, por custo =="
awk -F, 'NR>1 {
    n[$1]++; if ($8==1) ext[$1]++; if ($3==1) det[$1]++
  }
  END {
    ord="0.04 0.08 0.15 0.20 0.25 0.30"; split(ord, a, " ")
    for (i=1;i<=6;i++) { c=a[i]
      printf "   c=%-5s  extintas=%d/%d  detectadas=%d/%d\n", c, ext[c]+0, n[c], det[c]+0, n[c] }
  }' "$SAIDA1"

echo ""
echo "== D2: janela x condicao — deteccao e falso-positivo =="
awk -F, 'NR>1 {
    key=$1" custo="$2
    n[key]++; if ($4==1) det[key]++; if ($9==1) ext[key]++
  }
  END {
    for (k in n) printf "   janela=%-18s disparou=%d/%d  extintas=%d/%d\n", k, det[k]+0, n[k], ext[k]+0, n[k]
  }' "$SAIDA2" | sort
echo "== fim =="
