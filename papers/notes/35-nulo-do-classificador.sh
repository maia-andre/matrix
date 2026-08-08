#!/bin/sh
# Reproduz a nota 35 (papers/notes/35-nulo-do-classificador.md).
#
# O NULO DO CLASSIFICADOR (pre-registro: ROADMAP.md Sec4.8, ANTES de rodar).
# As notas 32/33/34 declararam tres vezes a mesma ameaca e nunca a mediram: se
# o efeito fundador for estrutural ao harness, nenhum n de seeds separa um
# sinal pequeno de "uma taxa de base nunca medida". Este script para de contar
# seeds e mede a taxa de base -- e um painel da REGUA, nao do mundo.
#
#   N1 -- nulo INERTE (verificacao de algebra, 10 seeds 1..10):
#         ablacao natural do remorso (remorso[i] = 0 depois do calculo; o
#         calculo fica de pe, e prever_valor nao consome RNG -> inocuo ao fluxo).
#         Com remorso == 0 o traco nao entra em utilidade_sigma (unico lugar
#         onde e lido) -> as duas montagens viram a MESMA simulacao bit a bit,
#         so muda o rotulo colado em cada paridade.
#           P1: CSVs de A e B identicos em TODAS as colunas menos arrep_m (24)
#           P2: arrep_m(B) = -arrep_m(A) a cada tick, em toda seed
#           P3: REAL = 0/10 (o classificador nao pode fabricar REAL de traco inerte)
#
#   N2 -- nulo ATIVO (a taxa de base de verdade, 30 seeds 1..30 -- as de T2):
#         mesmo termo do arrependimento, mesma dose (mesmo remorso[i], mesma
#         magnitude, mesma frequencia), com a DIRECAO destruida: sinal +-1 por
#         celula candidata, de um hash independente do campo de comida. Nenhum
#         dos dois valores pode ser sistematicamente melhor; os dois continuam
#         ativos o bastante para decorrelacionar as montagens.
#           P4: REAL(N2) ~ 15/30 (teto: decorrelacao parcial empurra p/ baixo)
#           P5: Fisher exato bilateral T2 (20/30) x N2  -- o numero da nota
#           P6: entre as REAL de N2, a direcao deve dar ~50/50 entre -2,0 e 2,0
#               (T2 deu 20/20 para -2,0; se N2 tambem pender, a nota 34 erra)
#
# Patch temporario sobre o main.c, compilado em tmpdir (tecnica das notas
# 23/24/25) -- o main.c do repo NAO e tocado e nenhum dataset congelado muda.
#
#   sh papers/notes/35-nulo-do-classificador.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS_N1=${SEEDS_N1:-"1 2 3 4 5 6 7 8 9 10"}
SEEDS_N2=${SEEDS_N2:-"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30"}
TICKS=${TICKS_OVERRIDE:-30000}

# T2 ja publicado (notas 33 + 34, pool de 30 seeds), para o Fisher do P5/P6:
T2_REAL=20
T2_N=30
T2_DIR_NEG=20   # das 20 REAL de T2, quantas favorecem -2,0 (nota 34: todas)

VRES="-2.0"; VINV="2.0"; MID="0.0"

