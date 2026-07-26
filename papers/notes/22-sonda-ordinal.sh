#!/bin/sh
# Nota 22 (Paper 2): A SONDA ORDINAL — o plano nao preve o valor, mas acerta o rank?
#
# A nota 18 fechou o "elo que falta" do Paper 2 §5/§8 medindo prever_valor como
# PREVISAO: corr(g_k, r_k) cai de ~0,65 (k=0) a quase 0 ja em k=1 — k*=0 em toda
# condicao povoada. Mas a DECISAO (melhor_celula) nunca usa o valor absoluto: ela
# faz um argmax entre ate 9 celulas candidatas (ficar + vizinhos vazios). O §8 do
# Paper 2 e o ROADMAP declaram a divida: "a sonda ordinal (...) Desenho: rank do
# valor previsto x rank do retorno realizado, por decisao, entre as <=9 celulas."
# Esta nota a constroi. A pergunta: o plano pode falhar como PREVISAO (nota 18) e
# ainda assim ajudar a ESCOLHER — bastando ORDENAR as opcoes certo, nao acerta-las
# em valor? Isso explicaria o pico de colheita h=2 > h=1 (nota 17): o termo g_1
# muda o rank mesmo errando o numero.
#
# O QUE A SONDA MEDE. A cada decisao (decidir(i)), enumera os candidatos
# alcancaveis NA MESMA ordem/regra de melhor_celula (ficar + vizinhos vazios) e
# guarda dois valores previstos por candidato: u = a decisao completa (utilidade,
# com o ajuste de antecipar do nivel 5) e m = so o mapa (prever_valor, sem
# antecipar nem espaco). h ticks depois (o horizonte do bloco NAQUELE tick),
# acumula quanto foi REALMENTE extraido de cada celula candidata por QUEM QUER
# QUE SEJA (um acumulador novo, comido[y][x], zerado a cada tick, incrementado no
# mesmo lugar que aplicar_e_comer decrementa comida[][] — pura leitura, nao
# contrafactual: e o que aconteceu na UNICA trajetoria, celula por celula,
# independente de quem a visitou). Concordancia = fracao de PARES discordantes
# entre rank previsto e rank realizado — o MESMO Kendall que phi_proxy ja usa
# (nota 05), de proposito: nunca precisa de sqrt (CLAUDE.md proibe <math.h>).
#
# POR QUE "QUEM QUER QUE SEJA" NAO E TRAPACA. O predicted-vs-realizado da nota 18
# testava SE o proprio bloco ocupasse a celula prevista (a premissa "eu fico la").
# Aqui a pergunta e outra: dado que so UMA das <=9 opcoes sera de fato visitada
# por este bloco, as outras 8 nunca terao "o que MEU bloco teria comido" —
# contrafactual que exigiria ramificar a simulacao (proibido pelo determinismo,
# ROADMAP "Engenharia"). O que SOBREVIVE como fato, para qualquer celula, e
# quanto ALGUEM extraiu dela — e essa e exatamente a grandeza que um planejador
# racional deveria tentar prever ao comparar opcoes: "esta celula tende a valer
# mais que aquela", nao "eu, especificamente, vou comer X".
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13). Um
# piloto de 1 seed (nao commitado, so para validar a sonda) ja confirmou que o
# instrumento compila limpo e reconstroi a decisao real bit a bit — os numeros
# abaixo sao a DIRECAO encontrada nesse piloto, escritos aqui ANTES da corrida de
# 8 seeds que decide de verdade (mesmo espirito da nota 16: medir o instrumento
# antes nao e medir o achado antes).
#   O0a (sanidade, regra 3): a sonda NAO muda a simulacao — CSV --log bit a bit
#       identico ao main.c vanilla, mesma seed/ticks. Se falhar: parar tudo.
#   O0b (sanidade, reconstrucao EXATA): para toda decisao amostrada, o candidato
#       de maior u[] recomputado pela sonda e EXATAMENTE (alvo_x,alvo_y) que
#       melhor_celula(antecipar=1) escolheu de verdade. Isto e determinista —
#       espera-se 100% exato (ok_check == n_check), nao "proximo de".
#   O1 (a concordancia ordinal do mapa): a fracao de pares discordantes entre
#       rank(m) e rank(real) fica BEM ABAIXO do acaso (0,5) em toda condicao
#       povoada (livre, uni h em {4,8,12}, ere). Predicao quantitativa: < 0,25
#       em todas — o rank sobrevive onde o valor (nota 18) ja tinha morrido.
#   O2 (o argmax do mapa bate mais que o acaso): P(argmax(m)==argmax(real) | pelo
#       menos uma garfada real ocorreu) > 3x o baseline 1/n_medio_candidatos, em
#       toda condicao povoada.
#   O3 (dose-resposta com h — o elo com a nota 17): a discordancia (O1) NAO cresce
#       muito de uni h=4 a uni h=12 (diferenca < 0,05 absoluto) — MUITO mais
#       estavel que o colapso do corr(g_k,r_k) da nota 18 (de ~0,65 a quase 0 ja
#       em k=1). E o porque candidato do pico de colheita h=2 (nota 17): o RANK
#       nao degrada como o VALOR degrada.
#   O4 (a decisao completa, u, rastreia melhor quando faminto — SO testavel onde
#       rivais_em varia por celula): em livre e uni, a discordancia rank(u) x
#       rank(real) e MENOR com fome>=0,5 (faminto) que com fome<0,5 (saciado) — o
#       termo de espaco deveria mesmo dominar quando saciado, por desenho (nivel
#       4), e isso nao e "a decisao ficando pior em rastrear comida": e ela fazendo
#       outra coisa de proposito. No ERE (rivais_em fixado em 0 por ablacao), este
#       teste e um CONTROLE NEGATIVO por construcao ALGEBRICA, nao empirica: como
#       rivais_em(*) == 0 para toda celula, 'espaco' e uma CONSTANTE entre
#       candidatos, e u[k] = A*m[k] + B com A=(1+urgencia*fome)>0 e B constante —
#       uma transformacao afim de inclinacao positiva preserva rank EXATAMENTE.
#       Logo rank(u) == rank(m) no ere, ponto por ponto, e a comparacao
#       faminto/saciado ali NAO deve reproduzir o padrao de livre/uni (se
#       reproduzir por acaso de amostragem, tanto faz a direcao — o ere nao testa
#       o mecanismo do O4, testa se a maquinaria nao inventa sinal onde a algebra
#       diz que nao pode haver).
#
# Desenho: 3 variantes do binario, todas patch sobre main.c (main.c INTOCADO):
#   livre = vanilla + sonda (evolucao solta);
#   uni   = patch tipo-unico da nota 17 (sem uma virgula de diferenca) + sonda,
#           h em {4, 8, 12} x delta em {0.80, 0.90, 0.95}, seeds 1..8;
#   ere   = patch eremita das notas 04/09/11 (rivais_em/pretendentes_em == 0,
#           MAS a populacao inteira continua evoluindo — nao e "um bloco so no
#           mundo": e "toda a populacao cega para rivais") + sonda, seeds 1..8.
# 3000 ticks; planos pontuam do tick 500 em diante (mesmo burn-in da nota 18).
#
# Custo: medido no piloto, ~5,3 s/corrida a 3000 ticks. 72 uni + 8 livre + 8 ere
# = 88 corridas => ~8 min seriais, poucos minutos com NPROC=16. Se passar de 30
# min, ha algo errado (a serie de erratas de custo manda desconfiar de excesso).
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/sonda-ordinal.csv (uma
# linha por variante x delta x h x seed, ja resumida — sem despejo por decisao).
#   git log -1 --oneline -- datasets/sonda-ordinal.csv
#
#   sh papers/notes/22-sonda-ordinal.sh                     # lote completo
#   SEEDS_LISTA="7" sh papers/notes/22-sonda-ordinal.sh     # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-3000}
NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
DESCONTOS=${DESCONTOS:-"0.80 0.90 0.95"}
HORIZONTES=${HORIZONTES:-"4 8 12"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src = open(sys.argv[1]).read()
tmp = sys.argv[2]

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a) == 1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a, b, 1)

