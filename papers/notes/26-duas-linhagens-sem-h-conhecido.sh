#!/bin/sh
# Nota 26 (eixo microscopio): "HA DUAS LINHAGENS DISTINTAS?" — SEM conhecer
# h* de antemao.
#
# A nota 23 classificou bimodalidade flanqueando um h*(delta) que as notas
# 19/20 ja tinham descoberto por invasao pareada — legitimo para TESTAR a
# teoria, mas e trapaca para um detector que devia "produzir conhecimento
# sobre a Matrix" (ROADMAP): ele recebia a resposta pronta. Esta nota
# generaliza o criterio para descobrir o ponto de corte SOZINHO, a partir só
# do histograma — e valida contra os MESMOS cenarios de terreno conhecido da
# nota 23 (reanalisando `datasets/bimodalidade.csv`, sem rodar nada de novo:
# o dataset ja tem os 12 bins crus por seed).
#
# O ALGORITMO (generico, sem sqrt, decidido ANTES de rodar a reanalise).
# Dado um histograma p_h (h=1..12, normalizado):
#   1. Para cada h interior (2..11): maxEsq(h) = max(p_1..p_{h-1});
#      maxDir(h) = max(p_{h+1}..p_12).
#   2. h e candidato a VALE se p_h < maxEsq(h) E p_h < maxDir(h) — um bin mais
#      baixo que o MAIOR pico de cada lado (nao so o vizinho imediato: isso e
#      o que corrige o defeito que a nota 23 achou e descartou ANTES do seu
#      proprio pre-registro — contagem de picos locais fragmentava um modo
#      largo e ruidoso em "3-4 picos" espurios porque comparava só com o
#      vizinho adjacente; comparar com o maximo corrido de cada lado ignora
#      ziguezague intermediario e so acusa vale onde ha de fato um pico maior
#      dos dois lados).
#   3. Entre os vales candidatos, o ESCOLHIDO e o de menor profundidade
#      relativa: prof(h) = p_h / min(maxEsq(h), maxDir(h)).
#   4. BIMODAL se, no vale escolhido h*: prof(h*) <= 0,5 (o vale desce a
#      menos da metade do menor pico) E massa_esq = soma(p_1..p_{h*-1}) >=
#      0,15 E massa_dir = soma(p_{h*+1}..p_12) >= 0,15 (o bin do vale fica de
#      fora dos dois lados — mesma logica de buffer da nota 23).
# E uma extensao EXATA do criterio da nota 23 (vale <= 50% do menor pico,
# massa >= 15% de cada lado) — a unica mudanca e que h* deixa de ser dado,
# vira DESCOBERTO.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   E0 (sanidade — a versao AO VIVO nao muda a simulacao): portado para
#       dentro do main.c (reaproveitando o histograma da nota 23), roda uma
#       corrida de demonstracao com --log e confirma CSV bit a bit identico
#       ao vanilla quando HIST_TOTAL nao esta setado (mesma sonda, mesmo
#       cuidado da nota 23).
#   E1 (concordancia nos casos que a nota 23 ja decidiu): reanalisando
#       `datasets/bimodalidade.csv` com o algoritmo generico (sem receber
#       h* nenhum), a classificacao concorda com a da nota 23 em >= 6/8
#       seeds em CADA condicao onde a nota 23 tinha um veredito forte:
#       delta=0,90/0,95/0,96 em uni_h_livre (nota 23: 8/8 bimodais) e
#       delta=0,80 + livre (nota 23: minoria/zero bimodais).
#   E2 (as discordancias sao o achado, nao o ruido): reportar TODA seed em
#       que o generico e o informado por h* discordam, com o histograma —
#       sem limiar de quantas sao "aceitaveis". Um detector que descobre
#       sozinho pode legitimamente discordar de um que recebeu a resposta
#       (o vale mais nitido nem sempre e o mais perto do h* teorico), e essa
#       discordancia e dado, nao falha.
#   E3 (demonstracao ao vivo): num cenario que a nota 23 ja sabe ser bimodal
#       (uni_h_livre, delta=0,95, 1 seed), o classificador AO VIVO (rodando
#       dentro da propria simulacao, sem python) concorda com a reanalise
#       post-hoc do mesmo histograma.
#
# Custo: a reanalise (E1/E2) e sobre dados JA COLETADOS — sem novas corridas
# de 30000 ticks. So E0/E3 rodam simulacao nova (2 corridas curtas).
#
# Nao entra no datasets/gerar.sh. Nao gera dataset novo — reanalisa
# `datasets/bimodalidade.csv` e escreve o resultado na propria nota.
#
#   sh papers/notes/26-duas-linhagens-sem-h-conhecido.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO = r"""
/* ============ HISTOGRAMA + CLASSIFICADOR AO VIVO (nota 23/26) ============ */
#define HIST_JANELA 5000
#define HIST_STRIDE 250
static double hist_soma[13];   /* indice 1..12 */
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

