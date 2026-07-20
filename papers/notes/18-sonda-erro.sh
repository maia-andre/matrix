#!/bin/sh
# Nota 18 (Paper 2): A SONDA DO ERRO DE PREVISAO A k PASSOS — o elo que falta.
#
# O §5 do Paper 2 e inferencia a melhor explicacao: provamos que o tipo fundo
# colhe pior (nota 17) e que o dano escala com delta (dose-resposta +20/+45/+74),
# mas NUNCA medimos o erro do plano diretamente. O §8 do paper e o ROADMAP
# declaram a divida: "uma sonda que compare prever_valor passo a passo com o
# realizado, e ela nao existe". Esta nota a constroi.
#
# O QUE A SONDA MEDE. Quando um bloco escolhe a celula (ax,ay) no tick t, o
# prever_valor projetou um fluxo de garfadas g_0..g_{h-1} (e, implicito, um
# fluxo de comida da celula f_1..f_{h-1}). A sonda guarda os dois fluxos e
# compara:
#   (B) g_k  x  r_{t+k} = a garfada que o bloco DE FATO comeu no tick t+k,
#       onde quer que estivesse. E o erro da previsao inteira, premissa inclusa
#       ("eu ocupo (ax,ay) por h ticks").
#   (A) f_k  x  comida real de (ax,ay) no inicio do tick t+k. E o erro do
#       modelo de MUNDO, sem cobrar a premissa de permanencia.
#   premissa(k): fracao dos planos cujo dono ocupou (ax,ay) do tick t ate t+k
#       (o proprio replanejamento e a disputa quebram a premissa).
# Estatisticas por k, acumuladas em double: n, vies, rmse, corr(g_k, r_k), e as
# mesmas condicionais a premissa cumprida. Planos feitos antes do tick 500
# (burn-in) nao pontuam. Morte censura o plano do tick da morte em diante
# (contada em 'cens'); slot reusado por cria nunca herda plano do morto.
#
# POR QUE O ZERO DO EREMITA E ESTRUTURAL (a ancora, regras 2 e 6). A garfada
# real e menor(comida, INGESTAO) INTEIRA (aplicar_e_comer nao partilha); a
# partilha do prever_valor e um desconto heuristico de risco, nao dinamica. No
# eremita (rivais_em == 0) a partilha e 1.0f, e '1.0f * x == x' exato — entao,
# enquanto a premissa vale (o bloco ocupa a celula planejada), o fluxo previsto
# executa AS MESMAS operacoes de float que o mundo executa (comer inteiro,
# rebrotar REGROW*(cap-food); comida nunca excede cap, entao o guarda
# 'falta > 0' do rebrotar real nao diverge). Previsao e realidade sao o mesmo
# programa: erro 0 bit a bit, para TODO k. Fora do eremita a partilha < 1
# quebra a identidade ja no k=0 — e isso e um ACHADO, nao um defeito: o modelo
# e pessimista por construcao na propria premissa.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   E0a (sanidade, regra 3): a sonda NAO muda a simulacao. O binario com sonda
#       (SONDA_ARQ ligado) produz --log CSV bit a bit identico ao main.c
#       vanilla, mesma seed/ticks. Se falhar: parar tudo.
#   E0b (ancora do zero, regras 2 e 6): no eremita (patch das notas 04/09/11),
#       o erro condicional a premissa cumprida e 0 EXATO em double
#       (maxabsP == 0) em todo k com cobertura (nP > 0), nas 3 seeds canonicas
#       7/42/1234. Se vazar, a sonda esta quebrada (aritmetica diferente da do
#       prever_valor) — consertar antes de ler qualquer outra linha.
#   E1  (o decaimento): nas condicoes povoadas, corr(g_k, r_k) DECAI com k e
#       rmse(k) CRESCE. Quantificado: k* := min{k : corr < 0,5} - 1 (o ultimo
#       passo ainda informativo; k com n >= 1000; se corr(0) < 0,5, k* = -1).
#       Predicao: k* <= 3 em uni h=8, uni h=12 (todos os deltas) e livre.
#       (uni h=4 so alcanca k=3: reportado, fora da predicao.)
#       SE FALHAR (corr alta em todo k): o modelo preve bem e o mecanismo do
#       deficit da nota 17 NAO e ruido da cauda — o §5 do Paper 2 cai, e como a
#       17 ja matou a alternativa posicional, e crise real. Mutuamente
#       exclusivo com E1, no espirito N1xN3.
#   E2  (a ponte com a evolucao): na corrida LIVRE, a mediana de k* sobre as 8
#       seeds cai em {2, 3} — casa com o pico de colheita h~2 (nota 17 §5) e a
#       profundidade efetiva evoluida 3,31+-0,24 (nota 15, c=0). Se k* >> 3, o
#       desconto evoluido joga fora informacao BOA e a leitura "regularizador"
#       ganha errata.
#   E3  (a decomposicao): a maior parte do erro em k >= 1 vem da QUEBRA DA
#       PREMISSA, nao da fisica da celula: premissa(k) cai abaixo de 0,5 ate
#       k = 3 nas condicoes povoadas, e rmseP (condicional a premissa) <<
#       rmse (incondicional). Sinal pre-registrado: viesP < 0 no k = 0 fora do
#       eremita (g_0 = partilha*garfada < garfada real: pessimismo).
#   E4  (controle de delta): em uni h=12, a curva corr(k) quase nao muda entre
#       delta 0,80 e 0,95 — |media_k(corr_95 - corr_80)| < 0,1 (pareado por
#       seed). O mecanismo do dano da nota 17 e o PESO delta^k dado ao mesmo
#       erro, nao um erro maior. Se mudar muito, ha segundo canal
#       (comportamento diferente muda o mundo) — reportar como achado.
#   E5  (analise derivada, nao medicao): peso mal-alocado
#       W(delta) = soma_{k>k*} delta^k / soma_{k=0..11} delta^k, com k* da
#       propria condicao (uni h=12): W cresce com delta na direcao da
#       dose-resposta da 17 (+20,3/+45,2/+73,6). Direcao e ordem de grandeza,
#       sem threshold rigido.
#
# Desenho: 3 variantes do binario, todas patch sobre main.c (main.c INTOCADO):
#   livre = vanilla + sonda (evolucao solta; --log ligado para contexto);
#   uni   = patch tipo-unico da nota 17 (sem uma virgula de diferenca) + sonda,
#           h em {4, 8, 12} x delta em {0.80, 0.90, 0.95}, seeds 1..8;
#   ere   = patch eremita das notas 04/09/11 + sonda, seeds 7/42/1234.
# 3000 ticks; planos pontuam do tick 500 em diante. Estatistica entre seeds,
# pareada quando comparar condicoes (licao da nota 17 §4).
#
# Custo: 72 uni + 8 livre + 3 ere = 83 corridas de 3000 ticks. A nota 17 mediu
# ~26 s/row em 6000 ticks com h medio 6,5; aqui h medio e maior (8) e os ticks
# metade. Estimo ~35-60 min com NPROC=16. A serie de erratas de custo (nota 14:
# 13x; nota 17: 5x) manda desconfiar: se passar de 3h, aborte e investigue.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/sonda-erro.csv
# (uma linha por variante x delta x h x seed x k; sentinela -9 = indefinido).
#   git log -1 --oneline -- datasets/sonda-erro.csv
#
#   sh papers/notes/18-sonda-erro.sh                     # lote completo
#   SEEDS_LISTA="7" sh papers/notes/18-sonda-erro.sh     # fumaca (nao grava)
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
SEEDS_ERE=${SEEDS_LISTA:-"7 42 1234"}
FUMACA=${SEEDS_LISTA:+sim}
DESCONTOS=${DESCONTOS:-"0.80 0.90 0.95"}
HORIZONTES=${HORIZONTES:-"4 8 12"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# ---- a sonda (medicao pura: nao consome rng, nao escreve estado da sim) ----
BLOCO_SONDA = r"""
/* ============ SONDA DO ERRO DE PREVISAO (nota 18) — medicao pura ========= */
/* Guarda, para cada plano, o fluxo que prever_valor projetou para a celula  */
/* escolhida, e pontua contra o realizado k ticks depois. Nada aqui consome  */
/* rng nem escreve no estado da simulacao; o despejo vai para SONDA_ARQ.     */
#define SONDA_K      12     /* = HORIZONTE_MAX                              */
#define SONDA_BURNIN 500    /* planos feitos antes disto nao pontuam        */
typedef struct {
    long  tick;             /* quando o plano foi feito; -1 = slot vazio    */
    int   ax, ay, h;        /* celula escolhida e profundidade do plano     */
    int   premissa;         /* 1 enquanto o dono ocupou (ax,ay) desde k=0   */
    float g[SONDA_K];       /* garfada prevista no passo k                  */
    float f[SONDA_K];       /* comida prevista na celula no inicio de t+k   */
} SondaPlano;
static SondaPlano sonda_plano[MAX_AG][SONDA_K];   /* anel por bloco: t%12   */
static float  sonda_r[MAX_AG];        /* garfada real do tick corrente      */
static long   sonda_t;
static int    sonda_pronta = 0;
static double sn[SONDA_K], scens[SONDA_K], snP[SONDA_K], snA[SONDA_K],
              s_g[SONDA_K], s_r[SONDA_K], s_e[SONDA_K], s_e2[SONDA_K],
              s_g2[SONDA_K], s_r2[SONDA_K], s_gr[SONDA_K],
              sP_e[SONDA_K], sP_e2[SONDA_K], sP_max[SONDA_K],
              s_f[SONDA_K], s_fr[SONDA_K], s_fe[SONDA_K], s_fe2[SONDA_K],
              s_f2[SONDA_K], s_fr2[SONDA_K], s_ffr[SONDA_K];

/* Replica o laco de prever_valor (sigma = 1) guardando o fluxo passo a     */
/* passo — as MESMAS expressoes na MESMA ordem, entao os floats saem        */
/* identicos aos que a decisao acabou de computar.                          */
static void sonda_grava(int i) {
    const Bloco *b = &blocos[i];
    SondaPlano *p = &sonda_plano[i][(int)(sonda_t % SONDA_K)];
    int cx = alvo_x[i], cy = alvo_y[i];
    int rivais = rivais_em(cx, cy, b->x, b->y);
    float partilha = 1.0f / (1.0f + COMPETICAO * rivais);
    float food = comida[cy][cx];
    float cap  = capacidade[cy][cx];
    p->tick = sonda_t; p->ax = cx; p->ay = cy;
    p->h = b->horizonte; p->premissa = 1;
    for (int k = 0; k < p->h; k++) {
        p->f[k] = food;
        float garfada = menor(food, INGESTAO) * partilha;
        p->g[k] = garfada;
        food -= garfada;
        food += REGROW * (cap - food);
    }
}

/* Inicio do tick t (estado estavel, antes de declarar): pontua a previsao  */
/* de COMIDA (f_k) dos planos pendentes — o erro do modelo de mundo (A).    */
static void sonda_tick_inicio(long t) {
    if (!sonda_pronta) {
        for (int i = 0; i < MAX_AG; i++)
            for (int s = 0; s < SONDA_K; s++) sonda_plano[i][s].tick = -1;
        sonda_pronta = 1;
    }
    sonda_t = t;
    for (int i = 0; i < n_blocos; i++) {
        if (!blocos[i].vivo) continue;
        for (int s = 0; s < SONDA_K; s++) {
            SondaPlano *p = &sonda_plano[i][s];
            if (p->tick < 0 || p->tick < SONDA_BURNIN) continue;
            long k = t - p->tick;
            if (k < 1 || k >= p->h) continue;
            double fp = p->f[k], fr = comida[p->ay][p->ax], fe = fp - fr;
            snA[k] += 1.0;
            s_f[k] += fp;      s_fr[k]  += fr;
            s_fe[k] += fe;     s_fe2[k] += fe * fe;
            s_f2[k] += fp*fp;  s_fr2[k] += fr*fr;  s_ffr[k] += fp*fr;
        }
    }
}

/* Depois de aplicar_e_comer (e ANTES de reproduzir reusar slots): pontua a */
/* garfada real contra a prevista (B) e atualiza a premissa. Morte censura  */
/* o plano do tick da morte em diante.                                      */
static void sonda_pos_comer(void) {
    for (int i = 0; i < n_blocos; i++) {
        for (int s = 0; s < SONDA_K; s++) {
            SondaPlano *p = &sonda_plano[i][s];
            if (p->tick < 0) continue;
            long k = sonda_t - p->tick;
            if (k < 0 || k >= p->h) { p->tick = -1; continue; }
            if (!blocos[i].vivo) {
                if (p->tick >= SONDA_BURNIN)
                    for (long c = k; c < p->h; c++) scens[c] += 1.0;
                p->tick = -1;
                continue;
            }
            if (blocos[i].x != p->ax || blocos[i].y != p->ay) p->premissa = 0;
            if (p->tick >= SONDA_BURNIN) {
                double g = p->g[k], r = sonda_r[i], e = g - r;
                sn[k] += 1.0; s_g[k] += g; s_r[k] += r;
                s_e[k] += e; s_e2[k] += e*e;
                s_g2[k] += g*g; s_r2[k] += r*r; s_gr[k] += g*r;
                if (p->premissa) {
                    double a = e < 0.0 ? -e : e;
                    snP[k] += 1.0; sP_e[k] += e; sP_e2[k] += e*e;
                    if (a > sP_max[k]) sP_max[k] = a;
                }
            }
            if (k == p->h - 1) p->tick = -1;   /* plano completo, aposenta  */
        }
    }
}

static void sonda_despeja(void) {
    const char *arq = getenv("SONDA_ARQ");
    if (!arq) return;
    FILE *fp = fopen(arq, "w");
    if (!fp) return;
    fprintf(fp, "k,n,cens,nP,nA,sum_g,sum_r,sum_e,sum_e2,sum_g2,sum_r2,sum_gr,"
                "sumP_e,sumP_e2,maxabsP,sum_f,sum_fr,sum_fe,sum_fe2,sum_f2,"
                "sum_fr2,sum_ffr\n");
    for (int k = 0; k < SONDA_K; k++)
        fprintf(fp, "%d,%.0f,%.0f,%.0f,%.0f,%.17g,%.17g,%.17g,%.17g,%.17g,"
                    "%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,"
                    "%.17g,%.17g,%.17g\n",
                k, sn[k], scens[k], snP[k], snA[k], s_g[k], s_r[k], s_e[k],
                s_e2[k], s_g2[k], s_r2[k], s_gr[k], sP_e[k], sP_e2[k],
                sP_max[k], s_f[k], s_fr[k], s_fe[k], s_fe2[k], s_f2[k],
                s_fr2[k], s_ffr[k]);
    fclose(fp);
}
/* ========================== fim da sonda ================================= */

static void decidir(int i) {
    melhor_celula(&blocos[i], i, 1, &alvo_x[i], &alvo_y[i]);
    sonda_grava(i);
}
"""

def sonda(s):
    s=troca(s,
      "static void decidir(int i) {\n"
      "    melhor_celula(&blocos[i], i, 1, &alvo_x[i], &alvo_y[i]);\n"
      "}",
      BLOCO_SONDA)
    s=troca(s,
      "        float garfada = menor(comida[y][x], INGESTAO);\n"
      "        comida[y][x]      -= garfada;",
      "        float garfada = menor(comida[y][x], INGESTAO);\n"
      "        sonda_r[i] = garfada;              /* sonda: le, nao escreve */\n"
      "        comida[y][x]      -= garfada;")
    s=troca(s,
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);",
      "            sonda_tick_inicio(t);\n"
      "            for (int i = 0; i < n_blocos; i++)\n"
      "                if (blocos[i].vivo) declarar(i);")
    s=troca(s,
      "            resolver();\n"
      "            aplicar_e_comer();",
      "            resolver();\n"
      "            aplicar_e_comer();\n"
      "            sonda_pos_comer();")
    s=troca(s,
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();",
      "    sonda_despeja();\n"
      "    fputs(CUR_ON, stdout);\n"
      "    if (interativo) termios_restaura();")
    return s

