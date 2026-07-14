#!/bin/sh
# Reproduz a nota 11: a REPLICACAO — 50 seeds para tudo que foi afirmado com 3.
#
# "Uma seed nao e um resultado" (o corolario aprendido tres vezes): seed 7
# sozinha teria confirmado duas hipoteses que as outras duas seeds mataram.
# Este script roda TODAS as condicoes de falseamento do Apendice A e as
# alegacoes direcionais das notas em seeds 1..50, 3000 ticks, e agrega um
# resumo por (condicao, seed) em datasets/replicacao50.csv — a materia da
# tabela "media ± dispersao" do Paper 1.
#
# O que esta sob replicacao, com os valores de 3 seeds publicados nas notas:
#   [zeros do Apendice A — qualquer seed que viole um "0 exato" e ACHADO]
#   Z1 modelo sob prever_valor=0 ........ 0 exato (notas 01/10)
#   Z2 phi sob eremita / esp0 / pv0 ..... 0 exato (notas 05/10)
#   Z3 relato sob interprete cego x4 .... 0 exato (notas 06/10)
#   Z4 modelo_do_outro no eremita ....... 0 exato (nota 04)
#   Z5 autocausa sob horizonte=1 ........ 0 exato (nota 09 P2)
#   Z6 agencia no eremita ............... piso f32 0,000-0,004; 0 em double
#                                         (notas 01/09) — aqui MEDIDO nas duas
#                                         precisoes em toda condicao
#   [valores e direcoes]
#   V1 controles: modelo ~0,63; phi ~0,06-0,07; relato ~0,62; kappa cheio ~0,67
#   V2 autocausa: ctl ~0,13-0,15 x eremita ~0,027-0,033 (razao ~5x, nota 09 P1)
#   V3 relato do eremita: MUDO, ~0,005 (nota 06 P5)
#   V4 direcoes opostas (nota 09 P4): autocausa ini ~0,09 -> fim ~0,17 (SOBE);
#      agencia ini ~0,44-0,47 -> fim ~0,36-0,39 (CAI); hor_m fim ~8-9,5
#   V5 honestidade (nota 08 S6): hon_f fim ~0,85 (domina sem fixar), blefe ~0,10
#   [pergunta aberta da nota 09/10 — respondida de graca pelo lote]
#   Q1 o piso da agencia FORA do eremita: toda corrida computa a agencia nas
#      duas precisoes (o CSV oficial segue float32; a dupla e so medicao) e
#      conta os blocos-tick em que elas discordam.
#
# Custo: 9 variantes x 50 seeds x 3000 ticks (~2h de CPU; ~15 min com -P 12).
# Por isso NAO entra no datasets/gerar.sh — a proveniencia e deste script:
#   git log -1 --oneline -- datasets/replicacao50.csv
#
#   sh papers/notes/11-replicacao.sh                     # 50 seeds
#   SEEDS_LISTA="7 42" sh papers/notes/11-replicacao.sh  # fumaca (nao grava dataset)
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,63" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=3000
NPROC=${NPROC:-12}
SEEDS=${SEEDS_LISTA:-$(seq 1 50)}
FUMACA=${SEEDS_LISTA:+sim}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# ---- instrumentacao Q1 (em TODAS as variantes): agencia nas duas precisoes --
# A sonda dupla nao toca o CSV (o float32 segue oficial) nem o RNG (a sonda e
# aritmetica pura). Conta blocos-tick em que as duas precisoes discordam.
base=troca(src,
  "static float agencia_do_bloco(Bloco *b, int i) {",
  "/* REPLICACAO (nota 11): a mesma sonda com a comparacao em DOUBLE — mede o\n"
  " * piso de arredondamento da agencia em qualquer populacao (a nota 09 §5 so\n"
  " * o mediu no eremita, onde a verdade algebrica e conhecida). */\n"
  "static long aud_ag_n, aud_ag_dif, aud_ag_f32so, aud_ag_dblso;\n"
  "static void aud_dump(void) {\n"
  "    fprintf(stderr, \"AUDIT ag_n=%ld ag_dif=%ld ag_f32so=%ld ag_dblso=%ld\\n\",\n"
  "            aud_ag_n, aud_ag_dif, aud_ag_f32so, aud_ag_dblso);\n"
  "}\n"
  "static float agencia_do_bloco_dbl(Bloco *b, int i) {\n"
  "    float C[9], E[9], K[9];\n"
  "    int n = 0;\n"
  "    C[n] = prever_valor(b->x, b->y, b);\n"
  "    E[n] = (8 - rivais_em(b->x, b->y, b->x, b->y)) / 8.0f;\n"
  "    K[n] = 1.0f;\n"
  "    n++;\n"
  "    for (int dy = -1; dy <= 1; dy++)\n"
  "        for (int dx = -1; dx <= 1; dx++) {\n"
  "            if (dx == 0 && dy == 0) continue;\n"
  "            int nx = b->x + dx, ny = b->y + dy;\n"
  "            if (nx < 0 || nx >= LARG || ny < 0 || ny >= ALT) continue;\n"
  "            if (ocup[ny][nx] != -1) continue;\n"
  "            C[n] = prever_valor(nx, ny, b);\n"
  "            E[n] = (8 - rivais_em(nx, ny, b->x, b->y)) / 8.0f;\n"
  "            K[n] = 1.0f + ANTECIPACAO * pretendentes_em(nx, ny, i);\n"
  "            n++;\n"
  "        }\n"
  "    if (n < 2) return -1.0f;\n"
  "    int trocas = 0, anterior = -1;\n"
  "    for (int p = 0; p < AG_PASSOS; p++) {\n"
  "        double lam = (double)b->peso_espaco * (double)p / (double)(AG_PASSOS - 1);\n"
  "        int    arg = 0;\n"
  "        double melhor = ((double)C[0] + lam * (double)E[0]) / (double)K[0];\n"
  "        for (int k = 1; k < n; k++) {\n"
  "            double nota = ((double)C[k] + lam * (double)E[k]) / (double)K[k];\n"
  "            if (nota > melhor) { melhor = nota; arg = k; }\n"
  "        }\n"
  "        if (anterior >= 0 && arg != anterior) trocas++;\n"
  "        anterior = arg;\n"
  "    }\n"
  "    return trocas > 0 ? 1.0f : 0.0f;\n"
  "}\n"
  "static float agencia_do_bloco(Bloco *b, int i) {")