# gen "res,inv" BRACO -- o harness 'invasao' das notas 30/32/33/34 SEM mudanca
# (pina os dois valores, desliga a mutacao do traco), mais a ablacao do braco.
gen() {
python3 - "$MAINC" "$TMP" "$1" "$2" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; valor = sys.argv[3]; braco = sys.argv[4]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua ({t.count(a)}x): {a[:70]!r}"
    return t.replace(a, b, 1)

# --- base: o harness 'invasao', identico ao da nota 34 -------------------
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

# --- N1: ablacao natural do remorso (o traco vira rotulo inerte) ---------
if braco == "N1":
    REM_ORIG = "        remorso[i] = remorso[i] * blocos[i].desconto + arrependimento;\n"
    s = troca(s, REM_ORIG, REM_ORIG +
        "        remorso[i] = 0.0f;   /* N1: o calculo fica de pe, o estado nao "
        "acumula */\n")

# --- N2: mesma dose, direcao destruida ----------------------------------
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

valor_tick() { awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"; }

# classifica(afA, afB) -> imprime "REAL <valor>" ou "FUNDADOR -"
# Mesma formula das duas montagens (o bug que a nota 33 pegou era usar formulas
# diferentes para A e B; aqui wA e wB sao identicas por construcao).
classifica() {
  awk -v afA="$1" -v afB="$2" -v mid="$MID" -v vr="$VRES" -v vi="$VINV" 'BEGIN{
      wA = (afA < mid) ? vr : vi;
      wB = (afB < mid) ? vr : vi;
      if (wA == wB) printf "REAL %s", wA; else printf "FUNDADOR -";
  }'
}

echo ""
echo "=============================================================="
echo "  N1 -- o nulo INERTE (ablacao natural do remorso)"
echo "  10 seeds, T2 (-2,0 x 2,0), $TICKS ticks."
echo "  Predito ANTES de rodar: P1 CSVs iguais fora da col 24;"
echo "  P2 arrep_m(B) = -arrep_m(A) a cada tick; P3 REAL = 0/10."
echo "=============================================================="
gen "$VRES,$VINV" N1; mv "$TMP/bin" "$TMP/N1_A"
gen "$VINV,$VRES" N1; mv "$TMP/bin" "$TMP/N1_B"

n1_real=0; n1_p1=0; n1_p2=0; n1_n=0
for s in $SEEDS_N1; do
  "$TMP/N1_A" "$s" "$TICKS" 0 --log "$TMP/N1_A_$s.csv" >/dev/null
  "$TMP/N1_B" "$s" "$TICKS" 0 --log "$TMP/N1_B_$s.csv" >/dev/null
  n1_n=$((n1_n+1))

  # P1: tudo menos arrep_m (col 24) tem de bater bit a bit
  cut -d, -f1-23,25- "$TMP/N1_A_$s.csv" > "$TMP/a.trim"
  cut -d, -f1-23,25- "$TMP/N1_B_$s.csv" > "$TMP/b.trim"
  if cmp -s "$TMP/a.trim" "$TMP/b.trim"; then p1="OK"; n1_p1=$((n1_p1+1)); else p1="FALHOU"; fi

  # P2: arrep_m(B) = -arrep_m(A) em TODOS os ticks
  p2=$(paste -d, "$TMP/N1_A_$s.csv" "$TMP/N1_B_$s.csv" | awk -F, '
      NR>1 { d = $24 + $49; if (d < 0) d = -d; if (d > max) max = d }
      END { printf (max > 1e-6) ? "FALHOU (max %.6f)" : "OK (max %.6f)", max }')
  case "$p2" in OK*) n1_p2=$((n1_p2+1));; esac

  afA=$(valor_tick "$TMP/N1_A_$s.csv" 24 $((TICKS-1)))
  afB=$(valor_tick "$TMP/N1_B_$s.csv" 24 $((TICKS-1)))
  cls=$(classifica "$afA" "$afB")
  case "$cls" in REAL*) n1_real=$((n1_real+1));; esac
  printf '      seed %-3s  A %8s  B %8s  | P1 %-6s  P2 %-18s  %s\n' \
         "$s" "$afA" "$afB" "$p1" "$p2" "$cls"
done
printf '\n  N1: P1 %d/%d   P2 %d/%d   REAL %d/%d\n' \
       "$n1_p1" "$n1_n" "$n1_p2" "$n1_n" "$n1_real" "$n1_n"
if [ "$n1_p1" -eq "$n1_n" ] && [ "$n1_p2" -eq "$n1_n" ] && [ "$n1_real" -eq 0 ]; then
  echo "  -> P1/P2/P3 CONFIRMAM: traco inerte nunca produz REAL. A algebra do Sec4.8 vale."
else
  echo "  -> ALGUMA PREDICAO FALHOU: a algebra do Sec4.8 esta errada; investigar ANTES de ler N2."
fi

echo ""
echo "=============================================================="
echo "  N2 -- o nulo ATIVO (mesma dose, direcao destruida)"
echo "  30 seeds (as mesmas de T2), $TICKS ticks."
echo "  Predito ANTES de rodar: P4 REAL ~ 15/30 (teto);"
echo "  P6 entre as REAL, direcao ~50/50."
echo "=============================================================="
gen "$VRES,$VINV" N2; mv "$TMP/bin" "$TMP/N2_A"
gen "$VINV,$VRES" N2; mv "$TMP/bin" "$TMP/N2_B"

n2_real=0; n2_n=0; n2_neg=0; n2_pos=0
for s in $SEEDS_N2; do
  "$TMP/N2_A" "$s" "$TICKS" 0 --log "$TMP/N2_A_$s.csv" >/dev/null
  "$TMP/N2_B" "$s" "$TICKS" 0 --log "$TMP/N2_B_$s.csv" >/dev/null
  n2_n=$((n2_n+1))
  afA=$(valor_tick "$TMP/N2_A_$s.csv" 24 $((TICKS-1)))
  afB=$(valor_tick "$TMP/N2_B_$s.csv" 24 $((TICKS-1)))
  cls=$(classifica "$afA" "$afB")
  case "$cls" in
    "REAL $VRES") n2_real=$((n2_real+1)); n2_neg=$((n2_neg+1));;
    "REAL $VINV") n2_real=$((n2_real+1)); n2_pos=$((n2_pos+1));;
  esac
  printf '      seed %-3s  A %8s  B %8s  %s\n' "$s" "$afA" "$afB" "$cls"
