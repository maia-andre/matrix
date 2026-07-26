#!/bin/sh
# Nota 28 (Paper 2 / eixo microscopio): CARGA DE MUTACAO OU RAMIFICACAO REAL EM
# delta=0,80? — decidido desligando a mutacao de horizonte.
#
# A nota 26 votou "carga de mutacao" para o resultado ambiguo de delta=0,80 na
# nota 23 (4/8 seeds "bimodais" pela particao fixa; 0/8 pelo vale descoberto —
# o histograma e uma cauda enviesada rumo ao teto, nao dois picos). Mas votar
# nao e isolar: a propria nota 26 registrou que decidir de vez exigia "uma
# variante com mutacao de horizonte desligada (equilibrio sem introducao
# continua de mutantes) comparada a uma com mutacao". Esta nota constroi essa
# variante.
#
# O DESENHO. Mesmo fundo pregado das notas 20/23/26 (uni_h_livre: desconto,
# urgencia, peso_espaco, estrategia pregados) e o horizonte semeado 1..12 —
# mas agora com MUT_HORIZ comutavel por ambiente: ligada (=1, reproduz a nota
# 23/26 exatamente — e a ancora G0) ou desligada (=0, cria->horizonte =
# pai->horizonte, SEM chamar muta_horizonte — so a semeadura inicial fornece
# variacao; a partir dai e selecao pura, sem reintroducao de mutantes).
#   - Se "carga de mutacao": sem mutacao alimentando o lado baixo, a selecao
#     (que favorece o teto em delta=0,80) deveria varrer a populacao para
#     quase-monomorfismo em h=12 — a massa baixa deveria DESABAR.
#   - Se "ramificacao real, ainda que fraca": o vale deveria SOBREVIVER (ou
#     ate aprofundar) mesmo sem mutantes novos — a coexistencia e mantida
#     pela propria selecao frequencia-dependente, nao pela reposicao de
#     mutantes.
# So precisa rodar a condicao NOVA (mutacao desligada): a de mutacao ligada
# ja esta em `datasets/bimodalidade.csv` (nota 23), 8 seeds, delta=0,80.
#
# O QUE O PILOTO ENSINOU (4 seeds, nao commitado — decidiu que a predicao
# original, "e tudo carga de mutacao", estava errada demais para pre-
# registrar como esta). Testei as 4 seeds que a nota 23 tinha marcado
# "bimodal" pela particao fixa (3, 5, 6, 8). O resultado FOI MISTO, nao
# uniforme: as seeds 6 e 8 desabam para quase-monomorfismo no teto (massa
# baixa cai a 1,7% e 2,3%) — carga de mutacao confirmada nelas. Mas as seeds
# 3 e 5 fazem o OPOSTO do previsto: SEM NENHUMA mutacao nova, o vale
# SOBREVIVE e ATE APROFUNDA (prof=0,24 e 0,00 — o de 0,00 tem literalmente
# ZERO populacao no vale), com massa quase igual dos dois lados (58%/36% e
# 51%/49%). Duas dessas quatro seeds sustentam uma bimodalidade MAIS limpa
# sem mutacao do que com ela — o oposto exato do que "carga de mutacao"
# previa, e evidencia estrutural de um polimorfismo genuino (nenhum mutante
# novo esta alimentando o lado baixo, e ele nao desaparece).
#
# PRE-REGISTRO (o piloto derrubou a predicao original ANTES deste commit —
# convencao da nota 16/21/23: medir o instrumento, e a direcao, antes de
# escrever o numero final):
#   G0 (sanidade — ancora): com MUT_HORIZ=1 (padrao), a corrida reproduz
#       EXATAMENTE o histograma que a nota 23 ja tinha publicado para
#       (delta=0,80, seed 1) — confirmado no piloto (12 bins identicos).
#   G1 (a resposta e MISTA, nao um veredito unico para delta=0,80): das 8
#       seeds com MUT_HORIZ=0, uma fracao NAO-TRIVIAL e NAO-TOTAL continua
#       bimodal pelo criterio da nota 26 (vale descoberto, prof<=0,5, massa
#       >=15% dos dois lados) — nem 0/8 (que confirmaria "e so carga de
#       mutacao", refutado no piloto) nem 8/8 (que confirmaria ramificacao
#       limpa em toda seed). Predicao quantitativa, ancorada no piloto:
#       2 a 5 de 8 seeds bimodais sem mutacao.
#   G2 (nas que colapsam, colapsam MAIS que com mutacao ligada): nas seeds
#       que ficam unimodais com MUT_HORIZ=0, a massa baixa cai para < 5% —
#       mais extremo que qualquer leitura com mutacao ligada (nota 23 tinha
#       m_baixa entre 6,8% e 38,8% nas mesmas seeds) — confirmando que ALI,
#       pelo menos, a mutacao estava mesmo alimentando uma cauda que a
#       selecao, sozinha, varreria.
#   G3 (nas que sustentam, o vale fica tao ou mais limpo): nas seeds que
#       continuam bimodais sem mutacao, a profundidade relativa do vale
#       (prof) e <= a de qualquer seed bimodal com mutacao ligada (nota 26:
#       a mais limpa tinha prof em torno de 0,15-0,30 nas condicoes
#       delta>=0,90) — evidencia de que a coexistencia ali nao depende de
#       reposicao de mutantes.
#
# Custo: 8 corridas de 30000 ticks (so a condicao nova). Medido no piloto,
# ~15-20s cada => poucos minutos com NPROC=16.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/mutacao-off.csv
# (compara-se com datasets/bimodalidade.csv, ja commitado na nota 23).
#   git log -1 --oneline -- datasets/mutacao-off.csv
#
#   sh papers/notes/28-mutacao-ou-ramificacao-em-delta-080.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO = r"""
/* ============ HISTOGRAMA + CLASSIFICADOR (notas 23/26/28) ================ */
#define HIST_JANELA 5000
#define HIST_STRIDE 250
static double hist_soma[13];
static long   hist_total = -1;

