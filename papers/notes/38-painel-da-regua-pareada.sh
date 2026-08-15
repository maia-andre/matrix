#!/bin/sh
# Reproduz a nota 38 (papers/notes/38-painel-da-regua-pareada.md).
#
# O PAINEL DA REGUA PAREADA (pre-registro: ROADMAP.md Sec4.11, ANTES de rodar).
#
# A regua pareada deu 28/30 na nota 37, mas como observavel SECUNDARIO (a P5 de
# um painel montado para outra pergunta) e nas MESMAS 30 seeds que as notas
# 33/34/35 ja tinham olhado. Aqui ela e a PRIMARIA, em 30 seeds que nenhuma nota
# deste projeto rodou (101-130), com corte declarado antes e potencia calculada
# antes:
#
#   corte >= 21/30 negativas (o corte do Sec4.6 -- nao se inventa regua nova)
#   alfa = P(X >= 21 | p = 0,5)          = 0,0214
#   potencia sob o efeito medido (0,933) = 0,99998
#   potencia sob o CP inferior   (0,805) = 0,947
#   menor efeito com 80% de potencia     = 0,749
#
#   d(t) = (arrep_m^A(t) + arrep_m^B(t)) / 4  =  f_impar^A(t) - f_impar^B(t)
#          (diferenca de COMPOSICAO entre as montagens, em fracao da populacao)
#
#   P1: PRIMARIA  -- T2, dbar_2000 com sinal, >= 21/30 negativas
#   P2: magnitude -- mediana de dbar_2000 em [-0,30; -0,05]
#   P3: o nulo    -- N2 em 10..20 negativas e |mediana| < 0,05 (aceitacao de p=0,5)
#   P4: as DUAS REGUAS nas MESMAS corridas -- binario T2 em 14..25, N2 em 4..15,
#       e entre as FUNDADOR de T2 a fracao com dbar < 0 deve passar de 0,5
#   P5: companheiro -- Wilcoxon signed-rank de dbar_2000 contra zero
#
# A algebra do nulo, feita antes da maquina (regra 5): sob N2 um bloco de peso w
# no campo s se comporta como um de peso -w no campo -s; como A e B so diferem em
# qual paridade carrega qual valor, A(-s) E B(s), logo d(-s) = -d(s). O ensemble
# de campos e simetrico sob complemento, entao a distribuicao de d e simetrica em
# torno de zero POR CONSTRUCAO -- o 15/30 exato da nota 37 nao foi sorte.
#
# Cada corrida vai a 30 000 ticks de proposito: o CSV contem o prefixo de 2 000,
# entao a MESMA corrida entrega dbar (janelas 500/2000/5000) E o desfecho binario
# na fixacao. As duas reguas medidas nas mesmas corridas e a unica comparacao
# honesta entre elas.
#
# PARALELISMO, declarado no Sec4.11 porque toca a invariante: as corridas rodam em
# processos simultaneos, mas nada dentro do tick muda -- cada corrida segue sendo
# um processo single-thread, f(seed), com o proprio CSV. O script CONFERE: guarda
# o md5 dos 120 CSVs e no fim repete uma corrida SOZINHA e compara. JOBS=1 roda
# sequencial e deve dar o mesmo painel.
#
# Patch temporario sobre o main.c, compilado em tmpdir (tecnica das notas
# 23/24/25) -- o main.c do repo NAO e tocado e nenhum dataset congelado muda.
# A analise inteira e em python: nenhum awk, nenhuma chance de o locale comer o
# ponto decimal (regra 7 do protocolo).
#
#   sh papers/notes/38-painel-da-regua-pareada.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 101..130: fora da amostra de TODAS as notas deste fio (que usaram 1..30, mais
# 31/32 na calibracao da janela da nota 37, mais 7/42/1234 nas notas 30/31/32).
SEEDS=${SEEDS:-"101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130"}
TICKS=${TICKS:-30000}    # a fixacao E o desfecho binario; as janelas saem do prefixo
JOBS=${JOBS:-12}         # 16 nucleos neste devbook; JOBS=1 = sequencial

