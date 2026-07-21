#!/bin/sh
# Nota 20 (Paper 2): O INVASOR-RARO — o h* da nota 19 e um ESS, ou so um vencedor
# 50/50?
#
# A nota 16 achou o ESS interior; a nota 19 o localizou em curva (h*(delta) desce
# 12->10->9->8->8->7 de delta=0.88 a 0.96). Mas TODOS esses duelos foram 50/50: a
# media do traco no CSV E a frequencia, e o vencedor e "quem passa de 0.5 partindo
# de 0.5". Isso mede DOMINANCIA, nao INVASIBILIDADE. Um ESS de verdade tem de
# resistir a um invasor RARO (a definicao de Maynard Smith: uma estrategia e ESS
# se, comum, nenhum mutante raro cresce). O ROADMAP declara o invasor-raro como
# item 3, "passou a importar de verdade agora que o ESS e interior" — porque um
# ponto interior pode ser vencedor-50/50 e AINDA assim invadivel por um raro.
#
# A distincao que o protocolo ja carrega (corolario: "populacao de equilibrio e
# proxy de GRUPO; para aptidao individual, ensaio de invasao"). Aqui: invasor a
# p0 = 0.1 (6 de 60 blocos iniciais; INVM=10), residente monomorfico no resto.
# Mutacao OFF, heranca exata (linhagens puras) — a media do horizonte no CSV segue
# sendo a frequencia: freq_inv = (hor_m - h_res)/(h_inv - h_res).
#
# Dois deltas, o h* da nota 19 como residente:
#   delta=0.95, H=8 ;  delta=0.96, H=7.
# Para cada delta, DOIS blocos de pares (bidirecional — a assinatura de ATRATOR):
#   RESISTENCIA: residente = H, invasor raro = cada j != H no probe set.
#                ESS => nenhum j cresce acima de p0.
#   ATRACAO:     residente = cada i != H, invasor raro = H.
#                Atrator => H cresce acima de p0 contra TODO i (invade dos dois
#                lados). Em particular contra i=12 (o "ESS" da nota 14) e i=1 (o
#                otimo de grupo): o interior invade o teto E o miope.
# Probe set por delta: {1, 4, H-2, H-1, H+1, H+2, 10, 12} inter [1,12] \ {H}.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   I0 (sanidade): h_inv == h_res => populacao pura (hor_m == h, desc_m == delta),
#       qualquer INVM. Checado em H=8/delta=0.95 e H=7/delta=0.96.
#   Idet (determinismo): a mesma seed reproduz (o binario e f(seed)).
#   I1 (o ESS resiste): residente = H, TODO invasor raro j termina com
#       freq_inv(T) <= p0 = 0.1 — nenhum cresce. Pareado por seed, o teste e
#       freq_inv(T) - 0.1: predicao = <= 0 para |j - H| grande (t < -2), e ~0
#       (dentro do ruido) para os vizinhos H±1, porque a nota 19 achou a escada
#       perto de H DENTRO do ruido de 0.5 (otimo mole). NENHUM j com
#       freq_inv(T) - 0.1 > 0 significativo (t > +2) — se houver, H NAO e ESS.
#   I2 (o interior invade o teto e o miope): residente = 12, invasor raro = H =>
#       freq_inv(T) >> p0 (t > +3). Idem residente = 1. O teto que a nota 14 leu
#       como ESS e, em delta alto, invadido por um raro interior — o resultado
#       que fecha a inversao das notas 16/19 no nivel individual.
#   I3 (atrator / convergence-stable): H cresce como raro contra residentes dos
#       DOIS lados (i < H e i > H); e, reciprocamente (bloco RESISTENCIA), H
#       repele invasores dos dois lados. O cruzamento de "H cresce" fica em i = H.
#       Predicao NEGATIVA que falsearia: se H so crescer contra i > H (invade os
#       fundos, perde para os rasos) ou vice-versa, H nao e atrator — e um ponto
#       de fuga, e a leitura "ESS interior" da nota 16 vira "otimo local instavel".
#   I4 (contraste com 50/50): para os mesmos pares (H, j), a freq final do
#       invasor RARO (p0=0.1) e do duelo 50/50 (a grade-fina.csv, freq de partida
#       0.5) contam a MESMA direcao (quem sobe, sobe nas duas). Se um par subir a
#       partir de 0.5 mas NAO a partir de 0.1, ha dependencia de frequencia forte
#       (o raro nao invade mas o comum domina) — dado, nao erro. Reportado.
#
# Custo: 2 deltas x ~14 pares x 8 seeds x 6000 ticks = ~224 corridas. A nota 16
# fez 600 em ~46 min; estimo ~20-30 min com NPROC=16. Se passar de 2h, aborte.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/invasor-raro.csv.
#   git log -1 --oneline -- datasets/invasor-raro.csv
#
#   sh papers/notes/20-invasor-raro.sh                     # 8 seeds, 6000 ticks
#   SEEDS_LISTA="7" sh papers/notes/20-invasor-raro.sh     # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-6000}
NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
INVM=${INVM:-10}          # p0 = 1/INVM = 0.1 (6 de 60 blocos iniciais)

