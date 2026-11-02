#!/bin/sh
# Reproduz a nota 40 (papers/notes/40-decomposicao-do-arrependimento.md).
#
# A DECOMPOSICAO (pre-registro: ROADMAP.md Sec4.13, commit f0c9a21, ANTES de rodar).
#
# Q5 respondeu um duelo (-2 x +2). Aqui: -2 ganha do ZERO, ou +2 perde para ele?
# A regua pareada contra o zero, X o valor nao nulo:
#
#   f_X^M(t) = arrep_m^M(t) / X           (fracao com o traco X na montagem M)
#   g(t)     = (f_X^A(t) + f_X^B(t))/2 - 1/2   (vies de paridade cancela)
#   gbar_W   = media de g em [0, W)
#
#   P1: NEG (-2 x 0)  gbar_2000 > 0 em >= 21/30
#   P2: POS (+2 x 0)  gbar_2000 < 0 em >= 21/30
#   P3: NUL (+2 x 0, termo com a direcao destruida pelo campo sinal_nulo) --
#       bilateral: <= 9 ou >= 21 positivas = um termo sem direcao ja tem efeito
#   S1: NEG/A seed 1 a 30 000 ticks reproduz arrep_m = -0,026 (nota 33)
#   S2: paralelismo (corrida repetida sozinha, mesmo md5)
#   S3: f_X no tick 0
#
# Patch temporario sobre o main.c em tmpdir (tecnica das notas 23/24/25): o
# main.c do repo NAO e tocado. Analise em python (regra 7: nenhum awk).
#
#   sh papers/notes/40-decomposicao-do-arrependimento.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS:-"301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330"}
TICKS=${TICKS:-5000}
JOBS=${JOBS:-12}

# gen "res,inv" BRACO -- o harness 'invasao' das notas 30-38 (ancoras verbatim);
# NUL acrescenta o patch N2 da nota 35, copiado verbatim da nota 38.
gen() {
python3 - "$MAINC" "$TMP" "$1" "$2" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; valor = sys.argv[3]; braco = sys.argv[4]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua ({t.count(a)}x): {a[:70]!r}"
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

if braco in ("NEG", "POS"):
    pass
elif braco == "NUL":
    UTI_ORIG = "         + b->peso_arrependimento * remorso[i] * espaco;\n"
    s = troca(s, UTI_ORIG,
        "         + b->peso_arrependimento * remorso[i] * espaco * sinal_nulo(cx, cy);\n")
    ASS_ORIG = "static float utilidade_sigma(int cx, int cy, Bloco *b, float sigma) {\n"
    s = troca(s, ASS_ORIG,
        "/* N2 (nulo ativo): o termo do arrependimento com a DIRECAO destruida.\n"
        " * hash2 com salt proprio nao tem relacao nenhuma com o campo de comida\n"
        " * (que sai de ruido() com a seed crua), entao cada valor do traco passa\n"
        " * a preferir espaco aberto em metade das celulas e lotacao na outra\n"
        " * metade, em espelho exato do outro: dose igual, vantagem nenhuma. */\n"
        "static float sinal_nulo(int cx, int cy) {\n"
        "    return (hash2(cx, cy, salt_nulo) & 1u) ? 1.0f : -1.0f;\n"
        "}\n" + ASS_ORIG)
    GER_ORIG = "static void gerar_mundo(uint32_t seed) {\n"
    s = troca(s, "\n" + GER_ORIG,
        "\nstatic uint32_t salt_nulo = 0u;   /* N2: campo arbitrario, um por seed */\n"
        + GER_ORIG +
        "    salt_nulo = seed ^ 0x5EED1u;\n")
else:
    raise SystemExit(f"braco desconhecido: {braco}")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/bin" "$TMP/v.c"
}

for br in NEG POS NUL; do
  if [ "$br" = NEG ]; then V="-2.0"; else V="2.0"; fi
  gen "$V,0.0" "$br"; mv "$TMP/bin" "$TMP/${br}_A"     # A: X nos pares
  gen "0.0,$V" "$br"; mv "$TMP/bin" "$TMP/${br}_B"     # B: X nos impares
