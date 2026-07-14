#!/bin/sh
# Reproduz a nota 10: a auditoria em DOUBLE dos tres mostradores restantes.
#
# A nota 09 §5 encontrou um piso de arredondamento (~0,003) na agencia do
# eremita — um "0 exato" do Apendice A que so era exato em R, nao em float32.
# Ficou a divida (ROADMAP §5.1, regra 6 do protocolo): 'modelo', 'phi' e
# 'relato' nunca foram recomputados em double; os seus checkmarks sao promessas.
# Esta e a quitacao. O metodo e o da nota 09: recomputar SO a comparacao (a
# montagem que a sonda compara) em double; componentes e simulacao seguem em
# float32, bit-a-bit os mesmos.
#
# Tres esconderijos que o CSV nao mostra, e que esta auditoria abre:
#   - o CSV imprime %.3f: um piso < 0,0005 seria invisivel na coluna;
#   - a phi do CSV e MEDIA da populacao: um bloco nao-zero some entre 300;
#   - o kappa e clampado em [0,1]: um negativo de arredondamento vira 0 calado.
# Por isso cada variante despeja em stderr, a 9 casas: o maximo por JANELA
# (modelo), por BLOCO (phi) e o |kappa| ANTES do clamp (relato).
#
# Expectativas, declaradas ANTES de rodar (a nota registra o que sair):
#   E1 modelo sob prever_valor=0: 0 nas DUAS precisoes — pred=0 da nota
#      1 - real/real, e x/x = 1 e exato em IEEE754 em qualquer precisao.
#      Unica fuga possivel: janela que fecha com colheita EXATAMENTE 0 le 1,0
#      POR DESENHO ("previu 0, colheu 0 = ok") — se aparecer, aparece nas duas
#      precisoes: e desenho, nao piso.
#   E2 phi sob {eremita, peso_espaco=0, prever_valor=0}: 0 exato nas duas.
#      O zero vem de modulo constante (empate => produto 0, nao <0) ou de ordem
#      herdada por MULTIPLICACAO por escalar positivo comum — e arredondamento
#      monotonico nao cria inversao estrita, so empates, que so REDUZEM a
#      discordancia. [A agencia caiu porque la o termo comum era SOMADO, e a
#      soma arredondada cria/destroi empates sob o desempate '>' — o piso.]
#   E3 relato sob interprete cego: kappa = 0 exato nas duas — po e pe sao o
#      MESMO quociente real (col/n), e a divisao IEEE arredonda o mesmo
#      quociente para o mesmo resultado; as somas inteiras (< 2^24) sao exatas.
#   E4 controles: float32 x double nao se movem alem da ultima casa impressa
#      (o analogo do "a autocausa nao se move um digito" da nota 09).
# Leitura: max f32 > 0 com double = 0  => piso de arredondamento (caso agencia).
#          max > 0 nas DUAS precisoes  => nao e aritmetica, e desenho.
#
# Como as demais notas: nao ha experiment_00N.c; as variantes sao patches numa
# copia temporaria do main.c canonico. Aceita um main.c alternativo em $1.
#
#   sh papers/notes/10-auditoria-double.sh          (~15 min)
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,003" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

MOD=14; PHI=17; REL=18   # colunas do CSV

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# ============ camada 1: INSTRUMENTACAO (identica em f32 e double) ============
# Maximos em alta precisao, fora do arredondamento %.3f do CSV e do clamp.
aud=troca(src,
  "static float phi_proxy(Bloco *b) {",
  "/* AUDITORIA (nota 10): maximos em alta precisao, direto de cada medicao —\n"
  " * por JANELA (modelo), por BLOCO (phi), e o |kappa| ANTES do clamp. */\n"
  "static double aud_mod_max = 0.0, aud_phi_max = 0.0, aud_rel_max = 0.0;\n"
  "static void aud_dump(void) {\n"
  "    fprintf(stderr, \"AUDIT mod_max=%.9e phi_max=%.9e rel_max=%.9e\\n\",\n"
  "            aud_mod_max, aud_phi_max, aud_rel_max);\n"
  "}\n"
  "static float phi_proxy(Bloco *b) {")
aud=troca(aud,
  "        acc += soma > 0.0f ? 1.0f - dif / soma : 1.0f;  /* previu 0, colheu 0 = ok */",
  "        float nota = soma > 0.0f ? 1.0f - dif / soma : 1.0f;  /* previu 0, colheu 0 = ok */\n"
  "        if ((double)nota > aud_mod_max) aud_mod_max = (double)nota;\n"
  "        acc += nota;")
aud=troca(aud,
  "        sphi += phi_proxy(&blocos[i]);",
  "        { float ph = phi_proxy(&blocos[i]);\n"
  "          if ((double)ph > aud_phi_max) aud_phi_max = (double)ph;\n"
  "          sphi += ph; }")