static void hist_tick(long t) {
    if (hist_total < 0) {
        const char *e = getenv("HIST_TOTAL");
        hist_total = e ? atol(e) : 0;
    }
    if (hist_total <= 0) return;
    if (t < hist_total - HIST_JANELA) return;
    if (t % HIST_STRIDE != 0) return;
    for (int i = 0; i < n_blocos; i++)
        if (blocos[i].vivo) hist_soma[blocos[i].horizonte] += 1.0;
}

static int    linh_bimodal = 0;
static int    linh_h_vale = -1;
static double linh_prof = -1.0, linh_massa_esq = -1.0, linh_massa_dir = -1.0;

static void linh_classifica(void) {
    double total = 0.0;
    for (int h = 1; h <= 12; h++) total += hist_soma[h];
    if (total <= 0.0) return;
    double p[13];
    for (int h = 1; h <= 12; h++) p[h] = hist_soma[h] / total;
    int melhor_h = -1; double melhor_prof = 1e18;
    for (int h = 2; h <= 11; h++) {
        double maxEsq = 0.0; for (int k = 1; k < h; k++) if (p[k] > maxEsq) maxEsq = p[k];
        double maxDir = 0.0; for (int k = h + 1; k <= 12; k++) if (p[k] > maxDir) maxDir = p[k];
        if (p[h] < maxEsq && p[h] < maxDir) {
            double menor = (maxEsq < maxDir) ? maxEsq : maxDir;
            double prof = p[h] / menor;
            if (prof < melhor_prof) { melhor_prof = prof; melhor_h = h; }
        }
    }
    if (melhor_h < 0) { linh_bimodal = 0; linh_h_vale = -1; return; }
    double me = 0.0; for (int k = 1; k < melhor_h; k++) me += p[k];
    double md = 0.0; for (int k = melhor_h + 1; k <= 12; k++) md += p[k];
    linh_h_vale = melhor_h; linh_prof = melhor_prof;
    linh_massa_esq = me; linh_massa_dir = md;
    linh_bimodal = (melhor_prof <= 0.5) && (me >= 0.15) && (md >= 0.15);
}

