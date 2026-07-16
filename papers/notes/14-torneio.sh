#!/bin/sh
# Nota 14 (Paper 2): o TORNEIO de invasao par-a-par do horizonte — a matriz
# 12x12 que a Fase 3 do ROADMAP (§3, "O que fazer") deixou como divida.
#
# Desenho (generaliza a invasao da nota 03, peso_espaco 0 x 3): a populacao
# comeca 50/50 com horizonte = HI e horizonte = HJ, e SO o horizonte difere —
# urgencia, peso_espaco, desconto e estrategia ficam pregados nas medias
# (#define), e TODA mutacao e desligada (heranca exata). Com dois valores de
# horizonte na populacao, hor_m no CSV E a frequencia:
#     freq(HJ) = (hor_m - HI) / (HJ - HI).
# Um binario, dois horizontes lidos do ambiente (TORN_HI/TORN_HJ) — 66 pares
# nao-ordenados (HI < HJ), sem recompilar.
#
# Por que pregar o desconto (ROADMAP §3.1): a profundidade efetiva e
# min(horizonte, 1/(1-desconto)). Com desconto solto, um bloco "compra"
# horizonte baixando o desconto e a compensacao contamina o contraste. Pregado
# em DESCONTO=0.80, o teto de profundidade efetiva e 1/(1-0.8)=5 — entao a
# PREDICAO ESTRUTURAL desta nota, registrada aqui antes de rodar:
#   T1: a vantagem do horizonte mais fundo SATURA perto de h~5; pares
#       HI,HJ ambos >= 5 devem empatar (freq perto de 0.5, deriva), e a linha
#       vencedora do torneio (o ESS aproximado) e um PLATO ~5..12, nao um pico.
#   T2: para HJ > HI com HI < 5, o mais fundo vence (freq(HJ) > 0.5) — a
#       corrida armamentista da Rainha Vermelha, ate o teto do desconto.
#   T3 (sanidade): pop cai monotonicamente com o horizonte tipico (custo de
#       grupo da Fase 3); e o par degenerado HI==HJ nao e rodado.
#
# Custo: 66 pares x NSEEDS seeds x TICKS ticks. Com NSEEDS=8, TICKS=6000,
# ~26 min de CPU (~2-3 min com NPROC=12). Nao entra no datasets/gerar.sh.
# Agregados em datasets/torneio.csv. Proveniencia:
#   git log -1 --oneline -- datasets/torneio.csv
#
#   sh papers/notes/14-torneio.sh                       # 8 seeds, 6000 ticks
#   SEEDS_LISTA="7" sh papers/notes/14-torneio.sh       # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-6000}
NPROC=${NPROC:-12}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
HMAX=12

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# 1. globais do torneio + leitura do ambiente (semear_blocos roda uma vez)
s=troca(src,
  "static void semear_blocos(void) {\n    n_blocos = 0;",
  "static int TORN_HI = 6, TORN_HJ = 6;   /* torneio: dois horizontes 50/50 */\n"
  "static void semear_blocos(void) {\n"
  "    { const char *a=getenv(\"TORN_HI\"), *c=getenv(\"TORN_HJ\");\n"
  "      if (a) TORN_HI=atoi(a); if (c) TORN_HJ=atoi(c); }\n"
  "    n_blocos = 0;")

# 2. so o horizonte varia; o resto pregado (rng01() preservado -> mesmo mundo)
s=troca(s,"b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
          "b->urgencia    = (rng01(), URGENCIA);")
s=troca(s,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
          "b->peso_espaco = (rng01(), PESO_ESPACO);")
s=troca(s,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
          "b->desconto    = (rng01(), DESCONTO);")
s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
          "b->horizonte   = (rng01(), ((n_blocos & 1) ? TORN_HJ : TORN_HI));")
s=troca(s,"b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */",
          "b->estrategia  = (rng01(), SIN_HONESTO);")

# 3. heranca exata: nenhuma mutacao (o horizonte fica com 2 valores para sempre)
s=troca(s,"cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);",
          "cria->urgencia    = pai->urgencia;")
s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
          "cria->peso_espaco = pai->peso_espaco;")
s=troca(s,"cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
          "cria->desconto    = pai->desconto;")
s=troca(s,"cria->horizonte   = muta_horizonte(pai->horizonte);",
          "cria->horizonte   = pai->horizonte;")
s=troca(s,"cria->estrategia  = muta_estrategia(pai->estrategia);",
          "cria->estrategia  = pai->estrategia;")
