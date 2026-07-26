#!/bin/sh
# Nota 23 (Paper 2): O TESTE DE BIMODALIDADE — a evolucao livre produz uma
# distribuicao de horizontes bimodal?
#
# A nota 20 achou que o h* nao e um ESS: e um PONTO DE RAMIFICACAO (convergence-
# stable + invasivel dos dois lados), a assinatura de um polimorfismo protegido.
# Mas a nota 20 mediu isso por INVASAO PAREADA (residente x invasor raro, so DOIS
# valores de horizonte por corrida, mutacao desligada). O ROADMAP §pos-nota-20
# declarou o teste direto que falta: "a evolucao livre produz uma distribuicao de
# horizontes BIMODAL?" — deixa o horizonte mutar livremente por TODO o dominio
# 1..12 (nao so dois valores) e olha a FORMA da distribuicao numa unica populacao,
# a mesma pergunta que "hor_m e ruido disperso entre seeds" (nota 15) levanta mas
# nao decide: disperso ENTRE seeds e bimodal DENTRO de uma populacao sao coisas
# diferentes, e so a segunda testa ramificacao de verdade.
#
# DUAS CONDICOES, DUAS PERGUNTAS (um piloto de 1-3 seeds, nao commitado, decidiu
# o desenho — ver §"o que o piloto ensinou" abaixo):
#   uni_h_livre = o MESMO fundo da nota 20 (desconto, urgencia, peso_espaco e
#       estrategia PREGADOS, mutacao desligada NELES — "resto pregado"), mas o
#       horizonte semeado 1..12 e mutando NORMALMENTE (sem restricao a dois
#       valores). Testa se o ponto de ramificacao da nota 20, no MESMO fundo em
#       que foi medido, produz uma populacao de fato bimodal quando o traco pode
#       explorar o dominio inteiro.
#   livre = a evolucao de verdade (main.c vanilla + so a sonda do histograma):
#       TODOS os tracos livres, inclusive o proprio desconto. E o teste LITERAL
#       que o ROADMAP pede, ligado ao hor_m da nota 15.
#
# O QUE O PILOTO ENSINOU (e por que o desenho tem duas condicoes, nao uma). Um
# primeiro piloto pregou SO o desconto (delta=0.80/0.95) e deixou urgencia/
# peso_espaco/estrategia livres: o horizonte convergiu para ~3, NADA parecido
# com o h*=8/7 da nota 20 — porque o h* da nota 20 foi medido com o FUNDO INTEIRO
# pregado, e outros tracos livres mudam a paisagem de aptidao do horizonte por
# completo (e o proprio achado da nota 15: profundidade evoluida LIVRE = 3,31,
# bem abaixo do h* do torneio). Um segundo piloto, no fundo EXATO da nota 20
# (uni_h_livre), achou bimodalidade LIMPA em delta=0.90/0.95/0.96 (vale entre os
# picos caindo a 0-15% do pico menor) e unimodal em delta=0.80 (dominado pelo
# teto h=12) — o piloto que decidiu manter esta condicao como o teste central.
# Um terceiro piloto (livre, 3 seeds) nao achou bimodalidade em NENHUMA seed —
# mas o pico UNICO de cada seed pousou em lugares MUITO diferentes (h~3, h~8,
# h~9): é a dispersao de hor_m da nota 15, vista agora como "cada corrida
# converge para UM ponto so, e o ponto varia", nao como populacao ambivalente.
#
# COMO SE MEDE BIMODALIDADE (o histograma e discreto, 1..12 — nao precisa de
# teste continuo tipo Hartigan's dip). Numa janela tardia (ultimos 5000 ticks,
# amostrada a cada 250 — 20 leituras, o mesmo espirito de janela da nota 12),
# soma-se quantos blocos vivos tem cada horizonte, agregado ao longo da janela.
# Um PRIMEIRO criterio (contar picos locais com um limiar de massa) se mostrou
# FRAGIL: o ruido de amostragem finita (populacao ~250-300, 20 leituras) cria
# ziguezagues locais dentro do que e claramente UM modo largo, fragmentando-o
# em "3-4 picos" espurios — o piloto pegou isso ANTES do pre-registro (regra
# de "medir o instrumento antes" da nota 16). O criterio adotado e mais grosso
# e mais robusto: MASSA EM DUAS REGIOES fixas, flanqueando o h*(delta) que as
# notas 19/20 ja localizaram (0,80 -> teto/12, censurado; 0,90 -> ~10; 0,95 ->
# 8; 0,96 -> 7), com um "buffer" de bins ao redor de h* que nao conta para
# nenhum lado (a regiao muda de bin a bin por causa de ruido, mas raramente
# muda de LADO). BIMODAL se a massa da regiao BAIXA (bem abaixo de h*) E a da
# regiao ALTA (bem acima) sao AMBAS >= 15% — dois morfos genuinos, nao um
# ombro. Sem sqrt, sem deteccao de pico — so soma de fracoes.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   B0a (sanidade): 'livre' (so a sonda do histograma, sem pino nenhum) produz
#       CSV --log bit a bit identico ao vanilla. Se falhar: parar tudo.
#   B0b (sanidade do fundo): 'uni_h_livre' prega desc_m/urg_m/esp_m com sd~0 e
#       hon_f=1,000 (estrategia pregada), e horizonte com sd > 0 (livre de
#       verdade) — confirmado no piloto (desc_sd=0,0002; urg_sd=esp_sd=0;
#       hor_sd=3,04 em delta=0,95).
#   B1 (o teste central, DENTRO do fundo pregado da nota 20): a fracao de seeds
#       classificadas BIMODAIS (por definicao, ja flanqueando o h* de cada
#       delta) em 'uni_h_livre' cresce com delta — <= 2/8 em delta=0,80 (regime
#       teto quase-ESS da nota 20); >= 6/8 em CADA UM de delta=0,90, 0,95 e
#       0,96 (regime de ramificacao da nota 20). A propria definicao do criterio
#       (regiao baixa/alta flanqueando h*) faz B1 conter o que seria um "B2" —
#       nao ha como classificar BIMODAL sem os dois morfos estarem nos dois
#       lados do ponto de ramificacao.
#   B2 (o teste literal do ROADMAP, evolucao de verdade): em 'livre', a fracao
#       de seeds bimodais (particao generica baixa<=5 / alta>=9, ja que delta
#       tambem evolui e nao ha um h* unico de referencia) e BAIXA (<= 2/8) —
#       mas a MODA principal de cada seed varia muito (sd entre seeds > 2, no
#       dominio 1..12) — cada corrida
#       comete a um ponto so, e o ponto disperso e o que a nota 15 mediu como
#       hor_m ruidoso. Falsearia B2: se a maioria das seeds livres tambem for
#       bimodal, a coevolucao dos outros tracos NAO apaga a ramificacao.
#
# Custo: medido no piloto, ~18s/corrida a 30000 ticks. (4 delta x 8 seeds)
# uni_h_livre + 8 livre = 40 corridas => ~12 min seriais, poucos minutos com
# NPROC=16.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/bimodalidade.csv (uma
# linha por variante x delta x seed: as 12 somas do histograma da janela).
#   git log -1 --oneline -- datasets/bimodalidade.csv
#
#   sh papers/notes/23-bimodalidade.sh                     # lote completo
#   SEEDS_LISTA="7" sh papers/notes/23-bimodalidade.sh     # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-30000}
NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
DESCONTOS=${DESCONTOS:-"0.80 0.90 0.95 0.96"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO_HIST = r"""
/* ============ HISTOGRAMA DE HORIZONTE (nota 23) — medicao pura =========== */
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

static void hist_despeja(void) {
    const char *arq = getenv("HIST_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "h,soma\n");
    for (int h = 1; h <= 12; h++) fprintf(fp, "%d,%.0f\n", h, hist_soma[h]);
    fclose(fp);
}
/* ========================== fim da sonda ================================= */
"""

def hist(s):
    s = troca(s, "/*  PART 3", BLOCO_HIST + "\n/*  PART 3")
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

# ---- "resto pregado" da nota 20 (delta+urgencia+peso_espaco+estrategia
# pregados, mutacao off NELES), horizonte LIVRE (semeio 1..12 + mutacao normal)
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
    return s   # horizonte: b->horizonte e cria->horizonte seguem 100% vanilla

open(f"{tmp}/livre.c", "w").write(hist(src))
open(f"{tmp}/uni_h.c", "w").write(uni_h_livre(hist(src)))
PY

gcc -std=c11 -O2 -o "$TMP/livre" "$TMP/livre.c" 2>"$TMP/gcc_livre.err" \
  || { echo "gcc falhou em livre:"; cat "$TMP/gcc_livre.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/uni_h" "$TMP/uni_h.c" 2>"$TMP/gcc_uni_h.err" \
  || { echo "gcc falhou em uni_h:"; cat "$TMP/gcc_uni_h.err"; exit 1; }
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# B0a: a sonda do histograma NAO muda a simulacao (sem TORN_DESC, e vanilla).
"$TMP/vanilla" 7 2000 0 --log "$TMP/b0a_van.csv" >/dev/null 2>&1
"$TMP/livre"   7 2000 0 --log "$TMP/b0a_liv.csv" >/dev/null 2>&1
cmp -s "$TMP/b0a_van.csv" "$TMP/b0a_liv.csv" \
  || { echo "B0a FALHOU: a sonda mudou a simulacao (CSV difere). PARAR."; exit 1; }
echo "   B0a ok: CSV bit a bit identico ao vanilla"

# B0b: uni_h_livre prega desc/urg/esp/estrategia (sd~0), horizonte livre (sd>0).
TORN_DESC=0.95 "$TMP/uni_h" 7 3000 0 --log "$TMP/b0b.csv" >/dev/null 2>&1
awk -F, 'END {
    bad=0
    if ($8 < 0.9495 || $8 > 0.9505) bad=1
    if ($9 > 0.001) bad=1
    if ($10 < 1.999 || $10 > 2.001) bad=1
    if ($12 < 2.999 || $12 > 3.001) bad=1
    if ($19 != 1) bad=1
    if ($7 < 0.5) bad=1
    exit bad
  }' "$TMP/b0b.csv" \
  || { echo "B0b FALHOU: o fundo nao pregou como esperado"; exit 1; }
echo "   B0b ok: desc/urg/esp/estrategia pregados, horizonte livre (sd>0)"

mkdir -p "$TMP/rows"
export TMP TICKS

NUNI=$(( $(echo $DESCONTOS | wc -w) * $(echo $SEEDS | wc -w) ))
echo "== corridas: $NUNI uni_h_livre + $(echo $SEEDS | wc -w) livre, $TICKS ticks, -P $NPROC =="
{
  for s in $SEEDS; do echo "livre evol $s"; done
  for d in $DESCONTOS; do for s in $SEEDS; do
    echo "uni_h $d $s"
  done; done
} | xargs -P "$NPROC" -n 3 sh -c '
    v=$1; d=$2; s=$3
    raw="$TMP/raw_${v}_${d}_${s}"
    case "$v" in
      livre) HIST_TOTAL="$TICKS" HIST_ARQ="$raw" "$TMP/livre" "$s" "$TICKS" 0 ;;
      uni_h) TORN_DESC="$d" HIST_TOTAL="$TICKS" HIST_ARQ="$raw" "$TMP/uni_h" "$s" "$TICKS" 0 ;;
    esac >/dev/null 2>&1 || { echo "$v $d $s" >> "$TMP/falhas"; exit 0; }
    # transpoe h,soma (13 linhas) numa linha: variante,desconto,seed,h1..h12
    awk -F, -v VAR="$v" -v DV="$d" -v SEED="$s" '"'"'
      NR>1 { v[$1]=$2 }
      END {
        printf "%s,%s,%s", VAR, DV, SEED
        for (h=1; h<=12; h++) printf ",%s", (h in v ? v[h] : 0)
        printf "\n"
      }'"'"' "$raw" > "$TMP/rows/${v}_${d}_${s}.row"
    rm -f "$raw"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/bimodalidade.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/bimodalidade.csv"}
{
echo "variante,desconto,seed,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

python3 - "$SAIDA" <<'PY'
import sys, csv

path = sys.argv[1]
rows = list(csv.DictReader(open(path)))

# regiao_baixa / regiao_alta flanqueando o h*(delta) das notas 19/20, com um
# "buffer" de pelo menos 1 bin ao redor de h* que nao conta para nenhum dos
# dois lados. h*: 0.80 -> teto (12, censurado); 0.90 -> ~10; 0.95 -> 8; 0.96 -> 7.
REGIOES = {
    "0.80": (range(1, 10), range(11, 13)),   # baixa 1-9 | (buffer 10) | alta 11-12
    "0.90": (range(1, 9),  range(12, 13)),   # baixa 1-8 | (buffer 9-11) | alta 12
    "0.95": (range(1, 7),  range(10, 13)),   # baixa 1-6 | (buffer 7-9)  | alta 10-12
    "0.96": (range(1, 6),  range(9, 13)),    # baixa 1-5 | (buffer 6-8)  | alta 9-12
    "evol": (range(1, 6),  range(9, 13)),    # 'livre': particao generica (sem h* unico)
}
LIMIAR = 0.15   # cada regiao precisa de pelo menos 15% da massa

def classifica(hs, delta):
    total = sum(hs)
    if total <= 0:
        return None
    p = {h: hs[h - 1] / total for h in range(1, 13)}
    baixa, alta = REGIOES[delta]
    m_baixa = sum(p[h] for h in baixa)
    m_alta = sum(p[h] for h in alta)
    bimodal = (m_baixa >= LIMIAR) and (m_alta >= LIMIAR)
    modo = max(p, key=lambda h: p[h])
    return {"bimodal": bimodal, "m_baixa": m_baixa, "m_alta": m_alta, "modo": modo, "p": p}

por_cond = {}
for r in rows:
    hs = [float(r[f"h{h}"]) for h in range(1, 13)]
    key = (r["variante"], r["desconto"])
    c = classifica(hs, r["desconto"])
    por_cond.setdefault(key, []).append((r["seed"], c))

print("\n== B1/B2/B3: classificacao por seed (BIMODAL = massa >=15% dos DOIS lados do h*, com buffer) ==")
for key in sorted(por_cond):
    entradas = por_cond[key]
    nbim = sum(1 for _, c in entradas if c and c["bimodal"])
    print(f"\n  {key[0]:<8} delta={key[1]:<6}  bimodais: {nbim}/{len(entradas)}")
    for seed, c in entradas:
        if c is None:
            print(f"    seed {seed}: sem dados")
            continue
        tag = "BIMODAL" if c["bimodal"] else "unimodal"
        print(f"    seed {seed}: {tag:<10} m_baixa={c['m_baixa']:.3f}  m_alta={c['m_alta']:.3f}  modo={c['modo']}")

print("\n== B3 contexto: moda principal por seed em 'livre' (dispersao entre seeds) ==")
for key in sorted(por_cond):
    if key[0] != "livre":
        continue
    modas = [c["modo"] for _, c in por_cond[key] if c]
    if modas:
        m = sum(modas) / len(modas)
        var = sum((x - m) ** 2 for x in modas) / (len(modas) - 1) if len(modas) > 1 else 0.0
        print(f"  modas: {modas}  media={m:.2f}  sd={var**0.5:.2f}")
PY
echo "== fim =="
