#!/bin/sh
# Reproduz a nota 09 (papers/notes/09-o-self-ja-estava-la.md).
#
# Roda as quatro predicoes do pre-registro (ROADMAP §5.0, commitado ANTES do
# codigo do mostrador) para 'autocausa' — o bloco modelar-se como CAUSA ("a
# celula vai empobrecer porque EU vou comer dela") muda a escolha dele?
#
#   P1  EREMITA: autocausa > 0 na solidao. Seria o PRIMEIRO mostrador da bateria
#       a sobreviver ao teste do eremita — e decide o item 9 do ROADMAP (a
#       bifurcacao (A) aquisicao de faculdades x (B) escalada de um conflito).
#   P2  SANIDADE: horizonte = 1 => autocausa = 0 EXATO. Quem nao olha alem da
#       propria garfada nao tem onde se modelar. O self exige um futuro.
#   P3  Simulacao bit-a-bit identica (sigma = 1 e o codigo de hoje): verificada
#       fora daqui, contra datasets/seed7.csv.
#   P4  autocausa NAO desbota como a agencia (nota 03): sigma nao e traco, e
#       estrutura da previsao — e o horizonte SOBE sob selecao.
#
# Como as demais notas: nao ha experiment_00N.c; as variantes sao patches numa
# copia temporaria do main.c canonico.
#
#   sh papers/notes/09-autocausa.sh
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,354" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

AC=21   # coluna autocausa
AG=15   # coluna agencia
HM=6    # coluna hor_m

# media da coluna $2 enquanto a populacao vive; ignora o transiente (tick > 20)
media() { awk -F, -v c="$2" 'NR>1 && $2>20 && $3>0 {s+=$c; n++} END{if(n) printf "%.4f", s/n; else printf "  --"}' "$1"; }
maxc()  { awk -F, -v c="$2" 'NR>1 {if($c>m)m=$c} END{printf "%.4f", m}' "$1"; }
# media da coluna $2 numa janela de ticks [$3, $4]
janela() { awk -F, -v c="$2" -v a="$3" -v b="$4" 'NR>1 && $2>=a && $2<=b && $3>0 {s+=$c; n++} END{if(n) printf "%.4f", s/n; else printf "  --"}' "$1"; }

gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/base" "$MAINC"

# ---- variante EREMITA (§1.5): nao percebe rivais NEM pretendentes ------------
python3 - "$MAINC" "$TMP/eremita.c" <<'PY'
import sys
src=open(sys.argv[1]).read()
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:50]!r} (o main.c mudou?)"
    return t.replace(a,b,1)