done
printf '\n  N2: REAL %d/%d   (direcao entre as REAL: %s -> %d, %s -> %d)\n' \
       "$n2_real" "$n2_n" "$VRES" "$n2_neg" "$VINV" "$n2_pos"

echo ""
echo "=============================================================="
echo "  P5/P6 -- T2 publicado x o nulo ativo"
echo "=============================================================="
python3 - "$n2_real" "$n2_n" "$n2_neg" "$n2_pos" "$T2_REAL" "$T2_N" "$T2_DIR_NEG" <<'PY'
import sys
from math import comb

n2_real, n2_n, n2_neg, n2_pos, t2_real, t2_n, t2_neg = map(int, sys.argv[1:8])

def fisher2x2(a, b, c, d):
    """p bilateral: soma das tabelas com as mesmas margens e P <= P(observada)."""
    n = a + b + c + d
    k = a + c                      # total da 1a coluna
    l1, l2 = a + b, c + d          # totais das linhas
    def P(x):                      # x = celula 'a'
        return comb(l1, x) * comb(l2, k - x) / comb(n, k)
    p_obs = P(a)
    lo, hi = max(0, k - l2), min(l1, k)
    return sum(P(x) for x in range(lo, hi + 1) if P(x) <= p_obs * (1 + 1e-9))

p5 = fisher2x2(t2_real, t2_n - t2_real, n2_real, n2_n - n2_real)
print(f"  P5  T2 {t2_real}/{t2_n} ({100*t2_real/t2_n:.1f}%)  x  N2 {n2_real}/{n2_n} "
      f"({100*n2_real/n2_n:.1f}%)   Fisher exato bilateral p = {p5:.4f}")

# leitura pre-registrada (ROADMAP Sec4.8)
if n2_real <= 10 and p5 < 0.05:
    print("  ->  o desenho quase nao fabrica REAL: os 20/30 de T2 sao sinal, e o")
    print("      'nao decide' vem do CORTE, nao de ausencia de sinal (veredito de T2 fica de pe).")
elif n2_real >= 20:
    print("  ->  a regua fabrica sozinha o que T2 mede: T2 esta morto; as notas 32/33/34")
    print("      mediram o instrumento, nao o mundo.")
elif p5 >= 0.05:
    print("  ->  T2 e INDISTINGUIVEL do nulo: o achado mais forte contra Q5 deste fio.")
else:
    print("  ->  banda intermediaria com diferenca significativa: ler a nota, o pre-registro")
    print("      nao antecipou este canto exato.")

# P6 -- a direcao (o 20/20 da nota 34)
if n2_real:
    def binom_bilateral(k, n):
        pk = comb(n, k) / 2**n
        return sum(comb(n, x) / 2**n for x in range(n + 1)
                   if comb(n, x) / 2**n <= pk * (1 + 1e-9))
    p6_nulo = binom_bilateral(n2_neg, n2_real)
    p6_vs = fisher2x2(t2_neg, t2_real - t2_neg, n2_neg, n2_real - n2_neg)
    print(f"\n  P6  direcao entre as REAL:  T2 {t2_neg}/{t2_real} para -2,0   x   "
          f"N2 {n2_neg}/{n2_real} para -2,0")
    print(f"      N2 contra 50/50 (binomial bilateral) p = {p6_nulo:.4f}; "
          f"T2 x N2 (Fisher) p = {p6_vs:.4f}")
    if n2_neg == n2_real and n2_real >= 5:
        print("  ->  o nulo TAMBEM pende inteiro para -2,0: o 20/20 da nota 34 e assinatura")
        print("      do desenho, nao do mundo -- a nota 34 precisa de ERRATA.")
    elif p6_nulo >= 0.05:
        print("  ->  a direcao do nulo e ~50/50, como previsto: o 20/20 da nota 34 sobrevive")
        print("      como achado sobre o mundo.")
    else:
        print("  ->  a direcao do nulo tem vies proprio (nao 50/50): ler a nota antes de citar")
        print("      o 20/20 da nota 34 como evidencia.")
else:
    print("\n  P6  N2 nao produziu nenhuma corrida REAL -- sem direcao para comparar.")
print("")
PY