BLOCO_ORD = r"""
/* ============ SONDA ORDINAL (nota 22) — medicao pura ===================== */
/* Por decisao, enumera os candidatos alcancaveis (ficar + vizinhos vazios,  */
/* MESMA ordem/regra de melhor_celula) e guarda o valor previsto (u = a      */
/* decisao completa, com antecipar; m = so o mapa, prever_valor). k ticks    */
/* depois, acumula o quanto de comida foi REALMENTE extraido de cada celula  */
/* candidata por QUEM QUER QUE SEJA (comido[][], zerado a cada tick) — nao   */
/* e contrafactual: e o que aconteceu na UNICA trajetoria, celula por        */
/* celula, independente de quem visitou. Ranking, nao valor: conta pares     */
/* discordantes (o mesmo Kendall do phi_proxy), nunca sqrt.                  */
#define ORD_K       12      /* = HORIZONTE_MAX                              */
#define ORD_BURNIN  500
#define ORD_MAXCAND 9
typedef struct {
    long  tick;             /* -1 = slot vazio                              */
    int   h;
    float desconto;
    int   n;
    int   cx[ORD_MAXCAND], cy[ORD_MAXCAND];
    float u[ORD_MAXCAND];   /* decisao completa (com antecipar)              */
    float m[ORD_MAXCAND];   /* so o mapa (prever_valor)                      */
    float fome;
    float peso;
    float real[ORD_MAXCAND];
} OrdPlano;
static OrdPlano ord_plano[MAX_AG][ORD_K];
static float    comido[ALT][LARG];   /* garfada extraida da celula NESTE tick */
static long     ord_t;
static int      ord_pronta = 0;

static double ord_n_check = 0, ord_ok_check = 0;              /* O0b        */
static double ord_n_disc_m = 0, ord_n_tot_m = 0;               /* O1         */
static double ord_n_hit = 0, ord_n_hit_tot = 0, ord_sum_n_hit = 0; /* O2     */
static double ord_n_disc_u_fam = 0, ord_n_tot_u_fam = 0;       /* O4 faminto */
static double ord_n_disc_u_sac = 0, ord_n_tot_u_sac = 0;       /* O4 saciado */
static double ord_n_dec = 0, ord_sum_n_dec = 0;                /* contexto   */

static void ord_tick_inicio(long t) {
    if (!ord_pronta) {
        for (int i = 0; i < MAX_AG; i++)
            for (int s = 0; s < ORD_K; s++) ord_plano[i][s].tick = -1;
        ord_pronta = 1;
    }
    ord_t = t;
    for (int y = 0; y < ALT; y++)
        for (int x = 0; x < LARG; x++) comido[y][x] = 0.0f;
}

/* Mesma varredura de melhor_celula(antecipar=1): self + vizinhos vazios, na
 * MESMA ordem, com a MESMA divisao por (1+ANTECIPACAO*pret). u[] e essa
 * decisao completa; m[] e so o prever_valor, sem antecipar nem espaco. */
static void ord_grava(int i) {
    Bloco *b = &blocos[i];
    OrdPlano *p = &ord_plano[i][(int)(ord_t % ORD_K)];
    int n = 0;
    p->cx[n] = b->x; p->cy[n] = b->y;
    p->u[n]  = utilidade(b->x, b->y, b);
    p->m[n]  = prever_valor(b->x, b->y, b);
    n++;
    for (int dy = -1; dy <= 1; dy++)
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            int nx = b->x + dx, ny = b->y + dy;
            if (nx < 0 || nx >= LARG || ny < 0 || ny >= ALT) continue;
            if (ocup[ny][nx] != -1) continue;
            float u = utilidade(nx, ny, b);
            int pret = pretendentes_em(nx, ny, i);
            u /= 1.0f + ANTECIPACAO * pret;
            p->cx[n] = nx; p->cy[n] = ny;
            p->u[n]  = u;
            p->m[n]  = prever_valor(nx, ny, b);
            n++;
        }
    p->n = n;
    p->tick = ord_t;
    p->h = b->horizonte;
    p->desconto = b->desconto;
    float fome = 1.0f - b->energia / SACIADO;
    if (fome < 0.0f) fome = 0.0f;
    if (fome > 1.0f) fome = 1.0f;
    p->fome = fome;
    p->peso = 1.0f;
    for (int k = 0; k < n; k++) p->real[k] = 0.0f;

    /* O0b: a reconstrucao bate com a escolha real de melhor_celula? */
    int arg = 0; float melhor = p->u[0];
    for (int k = 1; k < n; k++) if (p->u[k] > melhor) { melhor = p->u[k]; arg = k; }
    ord_n_check += 1.0;
    if (p->cx[arg] == alvo_x[i] && p->cy[arg] == alvo_y[i]) ord_ok_check += 1.0;
}

static void ord_pontuar(const OrdPlano *p) {
    int n = p->n;
    if (n < 2) return;
    ord_n_dec += 1.0; ord_sum_n_dec += n;

    int disc_m = 0, tot = 0;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) {
            float dm = p->m[i] - p->m[j];
            float dr = p->real[i] - p->real[j];
            if (dm * dr < 0.0f) disc_m++;
            tot++;
        }
    ord_n_disc_m += disc_m; ord_n_tot_m += tot;

    int am = 0; float bm = p->m[0];
    for (int k = 1; k < n; k++) if (p->m[k] > bm) { bm = p->m[k]; am = k; }
    int ar = 0; float br = p->real[0];
    for (int k = 1; k < n; k++) if (p->real[k] > br) { br = p->real[k]; ar = k; }
    if (br > 0.0f) {
        ord_n_hit_tot += 1.0; ord_sum_n_hit += n;
        if (am == ar) ord_n_hit += 1.0;
    }

    int disc_u = 0;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) {
            float du = p->u[i] - p->u[j];
            float dr = p->real[i] - p->real[j];
            if (du * dr < 0.0f) disc_u++;
        }
    if (p->fome >= 0.5f) { ord_n_disc_u_fam += disc_u; ord_n_tot_u_fam += tot; }
    else                 { ord_n_disc_u_sac += disc_u; ord_n_tot_u_sac += tot; }
}

/* Morte censura TODOS os planos pendentes do bloco (nao so o do tick) —
 * slot reusado por cria nunca herda plano do morto (regra da nota 18). */
static void ord_pos_comer(void) {
    for (int i = 0; i < n_blocos; i++) {
        if (blocos[i].vivo) continue;
        for (int s = 0; s < ORD_K; s++) ord_plano[i][s].tick = -1;
    }
    for (int i = 0; i < n_blocos; i++) {
        if (!blocos[i].vivo) continue;
        for (int s = 0; s < ORD_K; s++) {
            OrdPlano *p = &ord_plano[i][s];
            if (p->tick < 0) continue;
            long k = ord_t - p->tick;
            if (k < 0 || k >= p->h) { p->tick = -1; continue; }
            if (p->tick >= ORD_BURNIN)
                for (int c = 0; c < p->n; c++)
                    p->real[c] += p->peso * comido[p->cy[c]][p->cx[c]];
            p->peso *= p->desconto;
            if (k == p->h - 1) {
                if (p->tick >= ORD_BURNIN) ord_pontuar(p);
                p->tick = -1;
            }
        }
    }
}

static void ord_despeja(void) {
    const char *arq = getenv("ORD_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "n_check,ok_check,disc_m,tot_m,hit,hit_tot,sum_n_hit,"
                "disc_u_fam,tot_u_fam,disc_u_sac,tot_u_sac,n_dec,sum_n_dec\n");
    fprintf(fp, "%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\n",
        ord_n_check, ord_ok_check, ord_n_disc_m, ord_n_tot_m,
        ord_n_hit, ord_n_hit_tot, ord_sum_n_hit,
        ord_n_disc_u_fam, ord_n_tot_u_fam, ord_n_disc_u_sac, ord_n_tot_u_sac,
        ord_n_dec, ord_sum_n_dec);
    fclose(fp);
}
/* ========================== fim da sonda ================================= */

static void decidir(int i) {
    melhor_celula(&blocos[i], i, 1, &alvo_x[i], &alvo_y[i]);
    ord_grava(i);
}
"""

