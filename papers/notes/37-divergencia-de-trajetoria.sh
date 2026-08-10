#!/bin/sh
# Reproduz a nota 37 (papers/notes/37-divergencia-de-trajetoria.md).
#
# A DIVERGENCIA DE TRAJETORIA (pre-registro: ROADMAP.md Sec4.10, ANTES de rodar).
#
# A nota 35 fechou declarando a fraqueza central do proprio nulo: o termo do
# arrependimento em T2 e espacialmente COERENTE (multiplica 'espaco', que e
# suave) e o de N2 troca de sinal CELULA A CELULA. Se coerencia decorrelacionar
# as duas montagens espelhadas mais que incoerencia de mesma magnitude, parte do
# vao 30% -> 66,7% e decorrelacao, nao vantagem. O teste que fecha isso muda o
# que o script GUARDA (as series), nao o que ele roda.
#
# A algebra, feita antes da maquina (Sec4.10), da um teto que corrida nenhuma
# move: sem mecanismo as duas montagens sao a MESMA simulacao (REAL = 0%,
# medido pelo N1 da nota 35); com decorrelacao total sao dois sorteios justos
# (REAL = 50%); e passar de 50% equivale, por definicao deste harness, a
# vantagem. Logo T2 (20/30) esta acima do teto (p = 0,0494) e o nulo (9/30)
# esta significativamente abaixo (p = 0,0214).
#
#   d(t) = (arrep_m^A(t) + arrep_m^B(t)) / 4  =  f_impar^A(t) - f_impar^B(t)
#          (diferenca de COMPOSICAO entre as montagens, em fracao da populacao)
#
#   P1: dose      -- t_div e t_01 pareados, T2 x N2
#   P2: a ameaca  -- escala de dbar (|dbar - mediana do braco|), T2 x N2
#   P3: no mundo  -- Delta pop pareado, T2 x N2 (cego a qual valor vence)
#   P4: o modelo  -- dentro de N2, REAL deve ter |dbar| maior que FUNDADOR
#   P5: direcao   -- dbar COM SINAL; T2 deve pender para negativo (>= 21/30)
#
# Janela primaria W = 2000, calibrada em seeds 31/32 (FORA das 30 do painel);
# W = 500 e W = 5000 entram como sensibilidade, das mesmas corridas.
#
# Patch temporario sobre o main.c, compilado em tmpdir (tecnica das notas
# 23/24/25) -- o main.c do repo NAO e tocado e nenhum dataset congelado muda.
# A analise inteira e em python: nenhum awk, nenhuma chance de o locale comer o
# ponto decimal (a regra 7 do protocolo, e o erro que atrasou esta nota).
#
#   sh papers/notes/37-divergencia-de-trajetoria.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS:-"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30"}
W_MAX=${W_MAX:-5000}          # o que se roda; as janelas saem deste prefixo
TICKS_REG=${TICKS_REG:-30000} # a regressao precisa do desfecho publicado

VRES="-2.0"; VINV="2.0"

# gen "res,inv" BRACO -- o harness 'invasao' das notas 30/32/33/34 SEM mudanca
# (pina os dois valores, desliga a mutacao do traco), mais o patch do braco.
# O bloco N2 e copiado VERBATIM da nota 35: e o mesmo nulo, nao um parecido.
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

if braco == "T2":
    pass   # o harness 'invasao' puro: exatamente o que as notas 33/34 rodaram

elif braco == "N2":
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

for br in T2 N2; do
  gen "$VRES,$VINV" "$br"; mv "$TMP/bin" "$TMP/${br}_A"
  gen "$VINV,$VRES" "$br"; mv "$TMP/bin" "$TMP/${br}_B"
done

