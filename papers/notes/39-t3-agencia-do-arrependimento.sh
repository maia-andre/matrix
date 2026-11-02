#!/bin/sh
# Reproduz a nota 39 (papers/notes/39-t3-agencia-do-arrependimento.md).
#
# T3 (pre-registro: ROADMAP.md Sec4.12, commit 9ba7cf4, ANTES de rodar).
#
# A pergunta herdada do Sec4.5 / nota 30 Sec4: blocos com peso_arrependimento
# fortemente negativo mostram MENOS agencia que blocos com o traco em zero?
#
# A algebra antes da maquina (regra 9): agencia_do_bloco varre C + lam*E e NAO
# ve o termo w*r*E da utilidade. Dado o mesmo estado, a leitura e identica para
# w = -2 e w = 0. A sonda COMPLETA divide a utilidade por (1+u*f) e varre
#     c(lam) = lam + rho,   rho = w*r/(1+u*f),   f = (P-lam)/(P+u*lam)
# que e linear em lam: c = s*lam + w*r/(1+u), s = 1 + w*r*u/(P*(1+u)).
# Ou seja, a sonda original sobre OUTRO intervalo. Onde w*r = 0, rho = 0 exato
# em float e as duas sondas tem de concordar bit a bit (S2).
#
#   P1 (primaria): NEG (-2 x 0), delta = (F_X - O_X)/n_X < 0 em >= 21/30 seeds
#   P2 (contraprova de sinal): POS (+2 x 0), delta > 0 em >= 21/30
#   P3 (T3 literal): NEG, Dorig = O_X/n_X - O_Z/n_Z < 0: >=21 confirma, <=9 inverte
#   P4: P1/P2 recontadas em double (regra 6)
#   P5: dose (r > 0), delta condicionado, |s| < 1; Wilcoxon companheiro
#   S1: a sonda nao toca o mundo (CSV bit a bit igual ao do harness sem sonda)
#   S2: identidade: zero divergencias onde w*r = 0, em float e double
#   S3: a coluna agencia do CSV = (O_X+O_Z)/(n_X+n_Z) a %.3f, tick a tick
#   S4: paralelismo: uma corrida repetida SOZINHA da os mesmos md5
#
# Patch temporario sobre o main.c, compilado em tmpdir (tecnica das notas
# 23/24/25) -- o main.c do repo NAO e tocado e nenhum dataset congelado muda.
# A sonda escreve num fluxo a parte (stderr); o CSV do --log nao ganha coluna.
# Analise inteira em python (regra 7: nenhum awk).
#
#   sh papers/notes/39-t3-agencia-do-arrependimento.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 201..230: fora da amostra de todas as notas deste fio (1..32, 101..130, 7/42/1234)
SEEDS=${SEEDS:-"201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230"}
TICKS=${TICKS:-5000}
JOBS=${JOBS:-12}