VRES="-2.0"; VINV="2.0"

# gen "res,inv" BRACO -- copiado VERBATIM da nota 37 (que o copiou da 35): os
# binarios precisam ser os mesmos que produziram os numeros publicados.
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

# --- o extrator, um arquivo so: o worker usa para o painel e a conferencia -----
cat > "$TMP/extrai.py" <<'PY'
import sys
pa, pb, br, seed = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

def carrega(p):
    with open(p) as f:
        f.readline()
        return [l.rstrip("\n").split(",") for l in f]

A, B = carrega(pa), carrega(pb)
assert len(A) == len(B), f"{br}/{seed}: A e B com numero de ticks diferente"

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

# o desfecho binario -- MESMA formula das notas 33/34: o sinal de arrep_m no
# ultimo tick de cada montagem; REAL quando os dois concordam.
fa, fb = float(A[-1][23]), float(B[-1][23])

def bloco(W):
    n = min(W, len(d))
    db = sum(d[:n]) / n
    ab = sum(abs(x) for x in d[:n]) / n
    dp = sum(dpop[:n]) / n / (sum(popm[:n]) / n)
    return db, ab, dp

campos = [br, seed, str(t_div), str(t_01), f"{fa:.6f}", f"{fb:.6f}"]
for W in (500, 2000, 5000):
    campos += [f"{x:.6f}" for x in bloco(W)]
print("\t".join(campos))
PY

# --- o worker: uma tarefa = um (braco, seed), as duas montagens ---------------
cat > "$TMP/worker.sh" <<'WORKER'
#!/bin/sh
set -eu
export LC_ALL=C
TMP=$1; br=$2; s=$3; TICKS=$4
ca="$TMP/csv/${br}_${s}_A.csv"; cb="$TMP/csv/${br}_${s}_B.csv"
"$TMP/${br}_A" "$s" "$TICKS" 0 --log "$ca" >/dev/null
"$TMP/${br}_B" "$s" "$TICKS" 0 --log "$cb" >/dev/null
{ md5sum "$ca" | cut -d' ' -f1; md5sum "$cb" | cut -d' ' -f1; } > "$TMP/md5/${br}_${s}.txt"
python3 "$TMP/extrai.py" "$ca" "$cb" "$br" "$s" > "$TMP/met/${br}_${s}.tsv"
rm -f "$ca" "$cb"
printf '  %s seed %s ok\n' "$br" "$s"
WORKER
chmod +x "$TMP/worker.sh"
mkdir -p "$TMP/csv" "$TMP/met" "$TMP/md5"

echo ""
echo "=============================================================="
echo "  REGRESSAO -- os binarios reproduzem os numeros publicados?"
echo "  (regra 8: conferir a regua antes de aceitar o que ela diz)"
echo "  main.c nao muda desde 65e83f3, anterior as notas 32-37."
echo "=============================================================="
printf '%s T2 11 %s\n%s N2 2 %s\n' "$TMP" "$TICKS" "$TMP" "$TICKS" > "$TMP/reg.txt"
xargs -P 2 -n 4 "$TMP/worker.sh" < "$TMP/reg.txt" >/dev/null
for par in "T2 11" "N2 2"; do
  set -- $par; br=$1; s=$2
  python3 - "$TMP/met/${br}_${s}.tsv" <<'PY'
import sys
c = open(sys.argv[1]).read().split("\t")
br, s, fa, fb = c[0], c[1], float(c[4]), float(c[5])
cls = "REAL" if (fa < 0) == (fb < 0) else "FUNDADOR"
val = ("-2,0" if fa < 0 else "2,0") if cls == "REAL" else "-"
print(f"      {br} seed {s}:  A {fa:+.3f}   B {fb:+.3f}   -> {cls} {val}")
PY
  rm -f "$TMP/met/${br}_${s}.tsv" "$TMP/md5/${br}_${s}.txt"
done
echo "      publicado:  T2 seed 11 -> A -2,000  B -2,000  REAL -2,0  (nota 34)"
echo "                  N2 seed  2 -> REAL                          (nota 35)"