echo ""
echo "=============================================================="
echo "  REGRESSAO -- os binarios reproduzem os numeros publicados?"
echo "  (regra 8: conferir a regua antes de aceitar o que ela diz)"
echo "  main.c nao muda desde 65e83f3, anterior as notas 32-36."
echo "=============================================================="
for par in "T2 11" "N2 2"; do
  set -- $par; br=$1; s=$2
  "$TMP/${br}_A" "$s" "$TICKS_REG" 0 --log "$TMP/reg_${br}_A.csv" >/dev/null
  "$TMP/${br}_B" "$s" "$TICKS_REG" 0 --log "$TMP/reg_${br}_B.csv" >/dev/null
  python3 - "$TMP/reg_${br}_A.csv" "$TMP/reg_${br}_B.csv" "$br" "$s" <<'PY'
import sys
a, b, br, s = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
def ultimo(p):
    with open(p) as f:
        return float(f.readlines()[-1].split(",")[23])
va, vb = ultimo(a), ultimo(b)
cls = "REAL" if (va < 0) == (vb < 0) else "FUNDADOR"
val = ("-2,0" if va < 0 else "2,0") if cls == "REAL" else "-"
print(f"      {br} seed {s}:  A {va:+.3f}   B {vb:+.3f}   -> {cls} {val}")
PY
done
echo "      publicado:  T2 seed 11 -> A -2,000  B -2,000  REAL -2,0  (nota 34)"
echo "                  N2 seed  2 -> REAL                          (nota 35)"

echo ""
echo "=============================================================="
echo "  PAINEL -- 30 seeds x 2 bracos x 2 montagens, $W_MAX ticks"
echo "=============================================================="
: > "$TMP/metricas.tsv"
for s in $SEEDS; do
  for br in T2 N2; do
    "$TMP/${br}_A" "$s" "$W_MAX" 0 --log "$TMP/m_A.csv" >/dev/null
    "$TMP/${br}_B" "$s" "$W_MAX" 0 --log "$TMP/m_B.csv" >/dev/null
    python3 - "$TMP/m_A.csv" "$TMP/m_B.csv" "$br" "$s" >> "$TMP/metricas.tsv" <<'PY'
import sys
pa, pb, br, seed = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

def carrega(p):
    with open(p) as f:
        f.readline()
        return [l.rstrip("\n").split(",") for l in f]

A, B = carrega(pa), carrega(pb)
assert len(A) == len(B)

# invariantes ao rotulo: tudo menos arrep_m (col 24, indice 23)
INV = [i for i in range(2, 25) if i != 23]

t_div = t_01 = -1
d = []          # d(t) = (arrep_m^A + arrep_m^B)/4 = f_impar^A - f_impar^B
dpop = []       # |pop_A - pop_B|
popm = []
for ra, rb in zip(A, B):
    t = int(ra[1])
    if t_div < 0 and any(ra[i] != rb[i] for i in INV):
        t_div = t
    v = (float(ra[23]) + float(rb[23])) / 4.0
    d.append(v)
    if t_01 < 0 and abs(v) >= 0.01:
        t_01 = t
    dpop.append(abs(int(ra[2]) - int(rb[2])))
    popm.append((int(ra[2]) + int(rb[2])) / 2.0)

def bloco(W):
    n = min(W, len(d))
    db = sum(d[:n]) / n
    ab = sum(abs(x) for x in d[:n]) / n
    dp = sum(dpop[:n]) / n / (sum(popm[:n]) / n)
    return db, ab, dp

campos = [br, seed, str(t_div), str(t_01)]
for W in (500, 2000, 5000):
    campos += [f"{x:.6f}" for x in bloco(W)]
print("\t".join(campos))
PY
  done
  printf '  seed %-3s ok\n' "$s"
done

echo ""
echo "=============================================================="
echo "  P1..P5 -- as predicoes do Sec4.10"
echo "=============================================================="
python3 - "$TMP/metricas.tsv" <<'PY'
import sys, random
from math import comb

# --- desfechos JA PUBLICADOS (notas 33/34 para T2, nota 35 para N2) ---------
REAL = {
    "T2": {2,3,4,6,8,9,11,12,13,15,16,20,21,22,23,24,25,27,28,30},   # 20/30
    "N2": {2,12,13,15,16,19,24,25,29},                               # 9/30
}