aud=troca(aud,
  "        float kappa = pe < 1.0f ? (po - pe) / (1.0f - pe) : 0.0f;\n"
  "        if (kappa < 0.0f) kappa = 0.0f;",
  "        float kappa = pe < 1.0f ? (po - pe) / (1.0f - pe) : 0.0f;\n"
  "        { double ak = kappa < 0.0f ? -(double)kappa : (double)kappa;\n"
  "          if (ak > aud_rel_max) aud_rel_max = ak; }\n"
  "        if (kappa < 0.0f) kappa = 0.0f;")
aud=troca(aud,
  "    signal(SIGINT, ao_interromper);",
  "    signal(SIGINT, ao_interromper);\n    atexit(aud_dump);")

# ============ camada 2: as sondas recomputadas em DOUBLE =====================
# So a COMPARACAO muda de precisao; os componentes (prever_valor, espaco, fome,
# comida[][]) seguem float32 — o paralelo exato do patch da agencia na nota 09.
dbl=troca(aud,
  "static float phi_proxy(Bloco *b) {",
  "/* AUDITORIA (nota 10): a MESMA montagem de utilidade(), em double, sobre os\n"
  " * MESMOS componentes float32. */\n"
  "static double utilidade_dbl(int cx, int cy, Bloco *b) {\n"
  "    float fome = 1.0f - b->energia / SACIADO;\n"
  "    if (fome < 0.0f) fome = 0.0f;\n"
  "    if (fome > 1.0f) fome = 1.0f;\n"
  "    float comida_prev = prever_valor(cx, cy, b);\n"
  "    float espaco = (8 - rivais_em(cx, cy, b->x, b->y)) / 8.0f;\n"
  "    return (double)comida_prev * (1.0 + (double)b->urgencia * (double)fome)\n"
  "         + (double)b->peso_espaco * (double)espaco * (1.0 - (double)fome);\n"
  "}\n"
  "static float phi_proxy(Bloco *b) {")
dbl=troca(dbl,
  "    float u[9], f[9], e[9], m[9];",
  "    double u[9]; float f[9], e[9], m[9];")
dbl=troca(dbl,
  "            u[n] = utilidade(nx, ny, b);      /* a decisao integrada (nv3+nv4)     */",
  "            u[n] = utilidade_dbl(nx, ny, b);  /* a decisao integrada (nv3+nv4)     */")
dbl=troca(dbl,
  "            float du = u[i] - u[j];\n"
  "            if (du * (f[i] - f[j]) < 0.0f) df++;   /* discorda do reflexo  */\n"
  "            if (du * (e[i] - e[j]) < 0.0f) de++;   /* discorda do espaco   */\n"
  "            if (du * (m[i] - m[j]) < 0.0f) dm++;   /* discorda do mapa     */",
  "            double du = u[i] - u[j];\n"
  "            if (du * ((double)f[i] - (double)f[j]) < 0.0) df++;   /* reflexo */\n"
  "            if (du * ((double)e[i] - (double)e[j]) < 0.0) de++;   /* espaco  */\n"
  "            if (du * ((double)m[i] - (double)m[j]) < 0.0) dm++;   /* mapa    */")
dbl=troca(dbl,
  "        float pred = pred_valor[i], real = real_acum[i];\n"
  "        float soma = pred + real;\n"
  "        float dif  = pred > real ? pred - real : real - pred;\n"
  "        float nota = soma > 0.0f ? 1.0f - dif / soma : 1.0f;  /* previu 0, colheu 0 = ok */\n"
  "        if ((double)nota > aud_mod_max) aud_mod_max = (double)nota;\n"
  "        acc += nota;",
  "        double pred = (double)pred_valor[i], real = (double)real_acum[i];\n"
  "        double soma = pred + real;\n"
  "        double dif  = pred > real ? pred - real : real - pred;\n"
  "        double nota = soma > 0.0 ? 1.0 - dif / soma : 1.0;\n"
  "        if (nota > aud_mod_max) aud_mod_max = nota;\n"
  "        acc += (float)nota;")
