#!/bin/sh
# Reproduz a nota 41 (papers/notes/41-mecanismo-do-arrependimento.md).
#
# O MECANISMO (pre-registro: ROADMAP.md Sec4.14, commit d1f6bde, ANTES de rodar).
#
# A hipotese da nota 30 Sec4: depois de perder uma disputa, o bloco de peso
# negativo continua competindo pelo recurso que valia a disputa.
#
# Regua de DECISAO (ablacao dentro do bloco, tecnica da nota 39): a cada tick,
# depois de decidir, o alvo final de cada bloco X (w != 0) e recalculado com o
# termo DESLIGADO (w = 0 so nessa chamada de melhor_celula):
#   R_comida = comida(alvo) - comida(alvo sem termo)   (comida REAL da celula)
#   R_rivais = rivais(alvo) - rivais(alvo sem termo)   (rivais_em)
# media por bloco-tick X (zero onde o alvo nao muda); por seed, media de A e B.
#
# Regua ECOLOGICA (X - Z por bloco-tick, montagens espelhadas): comida no alvo,
# lotacao do alvo, fracao de negados, garfada.
#
#   P1 (primaria): NEG R_comida > 0 em >= 21/30
#   P2: NEG R_rivais > 0 em >= 21/30
#   P3: POS R_comida < 0 e R_rivais < 0, cada um >= 21/30
#   P4: NUL, bilateral nos dois R
#   P5: NEG E_garfada > 0 em >= 21/30; descritivo: escada na garfada, E_negado
#   S1: patch nao toca o mundo   S2: alvo recalculado COM termo = alvo real
#   S3: paralelismo
#
# Patch temporario em tmpdir; o main.c do repo NAO e tocado. Analise em python.
#
#   sh papers/notes/41-mecanismo-do-arrependimento.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS=${SEEDS:-"401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430"}
TICKS=${TICKS:-5000}
JOBS=${JOBS:-12}

# gen "res,inv" BRACO SONDA(0|1) -- o harness 'invasao' das notas 30-38 (ancoras verbatim);
# NUL acrescenta o patch N2 da nota 35, copiado verbatim da nota 38.
gen() {
python3 - "$MAINC" "$TMP" "$1" "$2" "$3" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; valor = sys.argv[3]; braco = sys.argv[4]; sonda = sys.argv[5] == "1"

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


if sonda:
    T4 = r'''
/* ---- nota 41: a sonda do mecanismo, so leitura -------------------------
 * Nao consome RNG, nao escreve em estado da simulacao (o w e restaurado
 * no mesmo bloco de codigo, antes de qualquer outra leitura). */
static long   t4_tick = 0;
static double t4_acc[2][5];   /* [Z,X][nb, comida_alvo, rivais_alvo, negados, garfada] */
static double t4_r[4];        /* X: redirecionados, dcomida, drivais, S2 divergencias */

static void t4_decisao(void) {
    for (int i = 0; i < n_blocos; i++) {
        if (!blocos[i].vivo) continue;
        Bloco *b = &blocos[i];
        int X = (b->peso_arrependimento != 0.0f);
        int tx = alvo_x[i], ty = alvo_y[i];
        t4_acc[X][0] += 1.0;
        t4_acc[X][1] += comida[ty][tx];
        t4_acc[X][2] += rivais_em(tx, ty, b->x, b->y);
        if (!X) continue;
        int ax, ay, cx, cy;
        melhor_celula(b, i, 1, &ax, &ay, NULL, NULL);          /* S2: com termo */
        if (ax != tx || ay != ty) t4_r[3] += 1.0;
        float w = b->peso_arrependimento;
        b->peso_arrependimento = 0.0f;
        melhor_celula(b, i, 1, &cx, &cy, NULL, NULL);          /* sem termo */
        b->peso_arrependimento = w;
        if (cx != tx || cy != ty) {
            t4_r[0] += 1.0;
            t4_r[1] += (double)comida[ty][tx] - (double)comida[cy][cx];
            t4_r[2] += rivais_em(tx, ty, b->x, b->y) - rivais_em(cx, cy, b->x, b->y);
        }
    }
}

static void t4_negados(void) {
    for (int i = 0; i < n_blocos; i++)
        if (blocos[i].vivo && negado_tick[i])
            t4_acc[blocos[i].peso_arrependimento != 0.0f][3] += 1.0;
}

static void t4_despeja(void) {
    fprintf(stderr, "%ld", t4_tick++);
    for (int x = 0; x < 2; x++)
        for (int k = 0; k < 5; k++) fprintf(stderr, ",%.6f", t4_acc[x][k]);
    for (int k = 0; k < 4; k++) fprintf(stderr, ",%.6f", t4_r[k]);
    fputc('\n', stderr);
    for (int x = 0; x < 2; x++) for (int k = 0; k < 5; k++) t4_acc[x][k] = 0.0;
    for (int k = 0; k < 4; k++) t4_r[k] = 0.0;
}

'''
    APL = "static void aplicar_e_comer(void) {\n"
    s = troca(s, APL, T4 + APL)
    GARF = "        blocos[i].energia += garfada;\n"
    s = troca(s, GARF, GARF +
        "        t4_acc[blocos[i].peso_arrependimento != 0.0f][4] += garfada;\n")
    MED = "            if (interativo || logf) medir_decisao();\n"
    s = troca(s, MED, MED + "            t4_decisao();\n")
    REM = "            atualizar_remorso();    /* §4.3: le reivindicado[][] antes que suma */\n"
    s = troca(s, REM, REM + "            t4_negados();\n")
    APC = "            aplicar_e_comer();\n"
    s = troca(s, APC, APC + "            t4_despeja();\n")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -Wall -Wextra -O2 -o "$TMP/bin" "$TMP/v.c"
}