echo ""
echo "=============================================================="
echo "  PAINEL -- 30 seeds NOVAS x 2 bracos x 2 montagens, $TICKS ticks"
echo "  ($JOBS processos simultaneos; a ordem de chegada varia, o painel nao)"
echo "=============================================================="
: > "$TMP/tarefas.txt"
for s in $SEEDS; do
  for br in T2 N2; do
    printf '%s %s %s %s\n' "$TMP" "$br" "$s" "$TICKS" >> "$TMP/tarefas.txt"
  done
done
xargs -P "$JOBS" -n 4 "$TMP/worker.sh" < "$TMP/tarefas.txt"

# concatenacao em ordem ordenada: o agregado nao depende de quem terminou antes
cat "$TMP/met/"*.tsv | sort > "$TMP/metricas.tsv"

echo ""
echo "=============================================================="
echo "  DETERMINISMO SOB PARALELISMO -- a corrida repetida SOZINHA"
echo "=============================================================="
CONF_S=$(echo $SEEDS | cut -d' ' -f1)
"$TMP/T2_A" "$CONF_S" "$TICKS" 0 --log "$TMP/solo.csv" >/dev/null
M_SOLO=$(md5sum "$TMP/solo.csv" | cut -d' ' -f1)
M_PAR=$(head -1 "$TMP/md5/T2_${CONF_S}.txt")
echo "      T2/$CONF_S/A  no painel: $M_PAR"
echo "      T2/$CONF_S/A  sozinha:   $M_SOLO"
if [ "$M_SOLO" = "$M_PAR" ]; then
  echo "      IDENTICOS -- o paralelismo esta no shell, nao dentro do tick."
else
  echo "      DIFEREM -- o painel e NULO (o Sec4.11 declarou isto)."
  exit 1
fi

echo ""
echo "=============================================================="
echo "  P1..P5 -- as predicoes do Sec4.11"
echo "=============================================================="
python3 - "$TMP/metricas.tsv" <<'PY'
import sys, random
from math import comb

M = {}
for linha in open(sys.argv[1]):
    c = linha.rstrip("\n").split("\t")
    br, seed = c[0], int(c[1])
    r = {"t_div": int(c[2]), "t_01": int(c[3]), "fa": float(c[4]), "fb": float(c[5])}
    for k, W in enumerate((500, 2000, 5000)):
        r[f"dbar{W}"], r[f"absd{W}"], r[f"dpop{W}"] = (float(x) for x in c[6+3*k:9+3*k])
    r["real"] = (r["fa"] < 0) == (r["fb"] < 0)          # classificador das notas 33/34
    r["vence"] = ("-2,0" if r["fa"] < 0 else "2,0") if r["real"] else "-"
    M[(br, seed)] = r
SEEDS = sorted({s for _, s in M})
N = len(SEEDS)

