#!/bin/sh
# Reproduz a nota 33 (papers/notes/33-invasao-arrependimento-10-seeds.md).
#
# EXTENSAO DA NOTA 32 (pre-registro: ROADMAP.md Sec4.6, ANTES de rodar). A
# nota 32 rodou T1/T2 (invasao direta do arrependimento) em so 3 seeds e nao
# decidiu: 5 das 6 comparacoes mostraram a assinatura de efeito fundador (a
# paridade do indice vence nas duas montagens espelhadas, nao o valor do
# traco). Esta nota reaproveita o MESMO desenho exato (50/50, SEM mutacao no
# traco, montagens espelhadas por paridade de indice, 30000 ticks), so com
# 10 seeds novas e sequenciais (1..10, convencao da nota 11) em vez das 3
# seeds da nota 32. Nenhum mecanismo novo -- e o main.c de hoje, o mesmo
# harness 'invasao'.
#
#   Criterio de decisao (declarado ANTES de rodar, ROADMAP Sec4.6):
#   por comparacao (T1, T2), conte quantas das 10 seeds tem o MESMO valor
#   vencendo nas duas montagens espelhadas, independente de paridade.
#     >=7/10: confirma
#     4-6/10: nao decide (mantem a duvida da nota 32)
#     <=3/10: le como efeito fundador puro (a leitura que a nota 32 ja deu a 1/6)
#
#   sh papers/notes/33-invasao-arrependimento-10-seeds.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS_LISTA:-"1 2 3 4 5 6 7 8 9 10"}
TICKS_LONGO=${TICKS_OVERRIDE:-30000}

# gen MODO VALOR -- identico ao harness 'invasao' das notas 30/32; so pina os
# dois valores em competicao, sem mutacao no traco.
gen() {
python3 - "$MAINC" "$TMP" "$1" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; valor = sys.argv[3]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    return t.replace(a, b, 1)

SEM_ORIG = "        b->peso_arrependimento = (rng01() - 0.5f) * 4.0f;          /* -2..2, folga */\n"
MUT_ORIG = ("        cria->peso_arrependimento =\n"
            "            muta_traco(pai->peso_arrependimento, 2.0f * MUTACAO, -6.0f, 6.0f);\n")

res, inv = valor.split(",")
s = troca(src, SEM_ORIG,
    "        b->peso_arrependimento = (rng01() - 0.5f) * 4.0f;   /* descartado */\n"
    f"        b->peso_arrependimento = (n_blocos % 2) ? {inv}f : {res}f;   /* invasao 50/50 */\n")
s = troca(s, MUT_ORIG,
    "        cria->peso_arrependimento =\n"
    "            (muta_traco(pai->peso_arrependimento, 2.0f * MUTACAO, -6.0f, 6.0f), "
    "pai->peso_arrependimento);   /* SEM mutacao no traco: invasao limpa */\n")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/bin" "$TMP/v.c"
}

valor_tick() { awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"; }

# roda uma comparacao completa (duas montagens espelhadas, 10 seeds) e classifica
rodar_comparacao() {
  nome=$1; vres=$2; vinv=$3; mid=$4
  printf '\n  %s: peso %s (residente, pares) x %s (invasor, impares), 50/50, sem mutacao\n' "$nome" "$vres" "$vinv"
  printf '  arrep_m (col 24) em t=0 e t=%s\n\n' "$TICKS_LONGO"
  gen "$vres,$vinv"; mv "$TMP/bin" "$TMP/${nome}_A"
  gen "$vinv,$vres"; mv "$TMP/bin" "$TMP/${nome}_B"
  real=0; fundador=0
  for s in $SEEDS; do
    "$TMP/${nome}_A" "$s" "$TICKS_LONGO" 0 --log "$TMP/${nome}_A_$s.csv" >/dev/null
    "$TMP/${nome}_B" "$s" "$TICKS_LONGO" 0 --log "$TMP/${nome}_B_$s.csv" >/dev/null
    afA=$(valor_tick "$TMP/${nome}_A_$s.csv" 24 $((TICKS_LONGO-1)))
    afB=$(valor_tick "$TMP/${nome}_B_$s.csv" 24 $((TICKS_LONGO-1)))
    # A: residente(par)=vres, invasor(impar)=vinv -- winner = vres se af < mid, senao vinv
    wA=$(awk -v af="$afA" -v mid="$mid" -v vr="$vres" -v vi="$vinv" 'BEGIN{print (af<mid)?vr:vi}')
    # B: residente(par)=vinv, invasor(impar)=vres -- winner = vinv se af < mid, senao vres
    wB=$(awk -v af="$afB" -v mid="$mid" -v vr="$vres" -v vi="$vinv" 'BEGIN{print (af<mid)?vi:vr}')
    if [ "$wA" = "$wB" ]; then
      classe="REAL (vencedor=$wA, indep. de paridade)"
      real=$((real+1))
    else
      classe="FUNDADOR (paridade decide, nao o valor)"
      fundador=$((fundador+1))
    fi
    printf '      seed %-3s  A: %7s -> %7s  B: %7s -> %7s  %s\n' "$s" "$vres,$vinv" "$afA" "$vinv,$vres" "$afB" "$classe"
  done
  printf '\n  %s: REAL=%d/10  FUNDADOR=%d/10  ->  ' "$nome" "$real" "$fundador"
  if [ "$real" -ge 7 ]; then echo "CONFIRMA (>=7/10)"
  elif [ "$real" -ge 4 ]; then echo "NAO DECIDE (4-6/10)"
  else echo "FUNDADOR PURO (<=3/10)"; fi
}

printf '\n  nota 33 -- extensao da invasao do arrependimento (10 seeds: %s)\n' "$SEEDS"

rodar_comparacao "T1" "-2.0" "0.0" "-1.0"
rodar_comparacao "T2" "-2.0" "2.0" "0.0"

echo ""
echo "== fim de T1/T2. Decida T3 (agencia negativo x zero) a partir do placar acima =="