# ---- patch tipo-unico da nota 16/17, sem uma virgula de diferenca ----------
def uni(s):
    s=troca(s,
      "static void semear_blocos(void) {\n    n_blocos = 0;",
      "static int TORN_HI = 6, TORN_HJ = 6;   /* torneio: dois horizontes 50/50 */\n"
      "static float TORN_DESC = DESCONTO;     /* varredura: o desconto pregado  */\n"
      "static void semear_blocos(void) {\n"
      "    { const char *a=getenv(\"TORN_HI\"), *c=getenv(\"TORN_HJ\");\n"
      "      const char *d=getenv(\"TORN_DESC\");\n"
      "      if (a) TORN_HI=atoi(a); if (c) TORN_HJ=atoi(c);\n"
      "      if (d) TORN_DESC=(float)atof(d); }\n"
      "    n_blocos = 0;")
    s=troca(s,"b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
              "b->urgencia    = (rng01(), URGENCIA);")
    s=troca(s,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
              "b->peso_espaco = (rng01(), PESO_ESPACO);")
    s=troca(s,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
              "b->desconto    = (rng01(), TORN_DESC);")
    s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
              "b->horizonte   = (rng01(), ((n_blocos & 1) ? TORN_HJ : TORN_HI));")
    s=troca(s,"b->estrategia  = (int)(rng01() * 3.0f);                   /* tercos      */",
              "b->estrategia  = (rng01(), SIN_HONESTO);")
    s=troca(s,"cria->urgencia    = muta_traco(pai->urgencia,    1.5f * MUTACAO, 0.0f, 6.0f);",
              "cria->urgencia    = pai->urgencia;")
    s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
              "cria->peso_espaco = pai->peso_espaco;")
    s=troca(s,"cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
              "cria->desconto    = pai->desconto;")
    s=troca(s,"cria->horizonte   = muta_horizonte(pai->horizonte);",
              "cria->horizonte   = pai->horizonte;")
    s=troca(s,"cria->estrategia  = muta_estrategia(pai->estrategia);",
              "cria->estrategia  = pai->estrategia;")
    return s