def mediana(v):
    v = sorted(v); n = len(v)
    return v[n//2] if n % 2 else (v[n//2-1] + v[n//2]) / 2

def binom_ge(k, n, p=0.5):
    return sum(comb(n, x) * p**x * (1-p)**(n-x) for x in range(k, n+1))

def binom_bilateral(k, n):
    return min(1.0, 2 * binom_ge(max(k, n-k), n))

def sinal_exato(pares):
    mais = sum(1 for a, b in pares if a > b)
    menos = sum(1 for a, b in pares if a < b)
    n = mais + menos
    if n == 0: return mais, menos, 1.0
    k = min(mais, menos)
    return mais, menos, min(1.0, 2 * sum(comb(n, x) for x in range(k+1)) / 2**n)

def wilcoxon_perm(v, rng, NP=100000):
    """signed-rank contra zero, p bilateral por permutacao de sinais"""
    def W(xs):
        pares = sorted(((abs(x), x) for x in xs if x != 0))
        soma, i = 0.0, 0
        while i < len(pares):
            j = i
            while j+1 < len(pares) and pares[j+1][0] == pares[i][0]: j += 1
            posto = (i + j) / 2.0 + 1.0            # postos medios nos empates
            for k in range(i, j+1):
                soma += posto if pares[k][1] > 0 else -posto
            i = j + 1
        return soma
    obs = W(v)
    ge = 0
    for _ in range(NP):
        if abs(W([x if rng.random() < 0.5 else -x for x in v])) >= abs(obs) - 1e-12:
            ge += 1
    return obs, ge / NP

rng = random.Random(20260815)   # semente fixa: este projeto nao sorteia sem semente
placar = []

print("\n  tabela por seed (janela primaria W = 2000)\n")
print("  seed |  T2: dbar_2000    |d|    dpop  binario | "
      "N2: dbar_2000    |d|    dpop  binario")
for s in SEEDS:
    l = f"  {s:4d} |"
    for br in ("T2", "N2"):
        r = M[(br, s)]
        cls = f"REAL {r['vence']}" if r["real"] else "FUNDADOR"
        l += (f" {r['dbar2000']:+.4f} {r['absd2000']:.4f} {r['dpop2000']:.4f} "
              f"{cls:>10s} |")
    print(l)

print("\n  ---- P1 (PRIMARIA): a direcao, fora da amostra ----")
print("       corte pre-registrado: >= 21/30 negativas em dbar_2000 (T2)")
v = [M[("T2", s)]["dbar2000"] for s in SEEDS]
neg = sum(1 for x in v if x < 0)
p1 = binom_bilateral(neg, N)
print(f"       T2: mediana {mediana(v):+.5f}   negativas {neg}/{N}   "
      f"p (binomial bilateral) = {p1:.3g}")
ok1 = neg >= 21
placar.append(("P1 (primaria)", ok1, f"{neg}/{N} negativas, corte >= 21/30"))
print(f"       -> {'CONFIRMA' if ok1 else 'FALHA'} (nota 37, in-sample: 28/30)")

print("\n  ---- P2: a magnitude, e nao so o sinal ----")
print("       faixa pre-registrada: mediana de dbar_2000 em [-0,30; -0,05]")
med = mediana(v)
ok2 = -0.30 <= med <= -0.05
print(f"       mediana {med:+.5f}   (nota 37: -0,16386)")
placar.append(("P2 (magnitude)", ok2, f"mediana {med:+.4f} em [-0,30; -0,05]"))
print(f"       -> {'CONFIRMA' if ok2 else 'FALHA'}")

print("\n  ---- P3: o nulo, na mesma amostra fresca ----")
print("       aceitacao pre-registrada: 10..20 negativas e |mediana| < 0,05")
vn = [M[("N2", s)]["dbar2000"] for s in SEEDS]
negn = sum(1 for x in vn if x < 0)
medn = mediana(vn)
ok3 = 10 <= negn <= 20 and abs(medn) < 0.05
print(f"       N2: mediana {medn:+.5f}   negativas {negn}/{N}   "
      f"p (binomial bilateral) = {binom_bilateral(negn, N):.4f}")
print(f"       algebra do Sec4.11 previa 15/30 por simetria do ensemble")
placar.append(("P3 (nulo)", ok3, f"{negn}/{N} negativas, mediana {medn:+.4f}"))
print(f"       -> {'CONFIRMA' if ok3 else 'FALHA'}"
      f"{'' if ok3 else '  (o nulo tem vies: P1 NAO se le)'}")

print("\n  ---- P4: as DUAS REGUAS nas MESMAS corridas ----")
for br, faixa in (("T2", (14, 25)), ("N2", (4, 15))):
    r = sum(1 for s in SEEDS if M[(br, s)]["real"])
    menos2 = sum(1 for s in SEEDS if M[(br, s)]["real"] and M[(br, s)]["vence"] == "-2,0")
    ok = faixa[0] <= r <= faixa[1]
    print(f"       binario {br}: REAL {r}/{N} (dos quais {menos2} para -2,0)   "
          f"faixa pre-registrada {faixa[0]}..{faixa[1]}   "
          f"-> {'dentro' if ok else 'FORA'}")
    placar.append((f"P4a binario {br}", ok, f"REAL {r}/{N} em {faixa[0]}..{faixa[1]}"))
    if br == "T2":
        alcanca = r >= 21
        print(f"                   corte do proprio binario (>= 21/30): "
              f"{'ALCANCA' if alcanca else 'nao alcanca'} "
              f"-- o Sec4.11 declarou 'provavel que nao'")
fund = [s for s in SEEDS if not M[("T2", s)]["real"]]
if len(fund) >= 5:
    nf = sum(1 for s in fund if M[("T2", s)]["dbar2000"] < 0)
    p4 = binom_ge(nf, len(fund))
    ok4 = p4 < 0.05
    print(f"       entre as FUNDADOR de T2 (n = {len(fund)}): dbar < 0 em "
          f"{nf}/{len(fund)}   p unilateral = {p4:.4f}   "
          f"-> {'CONFIRMA' if ok4 else 'FALHA'}   (nota 37: 9/10, p = 0,0215)")
    placar.append(("P4b sinal nas FUNDADOR", ok4, f"{nf}/{len(fund)}, p = {p4:.4f}"))
else:
    print(f"       entre as FUNDADOR de T2: n = {len(fund)} < 5, "
          f"condicao pre-registrada nao se aplica")
    placar.append(("P4b sinal nas FUNDADOR", None, f"n = {len(fund)} < 5"))

print("\n  ---- P5 (companheiro): Wilcoxon signed-rank contra zero ----")
for br in ("T2", "N2"):
    x = [M[(br, s)]["dbar2000"] for s in SEEDS]
    W, p = wilcoxon_perm(x, rng)
    print(f"       {br}: W = {W:+.1f}   p bilateral (permutacao de sinais, 1e5) = {p:.5f}")

print("\n  ---- sensibilidade: as outras janelas (mesmas corridas) ----")
for W in (500, 2000, 5000):
    for br in ("T2", "N2"):
        x = [M[(br, s)][f"dbar{W}"] for s in SEEDS]
        neg_w = sum(1 for y in x if y < 0)
        marca = "  <-- PRIMARIA" if W == 2000 and br == "T2" else ""
        print(f"       W={W:5d}  {br}: mediana {mediana(x):+.5f}   "
              f"negativas {neg_w}/{N}   p = {binom_bilateral(neg_w, N):.3g}{marca}")
    pares = [(M[("T2", s)][f"dbar{W}"], M[("N2", s)][f"dbar{W}"]) for s in SEEDS]
    mais, menos, pp = sinal_exato(pares)
    print(f"                pareado T2 x N2: T2 mais negativo em {menos}/{N}   p = {pp:.3g}")

print("\n  ---- descritivo: a dose (t_div, t_01) e a divergencia do mundo ----")
for k in ("t_div", "t_01"):
    pares = [(M[("T2", s)][k], M[("N2", s)][k]) for s in SEEDS]
    mais, menos, p = sinal_exato(pares)
    print(f"       {k:6s} mediana T2 {mediana([a for a,_ in pares]):7.1f}   "
          f"N2 {mediana([b for _,b in pares]):7.1f}   "
          f"T2>N2 em {mais}, T2<N2 em {menos}   p = {p:.4f}")
pares = [(M[("T2", s)]["dpop2000"], M[("N2", s)]["dpop2000"]) for s in SEEDS]
mais, menos, p = sinal_exato(pares)
print(f"       dpop   mediana T2 {mediana([a for a,_ in pares]):.5f}   "
      f"N2 {mediana([b for _,b in pares]):.5f}   "
      f"T2>N2 em {mais}, T2<N2 em {menos}   p = {p:.4f}")

print("\n  =============== PLACAR CONTRA O PRE-REGISTRO ===============")
for nome, ok, detalhe in placar:
    marca = "  ?  " if ok is None else ("  OK " if ok else " FALHA")
    print(f"   {marca}  {nome:24s} {detalhe}")
print("")
PY