# gen "res,inv" SONDA(0|1) -- o harness 'invasao' das notas 30-38 (ancoras
# identicas), mais, se SONDA=1, a sonda completa dentro de medir_decisao.
gen() {
python3 - "$MAINC" "$TMP" "$1" "$2" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; valor = sys.argv[3]; sonda = sys.argv[4] == "1"

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

if sonda:
    SONDA = r'''
/* ---- T3 (nota 39): a sonda COMPLETA da agencia, so leitura ----------------
 * Mesma construcao de C/E/K, mesma grade em lam, mesmo '>' estrito e mesmo
 * criterio de encurralado de agencia_do_bloco; a unica diferenca e o
 * coeficiente do espaco c = lam + rho, rho = w*r/(1+u*f). completa=0 -> rho=0.
 * Nao consome RNG, nao escreve em estado nenhum da simulacao. */
static long t3_tick = 0;
static long t3_acc[2][6];  /* [Z=0,X=1][n, O, F, Od, Fd, -] */
static long t3_rp[5];      /* X com r>0 e escolha: n, O, F, |s|<1, - */
static long t3_mis[4];     /* S2 float, S2 double, O!=Od, F!=Fd */

static int t3_sonda(Bloco *b, int i, int completa, int dupla) {
    float C[9], E[9], K[9];
    int n = 0;
    C[n] = prever_valor(b->x, b->y, b);
    E[n] = (8 - rivais_em(b->x, b->y, b->x, b->y)) / 8.0f;
    K[n] = 1.0f;
    n++;
    for (int dy = -1; dy <= 1; dy++)
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            int nx = b->x + dx, ny = b->y + dy;
            if (nx < 0 || nx >= LARG || ny < 0 || ny >= ALT) continue;
            if (ocup[ny][nx] != -1) continue;
            C[n] = prever_valor(nx, ny, b);
            E[n] = (8 - rivais_em(nx, ny, b->x, b->y)) / 8.0f;
            K[n] = 1.0f + ANTECIPACAO * pretendentes_em(nx, ny, i);
            n++;
        }
    if (n < 2) return -1;

    float  P = b->peso_espaco, u = b->urgencia;
    float  wr = completa ? b->peso_arrependimento * remorso[i] : 0.0f;
    int trocas = 0, anterior = -1;
    for (int p = 0; p < AG_PASSOS; p++) {
        int arg = 0;
        if (!dupla) {
            float lam = b->peso_espaco * (float)p / (float)(AG_PASSOS - 1);
            float f = (P > 0.0f) ? (P - lam) / (P + u * lam)
                                 : 1.0f - (float)p / (float)(AG_PASSOS - 1);
            float c = lam + wr / (1.0f + u * f);
            float melhor = (C[0] + c * E[0]) / K[0];
            for (int k = 1; k < n; k++) {
                float nota = (C[k] + c * E[k]) / K[k];
                if (nota > melhor) { melhor = nota; arg = k; }
            }
        } else {
            double Pd = P, ud = u, wrd = completa ? (double)b->peso_arrependimento * (double)remorso[i] : 0.0;
            double lam = Pd * (double)p / (double)(AG_PASSOS - 1);
            double f = (Pd > 0.0) ? (Pd - lam) / (Pd + ud * lam)
                                  : 1.0 - (double)p / (double)(AG_PASSOS - 1);
            double c = lam + wrd / (1.0 + ud * f);
            double melhor = ((double)C[0] + c * (double)E[0]) / (double)K[0];
            for (int k = 1; k < n; k++) {
                double nota = ((double)C[k] + c * (double)E[k]) / (double)K[k];
                if (nota > melhor) { melhor = nota; arg = k; }
            }
        }
        if (anterior >= 0 && arg != anterior) trocas++;
        anterior = arg;
    }
    return trocas > 0 ? 1 : 0;
}

static void t3_mede(Bloco *b, int i, float a_orig) {
    int O  = (int)a_orig;                    /* a leitura do main.c (-1, 0 ou 1) */
    int F  = t3_sonda(b, i, 1, 0);
    int Od = t3_sonda(b, i, 0, 1);
    int Fd = t3_sonda(b, i, 1, 1);
    if (a_orig < 0.0f) { if (F >= 0 || Od >= 0 || Fd >= 0) t3_mis[0]++; return; }
    int X = (b->peso_arrependimento != 0.0f);
    float r = remorso[i];
    if (b->peso_arrependimento * r == 0.0f) {      /* S2: a identidade */
        if (F != O)  t3_mis[0]++;
        if (Fd != Od) t3_mis[1]++;
    }
    if (O != Od) t3_mis[2]++;
    if (F != Fd) t3_mis[3]++;
    t3_acc[X][0]++; t3_acc[X][1] += O; t3_acc[X][2] += F;
    t3_acc[X][3] += Od; t3_acc[X][4] += Fd;
    if (X && r > 0.0f) {
        float P = b->peso_espaco, u = b->urgencia;
        t3_rp[0]++; t3_rp[1] += O; t3_rp[2] += F;
        if (P > 0.0f) {
            double sl = 1.0 + (double)b->peso_arrependimento * r * u / ((double)P * (1.0 + u));
            if (sl > -1.0 && sl < 1.0) t3_rp[3]++;
        }
    }
}

static void t3_despeja(void) {
    fprintf(stderr, "%ld", t3_tick++);
    for (int x = 0; x < 2; x++)
        for (int k = 0; k < 5; k++) fprintf(stderr, ",%ld", t3_acc[x][k]);
    for (int k = 0; k < 4; k++) fprintf(stderr, ",%ld", t3_rp[k]);
    for (int k = 0; k < 4; k++) fprintf(stderr, ",%ld", t3_mis[k]);
    fputc('\n', stderr);
    for (int x = 0; x < 2; x++) for (int k = 0; k < 6; k++) t3_acc[x][k] = 0;
    for (int k = 0; k < 5; k++) t3_rp[k] = 0;
    for (int k = 0; k < 4; k++) t3_mis[k] = 0;
}

'''
    MED_ORIG = "static void medir_decisao(void) {\n"
    s = troca(s, MED_ORIG, SONDA + MED_ORIG)
    AG_ORIG = ("        float a = agencia_do_bloco(&blocos[i], i);\n"
               "        if (a >= 0.0f) { ag += a; n_ag++; }      /* < 0 = encurralado */\n")
    s = troca(s, AG_ORIG, AG_ORIG + "        t3_mede(&blocos[i], i, a);\n")
    FIM_ORIG = "    ultima_bateria.agencia         = n_ag ? ag / n_ag : 0.0f;  /* so quem tinha escolha */\n"
    s = troca(s, FIM_ORIG, "    t3_despeja();\n" + FIM_ORIG)

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/bin" "$TMP/v.c"
}