# ---- patch eremita das notas 04/09/11, sem uma virgula de diferenca --------
def eremita(s):
    s=troca(s,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
              "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
              "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
    s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
              "static int pretendentes_em(int cx, int cy, int self_i) {\n"
              "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
    return s

open(f"{tmp}/livre.c","w").write(sonda(src))
open(f"{tmp}/uni.c","w").write(sonda(uni(src)))
open(f"{tmp}/ere.c","w").write(sonda(eremita(src)))
PY

for v in livre uni ere; do
  gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>"$TMP/gcc_$v.err" \
    || { echo "gcc falhou em $v:"; cat "$TMP/gcc_$v.err"; exit 1; }
done
gcc -std=c11 -O2 -o "$TMP/vanilla" "$MAINC" 2>/dev/null

# E0a: a sonda NAO muda a simulacao — CSV bit a bit contra o vanilla.
"$TMP/vanilla" 7 400 0 --log "$TMP/e0a_van.csv" >/dev/null 2>&1
SONDA_ARQ="$TMP/e0a_sonda_raw" "$TMP/livre" 7 400 0 --log "$TMP/e0a_son.csv" >/dev/null 2>&1
cmp -s "$TMP/e0a_van.csv" "$TMP/e0a_son.csv" \
  || { echo "E0a FALHOU: a sonda mudou a simulacao (CSV difere). PARAR."; exit 1; }
[ -s "$TMP/e0a_sonda_raw" ] || { echo "E0a FALHOU: sonda nao despejou."; exit 1; }
echo "   E0a ok: CSV bit a bit identico ao vanilla; sonda despejou"

# N0 da nota 17, re-checado no binario novo (uni+sonda): o tipo esta pregado?
TORN_HI=3 TORN_HJ=3 TORN_DESC=0.95 "$TMP/uni" 7 60 0 --log "$TMP/n0.csv" >/dev/null 2>&1
awk -F, 'NR>1 && ($6 < 2.99 || $6 > 3.01) { bad=1 } NR>1 && ($8 < 0.94 || $8 > 0.96) { bad=1 }
         END { exit bad+0 }' "$TMP/n0.csv" \
  || { echo "N0 FALHOU: uni+sonda nao prega o tipo"; exit 1; }
echo "   N0 ok: uni+sonda prega hor_m==3, desc_m==0.95"

# Converte o despejo cru de uma corrida em linhas tidy do dataset.
cat > "$TMP/conv.awk" <<'AWK'
BEGIN { FS=","; OFS="," }
NR>1 {
  k=$1+0; n=$2+0; cens=$3+0; nP=$4+0; nA=$5+0
  sg=$6+0; sr=$7+0; se=$8+0; se2=$9+0; sg2=$10+0; sr2=$11+0; sgr=$12+0
  sPe=$13+0; sPe2=$14+0; mx=$15
  sf=$16+0; sfr=$17+0; sfe=$18+0; sfe2=$19+0; sf2=$20+0; sfr2=$21+0; sffr=$22+0
  if (n < 2) next
  pm=sg/n; rm=sr/n; v=se/n; rmse=sqrt(se2/n)
  num=n*sgr-sg*sr; d1=n*sg2-sg*sg; d2=n*sr2-sr*sr
  corr=(d1>0 && d2>0) ? num/sqrt(d1*d2) : -9
  fprem=nP/n
  vP=(nP>0)?sPe/nP:-9; rP=(nP>0)?sqrt(sPe2/nP):-9
  if (nA>1) { fv=sfe/nA; frm=sqrt(sfe2/nA)
    fn=nA*sffr-sf*sfr; fd1=nA*sf2-sf*sf; fd2=nA*sfr2-sfr*sfr
    fc=(fd1>0 && fd2>0)?fn/sqrt(fd1*fd2):-9
  } else { fv=-9; frm=-9; fc=-9 }
  printf "%s,%s,%s,%s,%d,%d,%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.4f,%.4f,%.6f,%.6f,%s,%.6f,%.6f,%.4f\n", \
    VAR, DV, HV, SEED, k, n, cens, nP, nA, pm, rm, v, rmse, corr, fprem, vP, rP, mx, fv, frm, fc
}
AWK

mkdir -p "$TMP/rows"
export TMP TICKS

NUNI=$(( $(echo $DESCONTOS | wc -w) * $(echo $HORIZONTES | wc -w) * $(echo $SEEDS | wc -w) ))
echo "== corridas: $NUNI uni + $(echo $SEEDS | wc -w) livre + $(echo $SEEDS_ERE | wc -w) ere, $TICKS ticks, -P $NPROC =="
{
  for s in $SEEDS;     do echo "livre evol evol $s"; done
  for s in $SEEDS_ERE; do echo "ere evol evol $s";   done
  for d in $DESCONTOS; do for h in $HORIZONTES; do for s in $SEEDS; do
    echo "uni $d $h $s"
  done; done; done
} | xargs -P "$NPROC" -n 4 sh -c '
    v=$1; d=$2; h=$3; s=$4
    raw="$TMP/raw_${v}_${d}_${h}_${s}"
    case "$v" in
      livre) SONDA_ARQ="$raw" "$TMP/livre" "$s" "$TICKS" 0 \
               --log "$TMP/log_livre_$s.csv" ;;
      ere)   SONDA_ARQ="$raw" "$TMP/ere" "$s" "$TICKS" 0 ;;
      uni)   TORN_DESC="$d" TORN_HI="$h" TORN_HJ="$h" \
               SONDA_ARQ="$raw" "$TMP/uni" "$s" "$TICKS" 0 ;;
    esac >/dev/null 2>&1 || { echo "$v $d $h $s" >> "$TMP/falhas"; exit 0; }
    awk -v VAR="$v" -v DV="$d" -v HV="$h" -v SEED="$s" -f "$TMP/conv.awk" \
      "$raw" > "$TMP/rows/${v}_${d}_${h}_${s}.row"
    rm -f "$raw"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas convertidas"