s=troca(src,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
            "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
            "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
          "static int pretendentes_em(int cx, int cy, int self_i) {\n"
          "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
open(sys.argv[2],"w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/eremita" "$TMP/eremita.c"

# ---- variante HORIZONTE = 1: o teto do horizonte cai para 1 -------------------
# Uma linha so: HORIZONTE_MAX 1 faz o sorteio inicial (1 + rng01()*MAX) e a
# mutacao (clamp em [1,MAX]) entregarem 1 sempre. As chamadas de rng01() ficam
# de pe, entao o fluxo do RNG nao se desloca.
python3 - "$MAINC" "$TMP/h1.c" <<'PY'
import sys
src=open(sys.argv[1]).read()
a="#define HORIZONTE_MAX 12"
assert a in src, "ancora sumiu: HORIZONTE_MAX (o main.c mudou?)"
open(sys.argv[2],"w").write(src.replace(a,"#define HORIZONTE_MAX 1",1))
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/h1" "$TMP/h1.c"

echo
echo "=============================================================="
echo " NOTA 09 — autocausa: o self ja estava la"
echo " $TICKS ticks, seeds: $SEEDS"
echo "=============================================================="
echo
echo "--- P1: o TESTE DO EREMITA (a predicao que decide o item 9) ---"
echo "Os outros mostradores relacionais zeram na solidao. Este?"
echo
printf "  %-8s | %-22s | %-22s\n" "seed" "autocausa (normal)" "autocausa (EREMITA)"
printf "  %-8s-+-%-22s-+-%-22s\n" "--------" "----------------------" "----------------------"
for s in $SEEDS; do
    "$TMP/base"    "$s" "$TICKS" 0 --log "$TMP/b_$s.csv"  >/dev/null 2>&1
    "$TMP/eremita" "$s" "$TICKS" 0 --log "$TMP/e_$s.csv"  >/dev/null 2>&1
    printf "  %-8s | %-22s | %-22s\n" "$s" "$(media "$TMP/b_$s.csv" $AC)" "$(media "$TMP/e_$s.csv" $AC)"
done
echo
echo "  (para contraste, na MESMA rodada do eremita — os que zeram:)"
printf "  %-8s | %-22s | %-22s\n" "seed" "agencia (EREMITA)" "modelo_do_outro (EREM.)"
printf "  %-8s-+-%-22s-+-%-22s\n" "--------" "----------------------" "----------------------"
for s in $SEEDS; do
    printf "  %-8s | %-22s | %-22s\n" "$s" "$(maxc "$TMP/e_$s.csv" $AG)" "$(maxc "$TMP/e_$s.csv" 16)"
done
echo "  (estes sao MAXIMOS, nao medias: zero no maximo e zero em todo tick.)"

echo
echo "--- P2: a SANIDADE — horizonte = 1 TEM de zerar (o self exige um futuro) ---"
echo
printf "  %-8s | %-16s | %-16s | %-16s\n" "seed" "hor_m (h=1)" "autocausa media" "autocausa MAX"
printf "  %-8s-+-%-16s-+-%-16s-+-%-16s\n" "--------" "----------------" "----------------" "----------------"
for s in $SEEDS; do
    "$TMP/h1" "$s" "$TICKS" 0 --log "$TMP/h_$s.csv" >/dev/null 2>&1
    printf "  %-8s | %-16s | %-16s | %-16s\n" "$s" \
        "$(media "$TMP/h_$s.csv" $HM)" "$(media "$TMP/h_$s.csv" $AC)" "$(maxc "$TMP/h_$s.csv" $AC)"
done
echo "  MAX = 0.0000 e a condicao de falseamento cumprida: nao ha UM tick,"
echo "  em nenhuma seed, em que um bloco de horizonte 1 se modele como causa."

echo
echo "--- P4: autocausa desbota como a agencia? (a predicao arriscada) ---"
echo "A agencia morre porque peso_espaco -> 0 sob selecao. Sigma nao e traco."
echo
printf "  %-6s | %-11s %-11s | %-11s %-11s | %-11s\n" \
    "seed" "AC inicio" "AC fim" "AG inicio" "AG fim" "hor_m fim"
printf "  %-6s-+-%-11s-%-11s-+-%-11s-%-11s-+-%-11s\n" \
    "------" "-----------" "-----------" "-----------" "-----------" "-----------"
for s in $SEEDS; do
    printf "  %-6s | %-11s %-11s | %-11s %-11s | %-11s\n" "$s" \
        "$(janela "$TMP/b_$s.csv" $AC 20 300)"   "$(janela "$TMP/b_$s.csv" $AC 2700 3000)" \
        "$(janela "$TMP/b_$s.csv" $AG 20 300)"   "$(janela "$TMP/b_$s.csv" $AG 2700 3000)" \
        "$(janela "$TMP/b_$s.csv" $HM 2700 3000)"
done

echo
echo "--- P5 (nao pre-registrada): e tudo isso ARREDONDAMENTO? ---"
echo "A regua roda em float32. Um zero que nao e zero, ou um nao-zero que"
echo "e so ruido de bit, derrubaria P1. Recomputamos os mostradores em"
echo "DOUBLE (so a comparacao; o mundo segue em float, bit-a-bit o mesmo)."
echo

# eremita + a comparacao da AGENCIA em double
python3 - "$TMP/eremita.c" "$TMP/ag_dbl.c" <<'PY'
import sys
s=open(sys.argv[1]).read()
def t(x,a,b):
    assert a in x, f"ancora sumiu: {a[:50]!r}"
    return x.replace(a,b,1)
s=t(s,"        float lam = b->peso_espaco * (float)p / (float)(AG_PASSOS - 1);\n"
      "        int   arg = 0;\n"
      "        float melhor = (C[0] + lam * E[0]) / K[0];",
      "        double lam = (double)b->peso_espaco * (double)p / (double)(AG_PASSOS - 1);\n"
      "        int   arg = 0;\n"
      "        double melhor = ((double)C[0] + lam * (double)E[0]) / (double)K[0];")
s=t(s,"            float nota = (C[k] + lam * E[k]) / K[k];",
      "            double nota = ((double)C[k] + lam * (double)E[k]) / (double)K[k];")
open(sys.argv[2],"w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/ag_dbl" "$TMP/ag_dbl.c"

# eremita + a comparacao da AUTOCAUSA em double
python3 - "$TMP/eremita.c" "$TMP/ac_dbl.c" <<'PY'
import sys
s=open(sys.argv[1]).read()
a=("        float sig = (float)p / (float)(AC_PASSOS - 1);   /* 0 .. 1 */\n"
   "        int   arg = 0;\n"
   "        float melhor = utilidade_sigma(cx[0], cy[0], b, sig);   /* parado: K = 1 */\n"
   "        for (int k = 1; k < n; k++) {\n"
   "            float u = utilidade_sigma(cx[k], cy[k], b, sig);\n"
   "            u /= 1.0f + ANTECIPACAO * (float)pret[k];")
b=("        float sig = (float)p / (float)(AC_PASSOS - 1);   /* 0 .. 1 */\n"
   "        int   arg = 0;\n"
   "        double melhor = (double)utilidade_sigma(cx[0], cy[0], b, sig);\n"
   "        for (int k = 1; k < n; k++) {\n"
   "            double u = (double)utilidade_sigma(cx[k], cy[k], b, sig);\n"
   "            u /= 1.0 + (double)ANTECIPACAO * (double)pret[k];")
assert a in s, "ancora sumiu: o laco da autocausa (o main.c mudou?)"
open(sys.argv[2],"w").write(s.replace(a,b,1))
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/ac_dbl" "$TMP/ac_dbl.c"

echo "  Tudo no EREMITA (onde a verdade algebrica e conhecida):"
echo
printf "  %-6s | %-19s | %-19s\n" "" "agencia (MAX)" "autocausa (media)"
printf "  %-6s | %-9s %-9s | %-9s %-9s\n" "seed" "float32" "double" "float32" "double"
printf "  %-6s-+-%-9s-%-9s-+-%-9s-%-9s\n" "------" "---------" "---------" "---------" "---------"
for s in $SEEDS; do
    "$TMP/ag_dbl" "$s" "$TICKS" 0 --log "$TMP/agd_$s.csv" >/dev/null 2>&1
    "$TMP/ac_dbl" "$s" "$TICKS" 0 --log "$TMP/acd_$s.csv" >/dev/null 2>&1
    printf "  %-6s | %-9s %-9s | %-9s %-9s\n" "$s" \
        "$(maxc  "$TMP/e_$s.csv"   $AG)" "$(maxc  "$TMP/agd_$s.csv" $AG)" \
        "$(media "$TMP/e_$s.csv"   $AC)" "$(media "$TMP/acd_$s.csv" $AC)"
done
echo
echo "  AGENCIA: o nao-zero do eremita e ARREDONDAMENTO. Em double, zero exato."
echo "    A demonstracao da nota 01 §3 (o termo do espaco vira constante entre as"
echo "    celulas e 'some do argmax') vale em R, nao em float32: somar a MESMA"
echo "    constante a duas utilidades quase empatadas pode inverter qual e"
echo "    estritamente maior. O Apendice A da v3 dizia '0 exato'. E 0 exato em R,"
echo "    com um piso de ~0,003 na regua como ela foi construida. Errata na nota 01."
echo "  AUTOCAUSA: identica ate o ultimo digito. P1 NAO e artefato de bit."
echo "    (E o zero da P2 e exato POR CONSTRUCAO: com horizonte 1 o termo do self"
echo "     nem chega a entrar no valor — o mesmo float sai para todo sigma.)"
echo
echo "=============================================================="