open(f"{tmp}/torn.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/torn" "$TMP/torn.c" 2>/dev/null

# Sanidade do patch: HI==HJ==6 -> todo bloco tem horizonte 6, logo hor_m == 6
# (a menos do arredondamento de sh*(1/pop) em float: tolerancia 0.01).
TORN_HI=6 TORN_HJ=6 "$TMP/torn" 7 50 0 --log "$TMP/san.csv" >/dev/null 2>&1
awk -F, 'NR>1 && ($6 < 5.99 || $6 > 6.01) { print "SANIDADE FALHOU tick "$2": hor_m="$6; bad=1 }
         END { exit bad+0 }' "$TMP/san.csv" \
  || { echo "patch quebrou: hor_m != HI com HI==HJ"; exit 1; }

# Resumo de UMA corrida: frequencia final de HJ (o horizonte MAIOR) na janela
# fim (T-300..T). freq = (hor_m - HI)/(HJ - HI). Tambem: pop final e fixou?
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0
  if (pop>0 && t>=T-300 && t<=T) { nf++; shor+=$6; spop+=$3 }
}
END {
  if (!nf) { printf "%s,%d,%d,-1,-1,-1,extinta\n", seed, HI, HJ; exit }
  hor=shor/nf; f=(hor-HI)/(HJ-HI)
  fixou = (f<0.02) ? "HI" : (f>0.98) ? "HJ" : "misto"
  printf "%s,%d,%d,%.4f,%.4f,%.1f,%s\n", seed, HI, HJ, f, hor, spop/nf, fixou
}
AWK

echo "== torneio: 66 pares x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/rows"
export TMP TICKS
# gera a lista de tarefas: "HI HJ SEED" para todo par HI<HJ e toda seed
for hi in $(seq 1 $HMAX); do
  for hj in $(seq $((hi+1)) $HMAX); do
    for s in $SEEDS; do echo "$hi $hj $s"; done
  done
done | xargs -P "$NPROC" -n 3 sh -c '
    TORN_HI="$1" TORN_HJ="$2" "$TMP/torn" "$3" "$TICKS" 0 \
      --log "$TMP/c_$1_$2_$3.csv" >/dev/null 2>&1 \
      || { echo "$1 $2 $3" >> "$TMP/falhas"; exit 0; }
    awk -F, -v seed="$3" -v HI="$1" -v HJ="$2" -v T="$TICKS" \
      -f "$TMP/resumo.awk" "$TMP/c_$1_$2_$3.csv" > "$TMP/rows/$1_$2_$3.row"
    rm -f "$TMP/c_$1_$2_$3.csv"
  ' _
if [ -s "$TMP/falhas" ]; then
    echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1
fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/torneio.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/torneio.csv"}
{
echo "seed,hi,hj,freq_hj,hor_m_fim,pop_fim,fixou"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== matriz de vitoria (media entre seeds; celula = freq do horizonte da COLUNA) =="
echo "   linha = HI (residente), coluna = HJ; >0.5 => a coluna, mais funda, vence"
awk -F, -v HMAX="$HMAX" 'NR>1 && $7!="extinta" {
    key=$2"_"$3; s[key]+=$4; n[key]++
    pk=$2; pp[pk]+=$6; pn[pk]++          # pop media por HI
  }
  END {
    printf "   HI\\HJ"; for (j=1;j<=HMAX;j++) printf " %4d", j; printf "\n"
    for (i=1;i<=HMAX;i++) {
      printf "   %4d ", i
      for (j=1;j<=HMAX;j++) {
        if (i==j) { printf "    ."; continue }
        a=i; b=j; inv=(i<j)?0:1        # so rodamos HI<HJ; espelha o outro lado
        if (i>j) { a=j; b=i }
        key=a"_"b
        if (!(key in n)) { printf "    -"; continue }
        f=s[key]/n[key]                # freq do horizonte MAIOR (b)
        v=(i<j)? f : 1-f               # freq do horizonte da COLUNA (j)
        printf " %4.2f", v
      }
      printf "\n"
    }
  }' "$SAIDA"

echo "== quem vence cada duelo (linha vence a coluna? conta de vitorias por horizonte) =="
awk -F, -v HMAX="$HMAX" 'NR>1 && $7!="extinta" {
    key=$2"_"$3; s[key]+=$4; n[key]++
  }
  END {
    for (i=1;i<=HMAX;i++) {
      win=0; tot=0
      for (j=1;j<=HMAX;j++) {
        if (i==j) continue
        a=(i<j)?i:j; b=(i<j)?j:i; key=a"_"b
        if (!(key in n)) continue
        f=s[key]/n[key]; fi=(i<j)? 1-f : f   # freq do horizonte i
        tot++; if (fi>0.5) win++
      }
      printf "   h=%2d vence %d de %d duelos\n", i, win, tot
    }
  }' "$SAIDA"
echo "== fim =="
