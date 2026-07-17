#!/bin/sh
# Nota 17 (Paper 2): RUIDO ou TEIMOSIA? — a inversao da nota 16 tem contraparte
# solitaria?
#
# A nota 16 achou que em delta=0.95 a escada INVERTE: o h=9 vence o h=12 (t=-11)
# e o h=6 vence o h=12 (t=-4.4). Ha ESS interior, e o otimo DESCE conforme o
# delta sobe. A §4 da nota 16 ofereceu uma leitura — o desconto e um
# REGULARIZADOR: a cauda da previsao e ruido, delta^k e o peso que ela recebe, e
# em 0.95 ela envenena a decisao — e marcou a leitura como HIPOTESE, nao medicao.
#
# ESTA NOTA CORRIGE O TESTE QUE A NOTA 16 §4 PROPOS. La eu escrevi que o
# discriminante seria "`modelo` cai com h". Ele NAO serve, e o motivo e de
# desenho: a janela de comparacao do `modelo` dura `horizonte` ticks do proprio
# bloco (nota 01, "O conserto"). Um h maior alonga a janela e a torna mais dificil
# POR CONSTRUCAO — `modelo` cairia com h em qualquer mundo, com ou sem ruido na
# cauda. E controle, nao discriminante. (A nota 16 §4 fica com uma errata.)
#
# O discriminante de verdade e a distincao que o protocolo do projeto ja carrega
# (regra do corolario: "populacao de equilibrio e proxy de GRUPO; para aptidao
# individual, ensaio de invasao"). A pergunta:
#
#     a inversao do DUELO tem contraparte SOLITARIA?
#     o h=12 em delta=0.95 e ABSOLUTAMENTE pior, ou so RELATIVAMENTE?
#
#   - RUIDO: a previsao funda e pior contra o MUNDO. O deficit e absoluto, e
#     aparece numa populacao de TIPO UNICO, sem rival nenhum para lhe tomar a
#     comida: menos populacao, menos energia, mais comida sobrando de pe.
#   - TEIMOSIA / POSICIONAL: a previsao esta certa; o fundo so perde porque um
#     raso chega antes na comida que ele planejou. Sem rival, o deficit SOME —
#     a populacao de tipo unico nao cai com h.
#
# As duas sao mutuamente exclusivas no sinal, e e isso que faz disto um teste.
#
# Desenho: o patch da nota 16 (so o horizonte varia, resto pregado, mutacao off,
# desconto do ambiente), rodado com TORN_HI == TORN_HJ — logo populacao de TIPO
# UNICO, todo bloco com o mesmo h e o mesmo delta. h = 1..12, delta = 0.80/0.90/
# 0.95, seeds 1..8, 6000 ticks. Nenhum duelo: e a curva de aptidao de GRUPO.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; a regra da nota 13):
#   N0 (sanidade): HI==HJ==h => hor_m == h e desc_m == delta (a menos do
#       arredondamento de float). Se falhar, o patch nao esta pregando o tipo.
#   N1 (a hipotese do RUIDO, nota 16 §4): em delta=0.95, a populacao de tipo
#       unico CAI de h~8 para h=12, com |t| > 2 entre os dois. Idem energia_media.
#       E comida_total SOBE (o planejador fundo colhe pior, sobra comida de pe).
#   N2: em delta=0.80, a mesma diferenca (h~8 x h=12) e NAO significativa — o
#       "ESS = teto" do 0.80 e mesmo "inofensivo e inutil" (nota 16 §4), entao o
#       tipo unico fundo nao paga nada. A Fase 3 mediu ~2% de pop entre h=1 e
#       h=12; e o numero a bater.
#   N3 (a alternativa, mutuamente exclusiva com N1): se em delta=0.95 a populacao
#       NAO cair com h, o deficit e RELACIONAL — o h=12 so perde quando existe um
#       h=9 para lhe tomar a comida — e a historia do ruido esta ERRADA. Nesse
#       caso a candidata vira teimosia/posicional, e a nota 16 §4 ganha errata.
#   N4 (controle, NAO teste): `modelo` cai com h. Esperado por construcao (janela
#       mais longa). Reportado para deixar a vacuidade a vista, nao para decidir.
#       Cuidado ao ler entre deltas: a janela do `modelo` e descontada pelo delta
#       do proprio bloco, entao `modelo` NAO e comparavel atraves de delta — so
#       ao longo de h, com delta fixo.
#
# Custo: 12 horizontes x 3 descontos x NSEEDS seeds x TICKS ticks. Com NSEEDS=8 e
# TICKS=6000 sao 288 corridas — a nota 16 fez 600 em ~46 min com NPROC=16, entao
# ~22 min. Nao entra no datasets/gerar.sh. Agregados em datasets/tipo-unico.csv.
#   git log -1 --oneline -- datasets/tipo-unico.csv
#
#   sh papers/notes/17-tipo-unico.sh                       # 8 seeds, 6000 ticks
#   SEEDS_LISTA="7" sh papers/notes/17-tipo-unico.sh       # fumaca (nao grava)
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
DESCONTOS=${DESCONTOS:-"0.80 0.90 0.95"}
HORIZONTES=${HORIZONTES:-"1 2 3 4 5 6 7 8 9 10 11 12"}