SAIDA=${FUMACA:+"$TMP/sonda-erro.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/sonda-erro.csv"}
{
echo "variante,desconto,horizonte,seed,k,n,cens,nP,nA,pred_m,real_m,vies,rmse,corr,fprem,viesP,rmseP,maxabsP,fvies,frmse,fcorr"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   dataset: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== E0b: o zero do eremita (erro condicional a premissa cumprida) =="
awk -F, 'NR>1 && $1=="ere" {
    tot++; if ($8+0 > 0) { cob++; if ($18+0 != 0) { bad++
      printf "   VAZOU: seed %s k %s maxabsP=%s nP=%s\n", $4, $5, $18, $8 } }
  }
  END {
    printf "   %d linhas ere, %d com cobertura (nP>0)\n", tot, cob
    if (bad) { print "   E0b FALHOU: o zero vazou — sonda quebrada."; exit 1 }
    print "   E0b ok: maxabsP == 0 exato em toda linha com cobertura"
  }' "$SAIDA" || exit 1

echo ""
echo "== cobertura do eremita por k (nP media/seed; onde o zero foi testado) =="
awk -F, 'NR>1 && $1=="ere" { n[$5]+=$8; c[$5]++ }
  END { for (k=0; k<12; k++) if (k in n)
    printf "   k=%2d  nP medio = %.0f\n", k, n[k]/c[k] }' "$SAIDA"

