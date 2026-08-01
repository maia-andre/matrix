#!/bin/sh
# Reproduz a nota 34 (papers/notes/34-invasao-arrependimento-t2-20-seeds.md).
#
# SEGUNDA EXTENSAO DE T2 (pre-registro: ROADMAP.md Sec4.7, ANTES de rodar). A
# nota 33 fechou T1 (fundador puro, 1/10) mas deixou T2 (-2,0 x 2,0) em 6/10 --
# sub-limiar, mas as seis corridas "reais" concordam na direcao que a nota 30
# (Q5) apostou. So T2 e' rerodado aqui -- T1 ja esta' decidido e nao precisa de
# mais seeds. MESMO desenho exato (50/50, SEM mutacao no traco, montagens
# espelhadas por paridade de indice, 30000 ticks), 20 seeds novas e sequenciais
# (11..30, continuando a serie 1..10 da nota 33 -- convencao da nota 11).
# Nenhum mecanismo novo -- mesmo main.c, mesmo harness 'invasao'.
#
#   Criterio de decisao (declarado ANTES de rodar, ROADMAP Sec4.7):
#     standalone (as 20 novas sozinhas):  >=14/20 confirma, 7-13/20 nao decide, <=6/20 fundador puro
#     pool (20 novas + as 10 ja publicadas na nota 33 -- 6 REAL de 10):
#                                          >=21/30 confirma, 10-20/30 nao decide, <=9/30 fundador puro
#   Se as duas bandas discordarem, o POOL decide (mais poder estatistico); o
#   standalone entra como replica independente, nao como segundo veredito.
#
#   sh papers/notes/34-invasao-arrependimento-t2-20-seeds.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS_LISTA:-"11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30"}
TICKS_LONGO=${TICKS_OVERRIDE:-30000}

# REAL de T2 ja publicado na nota 33 (seeds 1..10, sem rerodar -- deterministico):
# seeds 2,3,4,6,8,9 = REAL (6); seeds 1,5,7,10 = FUNDADOR (4).
NOTA33_REAL=6
NOTA33_N=10

# gen MODO VALOR -- identico ao harness 'invasao' das notas 30/32/33; so pina
# os dois valores em competicao, sem mutacao no traco.
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

nome="T2"; vres="-2.0"; vinv="2.0"; mid="0.0"
printf '\n  %s: peso %s (residente, pares) x %s (invasor, impares), 50/50, sem mutacao\n' "$nome" "$vres" "$vinv"
printf '  20 seeds novas (%s) -- as 10 da nota 33 nao sao rerodadas (deterministico)\n' "$SEEDS"
printf '  arrep_m (col 24) em t=0 e t=%s\n\n' "$TICKS_LONGO"

gen "$vres,$vinv"; mv "$TMP/bin" "$TMP/${nome}_A"
gen "$vinv,$vres"; mv "$TMP/bin" "$TMP/${nome}_B"
real=0; fundador=0
for s in $SEEDS; do
  "$TMP/${nome}_A" "$s" "$TICKS_LONGO" 0 --log "$TMP/${nome}_A_$s.csv" >/dev/null
  "$TMP/${nome}_B" "$s" "$TICKS_LONGO" 0 --log "$TMP/${nome}_B_$s.csv" >/dev/null
  afA=$(valor_tick "$TMP/${nome}_A_$s.csv" 24 $((TICKS_LONGO-1)))
  afB=$(valor_tick "$TMP/${nome}_B_$s.csv" 24 $((TICKS_LONGO-1)))
  # winner = o VALOR (nao o papel) para o qual arrep_m convergiu -- mesma
  # formula nas duas montagens (o bug da nota 33 estava em usar formulas
  # diferentes para A e B; aqui wA e wB sao identicas por construcao).
  wA=$(awk -v af="$afA" -v mid="$mid" -v vr="$vres" -v vi="$vinv" 'BEGIN{print (af<mid)?vr:vi}')
  wB=$(awk -v af="$afB" -v mid="$mid" -v vr="$vres" -v vi="$vinv" 'BEGIN{print (af<mid)?vr:vi}')
  if [ "$wA" = "$wB" ]; then
    classe="REAL (vencedor=$wA, indep. de paridade)"
    real=$((real+1))
  else
    classe="FUNDADOR (paridade decide, nao o valor)"
    fundador=$((fundador+1))
  fi
  printf '      seed %-3s  A: %7s -> %7s  B: %7s -> %7s  %s\n' "$s" "$vres,$vinv" "$afA" "$vinv,$vres" "$afB" "$classe"
done

n_novas=$((real+fundador))
printf '\n  standalone (20 novas): REAL=%d/%d  FUNDADOR=%d/%d  ->  ' "$real" "$n_novas" "$fundador" "$n_novas"
if [ "$real" -ge 14 ]; then echo "CONFIRMA (>=14/20)"
elif [ "$real" -ge 7 ]; then echo "NAO DECIDE (7-13/20)"
else echo "FUNDADOR PURO (<=6/20)"; fi

pool_real=$((real+NOTA33_REAL))
pool_n=$((n_novas+NOTA33_N))
printf '  pool (20 novas + %d/%d da nota 33): REAL=%d/%d  ->  ' "$NOTA33_REAL" "$NOTA33_N" "$pool_real" "$pool_n"
if [ "$pool_real" -ge 21 ]; then echo "CONFIRMA (>=21/30)"
elif [ "$pool_real" -ge 10 ]; then echo "NAO DECIDE (10-20/30)"
else echo "FUNDADOR PURO (<=9/30)"; fi

echo ""
echo "== fim de T2. O POOL decide (ROADMAP Sec4.7); T3 so roda se o pool confirmar =="