dbl=troca(dbl,
  "        float po = 0.0f, pe = 0.0f;\n"
  "        for (int k = 0; k < 4; k++) {\n"
  "            int lin = 0, col = 0;\n"
  "            for (int j = 0; j < 4; j++) { lin += conf[k][j]; col += conf[j][k]; }\n"
  "            po += (float)conf[k][k];\n"
  "            pe += (float)lin * (float)col;\n"
  "        }\n"
  "        po /= (float)n;\n"
  "        pe /= (float)n * (float)n;\n"
  "        float kappa = pe < 1.0f ? (po - pe) / (1.0f - pe) : 0.0f;\n"
  "        { double ak = kappa < 0.0f ? -(double)kappa : (double)kappa;\n"
  "          if (ak > aud_rel_max) aud_rel_max = ak; }\n"
  "        if (kappa < 0.0f) kappa = 0.0f;          /* mostradores moram em [0,1] */\n"
  "        relato_ultimo = kappa;",
  "        double po = 0.0, pe = 0.0;\n"
  "        for (int k = 0; k < 4; k++) {\n"
  "            int lin = 0, col = 0;\n"
  "            for (int j = 0; j < 4; j++) { lin += conf[k][j]; col += conf[j][k]; }\n"
  "            po += (double)conf[k][k];\n"
  "            pe += (double)lin * (double)col;\n"
  "        }\n"
  "        po /= (double)n;\n"
  "        pe /= (double)n * (double)n;\n"
  "        double kappa = pe < 1.0 ? (po - pe) / (1.0 - pe) : 0.0;\n"
  "        { double ak = kappa < 0.0 ? -kappa : kappa;\n"
  "          if (ak > aud_rel_max) aud_rel_max = ak; }\n"
  "        if (kappa < 0.0) kappa = 0.0;            /* mostradores moram em [0,1] */\n"
  "        relato_ultimo = (float)kappa;")

# ============ camada 3: as ABLACOES sob auditoria (das notas 01/05/06) =======
def eremita(s):   # nao percebe rivais nem pretendentes (nota 01 §3 / §1.5)
    s=troca(s,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
              "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
              "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
    s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
              "static int pretendentes_em(int cx, int cy, int self_i) {\n"
              "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
    return s
def pv0(s):       # a lobotomia da nota 01: o mapa devolve 0 sempre
    return troca(s,"\n    return valor;\n","\n    return 0.0f;\n")
def esp0(s):      # peso_espaco identicamente 0 (semeadura e mutacao; RNG preservado)
    s=troca(s,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
              "b->peso_espaco = (rng01(), 0.0f);")
    s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
              "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 0.0f);")
    return s
def cego(s,k):    # interprete cego da nota 06: o relato vira a constante k
    return troca(s,
      "        int r = rel_classifica(blocos[i].x, blocos[i].y,\n"
      "                               rel_cx[i], rel_cy[i], rel_ex[i], rel_ey[i]);",
      f"        int r = {k};")

for nome,base in (("f32",aud),("dbl",dbl)):
    open(f"{tmp}/ctl_{nome}.c","w").write(base)
    open(f"{tmp}/pv0_{nome}.c","w").write(pv0(base))
    open(f"{tmp}/erem_{nome}.c","w").write(eremita(base))
    open(f"{tmp}/esp0_{nome}.c","w").write(esp0(base))
    for k in range(4):
        open(f"{tmp}/cego{k}_{nome}.c","w").write(cego(base,k))
PY

VARS="ctl pv0 erem esp0 cego0 cego1 cego2 cego3"
for v in $VARS; do
    # o warning de valor nao usado do idioma '(rng01(), 0.0f)' e conhecido
    gcc -std=c11 -O2 -o "$TMP/${v}_f32" "$TMP/${v}_f32.c" 2>/dev/null
    gcc -std=c11 -O2 -o "$TMP/${v}_dbl" "$TMP/${v}_dbl.c" 2>/dev/null
done

roda() {  # roda() variante seed -> csv + err (cacheado)
    [ -f "$TMP/${1}_$2.csv" ] || "$TMP/$1" "$2" "$TICKS" 0 --log "$TMP/${1}_$2.csv" \
        >/dev/null 2>"$TMP/${1}_$2.err"
}
media() { awk -F, -v c="$2" 'NR>1 && $2>20 && $3>0 {s+=$c;n++} END{if(n) printf "%.4f", s/n; else printf "--"}' "$1"; }
maxc()  { awk -F, -v c="$2" 'NR>1 {if($c>m)m=$c} END{printf "%.4f", m+0}' "$1"; }
audv()  { sed -n "s/.*$2=\([^ ]*\).*/\1/p" "$1" | tail -1; }

echo
echo "=============================================================="
echo " NOTA 10 — auditoria em double: modelo, phi, relato"
echo " (a divida da nota 09 §5; $TICKS ticks, seeds: $SEEDS)"
echo "=============================================================="

echo
echo "--- 0. SANIDADE (regra 3): a instrumentacao nao pode tocar a simulacao ---"
"$TMP/ctl_f32" 7 2000 0 --log "$TMP/bit.csv" >/dev/null 2>/dev/null
if diff -q "$TMP/bit.csv" datasets/seed7.csv >/dev/null; then
    echo "  instrumentada (f32) x datasets/seed7.csv: BIT-A-BIT IDENTICO"