for br in NEG POS NUL; do
  if [ "$br" = NEG ]; then V="-2.0"; else V="2.0"; fi
  gen "$V,0.0" "$br" 1; mv "$TMP/bin" "$TMP/${br}_A"     # A: X nos pares
  gen "0.0,$V" "$br" 1; mv "$TMP/bin" "$TMP/${br}_B"     # B: X nos impares
  gen "$V,0.0" "$br" 0; mv "$TMP/bin" "$TMP/${br}_A0"    # sem sonda (S1)
  gen "0.0,$V" "$br" 0; mv "$TMP/bin" "$TMP/${br}_B0"
done

# --- extrator por corrida: somas por janela -----------------------------------
# fluxo: tick | Z: nb comida rivais neg garf | X: nb comida rivais neg garf |
#        redir dcomida drivais s2
cat > "$TMP/extrai.py" <<'PY'
import sys
fluxo, br, seed, m = sys.argv[1:5]
L = [list(map(float, l.split(","))) for l in open(fluxo)]
s2 = sum(r[14] for r in L)
out = [br, seed, m, f"{s2:.0f}"]
for W in (500, 2000, 5000):
    out += [f"{sum(r[k] for r in L[:W]):.6f}" for k in range(1, 14)]
print("\t".join(out))
PY

cat > "$TMP/worker.sh" <<'WORKER'
set -eu
export LC_ALL=C
TMP=$1; br=$2; s=$3; TICKS=$4; S0=$5
for m in A B; do
  c="$TMP/csv/${br}_${s}_$m.csv"; x="$TMP/csv/${br}_${s}_$m.t4"
  "$TMP/${br}_$m" "$s" "$TICKS" 0 --log "$c" >/dev/null 2>"$x"
  md5sum "$c" "$x" | cut -d' ' -f1 | tr '\n' ' ' > "$TMP/md5/${br}_${s}_$m.txt"
  python3 "$TMP/extrai.py" "$x" "$br" "$s" "$m" > "$TMP/met/${br}_${s}_$m.tsv"
  rm -f "$x"
  [ "$s" = "$S0" ] || rm -f "$c"          # guarda os CSVs da primeira seed (S1)
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
  for br in NEG POS NUL; do
    printf '%s %s %s %s %s\n' "$TMP" "$br" "$s" "$TICKS" "$S0" >> "$TMP/tarefas.txt"
  done
done
xargs -P "$JOBS" -n 5 "$TMP/worker.sh" < "$TMP/tarefas.txt"
cat "$TMP/met/"*.tsv | sort > "$TMP/metricas.tsv"

echo ""
echo "=============================================================="
echo "  S1 -- o patch nao toca o mundo   |   S3 -- paralelismo"
echo "=============================================================="
falha=0
for br in NEG POS NUL; do for m in A B; do
  "$TMP/${br}_${m}0" "$S0" "$TICKS" 0 --log "$TMP/s1.csv" >/dev/null 2>&1
  a=$(md5sum "$TMP/s1.csv" | cut -d' ' -f1); b=$(md5sum "$TMP/csv/${br}_${S0}_$m.csv" | cut -d' ' -f1)
  if [ "$a" = "$b" ]; then r=IDENTICOS; else r=DIFEREM; falha=1; fi
  echo "      S1 $br/$S0/$m  sem patch $a  com patch $b  $r"
done; done
"$TMP/NEG_A" "$S0" "$TICKS" 0 --log "$TMP/solo.csv" >/dev/null 2>"$TMP/solo.t4"
solo=$(md5sum "$TMP/solo.csv" "$TMP/solo.t4" | cut -d' ' -f1 | tr '\n' ' ')
par=$(cat "$TMP/md5/NEG_${S0}_A.txt")
if [ "$solo" = "$par" ]; then r=IDENTICOS; else r=DIFEREM; falha=1; fi
echo "      S3 NEG/$S0/A  painel: $par"
echo "      S3 NEG/$S0/A  sozinha: $solo $r"
[ "$falha" = 0 ] || { echo "      SANIDADE FALHOU -- o painel e NULO (Sec4.14)."; exit 1; }

echo ""
echo "=============================================================="
echo "  S2 e P1..P5 -- as predicoes do Sec4.14"
echo "=============================================================="
python3 - "$TMP/metricas.tsv" <<'PY'
import sys, random
from math import comb

