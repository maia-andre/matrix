#!/bin/sh
# Reproduz a nota 04 (papers/notes/04-o-automodelo-era-um-modelo-do-outro.md).
#
# Mostra, para o mostrador 'modelo_do_outro' (ex-'automodelo'):
#   1. TESTE DO EREMITA: sem perceber pretendentes, a leitura e ZERO exato — a
#      prova de que mede o OUTRO, nao o self (e a razao do nome honesto).
#   2. A SONDA VELHA tinha um parametro escondido: a leitura "flip em alpha" — o
#      que 'intencao != alvo' media, no unico ponto alpha = ANTECIPACAO = 0.5 —
#      varia de 0 ate uma assintota conforme alpha cresce. A leitura NOVA,
#      ancorada, E essa assintota (varre alpha por todo o dominio [0,inf)) e nao
#      depende de ANTECIPACAO.
#
# Como as demais notas: nao ha experiment_00N.c; as variantes sao patches numa
# copia temporaria do main.c canonico. Aceita um main.c alternativo em $1 (mas
# ele precisa ja ter 'modelo_do_outro_do_bloco', isto e, ser >= o conserto).
#
#   sh papers/notes/04-modelo-do-outro.sh
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,354" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

# col 16 = modelo_do_outro; media enquanto a populacao vive (col 3 = pop)
media() { awk -F, -v c="$2" 'NR>1 && $2>20 && $3>0 {s+=$c; n++} END{if(n) printf "%.4f", s/n; else printf "  --"}' "$1"; }
maxc()  { awk -F, -v c="$2" 'NR>1 {if($c>m)m=$c} END{printf "%.4f", m}' "$1"; }

# ---- 1. eremita completo (§1.5): nao percebe rivais NEM pretendentes ----------
python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:50]!r} (o main.c mudou?)"
    return t.replace(a,b,1)
s=troca(src,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
            "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
            "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
          "static int pretendentes_em(int cx, int cy, int self_i) {\n"
          "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
open(f"{tmp}/eremita.c","w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/eremita" "$TMP/eremita.c" 2>/dev/null

printf '\n  nota 04 — modelo_do_outro (seeds %s, %s ticks)\n\n' "$SEEDS" "$TICKS"
printf '  1. TESTE DO EREMITA (nao percebe pretendentes): a leitura deve ser ZERO exato\n'
for s in $SEEDS; do
  "$TMP/eremita" "$s" "$TICKS" 0 --log "$TMP/erem_$s.csv" >/dev/null 2>&1
  printf '     seed %-5s media=%s  max=%s\n' "$s" "$(media "$TMP/erem_$s.csv" 16)" "$(maxc "$TMP/erem_$s.csv" 16)"
done

# ---- 2. sonda velha "flip em alpha" x nova ancorada ---------------------------
# Troca o corpo de modelo_do_outro_do_bloco por "a escolha muda entre alpha=0 e
# alpha=ALPHA_MEAS?" — a simulacao segue com ANTECIPACAO=0.5, entao a trajetoria
# nao muda: e a MESMA corrida relida em cada alpha.
gen_alpha() {
python3 - "$MAINC" "$TMP" "$1" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]; alpha="%.6f"%float(sys.argv[3])
novo=r'''static float modelo_do_outro_do_bloco(Bloco *b, int i) {
    float ALPHA_MEAS = %s;
    float u[9]; int pret[9], n = 0;
    u[0] = utilidade(b->x, b->y, b); pret[0] = 0; n = 1;
    for (int dy = -1; dy <= 1; dy++)
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            int nx = b->x + dx, ny = b->y + dy;
            if (nx < 0 || nx >= LARG || ny < 0 || ny >= ALT) continue;
            if (ocup[ny][nx] != -1) continue;
            u[n] = utilidade(nx, ny, b); pret[n] = pretendentes_em(nx, ny, i); n++;
        }
    if (n < 2) return -1.0f;
    int w0 = 0; for (int k = 1; k < n; k++) if (u[k] > u[w0]) w0 = k;
    int wa = 0; float best = u[0] / (1.0f + ALPHA_MEAS * pret[0]);
    for (int k = 1; k < n; k++) { float sc = u[k] / (1.0f + ALPHA_MEAS * pret[k]); if (sc > best) { best = sc; wa = k; } }
    return (wa != w0) ? 1.0f : 0.0f;
}''' % alpha
ini=src.index("static float modelo_do_outro_do_bloco(Bloco *b, int i) {")
fim=src.index("\n\n/* FASE 1", ini)
open(f"{tmp}/a.c","w").write(src[:ini]+novo+src[fim:])
PY
gcc -std=c11 -O2 -o "$TMP/a" "$TMP/a.c" 2>/dev/null
}

printf '\n  2. A SONDA VELHA tinha um parametro escondido (leitura "flip em alpha"):\n'
printf '     alpha=0.5 = o ponto que a sonda antiga media; ancorado = varre alpha->inf\n\n'
printf '     %-12s' alpha; for s in $SEEDS; do printf ' %9s' "seed$s"; done; echo
printf '     %s\n' "------------------------------------------------"
for al in 0 0.25 0.5 1 4; do
  gen_alpha "$al"
  printf '     %-12s' "$al"
  for s in $SEEDS; do
    "$TMP/a" "$s" "$TICKS" 0 --log "$TMP/s_$s.csv" >/dev/null 2>&1
    printf ' %9s' "$(media "$TMP/s_$s.csv" 16)"
  done
  echo
done
gcc -std=c11 -O2 -o "$TMP/anc" "$MAINC" 2>/dev/null    # ancorado = o main.c como esta
printf '     %-12s' "ancorado"
for s in $SEEDS; do
  "$TMP/anc" "$s" "$TICKS" 0 --log "$TMP/anc_$s.csv" >/dev/null 2>&1
  printf ' %9s' "$(media "$TMP/anc_$s.csv" 16)"
done
echo
printf '\n  A leitura ancorada = a assintota da curva, e nao menciona ANTECIPACAO.\n\n'