echo ""
echo "== E1: corr(g_k, r_k) por condicao (media entre seeds; -9 = indefinido) =="
awk -F, 'NR>1 && $1!="ere" && $14!=-9 && $6>=1000 {
    key=$1" d="$2" h="$3; c[key"_"$5]+=$14; q[key"_"$5]++; ks[key]=1 }
  END {
    for (key in ks) {
      printf "\n  %-22s", key
      for (k=0; k<12; k++) { kk=key"_"k
        if (kk in c) printf " %6.3f", c[kk]/q[kk]; else printf "      ." }
    }
    print ""
  }' "$SAIDA" | sort
echo "   (colunas: k=0..11)"

echo ""
echo "== E1/E2: k* por seed (ultimo k informativo; corr>=0,5; n>=1000) =="
awk -F, 'NR>1 && $1!="ere" {
    cond=$1" d="$2" h="$3; seed=$4; k=$5+0
    if ($6+0>=1000 && $14!=-9) { corr[cond"_"seed"_"k]=$14+0
      if (k>kmax[cond"_"seed]) kmax[cond"_"seed]=k }
    conds[cond]=1; seeds[cond"_"seed]=seed; par[cond"_"seed]=cond }
  END {
    for (cs in seeds) { cond=par[cs]
      ks=-2
      for (k=0; k<=kmax[cs]; k++) { key=cs"_"k
        if (!(key in corr)) break
        if (corr[key] < 0.5) { ks=k-1; break }
        ks=k }
      out[cond]=out[cond]" "ks
    }
    for (cond in out) printf "  %-22s k*:%s\n", cond, out[cond]
  }' "$SAIDA" | sort