def sonda(s):
    s = troca(s,
      "static void decidir(int i) {\n"
      "    melhor_celula(&blocos[i], i, 1, &alvo_x[i], &alvo_y[i]);\n"
      "}",
      BLOCO_ORD)
    s = troca(s,
      "        float garfada = menor(comida[y][x], INGESTAO);\n"
      "        comida[y][x]      -= garfada;",
      "        float garfada = menor(comida[y][x], INGESTAO);\n"
      "        comido[y][x] += garfada;                  /* sonda: le, nao escreve */\n"
      "        comida[y][x]      -= garfada;")
    s = troca(s,
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);",
      "            ord_tick_inicio(t);\n"
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);")
    s = troca(s,
      "            resolver();\n"
      "            aplicar_e_comer();",
      "            resolver();\n"
      "            aplicar_e_comer();\n"
      "            ord_pos_comer();")
    s = troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    ord_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

# ---- patch tipo-unico da nota 16/17, sem uma virgula de diferenca ----------
def uni(s):
    s = troca(s,
      "static void semear_blocos(void) {\n    n_blocos = 0;",
      "static int TORN_HI = 6, TORN_HJ = 6;   /* torneio: dois horizontes 50/50 */\n"
      "static float TORN_DESC = DESCONTO;     /* varredura: o desconto pregado  */\n"
      "static void semear_blocos(void) {\n"
      "    { const char *a=getenv(\"TORN_HI\"), *c=getenv(\"TORN_HJ\");\n"
      "      const char *d=getenv(\"TORN_DESC\");\n"
      "      if (a) TORN_HI=atoi(a); if (c) TORN_HJ=atoi(c);\n"
      "      if (d) TORN_DESC=(float)atof(d); }\n"
      "    n_blocos = 0;")
    s = troca(s, "b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->urgencia    = (rng01(), URGENCIA);")
    s = troca(s, "b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
                  "b->peso_espaco = (rng01(), PESO_ESPACO);")
    s = troca(s, "b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
                  "b->desconto    = (rng01(), TORN_DESC);")
    s = troca(s, "b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
                  "b->horizonte   = (rng01(), ((n_blocos & 1) ? TORN_HJ : TORN_HI));")
    s = troca(s, "b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */",
                  "b->estrategia  = (rng01(), SIN_HONESTO);")
    s = troca(s, "cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);",
                  "cria->urgencia    = pai->urgencia;")
    s = troca(s, "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
                  "cria->peso_espaco = pai->peso_espaco;")
    s = troca(s, "cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
                  "cria->desconto    = pai->desconto;")
    s = troca(s, "cria->horizonte   = muta_horizonte(pai->horizonte);",
                  "cria->horizonte   = pai->horizonte;")
    s = troca(s, "cria->estrategia  = muta_estrategia(pai->estrategia);",
                  "cria->estrategia  = pai->estrategia;")
    return s

