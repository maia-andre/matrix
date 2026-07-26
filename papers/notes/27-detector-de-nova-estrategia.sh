#!/bin/sh
# Nota 27 (eixo microscopio): "EMERGIU UMA NOVA ESTRATEGIA?" — terceiro
# modulo, o mais em aberto dos tres.
#
# As notas 24/25 detectaram mudanca de REGIME NA POPULACAO; a nota 26
# generalizou a deteccao de DUAS LINHAGENS no traco horizonte. Falta o
# terceiro exemplo do ROADMAP: "emergiu uma nova estrategia". Duas perguntas
# precisavam de resposta antes de codar (nao havia mecanismo pronto no
# projeto, ao contrario do imposto que ja servia de "colapso conhecido"):
#   (a) o que CONTA como estrategia nova? Escolhido: a fracao honesta da
#       populacao (hon_f), ja rastreada desde a nota 08 — honestidade e um
#       ESS sem multa (nota 08), entao um desvio sustentado dela E uma
#       mudanca de estrategia por definicao do proprio vocabulario do projeto.
#   (b) que CHOQUE conhecido move essa fracao? Inventado aqui: forcar TODO
#       nascimento, numa janela de ticks, a herdar SIN_BLEFE (nao SIN_HONESTO
#       nem a mutacao normal) — analogo ao imposto pigouviano das notas
#       15/21/24, so que a alavanca e a heranca de estrategia, nao a energia.
#
# O DETECTOR e o MESMO nucleo das notas 24/25 (janela recente x referencia
# sobre a propria historia), trocando "populacao" por "hon_f" — a mesma
# aritmetica, outro sinal.
#
# O QUE O PILOTO ENSINOU (dois pilotos nao commitados decidiram a escala de
# tempo, a mesma disciplina da nota 24). Um primeiro piloto ligou o choque em
# t=2000: a fracao honesta AINDA estava subindo rumo ao proprio equilibrio
# (semeada 1/3-1/3-1/3, sobe rapido nos primeiros milhares de ticks) —
# misturar transiente com choque deu uma queda ambigua (0,177, abaixo do
# limiar). Um segundo, medindo a corrida sem choque, achou que hon_f so
# assenta (~0,83-0,85) por volta de t=4000-8000 — bem mais lento que a
# populacao (que assenta em poucas centenas de ticks, nota 24). Com o choque
# em t=8000 (apos assentar) por 4000 ticks: hon_f cai de ~0,83 a ~0,42,
# dispara em 517 ticks (mais lento que a populacao — a alavanca aqui e
# substituicao demografica, nao efeito direto de energia), e recupera a
# ~0,80 em ~2500 ticks apos o choque sair.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   F0a (sanidade): sem forcar estrategia nenhuma, o detector nao muda a
#       simulacao — CSV --log bit a bit identico ao vanilla.
#   F0b (o choque muda o alvo certo): com FORCA ligada, hon_f cai; blef_f
#       sobe. Confirmado no piloto (nao re-verificado por seed aqui, e uma
#       consequencia direta e determinista da mudanca de heranca).
#   F1 (deteccao positiva): FORCA_INICIO=8000 (apos hon_f assentar), sem
#       desligar, total 13000 ticks: o detector DISPARA em >= 7/8 seeds
#       (o piloto deu queda de 26% numa seed so; margem generosa acima do
#       limiar de 20%, mas sem a garantia de saturacao total que a nota 25 so
#       viu apos varredura completa).
#   F2 (nao-confabulacao — o teste central do eixo, de novo): SEM forca
#       nenhuma, mesmo total de ticks, 8 seeds: o detector NAO dispara —
#       <= 1/8 (a flutuacao natural de hon_f no piloto ficou numa banda de
#       ~0,83-0,85, bem abaixo do limiar de 20% de queda relativa).
#   F3 (recuperacao): FORCA_INICIO=8000, FORCA_FIM=12000, total 16000 ticks:
#       o detector DISPARA (mesma deteccao do F1, >= 6/8) e, ao final da
#       corrida (4000 ticks depois do choque sair), ativo_no_fim = 0 em
#       >= 6/8 das que dispararam — o sinal desliga quando hon_f de fato
#       volta perto do equilibrio, como no piloto (recuperacao a ~0,80 em
#       ~2500 ticks).
#
# Custo: medido no piloto, ~65-85s/corrida dependendo da duracao. 8+8+8 = 24
# corridas => ~10-15 min com NPROC=16.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/detector-estrategia.csv
# (uma linha por condicao x seed).
#   git log -1 --oneline -- datasets/detector-estrategia.csv
#
#   sh papers/notes/27-detector-de-nova-estrategia.sh                 # lote completo
#   SEEDS_LISTA="7" sh papers/notes/27-detector-de-nova-estrategia.sh # fumaca (nao grava)
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

