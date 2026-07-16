#!/bin/sh
# Nota 16 (Paper 2): a VARREDURA DO DESCONTO — o joelho do valor posicional
# anda com 1/(1-delta)?
#
# A nota 14 (torneio 12x12) mediu a margem do horizonte saturando em h~5 e leu
# isso como o teto da PROFUNDIDADE EFETIVA min(h, 1/(1-desconto)): com o
# desconto pregado em 0.80, 1/(1-0.80) = 5. A nota 15 cobrou o imposto por essa
# mesma grandeza — e so mordeu porque era ela a identificavel (hor_m e ruido,
# sd ate 15x maior). A profundidade efetiva costura o Paper 2 INTEIRO, e foi
# medida num delta SO. A propria nota 14 abre as "Ameacas a validade" com isso:
# "o joelho em h~5 e artefato do 0.80 — outro desconto move o joelho".
#
# O problema de um ponto so: com delta=0.80, 1/(1-delta) = 5 — e h~5 e tambem o
# MEIO da faixa 1..12. Ninguem distingue "o joelho e o teto do desconto" de "o
# joelho caiu no meio da regua". Esta nota varre delta e ve se o joelho ANDA.
#
# Desenho: o patch da nota 14 (populacao 50/50 com horizonte HI e HJ; so o
# horizonte varia — urgencia, peso_espaco e estrategia pregados; mutacao
# desligada, heranca exata), com UMA mudanca: o desconto pregado vem do
# ambiente (TORN_DESC) em vez do #define. Com TORN_DESC=0.80 o binario e o da
# nota 14 — mesma consumacao de rng01(), mesmo float (0.80f e o float mais
# proximo de 0.8, e (float)atof("0.80") cai nele) — entao a fatia delta=0.80
# tem de REPRODUZIR datasets/torneio.csv linha a linha. E o P0.
#
# A grade de delta braceja os dois lados do #define, e os dois extremos sao
# CENSURADOS de proposito — e neles que a predicao arrisca mais:
#     delta  1/(1-delta)   o que a faixa 1..12 ve
#     0.30      1.43       joelho ABAIXO da escada -> escada plana de h=2 em diante
#     0.50      2.00       joelho no degrau 2
#     0.80      5.00       joelho em 5   (a nota 14; ancora conhecida)
#     0.90     10.00       joelho em 10
#     0.95     20.00       joelho ACIMA do teto HORIZONTE_MAX=12 -> nao satura
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; a regra da nota 13):
#   P0 (sanidade): a fatia delta=0.80 reproduz datasets/torneio.csv linha a
#       linha nos 15 pares x 8 seeds — mesmo binario, mesmo mundo. Se falhar, o
#       patch mudou a simulacao e o resto da nota nao vale nada.
#   P1 (o joelho anda): a margem freq(h -> h+1) fica ~1.0 ABAIXO do joelho e
#       desaba para ~0.5 ACIMA dele. Nos extremos censurados: em delta=0.30 a
#       escada e PLANA (freq ~0.5) de h=2 em diante — h=2 e h=3 tem a MESMA
#       profundidade efetiva (1.43), logo nada os separa; em delta=0.95 ela NAO
#       satura dentro da faixa (margens altas ate h=11).
#   P2 (a transicao fix->polim anda junto): a nota 14 §3 achou fixacao ate h=3 e
#       polimorfismo de h=4 em diante (delta=0.80, joelho 5). Definicao operacional
#       da nota 14, sem limiar novo: a transicao e o MENOR h com 0/8 fixacoes.
#       Predicao: transicao(delta) ~ 1/(1-delta) - 1, isto e
#       0.30 -> h=1 (nao fixa em lugar nenhum); 0.50 -> h~1-2; 0.80 -> h=4
#       (replica a nota 14); 0.90 -> h~9; 0.95 -> SEM transicao (fixa a escada
#       inteira, 1..11).
#   P3 (o ESS = teto era do 0.80): a dominancia par-a-par persiste em todo delta
#       (o mais fundo nunca PERDE), mas acima do joelho a margem some. Nos duelos
#       de longo alcance (1,12) (3,12) (6,12) (9,12): em delta=0.30 eles devem
#       dar freq ~0.5 (deriva — o PLATO que a T1 da nota 14 previu e nao achou,
#       redimido no delta certo); em delta=0.95, freq ~1.0. Se em delta=0.30 o
#       h=12 ainda vencer o h=3 de forma consistente, a vantagem NAO e a
#       profundidade descontada e a leitura da nota 14 §2 cai.
#
# Custo: 15 pares x 5 descontos x NSEEDS seeds x TICKS ticks. Com NSEEDS=8 e
# TICKS=6000 sao 600 corridas — a nota 14 fez 528 em ~40 min com NPROC=12, entao
# ~45 min. (O cabecalho da 14 estimou "2-3 min" e errou por ~15x; o numero acima
# e o medido, nao o estimado.) Nao entra no datasets/gerar.sh.
# Agregados em datasets/desconto.csv. Proveniencia:
#   git log -1 --oneline -- datasets/desconto.csv
#
#   sh papers/notes/16-desconto.sh                       # 8 seeds, 6000 ticks
#   SEEDS_LISTA="7" sh papers/notes/16-desconto.sh       # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-6000}
NPROC=${NPROC:-12}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
# A grade fica DENTRO do clamp do traco (muta_traco: 0.30..0.98) — com a mutacao
# desligada o clamp nao morde, mas um desconto fora dele seria um mundo que a
# evolucao canonica nao alcanca, e a nota nao falaria do mesmo bicho.
DESCONTOS=${DESCONTOS:-"0.30 0.50 0.80 0.90 0.95"}
# A ESCADA (h, h+1) mede o joelho (P1/P2); os LONGOS (h, 12) medem se a
# dominancia composta sobrevive acima dele (P3). Sem sobreposicao entre as duas.
PARES=${PARES:-"1_2 2_3 3_4 4_5 5_6 6_7 7_8 8_9 9_10 10_11 11_12 1_12 3_12 6_12 9_12"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# 1. globais do torneio + leitura do ambiente (semear_blocos roda uma vez).
#    Identico a nota 14, mais o TORN_DESC — a UNICA diferenca desta nota.
s=troca(src,
  "static void semear_blocos(void) {\n    n_blocos = 0;",
  "static int TORN_HI = 6, TORN_HJ = 6;   /* torneio: dois horizontes 50/50 */\n"
  "static float TORN_DESC = DESCONTO;     /* varredura: o desconto pregado  */\n"
  "static void semear_blocos(void) {\n"
  "    { const char *a=getenv(\"TORN_HI\"), *c=getenv(\"TORN_HJ\");\n"
  "      const char *d=getenv(\"TORN_DESC\");\n"
  "      if (a) TORN_HI=atoi(a); if (c) TORN_HJ=atoi(c);\n"
  "      if (d) TORN_DESC=(float)atof(d); }\n"
  "    n_blocos = 0;")

# 2. so o horizonte varia; o resto pregado (rng01() preservado -> mesmo mundo).
#    O desconto sai do ambiente em vez do #define: e o eixo da varredura.
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

# 3. heranca exata: nenhuma mutacao (horizonte E desconto ficam onde foram postos)
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
open(f"{tmp}/desc.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/desc" "$TMP/desc.c" 2>/dev/null

# Sanidade do patch (a mesma da nota 14): HI==HJ==6 -> hor_m == 6.
TORN_HI=6 TORN_HJ=6 "$TMP/desc" 7 50 0 --log "$TMP/san.csv" >/dev/null 2>&1
awk -F, 'NR>1 && ($6 < 5.99 || $6 > 6.01) { print "SANIDADE FALHOU tick "$2": hor_m="$6; bad=1 }
         END { exit bad+0 }' "$TMP/san.csv" \
  || { echo "patch quebrou: hor_m != HI com HI==HJ"; exit 1; }

# Resumo de UMA corrida (identico ao da nota 14, para as linhas serem
# comparaveis com datasets/torneio.csv campo a campo — e o P0).
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0
  if (pop>0 && t>=T-300 && t<=T) { nf++; shor+=$6; spop+=$3 }
}
END {
  if (!nf) { printf "%s,%d,%d,-1,-1,-1,extinta\n", seed, HI, HJ; exit }
  hor=shor/nf; f=(hor-HI)/(HJ-HI)
  fixou = (f<0.02) ? "HI" : (f>0.98) ? "HJ" : "misto"
  printf "%s,%d,%d,%.4f,%.4f,%.1f,%s\n", seed, HI, HJ, f, hor, spop/nf, fixou
}
AWK

NPARES=$(echo $PARES | wc -w); NDESC=$(echo $DESCONTOS | wc -w)
echo "== varredura de delta: $NPARES pares x $NDESC descontos x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/rows"
export TMP TICKS
for d in $DESCONTOS; do
  for p in $PARES; do
    hi=${p%_*}; hj=${p#*_}
    for s in $SEEDS; do echo "$d $hi $hj $s"; done
  done
done | xargs -P "$NPROC" -n 4 sh -c '
    TORN_DESC="$1" TORN_HI="$2" TORN_HJ="$3" "$TMP/desc" "$4" "$TICKS" 0 \
      --log "$TMP/c_$1_$2_$3_$4.csv" >/dev/null 2>&1 \
      || { echo "$1 $2 $3 $4" >> "$TMP/falhas"; exit 0; }
    awk -F, -v seed="$4" -v HI="$2" -v HJ="$3" -v T="$TICKS" \
      -f "$TMP/resumo.awk" "$TMP/c_$1_$2_$3_$4.csv" \
      | sed "s/^/$1,/" > "$TMP/rows/$1_$2_$3_$4.row"
    rm -f "$TMP/c_$1_$2_$3_$4.csv"
  ' _
if [ -s "$TMP/falhas" ]; then
    echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1
fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/desconto.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/desconto.csv"}
{
echo "desconto,seed,hi,hj,freq_hj,hor_m_fim,pop_fim,fixou"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

# ---------------------------------------------------------------- P0
# A fatia delta=0.80 tem de bater com datasets/torneio.csv linha a linha.
echo "== P0 (sanidade): a fatia delta=0.80 x datasets/torneio.csv =="
if [ -f "$RAIZ/datasets/torneio.csv" ]; then
  awk -F, -v OFS=, '
    NR==FNR { if (FNR>1) t[$1"_"$2"_"$3]=$4","$5","$6","$7; next }
    FNR>1 && $1+0==0.80 {
      k=$2"_"$3"_"$4; mine=$5","$6","$7","$8
      if (!(k in t))      { falta++; next }
      n++; if (t[k]!=mine) { bad++; if (bad<=3) print "   DIVERGE em (seed,hi,hj)="k": torneio="t[k]" | aqui="mine }
    }
    END {
      if (falta) printf "   (%d linhas sem par no torneio.csv — pares fora dos 66?)\n", falta
      if (bad) { printf "   P0 FALHOU: %d de %d linhas divergem — o patch MUDOU a simulacao\n", bad, n; exit 1 }
      printf "   P0 ok: %d/%d linhas identicas ao torneio.csv (o patch nao mexeu no mundo)\n", n, n
    }' "$RAIZ/datasets/torneio.csv" "$SAIDA" || exit 1
else
  echo "   (sem datasets/torneio.csv — P0 pulado)"
fi

# ---------------------------------------------------------------- P1 / P2
echo "== P1/P2: a escada (h -> h+1) por desconto — margem e fixacoes =="
echo "   margem = freq do horizonte h+1 (media +- sd entre seeds); fix = seeds em que o fundo FIXOU"
awk -F, '
  NR>1 && $8!="extinta" && $4==$3+1 {
    k=$1"_"$3; s[k]+=$5; ss[k]+=$5*$5; n[k]++
    if ($8=="HJ") fx[k]++
    dset[$1]=1
  }
  function sd(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    nd=0; for (d in dset) ds[nd++]=d
    for (a=0;a<nd;a++) for (b=a+1;b<nd;b++) if (ds[a]+0>ds[b]+0){t=ds[a];ds[a]=ds[b];ds[b]=t}
    for (a=0;a<nd;a++) {
      d=ds[a]; ed=1.0/(1.0-d)
      printf "\n   delta=%s   1/(1-delta)=%.2f   -> joelho previsto em h~%.0f\n", d, ed, ed
      trans=-1
      for (h=1;h<=11;h++) {
        k=d"_"h; if (!(k in n)) continue
        m=n[k]; f=s[k]/m; e=sd(s[k],ss[k],m); nf=fx[k]+0
        if (trans<0 && nf==0) trans=h
        printf "     %2d -> %2d   %.3f +- %.3f   fix %d/%d\n", h, h+1, f, e, nf, m
      }
      if (trans<0) printf "     transicao fix->polim: NENHUMA (fixou a escada inteira)   [previsto: h~%.0f]\n", ed-1
      else         printf "     transicao fix->polim: h=%d   [previsto: h~%.0f]\n", trans, ed-1
    }
  }' "$SAIDA"

# ---------------------------------------------------------------- P3
echo ""
echo "== P3: os duelos de longo alcance (h, 12) — a dominancia composta sobrevive acima do joelho? =="
echo "   freq do h=12; ~0.5 => plato (deriva); ~1.0 => o fundo ainda domina"
awk -F, '
  NR>1 && $8!="extinta" && $4==12 && $3!=11 {
    k=$1"_"$3; s[k]+=$5; ss[k]+=$5*$5; n[k]++; dset[$1]=1; hset[$3]=1
  }
  function sd(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    nd=0; for (d in dset) ds[nd++]=d
    for (a=0;a<nd;a++) for (b=a+1;b<nd;b++) if (ds[a]+0>ds[b]+0){t=ds[a];ds[a]=ds[b];ds[b]=t}
    nh=0; for (h in hset) hs[nh++]=h
    for (a=0;a<nh;a++) for (b=a+1;b<nh;b++) if (hs[a]+0>hs[b]+0){t=hs[a];hs[a]=hs[b];hs[b]=t}
    printf "   %-7s", "delta"
    for (b=0;b<nh;b++) printf " %11s", "h=" hs[b] " vs 12"
    printf "\n"
    for (a=0;a<nd;a++) {
      printf "   %-7s", ds[a]
      for (b=0;b<nh;b++) {
        k=ds[a]"_"hs[b]
        if (!(k in n)) { printf " %11s", "-"; continue }
        printf " %5.3f+-%.2f", s[k]/n[k], sd(s[k],ss[k],n[k])
      }
      printf "\n"
    }
  }' "$SAIDA"
echo "== fim =="