for br in NEG POS; do
  if [ "$br" = NEG ]; then V="-2.0"; else V="2.0"; fi
  gen "$V,0.0" 1; mv "$TMP/bin" "$TMP/${br}_A"     # A: X nos pares
  gen "0.0,$V" 1; mv "$TMP/bin" "$TMP/${br}_B"     # B: X nos impares
  gen "$V,0.0" 0; mv "$TMP/bin" "$TMP/${br}_A0"    # sem sonda (S1)
  gen "0.0,$V" 0; mv "$TMP/bin" "$TMP/${br}_B0"
done

# --- extrator por corrida: S3 + as somas por janela ---------------------------
cat > "$TMP/extrai.py" <<'PY'
import sys, struct
csv, fluxo, br, seed, m = sys.argv[1:6]
f32 = lambda x: struct.unpack("f", struct.pack("f", x))[0]
with open(csv) as f:
    f.readline()
    ag = [l.split(",")[14] for l in f]            # coluna 15: agencia
L = [list(map(int, l.split(","))) for l in open(fluxo)]
assert len(L) == len(ag), f"{br}/{seed}/{m}: fluxo {len(L)} x csv {len(ag)} ticks"
s3 = 0
for row, a in zip(L, ag):
    n = row[1] + row[6]; o = row[2] + row[7]
    if f"{(f32(o / n) if n else 0.0):.3f}" != a: s3 += 1
mis = [sum(r[15+k] for r in L) for k in range(4)]
out = [br, seed, m, str(s3)] + [str(x) for x in mis]
for W in (500, 2000, 5000):
    tot = [sum(r[k] for r in L[:W]) for k in range(1, 15)]
    out += [str(x) for x in tot]
print("\t".join(out))
PY

cat > "$TMP/worker.sh" <<'WORKER'
set -eu
export LC_ALL=C
TMP=$1; br=$2; s=$3; TICKS=$4
for m in A B; do
  c="$TMP/csv/${br}_${s}_$m.csv"; x="$TMP/csv/${br}_${s}_$m.t3"
  "$TMP/${br}_$m" "$s" "$TICKS" 0 --log "$c" >/dev/null 2>"$x"
  md5sum "$c" "$x" | cut -d' ' -f1 | tr '\n' ' ' > "$TMP/md5/${br}_${s}_$m.txt"
  python3 "$TMP/extrai.py" "$c" "$x" "$br" "$s" "$m" > "$TMP/met/${br}_${s}_$m.tsv"
  rm -f "$x"
  [ "$s" = "$5" ] || rm -f "$c"          # guarda os CSVs da primeira seed (S1)
done
printf '  %s seed %s ok\n' "$br" "$s"
WORKER
chmod +x "$TMP/worker.sh"
mkdir -p "$TMP/csv" "$TMP/met" "$TMP/md5"
S0=$(echo $SEEDS | cut -d' ' -f1)