/* Classificador GENERICO (nota 26): descobre o vale sozinho, sem receber
 * h* — mesma logica da reanalise em python, portada para dentro do main.c
 * (a Matrix escrevendo o proprio relatorio, nao um script por fora). */
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
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "h,soma\n");
    for (int h = 1; h <= 12; h++) fprintf(fp, "%d,%.0f\n", h, hist_soma[h]);
    fclose(fp);
    const char *arq2 = getenv("LINH_ARQ");
    if (!arq2) return;
    FILE *fp2 = fopen(arq2, "w");
    if (!fp2) return;
    fprintf(fp2, "bimodal,h_vale,prof,massa_esq,massa_dir\n");
    fprintf(fp2, "%d,%d,%.4f,%.4f,%.4f\n",
        linh_bimodal, linh_h_vale, linh_prof, linh_massa_esq, linh_massa_dir);
    fclose(fp2);
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

def uni_h_livre(s):
    s = troca(s,
      "static void semear_blocos(void) {\n    n_blocos = 0;",
      "static float TORN_DESC = DESCONTO;\n"
      "static void semear_blocos(void) {\n"
      "    { const char *d = getenv(\"TORN_DESC\"); if (d) TORN_DESC = (float)atof(d); }\n"
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
    return s

open(f"{tmp}/livre_hist.c", "w").write(hist(src))
open(f"{tmp}/uni_h_hist.c", "w").write(uni_h_livre(hist(src)))
PY

gcc -std=c11 -O2 -o "$TMP/livre_hist" "$TMP/livre_hist.c" 2>"$TMP/gcc1.err" \
  || { echo "gcc falhou (livre_hist):"; cat "$TMP/gcc1.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/uni_h_hist" "$TMP/uni_h_hist.c" 2>"$TMP/gcc2.err" \
  || { echo "gcc falhou (uni_h_hist):"; cat "$TMP/gcc2.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

echo "== E0: a sonda + classificador ao vivo nao mudam a simulacao =="
"$TMP/vanilla"     7 2000 0 --log "$TMP/e0_van.csv" >/dev/null 2>&1
"$TMP/livre_hist"  7 2000 0 --log "$TMP/e0_hist.csv" >/dev/null 2>&1
cmp -s "$TMP/e0_van.csv" "$TMP/e0_hist.csv" \
  || { echo "E0 FALHOU: a sonda mudou a simulacao. PARAR."; exit 1; }
echo "   E0 ok: CSV bit a bit identico ao vanilla"

echo ""
echo "== E3: demonstracao ao vivo (uni_h_livre, delta=0,95, seed 1 — bimodal conhecido) =="
TORN_DESC=0.95 HIST_TOTAL=30000 HIST_ARQ="$TMP/e3_hist" LINH_ARQ="$TMP/e3_linh" \
  "$TMP/uni_h_hist" 1 30000 0 >/dev/null 2>&1
echo "   histograma (deve bater com o piloto da nota 23, seed 1, delta=0,95):"
cat "$TMP/e3_hist" | tr '\n' ' '; echo
echo "   veredito AO VIVO (dentro do main.c, sem python):"
cat "$TMP/e3_linh"

echo ""
echo "== E1/E2: reanalise generica de datasets/bimodalidade.csv (sem h* dado) =="
python3 - "$RAIZ/datasets/bimodalidade.csv" <<'PY'
import sys, csv

rows = list(csv.DictReader(open(sys.argv[1])))

def classifica_generico(hs):
    total = sum(hs)
    if total <= 0:
        return None
    p = [x / total for x in hs]  # p[0]=h1 .. p[11]=h12
    candidatos = []
    for i in range(1, 11):  # h interior = indices 1..10 (h=2..11)
        maxEsq = max(p[0:i])
        maxDir = max(p[i+1:12])
        if p[i] < maxEsq and p[i] < maxDir:
            prof = p[i] / min(maxEsq, maxDir)
            candidatos.append((i, prof))
    if not candidatos:
        return {"bimodal": False, "h_vale": None, "prof": None}
    i, prof = min(candidatos, key=lambda x: x[1])
    massa_esq = sum(p[0:i])
    massa_dir = sum(p[i+1:12])
    bimodal = (prof <= 0.5) and (massa_esq >= 0.15) and (massa_dir >= 0.15)
    return {"bimodal": bimodal, "h_vale": i + 1, "prof": prof,
            "massa_esq": massa_esq, "massa_dir": massa_dir}

# classificacao da nota 23 (regiao fixa flanqueando h* conhecido)
REGIOES = {
    "0.80": (range(1, 10), range(11, 13)),
    "0.90": (range(1, 9),  range(12, 13)),
    "0.95": (range(1, 7),  range(10, 13)),
    "0.96": (range(1, 6),  range(9, 13)),
    "evol": (range(1, 6),  range(9, 13)),
}
def classifica_nota23(hs, delta):
    total = sum(hs)
    if total <= 0:
        return None
    p = {h: hs[h - 1] / total for h in range(1, 13)}
    baixa, alta = REGIOES[delta]
    m_baixa = sum(p[h] for h in baixa)
    m_alta = sum(p[h] for h in alta)
    return (m_baixa >= 0.15) and (m_alta >= 0.15)

por_cond = {}
discordancias = []
for r in rows:
    hs = [float(r[f"h{h}"]) for h in range(1, 13)]
    key = (r["variante"], r["desconto"])
    g = classifica_generico(hs)
    n23 = classifica_nota23(hs, r["desconto"])
    por_cond.setdefault(key, []).append((r["seed"], g, n23, hs))
    if g and (g["bimodal"] != n23):
        discordancias.append((key, r["seed"], g, n23, hs))

print("\n-- E1: concordancia generico x nota-23-informado, por condicao --")
for key in sorted(por_cond):
    entradas = por_cond[key]
    nbim_g = sum(1 for _, g, _, _ in entradas if g and g["bimodal"])
    nbim_23 = sum(1 for _, _, n23, _ in entradas if n23)
    concordam = sum(1 for _, g, n23, _ in entradas if g and g["bimodal"] == n23)
    print(f"  {key[0]:<8} delta={key[1]:<6}  generico={nbim_g}/{len(entradas)}  "
          f"nota23={nbim_23}/{len(entradas)}  concordam={concordam}/{len(entradas)}")

print("\n-- E2: TODAS as discordancias (generico != nota 23), com o vale achado --")
if not discordancias:
    print("  nenhuma")
for key, seed, g, n23, hs in discordancias:
    print(f"  {key[0]} delta={key[1]} seed={seed}: generico={g['bimodal']} "
          f"(vale em h={g['h_vale']}, prof={g['prof']:.3f}, "
          f"massa_esq={g.get('massa_esq',0):.3f}, massa_dir={g.get('massa_dir',0):.3f}) "
          f"x nota23={n23}  hist={hs}")
PY