# ---- patch eremita das notas 04/09/11, sem uma virgula de diferenca --------
def eremita(s):
    s = troca(s, "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
                  "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
                  "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
    s = troca(s, "static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
                  "static int pretendentes_em(int cx, int cy, int self_i) {\n"
                  "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
    return s

open(f"{tmp}/livre.c", "w").write(sonda(src))
open(f"{tmp}/uni.c", "w").write(sonda(uni(src)))
open(f"{tmp}/ere.c", "w").write(sonda(eremita(src)))
PY

for v in livre uni ere; do
  gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>"$TMP/gcc_$v.err" \
    || { echo "gcc falhou em $v:"; cat "$TMP/gcc_$v.err"; exit 1; }
done
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# O0a: a sonda NAO muda a simulacao — CSV bit a bit contra o vanilla.
"$TMP/vanilla" 7 400 0 --log "$TMP/o0a_van.csv" >/dev/null 2>&1
ORD_ARQ="$TMP/o0a_ord" "$TMP/livre" 7 400 0 --log "$TMP/o0a_son.csv" >/dev/null 2>&1
cmp -s "$TMP/o0a_van.csv" "$TMP/o0a_son.csv" \
  || { echo "O0a FALHOU: a sonda mudou a simulacao (CSV difere). PARAR."; exit 1; }
echo "   O0a ok: CSV bit a bit identico ao vanilla"

# N0 da nota 17/18, re-checado no binario novo: o tipo esta pregado?
TORN_HI=3 TORN_HJ=3 TORN_DESC=0.95 "$TMP/uni" 7 60 0 --log "$TMP/n0.csv" >/dev/null 2>&1
awk -F, 'NR>1 && ($6 < 2.99 || $6 > 3.01) { bad=1 } NR>1 && ($8 < 0.94 || $8 > 0.96) { bad=1 }
         END { exit bad+0 }' "$TMP/n0.csv" \
  || { echo "N0 FALHOU: uni+sonda nao prega o tipo"; exit 1; }
echo "   N0 ok: uni+sonda prega hor_m==3, desc_m==0.95"

mkdir -p "$TMP/rows"
export TMP TICKS

NUNI=$(( $(echo $DESCONTOS | wc -w) * $(echo $HORIZONTES | wc -w) * $(echo $SEEDS | wc -w) ))
echo "== corridas: $NUNI uni + $(echo $SEEDS | wc -w) livre + $(echo $SEEDS | wc -w) ere, $TICKS ticks, -P $NPROC =="
{
  for s in $SEEDS; do echo "livre evol evol $s"; done
  for s in $SEEDS; do echo "ere evol evol $s";   done
  for d in $DESCONTOS; do for h in $HORIZONTES; do for s in $SEEDS; do
    echo "uni $d $h $s"
  done; done; done
} | xargs -P "$NPROC" -n 4 sh -c '
    v=$1; d=$2; h=$3; s=$4
    raw="$TMP/raw_${v}_${d}_${h}_${s}"
    case "$v" in
      livre) ORD_ARQ="$raw" "$TMP/livre" "$s" "$TICKS" 0 ;;
      ere)   ORD_ARQ="$raw" "$TMP/ere"   "$s" "$TICKS" 0 ;;
      uni)   TORN_DESC="$d" TORN_HI="$h" TORN_HJ="$h" \
               ORD_ARQ="$raw" "$TMP/uni" "$s" "$TICKS" 0 ;;
    esac >/dev/null 2>&1 || { echo "$v $d $h $s" >> "$TMP/falhas"; exit 0; }
    tail -n 1 "$raw" | awk -F, -v VAR="$v" -v DV="$d" -v HV="$h" -v SEED="$s" \
      "{print VAR\",\"DV\",\"HV\",\"SEED\",\"\$0}" > "$TMP/rows/${v}_${d}_${h}_${s}.row"
    rm -f "$raw"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/sonda-ordinal.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/sonda-ordinal.csv"}
{
echo "variante,desconto,horizonte,seed,n_check,ok_check,disc_m,tot_m,hit,hit_tot,sum_n_hit,disc_u_fam,tot_u_fam,disc_u_sac,tot_u_sac,n_dec,sum_n_dec"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== O0b: a reconstrucao (todo bloco/variante/seed) =="
awk -F, 'NR>1 { n+=$5; ok+=$6 } END {
    printf "   %.0f decisoes amostradas, %.0f reconstruidas exato (%.6f%%)\n", n, ok, 100*ok/n
    if (ok != n) { print "   O0b FALHOU: a sonda diverge da decisao real."; exit 1 }
    print "   O0b ok: reconstrucao 100% exata"
  }' "$SAIDA" || exit 1

