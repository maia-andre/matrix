#!/bin/sh
# Reproduz a nota 36 (papers/notes/36-a-ablacao-do-id.md).
#
# A ABLACAO DO ID (pre-registro: ROADMAP.md Sec4.9, ANTES de rodar). A Sec3 da
# FILOSOFIA_v3 cobra de toda palavra emprestada a mesma entrada -- "que ablacao
# a zera? e ela carrega comportamento?" -- e admite por escrito que o id nunca
# a pagou. Este e' o ultimo item de pesquisa antes de a v3 poder fechar.
#
# O id = o termo comida_prev * (1 + urgencia * fome). A algebra (Sec4.9) diz
# que urgencia NAO tem canal proprio: o ranking e' invariante a reescalar tudo
# por um fator comum, entao a unica coisa que ela faz e' ENCOLHER os termos que
# nao sao comida (espaco e arrependimento, os dois multiplicados por espaco).
#
#   ctl       urgencia livre    peso_espaco livre           remorso normal
#   id0       urgencia = 0      peso_espaco livre           remorso normal
#   fesp      urgencia livre    peso_espaco = PESO_ESPACO   remorso normal
#   fesp_id0  urgencia = 0      peso_espaco = PESO_ESPACO   remorso normal
#   deg       urgencia livre    peso_espaco = 0             remorso = 0
#   deg_id0   urgencia = 0      peso_espaco = 0             remorso = 0
#
#   D1  fesp x fesp_id0: com o canal aberto a' forca, a ablacao carrega
#       comportamento -- pop final menor em >=6/8 seeds. Se nao, o id NAO paga
#       a entrada e a Sec3 tem de dizer isso.
#   D2  |dpop(ctl,id0)| < |dpop(fesp,fesp_id0)| em >=6/8: a selecao ja fechou o
#       canal (peso_espaco -> 0,095, nota 12).
#   D3  no tick 200 (antes de a selecao derrubar peso_espaco), ctl x id0 ja
#       diferem, na mesma direcao de D1. Lido dos MESMOS CSVs.
#   D4  deg x deg_id0 sao identicos BIT A BIT (urgencia sem canal). Se diferirem
#       so em colunas de mostrador, localiza qual mostrador le MAGNITUDE e nao
#       ORDEM -- achado nos dois casos.
#
# Toda pregacao preserva o rng01() descartado (idioma da nota 12) e usa
# muta_traco(v, 0.0f, ...), que consome exatamente um rng01() como o original.
# Patch temporario compilado em tmpdir -- o main.c do repo NAO e' tocado.
#
#   sh papers/notes/36-a-ablacao-do-id.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS_LISTA:-"1 2 3 4 5 6 7 8"}
TICKS=${TICKS_OVERRIDE:-30000}
T_CEDO=${T_CEDO:-200}

COND="ctl id0 fesp fesp_id0 deg deg_id0"

gen() {
python3 - "$MAINC" "$TMP" "$1" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; cond = sys.argv[3]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua ({t.count(a)}x): {a[:70]!r}"
    return t.replace(a, b, 1)

URG_SEM = "        b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */\n"
ESP_SEM = "        b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */\n"
URG_MUT = "        cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);\n"
ESP_MUT = "        cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);\n"
REMORSO = "        remorso[i] = remorso[i] * blocos[i].desconto + arrependimento;\n"

s = src

# --- id ablacionado: urgencia pregada em 0, sem mutacao ------------------
if cond.endswith("id0"):
    s = troca(s, URG_SEM, "        b->urgencia    = (rng01(), 0.0f);   /* id0: pregada em 0 */\n")
    s = troca(s, URG_MUT, "        cria->urgencia    = muta_traco(0.0f, 0.0f, 0.0f, 6.0f);   /* id0 */\n")

# --- canal do id mantido aberto a' forca (fesp) ou fechado (deg) ---------
if cond.startswith("fesp"):
    s = troca(s, ESP_SEM, "        b->peso_espaco = (rng01(), PESO_ESPACO);   /* fesp: pregado */\n")
    s = troca(s, ESP_MUT, "        cria->peso_espaco = muta_traco(PESO_ESPACO, 0.0f, 0.0f, 8.0f);   /* fesp */\n")
elif cond.startswith("deg"):
    s = troca(s, ESP_SEM, "        b->peso_espaco = (rng01(), 0.0f);   /* deg: canal do espaco fechado */\n")
    s = troca(s, ESP_MUT, "        cria->peso_espaco = muta_traco(0.0f, 0.0f, 0.0f, 8.0f);   /* deg */\n")
    # o outro termo multiplicado por espaco tambem precisa sumir para que
    # urgencia fique SEM canal nenhum (ver Sec4.9, consequencia 2)
    s = troca(s, REMORSO, REMORSO +
        "        remorso[i] = 0.0f;   /* deg: ablacao natural, idioma do N1 da nota 35 */\n")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/$1" "$TMP/v.c"
}