done

cat > "$TMP/extrai.py" <<'PY'
import sys
pa, pb, br, seed = sys.argv[1:5]
X = -2.0 if br == "NEG" else 2.0
def fx(p):
    with open(p) as f:
        f.readline()
        return [float(l.split(",")[23]) / X for l in f]   # col 24: arrep_m
A, B = fx(pa), fx(pb)
assert len(A) == len(B), f"{br}/{seed}: A e B com numero de ticks diferente"
g = [(a + b) / 2.0 - 0.5 for a, b in zip(A, B)]
out = [br, seed, f"{A[0]:.6f}", f"{B[0]:.6f}"]
for W in (500, 2000, 5000):
    n = min(W, len(g)); out.append(f"{sum(g[:n]) / n:.6f}")
out += [f"{A[-1]:.6f}", f"{B[-1]:.6f}"]
print("\t".join(out))
PY

cat > "$TMP/worker.sh" <<'WORKER'
set -eu
export LC_ALL=C
TMP=$1; br=$2; s=$3; TICKS=$4
ca="$TMP/csv/${br}_${s}_A.csv"; cb="$TMP/csv/${br}_${s}_B.csv"
"$TMP/${br}_A" "$s" "$TICKS" 0 --log "$ca" >/dev/null
"$TMP/${br}_B" "$s" "$TICKS" 0 --log "$cb" >/dev/null
md5sum "$ca" | cut -d' ' -f1 > "$TMP/md5/${br}_${s}.txt"
python3 "$TMP/extrai.py" "$ca" "$cb" "$br" "$s" > "$TMP/met/${br}_${s}.tsv"
rm -f "$ca" "$cb"
printf '  %s seed %s ok\n' "$br" "$s"
WORKER
chmod +x "$TMP/worker.sh"
mkdir -p "$TMP/csv" "$TMP/met" "$TMP/md5"

echo ""
echo "=============================================================="
echo "  PAINEL + S1 -- ${TICKS} ticks, seeds: $SEEDS ($JOBS processos)"
echo "=============================================================="
# S1 roda junto com o painel (30 000 ticks, a corrida mais longa: primeiro da fila)
( "$TMP/NEG_A" 1 30000 0 --log "$TMP/s1.csv" >/dev/null ) &
PID_S1=$!
: > "$TMP/tarefas.txt"
for s in $SEEDS; do
  for br in NEG POS NUL; do
    printf '%s %s %s %s\n' "$TMP" "$br" "$s" "$TICKS" >> "$TMP/tarefas.txt"
  done
done
xargs -P "$((JOBS - 1))" -n 4 "$TMP/worker.sh" < "$TMP/tarefas.txt"
wait "$PID_S1"
cat "$TMP/met/"*.tsv | sort > "$TMP/metricas.tsv"