base=troca(base,
  "        float a = agencia_do_bloco(&blocos[i], i);\n"
  "        if (a >= 0.0f) { ag += a; n_ag++; }      /* < 0 = encurralado */",
  "        float a = agencia_do_bloco(&blocos[i], i);\n"
  "        if (a >= 0.0f) { ag += a; n_ag++; }      /* < 0 = encurralado */\n"
  "        { float a2 = agencia_do_bloco_dbl(&blocos[i], i);\n"
  "          if (a >= 0.0f && a2 >= 0.0f) {\n"
  "              aud_ag_n++;\n"
  "              if (a != a2) { aud_ag_dif++;\n"
  "                             if (a > a2) aud_ag_f32so++; else aud_ag_dblso++; } } }")
base=troca(base,
  "    signal(SIGINT, ao_interromper);",
  "    signal(SIGINT, ao_interromper);\n    atexit(aud_dump);")

# ---- as ablacoes (mesmos patches das notas 01/05/06/09/10) -------------------
def eremita(s):
    s=troca(s,"static int rivais_em(int cx, int cy, int self_x, int self_y) {\n    int rivais = 0;",
              "static int rivais_em(int cx, int cy, int self_x, int self_y) {\n"
              "    (void)cx;(void)cy;(void)self_x;(void)self_y; return 0;\n    int rivais = 0;")
    s=troca(s,"static int pretendentes_em(int cx, int cy, int self_i) {\n    int n = 0;",
              "static int pretendentes_em(int cx, int cy, int self_i) {\n"
              "    (void)cx;(void)cy;(void)self_i; return 0;\n    int n = 0;")
    return s
def pv0(s):
    return troca(s,"\n    return valor;\n","\n    return 0.0f;\n")
def esp0(s):
    s=troca(s,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
              "b->peso_espaco = (rng01(), 0.0f);")
    s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
              "cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 0.0f);")
    return s
def h1(s):
    return troca(s,"#define HORIZONTE_MAX 12","#define HORIZONTE_MAX 1")
def cego(s,k):
    return troca(s,
      "        int r = rel_classifica(blocos[i].x, blocos[i].y,\n"
      "                               rel_cx[i], rel_cy[i], rel_ex[i], rel_ey[i]);",
      f"        int r = {k};")

open(f"{tmp}/ctl.c","w").write(base)
open(f"{tmp}/erem.c","w").write(eremita(base))
open(f"{tmp}/pv0.c","w").write(pv0(base))
open(f"{tmp}/esp0.c","w").write(esp0(base))
open(f"{tmp}/h1.c","w").write(h1(base))
for k in range(4):
    open(f"{tmp}/cego{k}.c","w").write(cego(base,k))
PY

VARS="ctl erem pv0 esp0 h1 cego0 cego1 cego2 cego3"
for v in $VARS; do
    # warning conhecido do idioma '(rng01(), 0.0f)' na esp0
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