echo ""
echo "== O1 (POOLED por condicao): discordancia rank(m) x rank(real); < 0,25 esperado =="
awk -F, 'NR>1 {
    key=$1" d="$2" h="$3
    dm[key]+=$7; tm[key]+=$8; ks[key]=1
  }
  END {
    for (k in ks) printf "   %-20s disc/tot = %.4f  (tot=%.0f)\n", k, dm[k]/tm[k], tm[k]
  }' "$SAIDA" | sort

echo ""
echo "== O1 (PAREADO por seed, media +- se, t): mesma fracao, por condicao =="
awk -F, 'NR>1 {
    key=$1" d="$2" h="$3; seed=$4
    r=$7/$8; s[key]+=r; ss[key]+=r*r; n[key]++
  }
  function sd(a,b,c){ v=(b-a*a/c)/(c>1?c-1:1); return v>0?v^0.5:0 }
  END {
    for (k in n) { m=s[k]/n[k]; e=sd(s[k],ss[k],n[k])/(n[k]^0.5)
      printf "   %-20s media=%.4f +- %.4f (n=%d)\n", k, m, e, n[k] }
  }' "$SAIDA" | sort

echo ""
echo "== O2: P(argmax(m)==argmax(real) | alguma garfada real) x baseline 1/n_medio =="
awk -F, 'NR>1 {
    key=$1" d="$2" h="$3
    hit[key]+=$9; tot[key]+=$10; sn[key]+=$11; ks[key]=1
  }
  END {
    for (k in ks) {
      p=hit[k]/tot[k]; nmed=sn[k]/tot[k]; base=1/nmed
      printf "   %-20s hit=%.4f  base(1/n_medio=%.2f)=%.4f  razao=%.2fx\n",
        k, p, nmed, base, p/base
    }
  }' "$SAIDA" | sort

