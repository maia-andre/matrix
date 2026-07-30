#!/bin/sh
# Reproduz a nota 32 (papers/notes/32-invasao-arrependimento.md).
#
# A INVASAO DIRETA DO ARREPENDIMENTO (pre-registro: ROADMAP.md Sec4.5, ANTES de
# rodar). A nota 30 (Q3/Q4) testou peso_arrependimento positivo x zero e nao
# achou vencedor (invasao 50/50, placar exato 3x3). Mas a mesma nota (Q5),
# semeando o traco livre com mutacao, achou a selecao convergindo para
# NEGATIVO nas tres seeds -- a regiao errada do dominio, que Q3/Q4 nunca
# testaram. Fecha-se o argumento com uma invasao direta: MESMO desenho exato
# do Q4 da nota 30 (50/50, SEM mutacao no traco, montagens espelhadas por
# paridade de indice, 3 seeds, 30000 ticks), so trocando os valores. Nenhum
# mecanismo novo -- e o main.c de hoje, o mesmo harness 'invasao'.
#
#   T1 (negativo vs. zero): -2.0 desloca 0.0 de forma consistente.
#   T2 (negativo vs. positivo): -2.0 desloca 2.0.
#   T3 (condicional, so roda se T1 e/ou T2 confirmarem): blocos fortemente
#      negativos mostram agencia mais baixa que blocos em zero.
#
#   sh papers/notes/32-invasao-arrependimento.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS_LONGO=30000

# gen MODO VALOR -- identico ao harness 'invasao' da nota 30 (main.c ja tem
# peso_arrependimento canonico desde a nota 30; so pinamos os dois valores em
# competicao, sem mutacao no traco).
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

printf '\n  nota 32 -- invasao direta do arrependimento (seeds %s)\n' "$SEEDS"

printf '\n  T1-invasao: peso -2.0 (residente, pares) x 0.0 (invasor, impares), 50/50, sem mutacao\n'
printf '  arrep_m (col 24) em t=0 e t=%s\n\n' "$TICKS_LONGO"
gen "-2.0,0.0"; mv "$TMP/bin" "$TMP/t1_neg_vs_zero"
gen "0.0,-2.0"; mv "$TMP/bin" "$TMP/t1_zero_vs_neg"
for par in "-2,0 residente / 0,0 invasor:t1_neg_vs_zero" "0,0 residente / -2,0 invasor:t1_zero_vs_neg"; do
  desc=${par%%:*}; bin=${par##*:}
  printf '      %s\n' "$desc"
  for s in $SEEDS; do
    "$TMP/$bin" "$s" "$TICKS_LONGO" 0 --log "$TMP/${bin}_$s.csv" >/dev/null
    a0=$(valor_tick "$TMP/${bin}_$s.csv" 24 0)
    af=$(valor_tick "$TMP/${bin}_$s.csv" 24 $((TICKS_LONGO-1)))
    printf '      %-8s arrep_m: %7s -> %7s\n' "$s" "$a0" "$af"
  done
done

printf '\n  T2-invasao: peso -2.0 (residente, pares) x 2.0 (invasor, impares), 50/50, sem mutacao\n'
printf '  arrep_m (col 24) em t=0 e t=%s\n\n' "$TICKS_LONGO"
gen "-2.0,2.0"; mv "$TMP/bin" "$TMP/t2_neg_vs_pos"
gen "2.0,-2.0"; mv "$TMP/bin" "$TMP/t2_pos_vs_neg"
for par in "-2,0 residente / 2,0 invasor:t2_neg_vs_pos" "2,0 residente / -2,0 invasor:t2_pos_vs_neg"; do
  desc=${par%%:*}; bin=${par##*:}
  printf '      %s\n' "$desc"
  for s in $SEEDS; do
    "$TMP/$bin" "$s" "$TICKS_LONGO" 0 --log "$TMP/${bin}_$s.csv" >/dev/null
    a0=$(valor_tick "$TMP/${bin}_$s.csv" 24 0)
    af=$(valor_tick "$TMP/${bin}_$s.csv" 24 $((TICKS_LONGO-1)))
    printf '      %-8s arrep_m: %7s -> %7s\n' "$s" "$a0" "$af"
  done
done

echo ""
echo "== fim de T1/T2. Decida T3 (agencia negativo x zero) a partir do placar acima =="