static void hist_despeja(void) {
    linh_classifica();
    const char *arq = getenv("HIST_ARQ");
    if (arq) {
        FILE *fp = fopen(arq, "w");
        if (fp) {
            fprintf(fp, "h,soma\n");
            for (int h = 1; h <= 12; h++) fprintf(fp, "%d,%.0f\n", h, hist_soma[h]);
            fclose(fp);
        }
    }
    const char *arq2 = getenv("LINH_ARQ");
    if (arq2) {
        FILE *fp2 = fopen(arq2, "w");
        if (fp2) {
            fprintf(fp2, "bimodal,h_vale,prof,massa_esq,massa_dir\n");
            fprintf(fp2, "%d,%d,%.4f,%.4f,%.4f\n",
                linh_bimodal, linh_h_vale, linh_prof, linh_massa_esq, linh_massa_dir);
            fclose(fp2);
        }
    }
}
/* ========================== fim da sonda ================================= */
"""

def hist(s):
    s = troca(s, "/*  PART 3", BLOCO + "\n/*  PART 3")
    s = troca(s,
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);",
      "            hist_tick(t);\n"
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    hist_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

def uni_h(s):
    s = troca(s,
      "static void semear_blocos(void) {\n    n_blocos = 0;",
      "static float TORN_DESC = DESCONTO;\n"
      "static int   MUT_HORIZ = 1;\n"
      "static void semear_blocos(void) {\n"
      "    { const char *d = getenv(\"TORN_DESC\"); if (d) TORN_DESC = (float)atof(d);\n"
      "      const char *m = getenv(\"MUT_HORIZ\"); if (m) MUT_HORIZ = atoi(m); }\n"
      "    n_blocos = 0;")
    s = troca(s, "b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->urgencia    = (rng01(), URGENCIA);")
    s = troca(s, "b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->peso_espaco = (rng01(), PESO_ESPACO);")
    s = troca(s, "b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
                  "b->desconto    = (rng01(), TORN_DESC);")
    s = troca(s, "b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */",
                  "b->estrategia  = (rng01(), SIN_HONESTO);")
    s = troca(s, "cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);",
                  "cria->urgencia    = pai->urgencia;")
    s = troca(s, "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
                  "cria->peso_espaco = pai->peso_espaco;")
    s = troca(s, "cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
                  "cria->desconto    = pai->desconto;")
    s = troca(s, "cria->estrategia  = muta_estrategia(pai->estrategia);",
                  "cria->estrategia  = pai->estrategia;")
    s = troca(s, "cria->horizonte   = muta_horizonte(pai->horizonte);",
                  "cria->horizonte   = MUT_HORIZ ? muta_horizonte(pai->horizonte)\n"
                  "                              : (rng01(), pai->horizonte);")
    return s

open(f"{tmp}/uni_h.c", "w").write(uni_h(hist(src)))
PY

gcc -std=c11 -O2 -o "$TMP/uni_h" "$TMP/uni_h.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }

# G0: com MUT_HORIZ=1, reproduz EXATAMENTE a nota 23 (delta=0,80, seed 1).
TORN_DESC=0.80 MUT_HORIZ=1 HIST_TOTAL=30000 HIST_ARQ="$TMP/g0" "$TMP/uni_h" 1 30000 0 >/dev/null 2>&1
G0_ESPERADO="0,0,0,11,20,0,0,63,209,344,1440,2364"
G0_OBTIDO=$(awk -F, 'NR>1{printf "%s%s", (NR>2?",":""), $2}' "$TMP/g0")
if [ "$G0_OBTIDO" != "$G0_ESPERADO" ]; then
  echo "G0 FALHOU: esperado [$G0_ESPERADO], obtido [$G0_OBTIDO]"; exit 1
fi
echo "   G0 ok: reproduz exatamente o histograma da nota 23 (delta=0,80, seed 1)"

mkdir -p "$TMP/rows"
export TMP

echo "== corridas: $(echo $SEEDS | wc -w) seeds, delta=0,80, MUT_HORIZ=0, 30000 ticks =="
for s in $SEEDS; do echo "$s"; done | xargs -P "$NPROC" -n 1 sh -c '
    s=$1
    raw="$TMP/raw_$s"; linh="$TMP/linh_$s"
    TORN_DESC=0.80 MUT_HORIZ=0 HIST_TOTAL=30000 HIST_ARQ="$raw" LINH_ARQ="$linh" \
      "$TMP/uni_h" "$s" 30000 0 >/dev/null 2>&1 \
      || { echo "$s" >> "$TMP/falhas"; exit 0; }
    hs=$(awk -F, "NR>1{printf \",%s\", \$2}" "$raw")
    lv=$(tail -n 1 "$linh")
    echo "$s$hs,$lv" > "$TMP/rows/$s.row"
    rm -f "$raw" "$linh"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/mutacao-off.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/mutacao-off.csv"}
{
echo "seed,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,bimodal,h_vale,prof,massa_esq,massa_dir"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== G1/G2/G3: mutacao DESLIGADA, por seed, contra o dado ja commitado (mutacao ligada) =="
awk -F, 'NR>1 { print $1, $14, $15, $16, $17, $18 }' "$SAIDA" | while read -r seed bimodal hvale prof me md; do
  echo "   seed $seed: bimodal=$bimodal vale=h$hvale prof=$prof massa_esq=$me massa_dir=$md"
done

echo ""
echo "== comparacao com a nota 23 (mutacao ligada), massa_esq lado a lado (join por seed) =="
python3 - "$SAIDA" "$RAIZ/datasets/bimodalidade.csv" <<'PY'
import sys, csv
off = {r["seed"]: r for r in csv.DictReader(open(sys.argv[1]))}
on = {}
for r in csv.DictReader(open(sys.argv[2])):
    if r["variante"] == "uni_h" and r["desconto"] == "0.80":
        hs = [float(r[f"h{h}"]) for h in range(1, 13)]
        tot = sum(hs)
        baixa = sum(hs[0:9])  # h1..h9
        on[r["seed"]] = baixa / tot if tot > 0 else 0.0
for seed in sorted(off, key=int):
    lig = on.get(seed)
    des = float(off[seed]["massa_esq"])
    bim = off[seed]["bimodal"]
    lig_s = f"{lig:.4f}" if lig is not None else "?"
    print(f"   seed {seed:<3} massa_baixa(h<=9) ligada={lig_s}  "
          f"massa_esq(vale) desligada={des:.4f}  bimodal_desligada={bim}")
PY

echo ""
echo "== resumo: quantas seeds continuam bimodais sem mutacao? =="
awk -F, 'NR>1 { n++; if ($14==1) b++ } END { printf "   %d/%d bimodais com MUT_HORIZ=0\n", b+0, n }' "$SAIDA"
echo "== fim =="
