#!/bin/sh
# Reproduz a tabela da nota 01 (papers/notes/01-quatro-modos-de-errar.md).
#
# Nao existe um "experiment_001.c": ha UM main.c canonico, e as ablacoes sao
# patches aplicados a uma copia dele num diretorio temporario. Assim o achado
# continua reproduzivel sem duplicar o nucleo da fisica.
#
#   sh papers/notes/01-ablacoes.sh                   (main.c atual; ~1 min)
#
# Aceita um main.c alternativo como argumento — e e assim que a evidencia do
# mostrador QUEBRADO sobrevive ao proprio conserto, sem checkout destrutivo:
#
#   git show 6da8c3a:main.c > /tmp/main_quebrado.c
#   sh papers/notes/01-ablacoes.sh /tmp/main_quebrado.c
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,638" e relê como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]

def troca(txt, a, b):
    assert a in txt, f"ancora nao encontrada: {a[:60]!r} (o main.c mudou?)"
    return txt.replace(a, b, 1)

# controle
open(f"{tmp}/ctl.c", "w").write(src)

# A: horizonte lobotomizado -- o mapa so enxerga 1 passo a frente
open(f"{tmp}/h1.c", "w").write(troca(src,
    "for (int h = 0; h < b->horizonte; h++) {",
    "for (int h = 0; h < 1; h++) {"))

# B: sem modelo de mundo nenhum -- prever_valor nao promete nada
open(f"{tmp}/zero.c", "w").write(troca(src, "\n    return valor;\n", "\n    return 0.0f;\n"))

# C: solipsista -- o bloco nao PERCEBE outros blocos (eles ainda o bloqueiam)
s = troca(src, "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
               "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
               "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
s = troca(s,   "static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
               "static int pretendentes_em(int cx, int cy, int self_i) {\n"
               "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
open(f"{tmp}/solip.c", "w").write(s)

# D: sem a crenca falsa 'partilha' (rivais ainda sao percebidos, para 'espaco')
open(f"{tmp}/nopart.c", "w").write(troca(src,
    "#define COMPETICAO  0.5f", "#define COMPETICAO  0.0f"))
PY

for v in ctl h1 zero solip nopart; do
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

# media de uma coluna do CSV enquanto a populacao vive (col 3 = pop)
media() { awk -F, -v c="$2" 'NR>1 && $2>20 && $3>0 {s+=$c; n++} END{if(n) printf "%.3f", s/n; else printf "  --"}' "$1"; }

printf '\n  mostradores por ablacao (media de %s ticks; seeds %s)\n\n' "$TICKS" "$SEEDS"
printf '  %-34s %8s %8s %11s %8s %8s\n' condicao modelo agencia automodelo phi 'pop fim'
printf '  %s\n' '----------------------------------------------------------------------------------'

linha() {
    printf '  %-34s' "$2"
    for col in 14 15 16 17; do
        tot=0; for s in $SEEDS; do
            v=$(media "$TMP/$1_$s.csv" $col); tot=$(awk -v a="$tot" -v b="$v" 'BEGIN{print (b=="  --")?a:a+b}')
        done
        awk -v t="$tot" 'BEGIN{printf "%9.3f", t/3}'
    done
    pop=$(tail -1 "$TMP/${1}_7.csv" | cut -d, -f3); printf '%9s\n' "$pop"
}

for v in ctl h1 zero solip nopart; do
    for s in $SEEDS; do "$TMP/$v" "$s" "$TICKS" 0 --log "$TMP/${v}_${s}.csv" >/dev/null 2>&1 || true; done
done

linha ctl    'controle (mapa intacto)'
linha h1     'A. horizonte=1 (mapa raso)'
linha zero   'B. prever_valor=0 (sem mapa)'
linha solip  'C. solipsista (nao ve rivais)'
linha nopart 'D. COMPETICAO=0 (sem partilha)'

printf '\n  B: sem modelo de mundo nenhum, a populacao se extingue -- e "modelo" deve ler ~0.\n'
printf '  C: agencia e automodelo devem ler ZERO exato (ver a nota 01, secao 3).\n\n'
