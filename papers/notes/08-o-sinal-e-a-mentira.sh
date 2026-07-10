#!/bin/sh
# Reproduz a nota 08 (papers/notes/08-o-sinal-e-a-mentira.md).
#
# O relato causal (pre-registro ROADMAP §4.0, commit 372e827, ANTES de rodar):
#   S2  o canal carrega comportamento (todo-honesto x todo-mudo): a ENERGIA muda
#       (~5,7 x ~6,5), a populacao quase nao — S2 confirma no fato, erra a direcao.
#   S3  todo-mudo => modelo_do_outro = 0 exato (silencio = eremita epistemico).
#   S4  invasao HONESTO x MUDO: a honestidade fixa contra o silencio.
#   S5  invasao HONESTO x BLEFE: a honestidade resiste — cheap talk nao degenera.
#   S6  dos tercos + mutacao: hon_f domina (~0,85) mas nao fixa (~10% de blefe).
#
# Patches fixam a estrategia PRESERVANDO o fluxo do RNG (comma-op no semear e no
# muta). Patch numa copia temporaria do main.c canonico (>= c924fbd). ~4 min.
#   sh papers/notes/08-o-sinal-e-a-mentira.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    return t.replace(a,b,1)
SEM = "b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */"
MUT = "cria->estrategia  = muta_estrategia(pai->estrategia);"
def fixa(nome, val):
    s=troca(src, SEM, f"b->estrategia  = (rng01(), {val});")
    s=troca(s, MUT, f"cria->estrategia  = (muta_estrategia(pai->estrategia), {val});")
    open(f"{tmp}/{nome}.c","w").write(s)
def invasao(nome, res, inv):
    s=troca(src, SEM, f"b->estrategia  = (rng01(), (n_blocos & 1) ? {inv} : {res});")
    s=troca(s, MUT, "cria->estrategia  = (muta_estrategia(pai->estrategia), pai->estrategia);")
    open(f"{tmp}/{nome}.c","w").write(s)
fixa("hon", "SIN_HONESTO")
fixa("mudo", "SIN_MUDO")
invasao("inv_mudo",  "SIN_HONESTO", "SIN_MUDO")
invasao("inv_blefe", "SIN_HONESTO", "SIN_BLEFE")
PY
for v in hon mudo inv_mudo inv_blefe; do gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null; done
gcc -std=c11 -O2 -o "$TMP/canon" "$MAINC" 2>/dev/null

pop() { awk -F, 'NR>1 && $2>=500 && $3>0 {s+=$3;n++} END{printf "%.1f", s/n}' "$1"; }
en()  { awk -F, 'NR>1 && $2>=500 && $3>0 {s+=$4;n++} END{printf "%.2f", s/n}' "$1"; }
mdo() { awk -F, 'NR>1 && $3>0 {s+=$16;n++; if($16>mx)mx=$16} END{printf "media=%.4f max=%.4f", s/n, mx}' "$1"; }
fr()  { awk -F, -v t="$2" -v c="$3" 'NR>1 && $2==t {printf "%.2f", $c}' "$1"; }

printf '\n  nota 08 — o sinal e a mentira (seeds %s)\n' "$SEEDS"

printf '\n  S2. o canal carrega comportamento (todo-honesto x todo-mudo, ticks 500-3000):\n'
for s in $SEEDS; do
  "$TMP/hon"  $s 3000 0 --log "$TMP/h_$s.csv" >/dev/null 2>&1
  "$TMP/mudo" $s 3000 0 --log "$TMP/m_$s.csv" >/dev/null 2>&1
  printf '      seed %-5s honesto pop=%s en=%s   mudo pop=%s en=%s\n' \
    "$s" "$(pop "$TMP/h_$s.csv")" "$(en "$TMP/h_$s.csv")" "$(pop "$TMP/m_$s.csv")" "$(en "$TMP/m_$s.csv")"
done

printf '\n  S3. todo-mudo => modelo_do_outro = 0 EXATO:\n'
for s in $SEEDS; do printf '      seed %-5s %s\n' "$s" "$(mdo "$TMP/m_$s.csv")"; done

printf '\n  S4. invasao HONESTO x MUDO (50/50, sem mutacao) — hon_f (col 19):\n'
for s in $SEEDS; do
  "$TMP/inv_mudo" $s 4000 0 --log "$TMP/im_$s.csv" >/dev/null 2>&1
  printf '      seed %-5s t0=%s t1000=%s t2000=%s t3999=%s\n' "$s" \
    "$(fr "$TMP/im_$s.csv" 0 19)" "$(fr "$TMP/im_$s.csv" 1000 19)" "$(fr "$TMP/im_$s.csv" 2000 19)" "$(fr "$TMP/im_$s.csv" 3999 19)"
done

printf '\n  S5. invasao HONESTO x BLEFE (50/50, sem mutacao) — hon_f:\n'
for s in $SEEDS; do
  "$TMP/inv_blefe" $s 4000 0 --log "$TMP/ib_$s.csv" >/dev/null 2>&1
  printf '      seed %-5s t0=%s t1000=%s t2000=%s t3999=%s\n' "$s" \
    "$(fr "$TMP/ib_$s.csv" 0 19)" "$(fr "$TMP/ib_$s.csv" 1000 19)" "$(fr "$TMP/ib_$s.csv" 2000 19)" "$(fr "$TMP/ib_$s.csv" 3999 19)"
done

printf '\n  S6. dos tercos + mutacao (30000 ticks) — hon_f / blef_f:\n'
for s in $SEEDS; do
  "$TMP/canon" $s 30000 0 --log "$TMP/e_$s.csv" >/dev/null 2>&1
  printf '      seed %-5s t0 h=%s b=%s   t29999 h=%s b=%s\n' "$s" \
    "$(fr "$TMP/e_$s.csv" 0 19)" "$(fr "$TMP/e_$s.csv" 0 20)" \
    "$(fr "$TMP/e_$s.csv" 29999 19)" "$(fr "$TMP/e_$s.csv" 29999 20)"
done
printf '\n  Mudo varrido, honesto domina, ~10%% de blefe persiste: equilibrio misto.\n\n'