echo "   (E1: k* <= 3 em uni h=8/12 e livre. E2: mediana livre em {2,3}.)"

echo ""
echo "== E3: a premissa quebra (fprem por k) e o pessimismo da partilha =="
awk -F, 'NR>1 && $1!="ere" && $6>=1000 {
    key=$1" d="$2" h="$3; f[key"_"$5]+=$15; q[key"_"$5]++; ks[key]=1
    if ($5==0) { vp[key]+=$16; nvp[key]++ }
    rm[key"_"$5]+=$13; rp[key"_"$5]+=($17==-9?0:$17) }
  END {
    for (key in ks) {
      linha = sprintf("  %-22s fprem:", key)
      for (k=0; k<12; k++) { kk=key"_"k
        linha = linha sprintf((kk in f) ? " %4.2f" : "    .", (kk in f) ? f[kk]/q[kk] : 0) }
      print linha
      printf "  %-22s viesP(k=0)=%+.4f rmse(k=3)=%.3f rmseP(k=3)=%.3f\n",
        key, (key in vp ? vp[key]/nvp[key] : -9),
        (key"_3" in rm ? rm[key"_3"]/q[key"_3"] : -9),
        (key"_3" in rp ? rp[key"_3"]/q[key"_3"] : -9)
    }
  }' "$SAIDA" | sort