echo ""
echo "=============================================================="
echo "  PAINEL -- ${TICKS} ticks, seeds: $SEEDS ($JOBS processos)"
echo "=============================================================="
: > "$TMP/tarefas.txt"
for s in $SEEDS; do
  for br in NEG POS; do
    printf '%s %s %s %s %s\n' "$TMP" "$br" "$s" "$TICKS" "$S0" >> "$TMP/tarefas.txt"
  done
done
xargs -P "$JOBS" -n 5 "$TMP/worker.sh" < "$TMP/tarefas.txt"
cat "$TMP/met/"*.tsv | sort > "$TMP/metricas.tsv"

echo ""
echo "=============================================================="
echo "  S1 -- a sonda nao toca o mundo   |   S4 -- paralelismo"
echo "=============================================================="
falha=0
for br in NEG POS; do for m in A B; do
  "$TMP/${br}_${m}0" "$S0" "$TICKS" 0 --log "$TMP/s1.csv" >/dev/null 2>&1
  a=$(md5sum "$TMP/s1.csv" | cut -d' ' -f1); b=$(md5sum "$TMP/csv/${br}_${S0}_$m.csv" | cut -d' ' -f1)
  if [ "$a" = "$b" ]; then r=IDENTICOS; else r=DIFEREM; falha=1; fi
  echo "      S1 $br/$S0/$m  sem sonda $a  com sonda $b  $r"
done; done
"$TMP/NEG_A" "$S0" "$TICKS" 0 --log "$TMP/solo.csv" >/dev/null 2>"$TMP/solo.t3"
solo=$(md5sum "$TMP/solo.csv" "$TMP/solo.t3" | cut -d' ' -f1 | tr '\n' ' ')
par=$(cat "$TMP/md5/NEG_${S0}_A.txt")
if [ "$solo" = "$par" ]; then r=IDENTICOS; else r=DIFEREM; falha=1; fi
echo "      S4 NEG/$S0/A  painel: $par"
echo "      S4 NEG/$S0/A  sozinha: $solo $r"
[ "$falha" = 0 ] || { echo "      SANIDADE FALHOU -- o painel e NULO (Sec4.12)."; exit 1; }

echo ""
echo "=============================================================="
echo "  S2/S3 e P1..P5 -- as predicoes do Sec4.12"
echo "=============================================================="
python3 - "$TMP/metricas.tsv" <<'PY'
import sys, random
from math import comb

R = {}
for linha in open(sys.argv[1]):
    c = linha.rstrip("\n").split("\t")
    br, seed, m = c[0], int(c[1]), c[2]
    r = {"s3": int(c[3]), "mis": list(map(int, c[4:8]))}
    for k, W in enumerate((500, 2000, 5000)):
        t = list(map(int, c[8+14*k:22+14*k]))
        # Z: n O F Od Fd | X: n O F Od Fd | rp: n O F s<1
        r[W] = {"Z": t[0:5], "X": t[5:10], "rp": t[10:14]}
    R[(br, seed, m)] = r
SEEDS = sorted({s for _, s, _ in R})
N = len(SEEDS)

s2f = sum(r["mis"][0] for r in R.values()); s2d = sum(r["mis"][1] for r in R.values())
s3 = sum(r["s3"] for r in R.values())
dO = sum(r["mis"][2] for r in R.values()); dF = sum(r["mis"][3] for r in R.values())
print(f"  S2 identidade (w*r = 0, F != O):  float {s2f}   double {s2d}   (tem de ser 0 e 0)")
print(f"  S3 coluna agencia x fluxo, ticks divergentes: {s3}   (tem de ser 0)")
print(f"  P4 piso: blocos-tick com O != Od: {dO}   com F != Fd: {dF}")
if s2f or s2d or s3:
    print("  SANIDADE FALHOU -- o painel e NULO (Sec4.12)."); sys.exit(1)

def binom_ge(k, n, p=0.5):
    return sum(comb(n, x) * p**x * (1-p)**(n-x) for x in range(k, n+1))
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