# O patch e o da nota 16, com UMA mudanca: a atribuicao do horizonte usa
# (n_blocos % INVM == 0) em vez de (n_blocos & 1) — fracao rara em vez de 50/50.
# rng01() preservado => o MUNDO e identico ao das notas 16/17/19.
python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

s=troca(src,
  "static void semear_blocos(void) {\n    n_blocos = 0;",
  "static int TORN_HI = 6, TORN_HJ = 6;   /* HI = residente, HJ = invasor    */\n"
  "static int TORN_INVM = 10;             /* invasor a cada INVM blocos (p0)  */\n"
  "static float TORN_DESC = DESCONTO;     /* o desconto pregado               */\n"
  "static void semear_blocos(void) {\n"
  "    { const char *a=getenv(\"TORN_HI\"), *c=getenv(\"TORN_HJ\");\n"
  "      const char *d=getenv(\"TORN_DESC\"), *m=getenv(\"TORN_INVM\");\n"
  "      if (a) TORN_HI=atoi(a); if (c) TORN_HJ=atoi(c);\n"
  "      if (m) TORN_INVM=atoi(m); if (d) TORN_DESC=(float)atof(d); }\n"
  "    n_blocos = 0;")
s=troca(s,"b->urgencia    = URGENCIA    * (0.5f + rng01());          /* ~0.5x..1.5x */",
          "b->urgencia    = (rng01(), URGENCIA);")
s=troca(s,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
          "b->peso_espaco = (rng01(), PESO_ESPACO);")
s=troca(s,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
          "b->desconto    = (rng01(), TORN_DESC);")
# a UNICA diferenca da nota 16: invasor raro (mod INVM) em vez de parity (50/50)
s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
          "b->horizonte   = (rng01(), (((n_blocos % TORN_INVM)==0) ? TORN_HJ : TORN_HI));")
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
open(f"{tmp}/inv.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/inv" "$TMP/inv.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }

# I0: h_inv == h_res => populacao pura (hor_m == h, desc_m == delta).
for cfg in "8 0.95" "7 0.96"; do
  set -- $cfg; H=$1; D=$2
  TORN_HI=$H TORN_HJ=$H TORN_DESC=$D TORN_INVM=$INVM "$TMP/inv" 7 60 0 \
    --log "$TMP/i0.csv" >/dev/null 2>&1
  awk -F, -v h="$H" -v d="$D" 'NR>1 && ($6<h-0.01 || $6>h+0.01) { bad=1 }
    NR>1 && ($8<d-0.01 || $8>d+0.01) { bad=1 } END { exit bad+0 }' "$TMP/i0.csv" \
    || { echo "I0 FALHOU em H=$H delta=$D (populacao nao e pura)"; exit 1; }
done
echo "   I0 ok: h_inv==h_res da populacao pura (H=8/0.95 e H=7/0.96)"

# Idet: a mesma seed reproduz.
TORN_HI=8 TORN_HJ=10 TORN_DESC=0.95 TORN_INVM=$INVM "$TMP/inv" 7 300 0 --log "$TMP/d1.csv" >/dev/null 2>&1
TORN_HI=8 TORN_HJ=10 TORN_DESC=0.95 TORN_INVM=$INVM "$TMP/inv" 7 300 0 --log "$TMP/d2.csv" >/dev/null 2>&1
cmp -s "$TMP/d1.csv" "$TMP/d2.csv" || { echo "Idet FALHOU: nao-deterministico"; exit 1; }
echo "   Idet ok: f(seed) reproduz bit-a-bit"

# Resumo de UMA corrida: janela fim (T-300..T) — freq do INVASOR (HJ).
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0
  if (pop>0 && t>=T-300 && t<=T) { nf++; shor+=$6; spop+=$3 }
}
END {
  if (!nf) { printf "%s,%s,%d,%d,-1,-1,-1,extinta\n", dval, seed, HI, HJ; exit }
  hor=shor/nf; f=(HJ==HI)?0:(hor-HI)/(HJ-HI)
  printf "%s,%s,%d,%d,%.4f,%.4f,%.1f,ok\n", dval, seed, HI, HJ, f, hor, spop/nf
}
AWK

# Monta a lista de pares por delta: RESISTENCIA (H, j) e ATRACAO (i, H).
gerar_pares() {  # $1 = H
  H=$1
  echo "$H $((H-2)) $((H-1)) $((H+1)) $((H+2)) 1 4 10 12" | tr ' ' '\n' \
    | awk -v H="$H" '$1>=1 && $1<=12 && $1!=H {print}' | sort -un > "$TMP/probe.$H"
  while read j; do echo "$H $j"; done < "$TMP/probe.$H"   # residente H, invasor j
  while read i; do echo "$i $H"; done < "$TMP/probe.$H"   # residente i, invasor H
}

{
  for cfg in "8 0.95" "7 0.96"; do
    set -- $cfg; H=$1; D=$2
    gerar_pares "$H" | while read hi hj; do
      for s in $SEEDS; do echo "$D $hi $hj $s"; done
    done
  done
} | sort -u > "$TMP/jobs"
NJOBS=$(wc -l < "$TMP/jobs")
echo "== invasor-raro: $NJOBS corridas (p0=1/$INVM), $TICKS ticks, -P $NPROC =="