BLOCO = r"""
static long geral_t = 0;

/* ============ DETECTOR DE MUDANCA DE ESTRATEGIA (nota 27) ================ */
/* Mesmo nucleo das notas 24/25 (janela recente x referencia), trocando
 * "populacao" por "hon_f" — pura leitura da propria historia, sem RNG, sem
 * escrita no estado da simulacao. */
#define EST_JANELA 250
#define EST_VAO 500
#define EST_TAM (EST_JANELA*2+EST_VAO)
static double est_hist[EST_TAM];
static long   est_n = 0;
static int    est_disparou = 0;
static long   est_tick_disparo = -1;
static double est_queda_max = 0.0;
static long   est_tick_queda_max = -1;
static int    est_ativo_agora = 0;

static void est_tick(long t, double hon_f) {
    est_hist[t % EST_TAM] = hon_f;
    est_n++;
    if (est_n < EST_TAM) { est_ativo_agora = 0; return; }
    double recente = 0.0, referencia = 0.0;
    for (long k = t - EST_JANELA; k < t; k++)
        recente += est_hist[((k % EST_TAM) + EST_TAM) % EST_TAM];
    recente /= EST_JANELA;
    for (long k = t - EST_JANELA - EST_VAO - EST_JANELA; k < t - EST_VAO - EST_JANELA; k++)
        referencia += est_hist[((k % EST_TAM) + EST_TAM) % EST_TAM];
    referencia /= EST_JANELA;
    if (referencia <= 0.0) { est_ativo_agora = 0; return; }
    double queda = (referencia - recente) / referencia;
    est_ativo_agora = (queda >= 0.20) ? 1 : 0;
    if (est_ativo_agora && !est_disparou) { est_disparou = 1; est_tick_disparo = t; }
    if (queda > est_queda_max) { est_queda_max = queda; est_tick_queda_max = t; }
}

static void est_despeja(void) {
    const char *arq = getenv("EST_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim\n");
    fprintf(fp, "%d,%ld,%.4f,%ld,%d\n",
        est_disparou, est_tick_disparo, est_queda_max, est_tick_queda_max, est_ativo_agora);
    fclose(fp);
}
/* ========================== fim do detector =============================== */
"""

def patch(s):
    s = troca(s, "/*  PART 3", BLOCO + "\n/*  PART 3")
    s = troca(s,
      "        cria->estrategia  = muta_estrategia(pai->estrategia);",
      "        { static int lido=0; static long finicio=-1, ffim=0;\n"
      "          if (!lido) { const char *ii=getenv(\"FORCA_INICIO\"); if (ii) finicio=atol(ii);\n"
      "            const char *ff=getenv(\"FORCA_FIM\"); if (ff) ffim=atol(ff); lido=1; }\n"
      "          int forcar = (finicio >= 0) && (geral_t >= finicio) && (ffim <= 0 || geral_t < ffim);\n"
      "          cria->estrategia = forcar ? SIN_BLEFE : muta_estrategia(pai->estrategia);\n"
      "        }")
    s = troca(s,
      "            resolver();\n"
      "            aplicar_e_comer();",
      "            geral_t = t;\n"
      "            resolver();\n"
      "            aplicar_e_comer();\n"
      "            { int pop=0, nhon=0;\n"
      "              for (int i=0;i<n_blocos;i++) if (blocos[i].vivo) {\n"
      "                pop++; if (blocos[i].estrategia==SIN_HONESTO) nhon++; }\n"
      "              double hf = pop>0 ? (double)nhon/(double)pop : 0.0;\n"
      "              est_tick(t, hf); }")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    est_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