# idx: 0 n, 1 O, 2 F, 3 Od, 4 Fd
def por_seed(br, s, W, qual):
    vs = []
    for m in "AB":
        q = R[(br, s, m)][W]; X, Z = q["X"], q["Z"]
        if X[0] == 0 or Z[0] == 0: continue          # um tipo sumiu nesta montagem
        if   qual == "delta":   vs.append((X[2] - X[1]) / X[0])
        elif qual == "delta_d": vs.append((X[4] - X[3]) / X[0])
        elif qual == "Dorig":   vs.append(X[1] / X[0] - Z[1] / Z[0])
        elif qual == "Dfull":   vs.append(X[2] / X[0] - Z[2] / Z[0])
    return sum(vs) / len(vs) if vs else None          # None = falha (sumiu nas duas)

def conta(br, W, qual, sinal):
    v = [por_seed(br, s, W, qual) for s in SEEDS]
    ok = sum(1 for x in v if x is not None and (x < 0 if sinal < 0 else x > 0))
    return ok, v

rng = random.Random(20261102)
for W in (2000, 500, 5000):
    tag = "PRIMARIA" if W == 2000 else "sensibilidade"
    print(f"\n  ---- W = {W} ({tag}) ----")
    for rot, br, qual, sinal in (("P1  NEG delta < 0     ", "NEG", "delta", -1),
                                 ("P2  POS delta > 0     ", "POS", "delta", +1),
                                 ("P4  NEG delta_d < 0   ", "NEG", "delta_d", -1),
                                 ("P4  POS delta_d > 0   ", "POS", "delta_d", +1),
                                 ("P3  NEG Dorig < 0     ", "NEG", "Dorig", -1),
                                 ("    NEG Dfull < 0     ", "NEG", "Dfull", -1),
                                 ("    POS Dorig < 0     ", "POS", "Dorig", -1)):
        ok, v = conta(br, W, qual, sinal)
        vv = [x for x in v if x is not None]
        nn = N - len(vv)
        lin = f"  {rot} {ok:2d}/{N}  mediana {mediana(vv):+.5f}  p(X>={ok}) {binom_ge(ok, N):.2e}"
        if nn: lin += f"  ({nn} seed(s) com tipo extinto)"
        if W == 2000 and qual in ("delta", "Dorig"):
            lin += f"  Wilcoxon p {wilcoxon_perm(vv, rng):.5f}"
        if qual.startswith("delta") or qual == "Dorig":
            if qual == "Dorig":
                lin += "  -> " + ("CONFIRMA" if ok >= 21 else ("INVERTE" if ok <= 9 else "NAO DECIDE"))
            else:
                lin += "  -> " + ("CONFIRMA" if ok >= 21 else "NAO CONFIRMA")
        print(lin)

print("\n  ---- P5: dose e forma (W = 2000, somado nas 60 corridas de cada braco) ----")
for br in ("NEG", "POS"):
    nX = sum(R[(br, s, m)][2000]["X"][0] for s in SEEDS for m in "AB")
    rp = [sum(R[(br, s, m)][2000]["rp"][k] for s in SEEDS for m in "AB") for k in range(4)]
    dX = sum(R[(br, s, m)][2000]["X"][2] - R[(br, s, m)][2000]["X"][1] for s in SEEDS for m in "AB")
    print(f"  {br}: blocos-tick X com escolha {nX}; com r>0 {rp[0]} ({rp[0]/nX:.3f})")
    if rp[0]:
        print(f"       entre r>0: O {rp[1]/rp[0]:.4f}  F {rp[2]/rp[0]:.4f}  delta|r>0 {(rp[2]-rp[1])/rp[0]:+.4f}"
              f"  |s|<1 {rp[3]/rp[0]:.3f}  (F-O fora de r>0: {dX - (rp[2]-rp[1])})")

print("\n  ---- por seed, W = 2000 (delta NEG, delta POS, Dorig NEG) ----")
for s in SEEDS:
    a, b, c = (por_seed("NEG", s, 2000, "delta"), por_seed("POS", s, 2000, "delta"),
               por_seed("NEG", s, 2000, "Dorig"))
    f = lambda x: "   extinto" if x is None else f"{x:+.5f}"
    print(f"    seed {s}:  {f(a)}  {f(b)}  {f(c)}")
PY