# O patch e o da nota 16, sem uma virgula de diferenca (mesmas ancoras, mesma
# consumacao de rng01()). Rodado com HI==HJ ele da populacao de tipo unico.
python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

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
open(f"{tmp}/uni.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/uni" "$TMP/uni.c" 2>/dev/null

# N0: HI==HJ==h => hor_m == h, desc_m == delta. Checado em h=3 e h=11, delta=0.95.
for h in 3 11; do
  TORN_HI=$h TORN_HJ=$h TORN_DESC=0.95 "$TMP/uni" 7 60 0 --log "$TMP/n0.csv" >/dev/null 2>&1
  awk -F, -v h="$h" 'NR>1 && ($6 < h-0.01 || $6 > h+0.01) { print "  N0 FALHOU tick "$2": hor_m="$6" (esperado "h")"; bad=1 }
           NR>1 && ($8 < 0.94 || $8 > 0.96) { print "  N0 FALHOU tick "$2": desc_m="$8" (esperado 0.95)"; bad=1 }
           END { exit bad+0 }' "$TMP/n0.csv" || { echo "N0 falhou em h=$h"; exit 1; }
done
echo "   N0 ok: HI==HJ==h da hor_m==h e desc_m==delta (h=3 e h=11)"

# Resumo de UMA corrida: janela fim (T-300..T).
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0
  if (pop>0 && t>=T-300 && t<=T) { n++; sp+=$3; se+=$4; sc+=$5; sh+=$6; sd+=$8; sm+=$14 }
}
function med(s,c){ return c ? sprintf("%.4f", s/c) : "-1" }
END {
  if (!n) { printf "%s,%s,%s,-1,-1,-1,-1,-1,-1\n", dval, hval, seed; exit }
  printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n", dval, hval, seed,
    med(sp,n), med(se,n), med(sc,n), med(sm,n), med(sh,n), med(sd,n)
}
AWK

NH=$(echo $HORIZONTES | wc -w); ND=$(echo $DESCONTOS | wc -w)
echo "== tipo unico: $NH horizontes x $ND descontos x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/rows"
export TMP TICKS
for d in $DESCONTOS; do for h in $HORIZONTES; do for s in $SEEDS; do echo "$d $h $s"; done; done; done | \
  xargs -P "$NPROC" -n 3 sh -c '
    TORN_DESC="$1" TORN_HI="$2" TORN_HJ="$2" "$TMP/uni" "$3" "$TICKS" 0 \
      --log "$TMP/c_$1_$2_$3.csv" >/dev/null 2>&1 \
      || { echo "$1 $2 $3" >> "$TMP/falhas"; exit 0; }
    awk -F, -v dval="$1" -v hval="$2" -v seed="$3" -v T="$TICKS" \
      -f "$TMP/resumo.awk" "$TMP/c_$1_$2_$3.csv" > "$TMP/rows/$1_$2_$3.row"
    rm -f "$TMP/c_$1_$2_$3.csv"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/tipo-unico.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/tipo-unico.csv"}
{
echo "desconto,horizonte,seed,pop,energia,comida_total,modelo,hor_m,desc_m"
for d in $DESCONTOS; do for h in $HORIZONTES; do for s in $SEEDS; do
  cat "$TMP/rows/${d}_${h}_${s}.row" 2>/dev/null || true
done; done; done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== N1/N2/N3: a curva de aptidao de GRUPO por horizonte (media +- sd, 8 seeds) =="
awk -F, 'NR>1 && $4!=-1 {
    k=$1"_"$2; n[k]++; p[k]+=$4; pp[k]+=$4*$4; e[k]+=$5; c[k]+=$6; m[k]+=$7
    ds[$1]=1; hs[$2]=1 }
  function sd(a,b,cc){ v=(b-a*a/cc)/(cc-1); return v>0?sqrt(v):0 }
  END {
    nd=0; for (d in ds) dd[nd++]=d
    for (a=0;a<nd;a++) for (b=a+1;b<nd;b++) if (dd[a]+0>dd[b]+0){t=dd[a];dd[a]=dd[b];dd[b]=t}
    nh=0; for (h in hs) hh[nh++]=h
    for (a=0;a<nh;a++) for (b=a+1;b<nh;b++) if (hh[a]+0>hh[b]+0){t=hh[a];hh[a]=hh[b];hh[b]=t}
    for (a=0;a<nd;a++) { d=dd[a]
      printf "\n  delta=%s\n", d
      printf "    %2s  %16s  %8s  %10s  %8s\n","h","pop","energia","comida_tot","modelo"
      for (b=0;b<nh;b++) { h=hh[b]; k=d"_"h; if(!(k in n)) continue
        printf "    %2s  %7.1f +- %-5.1f  %8.2f  %10.1f  %8.4f\n",
          h, p[k]/n[k], sd(p[k],pp[k],n[k]), e[k]/n[k], c[k]/n[k], m[k]/n[k] }
      # o teste: h=8 x h=12
      k8=d"_8"; k12=d"_12"
      if ((k8 in n) && (k12 in n)) {
        m8=p[k8]/n[k8]; m12=p[k12]/n[k12]
        s8=sd(p[k8],pp[k8],n[k8])/sqrt(n[k8]); s12=sd(p[k12],pp[k12],n[k12])/sqrt(n[k12])
        se=sqrt(s8*s8+s12*s12); t=(se>0)?(m12-m8)/se:0
        v=(t<-2)?"*** h=12 PERDE POPULACAO (N1: ruido) ***":((t>2)?"h=12 tem MAIS pop":"~ empate (N3: deficit relacional)")
        printf "    N1/N3 -> pop(h=12) - pop(h=8) = %+.1f   t=%+.1f   %s\n", m12-m8, t, v
      }
    }
  }' "$SAIDA"
echo "== fim =="