echo "== sanidade (regra 3): a instrumentacao nao pode tocar a simulacao =="
"$TMP/ctl" 7 2000 0 --log "$TMP/bit.csv" >/dev/null 2>/dev/null
if diff -q "$TMP/bit.csv" datasets/seed7.csv >/dev/null; then
    echo "   ctl instrumentada x datasets/seed7.csv: BIT-A-BIT IDENTICO"
else
    echo "   FALHOU: a instrumentacao mudou o CSV"; exit 1
fi

echo "== lote: $(echo $VARS | wc -w) variantes x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/csv"
export TMP TICKS
for v in $VARS; do for s in $SEEDS; do echo "$v $s"; done; done | \
  xargs -P "$NPROC" -n 2 sh -c '
    "$TMP/$1" "$2" "$TICKS" 0 --log "$TMP/csv/${1}_$2.csv" \
        >/dev/null 2>"$TMP/csv/${1}_$2.err" || echo "$1 $2" >> "$TMP/falhas"
  ' _
if [ -s "$TMP/falhas" ]; then
    echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1
fi
echo "   $(ls "$TMP/csv/"*.csv | wc -l) corridas concluidas"

echo "== agregacao =="
SAIDA=${FUMACA:+"$TMP/replicacao50.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/replicacao50.csv"}
{
echo "cond,seed,ticks,pop_fim,mod_med,mod_max,ag_med,ag_max,mo_med,mo_max,phi_med,phi_max,rel_med,rel_max,ac_med,ac_max,ac_ini,ac_fim,ag_ini,ag_fim,hor_ini,hor_fim,hon_fim,blef_fim,ag_pares,ag_dif,ag_dif_f32so,ag_dif_dblso"
for v in $VARS; do
  for s in $SEEDS; do
    awk -F, -v cond="$v" -v seed="$s" '
      NR>1 {
        t=$2+0; pop=$3+0; lt=t; lp=pop
        if (t>20 && pop>0) { n++
          smod+=$14; sag+=$15; smo+=$16; sphi+=$17; srel+=$18; sac+=$21 }
        if ($14>mmod) mmod=$14
        if ($15>mag)  mag=$15
        if ($16>mmo)  mmo=$16
        if ($17>mphi) mphi=$17
        if ($18>mrel) mrel=$18
        if ($21>mac)  mac=$21
        if (pop>0 && t>=20   && t<=300)  { ni++; iac+=$21; iag+=$15; ihor+=$6 }
        if (pop>0 && t>=2700 && t<=3000) { nf++; fac+=$21; fag+=$15; fhor+=$6
                                           fhon+=$19; fblef+=$20 }
      }
      function med(s,c) { return c ? sprintf("%.6f", s/c) : "-1" }
      END {
        printf "%s,%s,%d,%d,", cond, seed, lt, lp
        printf "%s,%.6f,%s,%.6f,%s,%.6f,%s,%.6f,%s,%.6f,%s,%.6f,",
          med(smod,n),mmod, med(sag,n),mag, med(smo,n),mmo,
          med(sphi,n),mphi, med(srel,n),mrel, med(sac,n),mac
        printf "%s,%s,%s,%s,%s,%s,%s,%s,",
          med(iac,ni),med(fac,nf), med(iag,ni),med(fag,nf),
          med(ihor,ni),med(fhor,nf), med(fhon,nf),med(fblef,nf)
      }' "$TMP/csv/${v}_$s.csv"
    sed -n 's/^AUDIT ag_n=\([0-9]*\) ag_dif=\([0-9]*\) ag_f32so=\([0-9]*\) ag_dblso=\([0-9]*\)$/\1,\2,\3,\4/p' \
        "$TMP/csv/${v}_$s.err"
  done
done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== previa (media entre seeds, por condicao) =="
awk -F, 'NR>1 {
    n[$1]++
    mod[$1]+=$5; ag[$1]+=$7; mo[$1]+=$9; phi[$1]+=$11; rel[$1]+=$13; ac[$1]+=$15
    dif[$1]+=$26; par[$1]+=$25
  }
  END {
    printf "   %-7s %8s %8s %8s %8s %8s %8s %12s\n",
      "cond","modelo","agencia","mo","phi","relato","autoc","ag f32!=dbl"
    for (c in n)
      printf "   %-7s %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f %12.2e\n",
        c, mod[c]/n[c], ag[c]/n[c], mo[c]/n[c], phi[c]/n[c], rel[c]/n[c],
        ac[c]/n[c], (par[c] ? dif[c]/par[c] : 0)
  }' "$SAIDA"
echo "== fim =="