echo ""
echo "== O3: dose-resposta com h (uni, POOLED por delta) — O1 de h=4 a h=12 =="
awk -F, 'NR>1 && $1=="uni" {
    key=$2; h=$3+0; dm[key"_"h]+=$7; tm[key"_"h]+=$8; hs[key]=1; hh[h]=1
  }
  END {
    for (k in hs) {
      printf "   delta=%-5s", k
      for (h=1; h<=12; h++) if ((h) in hh) {
        kk=k"_"h; if (kk in tm) printf "  h=%-2d:%.4f", h, dm[kk]/tm[kk]
      }
      print ""
    }
  }' "$SAIDA" | sort

echo ""
echo "== O4: discordancia rank(u) x rank(real), faminto x saciado =="
awk -F, 'NR>1 {
    key=$1" d="$2" h="$3
    df[key]+=$12; tf[key]+=$13; ds[key]+=$14; ts[key]+=$15; ks[key]=1
  }
  END {
    for (k in ks) printf "   %-20s faminto=%.4f  saciado=%.4f  (delta=%+.4f)\n",
      k, df[k]/tf[k], ds[k]/ts[k], df[k]/tf[k] - ds[k]/ts[k]
  }' "$SAIDA" | sort
echo "   (O4: em livre/uni, faminto < saciado esperado. Em ere, controle negativo —"
echo "   rank(u)==rank(m) por algebra, a diferenca ali nao testa o mecanismo.)"

echo ""
echo "== contexto: candidatos medios por decisao, por condicao =="
awk -F, 'NR>1 { key=$1" d="$2" h="$3; sn[key]+=$17; nd[key]+=$16; ks[key]=1 }
  END { for (k in ks) printf "   %-20s n_medio=%.2f (n_dec=%.0f)\n", k, sn[k]/nd[k], nd[k] }' "$SAIDA" | sort
echo "== fim =="