echo "   (E3: fprem < 0,5 ate k=3; viesP(0) < 0; rmseP << rmse.)"

echo ""
echo "== E4 (PAREADO por seed): uni h=12, corr_0.95 - corr_0.80, media sobre k =="
awk -F, 'NR>1 && $1=="uni" && $3=="12" && $14!=-9 && $6>=1000 {
    c[$2"_"$4"_"$5]=$14+0; ss[$4]=1; kk[$5]=1 }
  function sd(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    np=0; sx=0; sxx=0
    for (s in ss) { n=0; acc=0
      for (k in kk) { a="0.80_"s"_"k; b="0.95_"s"_"k
        if ((a in c) && (b in c)) { acc+=c[b]-c[a]; n++ } }
      if (n>0) { x=acc/n; np++; sx+=x; sxx+=x*x
        printf "   seed %-4s  media_k(delta corr) = %+.4f  (%d ks pareados)\n", s, x, n } }
    if (np>1) { m=sx/np; e=sd(sx,sxx,np)/sqrt(np)
      printf "   media = %+.4f +- %.4f  (t=%+.2f)  %s\n", m, e, (e>0)?m/e:0,
        (m<0.1 && m>-0.1) ? "|m| < 0,1: E4 ok (o erro nao muda; o PESO muda)" \
                          : "|m| >= 0,1: segundo canal — reportar como achado" }
  }' "$SAIDA"