echo ""
echo "=============================================================="
echo "  S1 -- regressao   |   S2 -- paralelismo"
echo "=============================================================="
S1=$(python3 -c "
import sys
L = open('$TMP/s1.csv').read().splitlines()
print(L[-1].split(',')[1], L[-1].split(',')[23])")
echo "      S1 NEG/1/A tick, arrep_m: $S1   (publicado, nota 33: 29999 -0.026)"
falha=0
[ "$S1" = "29999 -0.026" ] || falha=1
S0=$(echo $SEEDS | cut -d' ' -f1)
"$TMP/NEG_A" "$S0" "$TICKS" 0 --log "$TMP/solo.csv" >/dev/null
solo=$(md5sum "$TMP/solo.csv" | cut -d' ' -f1); par=$(cat "$TMP/md5/NEG_${S0}.txt")
echo "      S2 NEG/$S0/A  painel $par  sozinha $solo"
[ "$solo" = "$par" ] || falha=1
[ "$falha" = 0 ] || { echo "      SANIDADE FALHOU -- o painel e NULO (Sec4.13)."; exit 1; }
echo "      ok"

echo ""
echo "=============================================================="
echo "  S3 e P1..P3 -- as predicoes do Sec4.13"
echo "=============================================================="
python3 - "$TMP/metricas.tsv" <<'PY'
import sys, random
from math import comb
M = {}
for linha in open(sys.argv[1]):
    c = linha.rstrip("\n").split("\t")
    M[(c[0], int(c[1]))] = {"f0A": float(c[2]), "f0B": float(c[3]),
        500: float(c[4]), 2000: float(c[5]), 5000: float(c[6]),
        "fimA": float(c[7]), "fimB": float(c[8])}
SEEDS = sorted({s for _, s in M}); N = len(SEEDS)

f0 = sorted({(round(r["f0A"], 4), round(r["f0B"], 4)) for r in M.values()})
print(f"  S3 f_X no tick 0 (A, B), valores distintos no painel: {f0}")

def binom_ge(k, n):
    return sum(comb(n, x) for x in range(k, n + 1)) / 2**n
def mediana(v):
    v = sorted(v); n = len(v)
    return v[n//2] if n % 2 else (v[n//2-1] + v[n//2]) / 2
def wilcoxon_perm(v, rng, NP=100000):
    def W(xs):
        pares = sorted((abs(x), x) for x in xs if x != 0)
        soma, i = 0.0, 0
        while i < len(pares):
            j = i
            while j+1 < len(pares) and pares[j+1][0] == pares[i][0]: j += 1
            posto = (i + j) / 2.0 + 1.0
            for k in range(i, j+1): soma += posto if pares[k][1] > 0 else -posto
            i = j + 1
        return soma
    obs = abs(W(v)); ge = 0
    for _ in range(NP):
        if abs(W([x if rng.random() < 0.5 else -x for x in v])) >= obs - 1e-12: ge += 1
    return ge / NP

rng = random.Random(20261102)
for W in (2000, 500, 5000):
    print(f"\n  ---- W = {W} ({'PRIMARIA' if W == 2000 else 'sensibilidade'}) ----")
    for br in ("NEG", "POS", "NUL"):
        v = [M[(br, s)][W] for s in SEEDS]
        pos = sum(1 for x in v if x > 0); neg = sum(1 for x in v if x < 0)
        lin = f"  {br}: gbar > 0 em {pos:2d}/{N}  (< 0 em {neg:2d})  mediana {mediana(v):+.5f}"
        if br == "NEG":
            lin += f"  p(X>={pos}) {binom_ge(pos, N):.2e}  -> P1 " + ("CONFIRMA" if pos >= 21 else "NAO CONFIRMA")
        elif br == "POS":
            lin += f"  p(X>={neg}) {binom_ge(neg, N):.2e}  -> P2 " + ("CONFIRMA" if neg >= 21 else "NAO CONFIRMA")
        else:
            k = max(pos, neg)
            lin += f"  bilateral p {min(1, 2 * binom_ge(k, N)):.2e}  -> P3 " + \
                   ("EFEITO DETECTADO" if (pos >= 21 or pos <= 9) else "NAO DETECTADO")
        if W == 2000: lin += f"  Wilcoxon p {wilcoxon_perm(v, rng):.5f}"
        print(lin)

m = {br: mediana([M[(br, s)][2000] for s in SEEDS]) for br in ("NEG", "POS", "NUL")}
print(f"\n  descritivo: gbar_NEG - gbar_POS = {m['NEG'] - m['POS']:+.5f}   "
      f"(T2 publicado, nota 38: gbar = -dbar/2 = +0.10115; outras seeds)")

print("\n  ---- por seed, W = 2000 (gbar) e f_X no tick final (A, B) ----")
for s in SEEDS:
    print("    seed %d:" % s + "".join(
        f"  {br} {M[(br, s)][2000]:+.5f} ({M[(br, s)]['fimA']:.2f},{M[(br, s)]['fimB']:.2f})"
        for br in ("NEG", "POS", "NUL")))
PY
