#!/bin/sh
# Reproduz a nota 06 (papers/notes/06-o-interprete-leigo.md).
#
# Valida o mostrador 'relato' contra o pre-registro do ROADMAP §2.0 (que foi
# commitado em eee9511, ANTES do mostrador existir — ffb3014):
#   P1  interprete cego (relato = constante): kappa = 0 EXATO, 4 constantes.
#   P2  mundo intacto: 0 < relato < 1 (pode errar, e informa).
#   P3  confabulacao selvagem: resolver() intervem de graca; mede a calibracao
#       de OBEDECIDOS x NEGADOS e a taxa de racionalizacao dos negados.
#   P5  eremita: a predicao era "nao zera" — FALHOU; o eremita fica mudo.
#
# Como as demais notas: patches numa copia temporaria do main.c canonico.
# Aceita um main.c alternativo em $1 (>= ffb3014, precisa ter o relato).
#
#   sh papers/notes/06-relato.sh          (~3 min)
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,67" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

# col 18 = relato
mm() { awk -F, 'NR>1 && $2>20 && $3>0 {s+=$18;n++; if($18>mx)mx=$18} END{if(n) printf "media=%.4f max=%.4f", s/n, mx; else printf "--"}' "$1"; }

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    return t.replace(a,b,1)

open(f"{tmp}/ctl.c","w").write(src)

# P1: interprete cego — o relato vira uma constante k (4 variantes)
a=("        int r = rel_classifica(blocos[i].x, blocos[i].y,\n"
   "                               rel_cx[i], rel_cy[i], rel_ex[i], rel_ey[i]);")
for k in range(4):
    open(f"{tmp}/cego{k}.c","w").write(troca(src, a, f"        int r = {k};"))

# P5: eremita — nao percebe rivais nem pretendentes
s=troca(src,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
            "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
            "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
          "static int pretendentes_em(int cx, int cy, int self_i) {\n"
          "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
open(f"{tmp}/erem.c","w").write(s)

# P3: instrumentacao obedecidos x negados (só medicao; a simulacao nao muda)
s=troca(src,
  "    rel_cx[i] = fx; rel_cy[i] = fy;",
  "    rel_ax_[i] = alvo_x[i]; rel_ay_[i] = alvo_y[i];\n"
  "    rel_cx[i] = fx; rel_cy[i] = fy;")
s=troca(s,
  "static float relato_ultimo;",
  "static float relato_ultimo;\n"
  "static int rel_ax_[MAX_AG], rel_ay_[MAX_AG];\n"
  "static long g_ob_n, g_ob_acc, g_ng_n, g_ng_acc, g_ng_confab, g_ob_confab;\n"
  "static void relato_dump(void) {\n"
  "    fprintf(stderr, \"P3 obedecidos n=%ld acc=%.4f confab=%.4f | negados n=%ld acc=%.4f confab=%.4f\\n\",\n"
  "        g_ob_n, g_ob_n? (double)g_ob_acc/g_ob_n:0, g_ob_n? (double)g_ob_confab/g_ob_n:0,\n"
  "        g_ng_n, g_ng_n? (double)g_ng_acc/g_ng_n:0, g_ng_n? (double)g_ng_confab/g_ng_n:0);\n"
  "}")
s=troca(s,
  "        conf[r][rel_verdade[i]]++;\n        n++;",
  "        conf[r][rel_verdade[i]]++;\n        n++;\n"
  "        {\n"
  "            int negado = (blocos[i].x != rel_ax_[i] || blocos[i].y != rel_ay_[i]);\n"
  "            if (negado) { g_ng_n++; if (r == rel_verdade[i]) g_ng_acc++; if (r != REL_NAOSEI) g_ng_confab++; }\n"
  "            else        { g_ob_n++; if (r == rel_verdade[i]) g_ob_acc++; if (r != REL_NAOSEI) g_ob_confab++; }\n"
  "        }")
s=troca(s,"    signal(SIGINT, ao_interromper);",
          "    signal(SIGINT, ao_interromper);\n    atexit(relato_dump);")
open(f"{tmp}/p3.c","w").write(s)
PY

for v in ctl cego0 cego1 cego2 cego3 erem p3; do
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

printf '\n  nota 06 — relato, o interprete leigo (seeds %s, %s ticks)\n' "$SEEDS" "$TICKS"

printf '\n  P2. mundo intacto (0 < relato < 1):\n'
for s in $SEEDS; do
  "$TMP/ctl" "$s" "$TICKS" 0 --log "$TMP/ctl_$s.csv" >/dev/null 2>&1
  printf '      seed %-5s %s\n' "$s" "$(mm "$TMP/ctl_$s.csv")"
done

printf '\n  P1. interprete cego (relato = constante k): kappa deve ser 0 EXATO\n'
for k in 0 1 2 3; do
  printf '      k=%s:' "$k"
  for s in $SEEDS; do
    "$TMP/cego$k" "$s" "$TICKS" 0 --log "$TMP/c.csv" >/dev/null 2>&1
    printf '  seed %-5s %s' "$s" "$(mm "$TMP/c.csv")"
  done
  echo
done

printf '\n  P3. confabulacao selvagem (acc = relato bate com o motivo da decisao;\n'
printf '      confab = nomeia motivo positivo em vez de "nao sei"):\n'
for s in $SEEDS; do
  printf '      seed %-5s ' "$s"
  "$TMP/p3" "$s" "$TICKS" 0 --log /dev/null 2>&1 >/dev/null | tail -1
done

printf '\n  P5. eremita (a predicao "nao zera" FALHOU — ele fica mudo):\n'
for s in $SEEDS; do
  "$TMP/erem" "$s" "$TICKS" 0 --log "$TMP/e.csv" >/dev/null 2>&1
  printf '      seed %-5s %s\n' "$s" "$(mm "$TMP/e.csv")"
done
printf '\n  Sem segundo motivo, toda decisao tem o mesmo porque: nada a relatar\n'
printf '  acima do acaso. A costura da escada engole o quinto mostrador tambem.\n\n'