echo ""
echo "== E5 (analise): peso mal-alocado W(delta) = soma_{k>k*} delta^k / soma_k delta^k =="
awk -F, 'NR>1 && $1=="uni" && $3=="12" {
    cond=$2; seed=$4; k=$5+0
    if ($6+0>=1000 && $14!=-9) { corr[cond"_"seed"_"k]=$14+0
      if (k>kmax[cond"_"seed]) kmax[cond"_"seed]=k }
    ds[cond]=1; sds[cond"_"seed]=seed; par[cond"_"seed]=cond }
  END {
    for (cs in sds) { cond=par[cs]; ks=-2
      for (k=0; k<=kmax[cs]; k++) { key=cs"_"k
        if (!(key in corr)) break
        if (corr[key] < 0.5) { ks=k-1; break }
        ks=k }
      kst[cond]=kst[cond]" "ks }
    for (cond in ds) {
      split(kst[cond], arr, " "); n=0
      for (i in arr) if (arr[i]!="") v[++n]=arr[i]+0
      for (a=1;a<=n;a++) for (b=a+1;b<=n;b++) if (v[a]>v[b]) {t=v[a];v[a]=v[b];v[b]=t}
      med=(n%2)?v[(n+1)/2]:(v[n/2]+v[n/2+1])/2
      d=cond+0; tot=0; mal=0; p=1
      for (k=0; k<12; k++) { tot+=p; if (k>med) mal+=p; p*=d }
      printf "   delta=%s  k* mediano=%g  W=%.3f\n", cond, med, mal/tot }
    print "   (E5: W cresce com delta, na direcao de +20,3/+45,2/+73,6 da nota 17)"
  }' "$SAIDA"

echo ""
echo "== contexto da corrida livre (janela T-300..T): hor_m, desc_m =="
for s in $SEEDS; do
  [ -f "$TMP/log_livre_$s.csv" ] || continue
  awk -F, -v T="$TICKS" -v s="$s" 'NR>1 && $2>=T-300 { n++; sh+=$6; sd+=$8 }
    END { if (n) printf "   seed %-4s hor_m=%.2f desc_m=%.4f (prof.efetiva~min(h, 1/(1-d)))\n",
          s, sh/n, sd/n }' "$TMP/log_livre_$s.csv"
done
echo "== fim =="
