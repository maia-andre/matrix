#!/bin/sh
# Nota 24 (eixo microscopio): O DETECTOR DE COLAPSO — o primeiro modulo de
# "a Matrix pode produzir conhecimento sobre a Matrix?"
#
# O ROADMAP declara o eixo paralelo "A Matrix como microscopio": um detector de
# mudanca de regime ("a populacao entrou em colapso") E, ele mesmo, um sistema
# com faculdade de RELATO — e toda a bateria da Fase 2 recai sobre ele. Um
# detector que dispara em cima de ruido esta CONFABULANDO (o interprete de
# Gazzaniga um andar acima). Valida-se do mesmo jeito que o relato da nota 06:
# por INTERVENCAO — injete um colapso conhecido e veja se o relatorio e
# honesto; injete ruido sem colapso e veja se ele inventa.
#
# O QUE O DETECTOR VE. So a propria historia de populacao por tick — nada de
# privilegiado. Compara a media de uma janela RECENTE (ultimos 250 ticks) com a
# media de uma janela de REFERENCIA mais antiga (250 ticks, separada por um vao
# de 500), e dispara "colapso ativo" se a queda relativa passar de 20%. E o
# analogo populacional do `phi_proxy`/Kendall: aritmetica simples sobre o que
# a Matrix ja registra de si, sem sqrt, sem estado privilegiado.
#
# O GROUND TRUTH E O IMPOSTO PIGOUVIANO DAS NOTAS 15/21 — ja validado, dose-
# resposta ja medida (pop cai de 284 a 133 em c=0,30, ~30000 ticks de
# equilibrio). Aqui o imposto liga NO MEIO de uma corrida ja estavel (nao desde
# a semeadura — um piloto nao commitado achou que o "colapso" da nota 15/21
# acontece quase todo nos primeiros ~1000 ticks da corrida, entao testar
# deteccao exige um choque QUE ACONTECE DEPOIS de a populacao ja estar
# assentada). Uma segunda variante liga E desliga o imposto, para testar se o
# relatorio acompanha a RECUPERACAO ou fica preso numa narrativa de colapso.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13). Dois
# pilotos nao commitados validaram a maquinaria e a escala de tempo antes deste
# cabecalho: o choque de c=0,30 (que na nota 15/21 da uma queda de EQUILIBRIO de
# ~53%) produz uma queda AO VIVO muito mais brusca no piloto (~66-81% no pico,
# ~50-250 ticks apos o choque) — plausivel, ja que a janela do detector mede o
# transiente, nao a media de 30000 ticks.
#   C0a (sanidade): sem imposto, o detector nao muda a simulacao — CSV --log
#       bit a bit identico ao vanilla. Confirmado no piloto.
#   C0b (o detector nao antecipa): em toda corrida com choque, tick_disparo >
#       CUSTO_H_INICIO sempre — um detector que so ve o passado nao pode
#       acusar colapso antes do choque acontecer. Se vazar: bug de indexacao
#       do historico circular.
#   C1 (deteccao positiva, colapso REAL e forte): CUSTO_H=0,30 ligando em
#       t=2000 (populacao ja assentada), sem desligar, 6000 ticks. O detector
#       DISPARA em 8/8 seeds, com latencia pequena (tick_disparo − 2000 < 500 —
#       o piloto (1 seed) achou 54-260 ticks).
#   C2 (nao-confabulacao — o teste central do eixo): SEM imposto nenhum
#       (vanilla), 6000 ticks, 8 seeds. O detector NAO dispara — <= 1/8 seeds
#       (o ruido natural de populacao e ~3-5% de amplitude, nota 09/seed7.csv;
#       bem abaixo do limiar de 20%). Falsearia: se disparar em >= 4/8, o
#       detector confabula sobre flutuacao normal.
#   C3 (a recuperacao — o relato acompanha o retorno, ou fica preso?):
#       CUSTO_H=0,30 ligando em t=2000 e desligando em t=5000 (3000 ticks de
#       choque), 8000 ticks totais (3000 ticks para observar a recuperacao).
#       O detector DISPARA (mesma deteccao do C1, >= 7/8 seeds) e, ao final da
#       corrida (2500+ ticks depois do imposto sair), ativo_no_fim = 0 em
#       >= 6/8 das seeds que dispararam — o sinal desliga quando a populacao
#       de fato se recupera, nao fica grudado.
#
# Custo: medido no piloto, ~19-92s/corrida (mais caro em populacao alta e nas
# corridas com recuperacao). 8+8+8 = 24 corridas => ~3-5 min com NPROC=16.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/detector-colapso.csv
# (uma linha por condicao x seed: disparou, tick_disparo, queda_max,
# tick_queda_max, ativo_no_fim).
#   git log -1 --oneline -- datasets/detector-colapso.csv
#
#   sh papers/notes/24-detector-de-colapso.sh                     # lote completo
#   SEEDS_LISTA="7" sh papers/notes/24-detector-de-colapso.sh     # fumaca (nao grava)
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

/* ============ DETECTOR DE COLAPSO (nota 24) — o microscopio ============= */
/* So ve a propria historia de populacao por tick — nada privilegiado. Pura
 * leitura: nao consome RNG, nao escreve estado da simulacao. */
#define COL_JANELA  250
#define COL_VAO     500
#define COL_LIMIAR  0.20
#define COL_TAM     (COL_JANELA * 2 + COL_VAO)
static int  col_hist[COL_TAM];
static long col_n = 0;
static int  col_disparou = 0;
static long col_tick_disparo = -1;
static double col_queda_max = 0.0;
static long col_tick_queda_max = -1;
static int  col_ativo_agora = 0;