else
    echo "  FALHOU: a instrumentacao mudou o CSV"; exit 1
fi
roda ctl_f32 7; roda ctl_dbl 7
cut -d, -f1-13,15-16,19-21 "$TMP/ctl_f32_7.csv" > "$TMP/fora_f32.csv"
cut -d, -f1-13,15-16,19-21 "$TMP/ctl_dbl_7.csv" > "$TMP/fora_dbl.csv"
if diff -q "$TMP/fora_f32.csv" "$TMP/fora_dbl.csv" >/dev/null; then
    echo "  double x f32, colunas fora da sonda (1-13,15-16,19-21): IDENTICAS"
else
    echo "  FALHOU: a variante double vazou para fora da sonda"; exit 1
fi

echo
echo "--- 1. MODELO sob prever_valor=0 (nota 01: '0,000 exato') ---"
echo "  (max janela = a pior nota de UMA janela em todo o run, a 9 casas)"
printf "  %-6s | %-9s %-9s | %-15s %-15s\n" "seed" "med f32" "med dbl" "max janela f32" "max janela dbl"
for s in $SEEDS; do
    roda pv0_f32 "$s"; roda pv0_dbl "$s"
    printf "  %-6s | %-9s %-9s | %-15s %-15s\n" "$s" \
        "$(media "$TMP/pv0_f32_$s.csv" $MOD)" "$(media "$TMP/pv0_dbl_$s.csv" $MOD)" \
        "$(audv "$TMP/pv0_f32_$s.err" mod_max)" "$(audv "$TMP/pv0_dbl_$s.err" mod_max)"
done

echo
echo "--- 2. PHI sob as tres reducoes a um modulo (nota 05: '0 exato') ---"
echo "  (max bloco = a maior phi de UM bloco em todo o run — a media da"
echo "   populacao no CSV esconderia um bloco sozinho; esta nao esconde)"
printf "  %-14s %-6s | %-9s %-9s | %-15s %-15s\n" "ablacao" "seed" "med f32" "med dbl" "max bloco f32" "max bloco dbl"
for v in erem esp0 pv0; do
    for s in $SEEDS; do
        roda ${v}_f32 "$s"; roda ${v}_dbl "$s"
        printf "  %-14s %-6s | %-9s %-9s | %-15s %-15s\n" "$v" "$s" \
            "$(media "$TMP/${v}_f32_$s.csv" $PHI)" "$(media "$TMP/${v}_dbl_$s.csv" $PHI)" \
            "$(audv "$TMP/${v}_f32_$s.err" phi_max)" "$(audv "$TMP/${v}_dbl_$s.err" phi_max)"
    done
done

echo
echo "--- 3. RELATO sob interprete cego (nota 06: '0,0000 exato, 4 constantes') ---"
echo "  (max |kappa| ANTES do clamp: o clamp em [0,1] esconderia um negativo)"
printf "  %-6s %-6s | %-9s %-9s | %-15s %-15s\n" "k" "seed" "max f32" "max dbl" "|kappa| f32" "|kappa| dbl"
for k in 0 1 2 3; do
    for s in $SEEDS; do
        roda cego${k}_f32 "$s"; roda cego${k}_dbl "$s"
        printf "  %-6s %-6s | %-9s %-9s | %-15s %-15s\n" "$k" "$s" \
            "$(maxc "$TMP/cego${k}_f32_$s.csv" $REL)" "$(maxc "$TMP/cego${k}_dbl_$s.csv" $REL)" \
            "$(audv "$TMP/cego${k}_f32_$s.err" rel_max)" "$(audv "$TMP/cego${k}_dbl_$s.err" rel_max)"
    done
done

echo
echo "--- 4. CONTROLES: os valores normais nao podem se mover (analogo da"
echo "       'autocausa nao se move um digito', nota 09 §5) ---"
printf "  %-6s | %-9s %-9s | %-9s %-9s | %-9s %-9s\n" "seed" "mod f32" "mod dbl" "phi f32" "phi dbl" "rel f32" "rel dbl"
for s in $SEEDS; do
    roda ctl_f32 "$s"; roda ctl_dbl "$s"
    printf "  %-6s | %-9s %-9s | %-9s %-9s | %-9s %-9s\n" "$s" \
        "$(media "$TMP/ctl_f32_$s.csv" $MOD)" "$(media "$TMP/ctl_dbl_$s.csv" $MOD)" \
        "$(media "$TMP/ctl_f32_$s.csv" $PHI)" "$(media "$TMP/ctl_dbl_$s.csv" $PHI)" \
        "$(media "$TMP/ctl_f32_$s.csv" $REL)" "$(media "$TMP/ctl_dbl_$s.csv" $REL)"
done
echo
echo "=============================================================="