mkdir -p "$TMP/rows"
export TMP TICKS INVM
xargs -P "$NPROC" -n 4 sh -c '
    TORN_DESC="$1" TORN_HI="$2" TORN_HJ="$3" TORN_INVM="$INVM" "$TMP/inv" "$4" "$TICKS" 0 \
      --log "$TMP/c_$1_$2_$3_$4.csv" >/dev/null 2>&1 \
      || { echo "$1 $2 $3 $4" >> "$TMP/falhas"; exit 0; }
    awk -F, -v dval="$1" -v seed="$4" -v HI="$2" -v HJ="$3" -v T="$TICKS" \
      -f "$TMP/resumo.awk" "$TMP/c_$1_$2_$3_$4.csv" > "$TMP/rows/$1_$2_$3_$4.row"
    rm -f "$TMP/c_$1_$2_$3_$4.csv"
  ' _ < "$TMP/jobs"
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/invasor-raro.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/invasor-raro.csv"}
{
echo "desconto,seed,h_res,h_inv,freq_inv,hor_m,pop_fim,status"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== I1 (o ESS resiste): residente = H, invasor raro j — freq_inv(T) vs p0=0.1 =="
echo "   freq > 0.1 => o raro CRESCEU (invadiu); <= 0.1 => repelido"
for cfg in "8 0.95" "7 0.96"; do
  set -- $cfg; H=$1; D=$2
  echo "   --- delta=$D, residente H=$H ---"
  awk -F, -v H="$H" -v D="$D" 'NR>1 && $8!="extinta" && $1==D && $3==H && $4!=H {
      k=$4; s[k]+=$5; ss[k]+=$5*$5; n[k]++ }
    function se(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v/c):0 }
    END {
      for (j=1;j<=12;j++){ if(!(j in n))continue
        m=s[j]/n[j]; e=se(s[j],ss[j],n[j]); t=(e>0)?(m-0.1)/e:0
        printf "     invasor j=%2d  freq=%.3f se=%.3f t(vs0.1)=%+.2f  %s\n", j,m,e,t,
          (t>2?"*** INVADIU (H nao resiste) ***":(t<-2?"repelido":"~ neutro")) }
    }' "$SAIDA"
done

echo ""
echo "== I2/I3 (H e atrator): residente i, invasor raro = H — H cresce dos dois lados? =="
for cfg in "8 0.95" "7 0.96"; do
  set -- $cfg; H=$1; D=$2
  echo "   --- delta=$D, invasor H=$H contra residente i ---"
  awk -F, -v H="$H" -v D="$D" 'NR>1 && $8!="extinta" && $1==D && $4==H && $3!=H {
      k=$3; s[k]+=$5; ss[k]+=$5*$5; n[k]++ }
    function se(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v/c):0 }
    END {
      for (i=1;i<=12;i++){ if(!(i in n))continue
        m=s[i]/n[i]; e=se(s[i],ss[i],n[i]); t=(e>0)?(m-0.1)/e:0
        lado=(i<H)?"(raso)":"(fundo)"
        printf "     residente i=%2d %-7s  freqH=%.3f se=%.3f t(vs0.1)=%+.2f  %s\n", i,lado,m,e,t,
          (t>2?"H INVADE":(t<-2?"H repelido":"~ neutro")) }
      print  "     I2: i=12 e i=1 devem dar H INVADE. I3: H invade dos DOIS lados."
    }' "$SAIDA"
done

echo ""
echo "== I4 (contraste raro x 50/50): a direcao bate com grade-fina.csv? =="
if [ -f "$RAIZ/datasets/grade-fina.csv" ]; then
  echo "   par (H,j): freq_inv raro (p0=0.1) x freq_hj 50/50 — mesma direcao (ambos <>0.5/0.1)?"
  for cfg in "8 0.95" "7 0.96"; do
    set -- $cfg; H=$1; D=$2
    awk -F, -v H="$H" -v D="$D" '
      FNR==NR { if (FNR>1 && $1==D && $3==H) { g[$3"_"$4]+=$5; gn[$3"_"$4]++ } next }
      $8!="extinta" && $1==D && $3==H && $4!=H { r[$4]+=$5; rn[$4]++ }
      END {
        printf "   --- delta=%s, H=%d ---\n", D, H
        for (j=1;j<=12;j++){ kr=j; kg=H"_"j
          if (!(kr in rn) || !(kg in gn)) continue
          fr=r[kr]/rn[kr]; fg=g[kg]/gn[kg]
          dirr=(fr>0.1)?"+":"-"; dirg=(fg>0.5)?"+":"-"
          printf "     j=%2d  raro=%.3f(%s)  5050=%.3f(%s)  %s\n", j, fr, dirr, fg, dirg,
            (dirr==dirg)?"concordam":"DIVERGEM (freq-dep forte)" }
      }' "$RAIZ/datasets/grade-fina.csv" "$SAIDA"
  done
else
  echo "   (sem datasets/grade-fina.csv — I4 pulado)"
fi
echo "== fim =="