col_t() { awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"; }

printf '\n  Compilando as 6 condicoes...\n'
for c in $COND; do gen "$c"; done

printf '  %d seeds x %d ticks x 6 condicoes\n\n' "$(echo $SEEDS | wc -w)" "$TICKS"
for c in $COND; do
  for s in $SEEDS; do
    "$TMP/$c" "$s" "$TICKS" 0 --log "$TMP/${c}_$s.csv" >/dev/null
  done
  printf '    %s ok\n' "$c"
done

TF=$((TICKS-1))

echo ""
echo "=============================================================="
echo "  D1 -- fesp x fesp_id0 (canal do id aberto a' forca)"
echo "  Predito: pop final MENOR em fesp_id0 em >=6/8 seeds"
echo "=============================================================="
d1=0; n=0
for s in $SEEDS; do
  a=$(col_t "$TMP/fesp_$s.csv" 3 $TF); b=$(col_t "$TMP/fesp_id0_$s.csv" 3 $TF)
  ea=$(col_t "$TMP/fesp_$s.csv" 4 $TF); eb=$(col_t "$TMP/fesp_id0_$s.csv" 4 $TF)
  n=$((n+1))
  pior=$(awk -v a="$a" -v b="$b" 'BEGIN{print (b<a)?"SIM":"nao"}')
  [ "$pior" = "SIM" ] && d1=$((d1+1))
  printf '      seed %-3s  fesp pop %8s (E %6s)   fesp_id0 pop %8s (E %6s)   id0 pior: %s\n' \
         "$s" "$a" "$ea" "$b" "$eb" "$pior"
done
printf '\n  D1: %d/%d  ->  ' "$d1" "$n"
if [ "$d1" -ge 6 ]; then echo "CARREGA COMPORTAMENTO (>=6/8): o id paga a entrada"
elif [ "$d1" -ge 4 ]; then echo "NAO DECIDE (4-5/8)"
else echo "NAO CARREGA na direcao prevista (<=3/8)"; fi

echo ""
echo "=============================================================="
echo "  D2 -- o canal ja esta quase fechado na evolucao normal"
echo "  Predito: |dpop(ctl,id0)| < |dpop(fesp,fesp_id0)| em >=6/8"
echo "=============================================================="
d2=0
for s in $SEEDS; do
  c1=$(col_t "$TMP/ctl_$s.csv" 3 $TF);  c2=$(col_t "$TMP/id0_$s.csv" 3 $TF)
  f1=$(col_t "$TMP/fesp_$s.csv" 3 $TF); f2=$(col_t "$TMP/fesp_id0_$s.csv" 3 $TF)
  esp=$(col_t "$TMP/ctl_$s.csv" 12 $TF)
  r=$(awk -v c1="$c1" -v c2="$c2" -v f1="$f1" -v f2="$f2" 'BEGIN{
        dc=c1-c2; if(dc<0)dc=-dc; df=f1-f2; if(df<0)df=-df;
        printf "%.1f %.1f %s", dc, df, (dc<df)?"SIM":"nao"}')
  set -- $r
  [ "$3" = "SIM" ] && d2=$((d2+1))
  printf '      seed %-3s  |d ctl,id0| = %-7s  |d fesp,fesp_id0| = %-7s  menor: %-4s (esp_m final %s)\n' \
         "$s" "$1" "$2" "$3" "$esp"
done
printf '\n  D2: %d/%d  ->  %s\n' "$d2" "$n" \
  "$([ "$d2" -ge 6 ] && echo 'CONFIRMA: a selecao fecha o canal do id' || echo 'NAO CONFIRMA')"

echo ""
echo "=============================================================="
echo "  D3 -- a janela cedo (tick $T_CEDO), antes de peso_espaco cair"
echo "=============================================================="
d3=0
for s in $SEEDS; do
  a=$(col_t "$TMP/ctl_$s.csv" 3 $T_CEDO); b=$(col_t "$TMP/id0_$s.csv" 3 $T_CEDO)
  ea=$(col_t "$TMP/ctl_$s.csv" 12 $T_CEDO)
  pior=$(awk -v a="$a" -v b="$b" 'BEGIN{print (b<a)?"SIM":(b==a)?"igual":"nao"}')
  [ "$pior" = "SIM" ] && d3=$((d3+1))
  printf '      seed %-3s  ctl pop %8s   id0 pop %8s   id0 pior: %-5s (esp_m em t=%s: %s)\n' \
         "$s" "$a" "$b" "$pior" "$T_CEDO" "$ea"
done
printf '\n  D3: %d/%d na direcao de D1\n' "$d3" "$n"

echo ""
echo "=============================================================="
echo "  D4 -- controle degenerado: urgencia SEM canal nenhum"
echo "  Predito: deg x deg_id0 identicos BIT A BIT"
echo "=============================================================="
echo "  (D4 corrigido ANTES do painel -- ver a errata do Sec4.9: 'urg_m'/'urg_sd'"
echo "   (col. 10 e 11) DESCREVEM o traco ablacionado e nao podem coincidir; a"
echo "   comparacao que a algebra prediz e' a das outras 23 colunas, como a nota"
echo "   35 ja fizera com 'arrep_m'. As duas comparacoes vao abaixo.)"
echo ""
d4=0; d4full=0
for s in $SEEDS; do
  cmp -s "$TMP/deg_$s.csv" "$TMP/deg_id0_$s.csv" && d4full=$((d4full+1))
  cut -d, -f1-9,12- "$TMP/deg_$s.csv"     > "$TMP/d.a"
  cut -d, -f1-9,12- "$TMP/deg_id0_$s.csv" > "$TMP/d.b"
  difs=$(paste -d, "$TMP/deg_$s.csv" "$TMP/deg_id0_$s.csv" | awk -F, '
      NR>1 { for (i=1;i<=25;i++) if ($i != $(25+i)) col[i]=1 }
      END  { for (i=1;i<=25;i++) if (i in col) printf "%d ", i }')
  if cmp -s "$TMP/d.a" "$TMP/d.b"; then
    d4=$((d4+1))
    printf '      seed %-3s  as 23 colunas nao-urgencia: IDENTICAS  (diferem so: %s)\n' "$s" "$difs"
  else
    printf '      seed %-3s  as 23 colunas nao-urgencia: DIFEREM  (colunas: %s)\n' "$s" "$difs"
  fi
done
printf '\n  D4 (corrigido): %d/%d identicos nas 23 colunas   [D4 literal, 25 colunas: %d/%d]\n' \
       "$d4" "$n" "$d4full" "$n"
printf '  ->  %s\n\n' \
  "$([ "$d4" -eq "$n" ] && echo 'CONFIRMA: o id nao tem canal fora do termo do espaco' \
     || echo 'FALHOU: existe canal nao enumerado na algebra do Sec4.9 -- investigar ANTES de escrever')"