open(f"{tmp}/detector.c", "w").write(patch(src))
PY

gcc -std=c11 -O2 -o "$TMP/detector" "$TMP/detector.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# F0a: sem forca nenhuma, o detector NAO muda a simulacao.
"$TMP/vanilla"  7 2000 0 --log "$TMP/f0a_van.csv" >/dev/null 2>&1
"$TMP/detector" 7 2000 0 --log "$TMP/f0a_det.csv" >/dev/null 2>&1
cmp -s "$TMP/f0a_van.csv" "$TMP/f0a_det.csv" \
  || { echo "F0a FALHOU: o detector mudou a simulacao. PARAR."; exit 1; }
echo "   F0a ok: CSV bit a bit identico ao vanilla"

mkdir -p "$TMP/rows"
export TMP

echo "== corridas: $(echo $SEEDS | wc -w) x (F1 + F2 + F3) =="
{
  for s in $SEEDS; do echo "f1 8000 0    13000 $s"; done
  for s in $SEEDS; do echo "f2 -1   0    13000 $s"; done
  for s in $SEEDS; do echo "f3 8000 12000 16000 $s"; done
} | xargs -P "$NPROC" -n 5 sh -c '
    cond=$1; inicio=$2; fim=$3; ticks=$4; s=$5
    raw="$TMP/raw_${cond}_${s}"
    FORCA_INICIO="$inicio" FORCA_FIM="$fim" EST_ARQ="$raw" \
      "$TMP/detector" "$s" "$ticks" 0 >/dev/null 2>&1 \
      || { echo "$cond $s" >> "$TMP/falhas"; exit 0; }
    tail -n 1 "$raw" | awk -F, -v C="$cond" -v INI="$inicio" -v SEED="$s" \
      '"'"'{print C","INI","SEED","$0}'"'"' > "$TMP/rows/${cond}_${s}.row"
    rm -f "$raw"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/detector-estrategia.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/detector-estrategia.csv"}
{
echo "condicao,inicio,seed,disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== F1: deteccao positiva (forca de blefe em t=8000, sem desligar) =="
awk -F, 'NR>1 && $1=="f1" {
    n++; if ($4==1) { d++; lat+=($5-8000); print "   seed",$3,": disparou tick",$5,
      "(latencia",$5-8000,") queda_max",$6 }
  }
  END { printf "   %d/%d dispararam. latencia media = %.1f ticks\n", d, n, (d?lat/d:-1) }' "$SAIDA"

echo ""
echo "== F2 (o teste central): confabulacao em hon_f sem forca nenhuma =="
awk -F, 'NR>1 && $1=="f2" {
    n++; if ($4==1) { d++; print "   seed",$3,": FALSO POSITIVO tick",$5,"queda_max",$6 }
  }
  END { printf "   %d/%d dispararam (falsos positivos)\n", d, n }' "$SAIDA"

echo ""
echo "== F3: forca + recuperacao (liga em 8000, desliga em 12000) =="
awk -F, 'NR>1 && $1=="f3" {
    n++; if ($4==1) { d++
      ativo = ($8==1) ? "AINDA ATIVO no fim" : "desligou"
      print "   seed",$3,": disparou tick",$5,"(latencia",$5-8000,")",ativo }
  }
  END { printf "   %d/%d dispararam\n", d, n }' "$SAIDA"
awk -F, 'NR>1 && $1=="f3" && $4==1 { n++; if ($8==0) desl++ }
  END { if (n) printf "   %d/%d que dispararam DESLIGARAM ate o fim da corrida\n", desl, n }' "$SAIDA"
echo "== fim =="
