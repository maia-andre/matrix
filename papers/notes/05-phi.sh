#!/bin/sh
# Reproduz a nota 05 (papers/notes/05-phi-media-o-segundo-motivo.md).
#
# Tres evidencias, para o main.c dado (default: o da raiz, phi NOVA):
#   1. ABLACOES: eremita, peso_espaco=0, prever_valor=0 — na phi nova as tres
#      dao ZERO exato; na phi velha nenhuma zera (o bloco lobotomizado le 0,13).
#   2. TRACO CONGELADO (30 000 ticks): congelar peso_espaco SEGURA a phi;
#      congelar a profundidade (horizonte+desconto) NAO segura. Quem carrega a
#      phi e o mesmo traco que carrega a agencia (nota 03).
#   3. O ARTEFATO DA JANELA: corr(phi, profundidade efetiva) sobre os 30 000
#      ticks do controle x sobre os primeiros 3 000 dos MESMOS dados. A
#      correlacao alta so existe na janela longa: co-tendencia, nao acoplamento.
#
# Para reproduzir a evidencia da phi VELHA (destruida pelo conserto e151c45):
#   git show f09aa45:main.c > /tmp/main_phi_velha.c
#   sh papers/notes/05-phi.sh /tmp/main_phi_velha.c
#
# Demora ~5-8 min (nove corridas de 30 000 ticks).
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,065" e rele como 0
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
    assert a in t, f"ancora sumiu: {a[:55]!r} (o main.c mudou?)"
    return t.replace(a,b,1)

open(f"{tmp}/ctl.c","w").write(src)

# eremita: nao percebe rivais nem pretendentes (ablacao da nota 01/§1.5)
s=troca(src,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
            "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
            "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
          "static int pretendentes_em(int cx, int cy, int self_i) {\n"
          "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
open(f"{tmp}/erem.c","w").write(s)

# peso_espaco identicamente 0 (semeadura e mutacao presas em 0; RNG preservado)
s=troca(src,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
            "b->peso_espaco = (rng01(), 0.0f);")
s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
          "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 0.0f);")
open(f"{tmp}/esp0.c","w").write(s)

# prever_valor = 0 (a lobotomia da nota 01)
open(f"{tmp}/pv0.c","w").write(troca(src,"\n    return valor;\n","\n    return 0.0f;\n"))

# congela peso_espaco em PESO_ESPACO (o traco nao evolui)
s=troca(src,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
            "b->peso_espaco = (rng01(), PESO_ESPACO);")
s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
          "cria->peso_espaco = muta_traco(PESO_ESPACO, 0.0f, 0.0f, 8.0f);")
open(f"{tmp}/fesp.c","w").write(s)

# congela a profundidade (horizonte e desconto nao evoluem)
s=troca(src,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
            "b->desconto    = (rng01(), DESCONTO);")
s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
          "b->horizonte   = (int)(rng01(), HORIZONTE);")
s=troca(s,"cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
          "cria->desconto    = DESCONTO;")
s=troca(s,"cria->horizonte   = muta_horizonte(pai->horizonte);",
          "cria->horizonte   = HORIZONTE;")
open(f"{tmp}/fdep.c","w").write(s)
PY

for v in ctl erem esp0 pv0 fesp fdep; do
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

# col 17 = phi; media/max enquanto a populacao vive
mm() { awk -F, 'NR>1 && $3>0 {s+=$17;n++; if($17>mx)mx=$17} END{if(n) printf "media=%.4f max=%.4f", s/n, mx; else printf "  --"}' "$1"; }

printf '\n  nota 05 — phi (seeds %s)\n' "$SEEDS"
printf '\n  1. ABLACOES (3000 ticks): a phi nova deve dar ZERO exato nas tres\n'
for v in erem esp0 pv0; do
  printf '     %-22s' "$v"
  for s in $SEEDS; do
    "$TMP/$v" "$s" 3000 0 --log "$TMP/${v}_$s.csv" >/dev/null 2>&1 || true
    printf '  seed %-5s %s ' "$s" "$(mm "$TMP/${v}_$s.csv")"
  done
  echo
done

printf '\n  2. TRACO CONGELADO (30000 ticks): phi inicio -> fim\n'
traj() { awk -F, 'NR>1 && $2>20 && $3>0 {if(p=="")p=$17; u=$17} END{printf "%.3f -> %.3f", p, u}' "$1"; }
for v in ctl fesp fdep; do
  printf '     %-22s' "$v"
  for s in $SEEDS; do
    "$TMP/$v" "$s" 30000 0 --log "$TMP/${v}30_$s.csv" >/dev/null 2>&1 || true
    printf '  seed %-5s %s ' "$s" "$(traj "$TMP/${v}30_$s.csv")"
  done
  echo
done
printf '     (fesp = congela peso_espaco; fdep = congela horizonte+desconto)\n'

printf '\n  3. O ARTEFATO DA JANELA: corr(phi, profundidade efetiva) nos MESMOS dados\n'
for s in $SEEDS; do
python3 - "$TMP/ctl30_$s.csv" "$s" <<'PY'
import sys,csv,statistics as st
rows=[r for r in csv.DictReader(open(sys.argv[1]))
      if int(r['tick'])>20 and int(r['pop'])>0]
def corr(rows):
    phi=[float(r['phi']) for r in rows]
    eff=[min(float(r['hor_m']), 1.0/(1.0-float(r['desc_m']))) for r in rows]
    n=len(phi); mp=sum(phi)/n; me=sum(eff)/n
    cov=sum((a-mp)*(b-me) for a,b in zip(phi,eff))/n
    sp=st.pstdev(phi); se=st.pstdev(eff)
    return cov/(sp*se) if sp*se else 0.0
curta=[r for r in rows if int(r['tick'])<=3000]
print(f"     seed {sys.argv[2]:>4}:  janela 30000: {corr(rows):+.3f}   janela 3000: {corr(curta):+.3f}")
PY
done
printf '\n  Correlacao que muda com a janela e co-tendencia, nao acoplamento.\n\n'