R = {}
for linha in open(sys.argv[1]):
    c = linha.rstrip("\n").split("\t")
    br, seed, m = c[0], int(c[1]), c[2]
    r = {"s2": int(c[3])}
    for k, W in enumerate((500, 2000, 5000)):
        t = list(map(float, c[4+13*k:17+13*k]))
        r[W] = {"Z": t[0:5], "X": t[5:10], "r": t[10:13]}
    R[(br, seed, m)] = r
SEEDS = sorted({s for _, s, _ in R}); N = len(SEEDS)
s2 = sum(r["s2"] for r in R.values())
print(f"  S2 alvo recalculado COM termo != alvo real: {s2}   (tem de ser 0)")
if s2:
    print("  SANIDADE FALHOU -- o painel e NULO (Sec4.14)."); sys.exit(1)

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

# k: 0 nb, 1 comida, 2 rivais, 3 negados, 4 garfada ; r: 0 redir, 1 dcomida, 2 drivais
def por_seed(br, s, W, qual):
    vs = []
    for m in "AB":
        q = R[(br, s, m)][W]; X, Z, rr = q["X"], q["Z"], q["r"]
        if X[0] == 0 or Z[0] == 0: continue
        if   qual == "R_comida": vs.append(rr[1] / X[0])
        elif qual == "R_rivais": vs.append(rr[2] / X[0])
        elif qual == "redir":    vs.append(rr[0] / X[0])
        else:
            k = {"E_comida": 1, "E_rivais": 2, "E_negado": 3, "E_garfada": 4}[qual]
            vs.append(X[k] / X[0] - Z[k] / Z[0])
    return sum(vs) / len(vs) if vs else None

rng = random.Random(20261102)
TESTES = [("P1 ", "NEG", "R_comida", +1, True), ("P2 ", "NEG", "R_rivais", +1, True),
          ("P3 ", "POS", "R_comida", -1, True), ("P3 ", "POS", "R_rivais", -1, True),
          ("P4 ", "NUL", "R_comida", 0, True), ("P4 ", "NUL", "R_rivais", 0, True),
          ("P5 ", "NEG", "E_garfada", +1, True),
          ("   ", "POS", "E_garfada", 0, False), ("   ", "NUL", "E_garfada", 0, False),
          ("   ", "NEG", "E_negado", 0, False), ("   ", "POS", "E_negado", 0, False),
          ("   ", "NUL", "E_negado", 0, False),
          ("   ", "NEG", "E_comida", 0, False), ("   ", "POS", "E_comida", 0, False),
          ("   ", "NUL", "E_comida", 0, False),
          ("   ", "NEG", "E_rivais", 0, False), ("   ", "POS", "E_rivais", 0, False),
          ("   ", "NUL", "E_rivais", 0, False),
          ("   ", "NEG", "redir", 0, False), ("   ", "POS", "redir", 0, False),
          ("   ", "NUL", "redir", 0, False)]
for W in (2000, 500, 5000):
    print(f"\n  ---- W = {W} ({'PRIMARIA' if W == 2000 else 'sensibilidade'}) ----")
    for rot, br, qual, sinal, teste in TESTES:
        v = [por_seed(br, s, W, qual) for s in SEEDS]
        vv = [x for x in v if x is not None]
        pos = sum(1 for x in vv if x > 0); neg = sum(1 for x in vv if x < 0)
        lin = f"  {rot}{br} {qual:9s} >0 em {pos:2d}/{N} (<0 em {neg:2d})  mediana {mediana(vv):+.6f}"
        if N - len(vv): lin += f"  ({N - len(vv)} seed(s) com tipo extinto)"
        if teste:
            if sinal > 0:   k = pos; vered = "CONFIRMA" if k >= 21 else "NAO CONFIRMA"
            elif sinal < 0: k = neg; vered = "CONFIRMA" if k >= 21 else "NAO CONFIRMA"
            else:
                k = max(pos, neg)
                vered = "EFEITO DETECTADO" if (pos >= 21 or pos <= 9) else "NAO DETECTADO"
            p = binom_ge(k, N) if sinal else min(1.0, 2 * binom_ge(k, N))
            lin += f"  p {p:.2e}  -> {vered}"
            if W == 2000: lin += f"  Wilcoxon p {wilcoxon_perm(vv, rng):.5f}"
        print(lin)

print("\n  ---- por seed, W = 2000: R_comida, R_rivais (NEG) | E_garfada (NEG, POS, NUL) ----")
f = lambda x: "  extinto" if x is None else f"{x:+.5f}"
for s in SEEDS:
    print(f"    seed {s}:  {f(por_seed('NEG', s, 2000, 'R_comida'))}  {f(por_seed('NEG', s, 2000, 'R_rivais'))}"
          f"  |  {f(por_seed('NEG', s, 2000, 'E_garfada'))}  {f(por_seed('POS', s, 2000, 'E_garfada'))}"
          f"  {f(por_seed('NUL', s, 2000, 'E_garfada'))}")
PY