static void col_tick(long t, int pop) {
    col_hist[t % COL_TAM] = pop;
    col_n++;
    if (col_n < COL_TAM) { col_ativo_agora = 0; return; }
    double recente = 0.0, referencia = 0.0;
    for (long k = t - COL_JANELA; k < t; k++)
        recente += col_hist[((k % COL_TAM) + COL_TAM) % COL_TAM];
    recente /= COL_JANELA;
    for (long k = t - COL_JANELA - COL_VAO - COL_JANELA; k < t - COL_VAO - COL_JANELA; k++)
        referencia += col_hist[((k % COL_TAM) + COL_TAM) % COL_TAM];
    referencia /= COL_JANELA;
    if (referencia <= 0.0) { col_ativo_agora = 0; return; }
    double queda = (referencia - recente) / referencia;
    col_ativo_agora = (queda >= COL_LIMIAR) ? 1 : 0;
    if (col_ativo_agora && !col_disparou) { col_disparou = 1; col_tick_disparo = t; }
    if (queda > col_queda_max) { col_queda_max = queda; col_tick_queda_max = t; }
}

static void col_despeja(void) {
    const char *arq = getenv("COL_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim\n");
    fprintf(fp, "%d,%ld,%.4f,%ld,%d\n",
        col_disparou, col_tick_disparo, col_queda_max, col_tick_queda_max, col_ativo_agora);
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

# C0a: sem imposto, o detector NAO muda a simulacao.
"$TMP/vanilla" 7 2000 0 --log "$TMP/c0a_van.csv" >/dev/null 2>&1
"$TMP/colapso" 7 2000 0 --log "$TMP/c0a_col.csv" >/dev/null 2>&1
cmp -s "$TMP/c0a_van.csv" "$TMP/c0a_col.csv" \
  || { echo "C0a FALHOU: o detector mudou a simulacao (CSV difere). PARAR."; exit 1; }
echo "   C0a ok: CSV bit a bit identico ao vanilla"

mkdir -p "$TMP/rows"
export TMP

echo "== corridas: $(echo $SEEDS | wc -w) x (C1 + C2 + C3), -P $NPROC =="
{
  for s in $SEEDS; do echo "c1 0.30 2000 0    6000 $s"; done
  for s in $SEEDS; do echo "c2 0    0    0    6000 $s"; done
  for s in $SEEDS; do echo "c3 0.30 2000 5000 8000 $s"; done
} | xargs -P "$NPROC" -n 6 sh -c '
    cond=$1; custo=$2; inicio=$3; fim=$4; ticks=$5; s=$6
    raw="$TMP/raw_${cond}_${s}"
    CUSTO_H="$custo" CUSTO_H_INICIO="$inicio" CUSTO_H_FIM="$fim" \
      COL_ARQ="$raw" "$TMP/colapso" "$s" "$ticks" 0 >/dev/null 2>&1 \
      || { echo "$cond $s" >> "$TMP/falhas"; exit 0; }
    tail -n 1 "$raw" | awk -F, -v C="$cond" -v INI="$inicio" -v SEED="$s" \
      '"'"'{print C","INI","SEED","$0}'"'"' > "$TMP/rows/${cond}_${s}.row"
    rm -f "$raw"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/detector-colapso.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/detector-colapso.csv"}
{
echo "condicao,inicio,seed,disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== C0b: o detector nao antecipa (tick_disparo > inicio, sempre) =="
awk -F, 'NR>1 && $4==1 && $2+0>0 && $5+0 <= $2+0 { print "   VAZOU:",$0; bad=1 }
  END { if (bad) { print "   C0b FALHOU"; exit 1 } print "   C0b ok" }' "$SAIDA" || exit 1

echo ""
echo "== C1: deteccao positiva (colapso real, c=0,30 em t=2000, sem desligar) =="
awk -F, 'NR>1 && $1=="c1" {
    n++; if ($4==1) { d++; lat+=($5-$2); print "   seed",$3,": disparou tick",$5,
      "(latencia",$5-$2,") queda_max",$6 }
  }
  END { printf "   %d/%d dispararam. latencia media = %.1f ticks\n", d, n, (d?lat/d:-1) }' "$SAIDA"

echo ""
echo "== C2 (o teste central): confabulacao em ruido normal, sem imposto =="
awk -F, 'NR>1 && $1=="c2" {
    n++; if ($4==1) { d++; print "   seed",$3,": FALSO POSITIVO tick",$5,"queda_max",$6 }
  }
  END { printf "   %d/%d dispararam (falsos positivos)\n", d, n }' "$SAIDA"

echo ""
echo "== C3: colapso + recuperacao (imposto liga em 2000, desliga em 5000) =="
awk -F, 'NR>1 && $1=="c3" {
    n++; if ($4==1) { d++
      ativo = ($8==1) ? "AINDA ATIVO no fim" : "desligou"
      print "   seed",$3,": disparou tick",$5,"(latencia",$5-$2,")",ativo }
  }
  END { printf "   %d/%d dispararam\n", d, n }' "$SAIDA"
awk -F, 'NR>1 && $1=="c3" && $4==1 { n++; if ($8==0) desl++ }
  END { if (n) printf "   %d/%d que dispararam DESLIGARAM ate o fim da corrida\n", desl, n }' "$SAIDA"
echo "== fim =="