M = {}
for linha in open(sys.argv[1]):
    c = linha.split("\t")
    br, seed = c[0], int(c[1])
    r = {"t_div": int(c[2]), "t_01": int(c[3])}
    for k, W in enumerate((500, 2000, 5000)):
        r[f"dbar{W}"], r[f"absd{W}"], r[f"dpop{W}"] = (float(x) for x in c[4+3*k:7+3*k])
    M[(br, seed)] = r
SEEDS = sorted({s for _, s in M})

def mediana(v):
    v = sorted(v); n = len(v)
    return v[n//2] if n % 2 else (v[n//2-1] + v[n//2]) / 2

def sinal_exato(pares):
    """teste de sinal exato bilateral sobre (x_T2, x_N2) pareados"""
    mais = sum(1 for a, b in pares if a > b)
    menos = sum(1 for a, b in pares if a < b)
    n = mais + menos
    if n == 0: return mais, menos, 1.0
    k = min(mais, menos)
    p = min(1.0, 2 * sum(comb(n, x) for x in range(k+1)) / 2**n)
    return mais, menos, p

def binom_ge(k, n):
    return sum(comb(n, x) for x in range(k, n+1)) / 2**n

def perm_razao(pares, rng, N=100000):
    """p bilateral por permutacao pareada: troca o rotulo do braco dentro da seed"""
    def mad(v):
        m = mediana(v); return mediana([abs(x-m) for x in v])
    obs = mad([a for a, _ in pares]) / max(mad([b for _, b in pares]), 1e-12)
    extremos = 0
    for _ in range(N):
        A, B = [], []
        for a, b in pares:
            if rng.random() < 0.5: a, b = b, a
            A.append(a); B.append(b)
        r = mad(A) / max(mad(B), 1e-12)
        if max(r, 1/r) >= max(obs, 1/obs) - 1e-12:
            extremos += 1
    return obs, extremos / N

def rank_sum_perm(x, y, rng, N=100000):
    """Mann-Whitney unilateral (x > y) por permutacao"""
    todos = x + y
    def stat(idx):
        xs = [todos[i] for i in idx]
        ys = [todos[i] for i in range(len(todos)) if i not in idx]
        return sum(1 for u in xs for v in ys if u > v) + 0.5*sum(1 for u in xs for v in ys if u == v)
    obs = stat(set(range(len(x))))
    ge = 0
    ids = list(range(len(todos)))
    for _ in range(N):
        rng.shuffle(ids)
        if stat(set(ids[:len(x)])) >= obs: ge += 1
    return obs, ge / N

rng = random.Random(20260810)   # semente fixa: este projeto nao sorteia sem semente

print("\n  tabela por seed (janela primaria W = 2000)\n")
print("  seed |  T2: t_div t_01    dbar    |d|    dpop  cls | "
      "N2: t_div t_01    dbar    |d|    dpop  cls")
for s in SEEDS:
    l = f"  {s:4d} |"
    for br in ("T2", "N2"):
        r = M[(br, s)]
        cls = "REAL" if s in REAL[br] else "FUND"
        l += (f" {r['t_div']:6d} {r['t_01']:4d} {r['dbar2000']:+.4f} "
              f"{r['absd2000']:.4f} {r['dpop2000']:.4f} {cls} |")
    print(l)

print("\n  ---- P1: a dose (t_div e t_01 pareados, sinal exato bilateral) ----")
for k in ("t_div", "t_01"):
    pares = [(M[("T2", s)][k], M[("N2", s)][k]) for s in SEEDS]
    mais, menos, p = sinal_exato(pares)
    print(f"    {k:6s}  mediana T2 {mediana([a for a,_ in pares]):8.1f}   "
          f"N2 {mediana([b for _,b in pares]):8.1f}   "
          f"T2>N2 em {mais}, T2<N2 em {menos}   p = {p:.4f}")

print("\n  ---- P2: a AMEACA -- escala de dbar (deslocamento removido) ----")
for W in (500, 2000, 5000):
    esc = {}
    for br in ("T2", "N2"):
        v = [M[(br, s)][f"dbar{W}"] for s in SEEDS]
        m = mediana(v)
        esc[br] = {s: abs(M[(br, s)][f"dbar{W}"] - m) for s in SEEDS}
    pares = [(esc["T2"][s], esc["N2"][s]) for s in SEEDS]
    mais, menos, p = sinal_exato(pares)
    marca = "  <-- PRIMARIA" if W == 2000 else ""
    print(f"    W={W:5d}  escala mediana  T2 {mediana([a for a,_ in pares]):.5f}   "
          f"N2 {mediana([b for _,b in pares]):.5f}   "
          f"T2>N2 em {mais}, T2<N2 em {menos}   p = {p:.4f}{marca}")
    if W == 2000:
        razao, pp = perm_razao(pares, rng)
        print(f"             companheiro: razao de MADs T2/N2 = {razao:.3f}   "
              f"p (permutacao pareada, 1e5) = {pp:.4f}")

print("\n  ---- P3: a mesma ameaca no MUNDO (Delta pop pareado) ----")
for W in (500, 2000, 5000):
    pares = [(M[("T2", s)][f"dpop{W}"], M[("N2", s)][f"dpop{W}"]) for s in SEEDS]
    mais, menos, p = sinal_exato(pares)
    marca = "  <-- PRIMARIA" if W == 2000 else ""
    print(f"    W={W:5d}  mediana  T2 {mediana([a for a,_ in pares]):.5f}   "
          f"N2 {mediana([b for _,b in pares]):.5f}   "
          f"T2>N2 em {mais}, T2<N2 em {menos}   p = {p:.4f}{marca}")

print("\n  ---- P4: o modelo (dentro de N2, REAL deve divergir mais) ----")
for br in ("N2", "T2"):
    r = [M[(br, s)]["absd2000"] for s in SEEDS if s in REAL[br]]
    f = [M[(br, s)]["absd2000"] for s in SEEDS if s not in REAL[br]]
    U, p = rank_sum_perm(r, f, rng)
    nota = "(pre-registrado)" if br == "N2" else "(descritivo)"
    print(f"    {br}: |dbar| mediana  REAL {mediana(r):.5f} (n={len(r)})   "
          f"FUNDADOR {mediana(f):.5f} (n={len(f)})   "
          f"U = {U:.0f}   p unilateral = {p:.4f}  {nota}")

print("\n  ---- P5: a direcao, continua e cedo (dbar COM SINAL) ----")
for W in (500, 2000, 5000):
    for br in ("T2", "N2"):
        v = [M[(br, s)][f"dbar{W}"] for s in SEEDS]
        neg = sum(1 for x in v if x < 0)
        p = min(1.0, 2 * binom_ge(max(neg, len(v)-neg), len(v)))
        marca = "  <-- PRIMARIA" if W == 2000 else ""
        print(f"    W={W:5d}  {br}: mediana {mediana(v):+.5f}   "
              f"negativas {neg}/{len(v)}   p (binomial bilateral) = {p:.4f}{marca}")
    pares = [(M[("T2", s)][f"dbar{W}"], M[("N2", s)][f"dbar{W}"]) for s in SEEDS]
    mais, menos, pp = sinal_exato(pares)
    print(f"             pareado T2 x N2: T2 mais negativo em {menos}/{len(pares)}"
          f"   p = {pp:.4f}")

print("\n  ---- o teto do Sec4.10 (algebra, nao depende deste painel) ----")
print(f"    T2 20/30 acima do teto de 50%:  p unilateral = {binom_ge(20,30):.4f}")
print(f"    N2  9/30 abaixo do teto:        p unilateral = {binom_ge(21,30):.4f}")
print("")
PY
