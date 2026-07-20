#!/bin/sh
# Nota 19 (Paper 2): a GRADE FINA do desconto — onde exatamente o otimo sai do
# teto, e que forma tem a descida?
#
# A nota 16 mediu o otimo de horizonte em 3 pontos: >=12 (teto) em delta=0.80,
# ~10 em 0.90, ~7-8 em 0.95 — o otimo DESCE com a paciencia, e o ESS vira
# interior. Mas 3 pontos nao dizem NEM onde o otimo sai do teto (em algum delta
# entre 0.80 e 0.90? ou so em 0.88+?), NEM a forma da descida (suave? abrupta?).
# O ROADMAP declara a grade fina em delta [0.88; 0.96] como item 2 da fila.
#
# A nota 18 deu o mecanismo que faz a forma importar: com k* = 0 (so o primeiro
# passo do plano carrega informacao como PREVISAO), o valor da cauda e ordinal e
# ~constante em delta, mas o veneno dela cresce com delta por DOIS canais (o
# peso delta^k e a degradacao E4 — a cauda anticorrelaciona em 0.95). O h*
# otimo equilibra um contra o outro: a predicao qualitativa e uma descida
# MONOTONICA, nao um degrau.
#
# Desenho: o binario da nota 16 SEM UMA VIRGULA DE DIFERENCA (mesmo patch:
# populacao 50/50 com horizontes HI/HJ, resto pregado, mutacao off, desconto do
# ambiente). Grade delta = {0.88, 0.90, 0.92, 0.94, 0.95, 0.96} — 0.90 e 0.95
# sao as ANCORAS: fatias que tem de reproduzir datasets/desconto.csv linha a
# linha (mesmo binario, mesmas seeds, mesmos ticks). Pares: a escada
# 3_4..11_12 (localiza o cruzamento do 0.5 = o otimo, com resolucao +-1) e os
# longos 5_12, 7_12, 9_12 (o interior vence o teto em duelo direto?).
# 6000 ticks, seeds 1..8.
#
# Definicao operacional de h*(delta), registrada ANTES de rodar: na escada, o
# par (h, h+1) da freq_hj = frequencia final do tipo FUNDO. freq > 0.5 = subir
# paga. h* = o h+1 do ultimo par em que subir paga, quando ha UM cruzamento
# (freq > 0.5 ate ele, < 0.5 depois). Sem cruzamento nenhum (subir paga ate
# 11_12): h* = 12 (teto). Mais de um cruzamento: reportar todos (nao-unimodal,
# h* indefinido) — e um dado, nao um erro. Resolucao declarada: +-1.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   G0 (sanidade): as fatias delta=0.90 e 0.95 reproduzem datasets/desconto.csv
#       LINHA A LINHA nos pares sobrepostos (escada 3_4..11_12 e o longo 9_12:
#       10 pares x 2 deltas x 8 seeds = 160 linhas). Se falhar, o patch nao e o
#       da nota 16 e nada abaixo vale.
#   G1 (a descida e monotonica): h*(delta) e nao-crescente na grade, com as
#       ancoras da nota 16: h*(0.90) ~ 10, h*(0.95) em {7, 8}.
#   G2 (onde sai do teto): h*(0.88) < 12 — o otimo ja e interior em 0.88, ou
#       seja, delta_teto (o maior delta com h* = 12) esta ABAIXO da grade, em
#       [0.80; 0.88). ALTERNATIVA mutuamente exclusiva: h*(0.88) = 12 =>
#       delta_teto em [0.88; 0.90) e a descida e mais abrupta do que suave —
#       reportar como achado, nao como falha.
#   G3 (predicao NEGATIVA, a forma): h*(delta) NAO segue 1/(1-delta), que na
#       grade CRESCE de 8,3 para 25 — o medido deve DESCER. A nota 16 ja
#       mostrou que 1/(1-delta) diz quando a profundidade extra e invisivel,
#       nao quando e nociva; aqui a grade fina poe a divergencia em curva.
#   G4 (replicacao na regiao fina): a transicao fixacao->polimorfismo NAO anda
#       (nota 16 P2): fixacoes frequentes no par 3_4 e ~0/8 fixacoes de 4_5 em
#       diante, em todo delta da grade.
#   G5 (os longos): o interior vence o teto em duelo direto onde h* <= 9: para
#       cada delta, o par longo (h, 12) com h mais proximo de h* da freq_hj <
#       0.5 (o 12 perde). Em delta=0.88, se h* ainda estiver em 10-12, os
#       longos 5/7 podem ainda perder para o 12 — reportar a tabela inteira.
#
# Custo: 12 pares x 6 deltas x 8 seeds = 576 corridas de 6000 ticks. A nota 16
# fez 600 em ~46 min com NPROC=12..16. Estimo ~45-60 min com NPROC=16; se
# passar de 3h, aborte e investigue.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/grade-fina.csv (mesmas
# colunas de desconto.csv). Proveniencia:
#   git log -1 --oneline -- datasets/grade-fina.csv
#
#   sh papers/notes/19-grade-fina.sh                     # 8 seeds, 6000 ticks
#   SEEDS_LISTA="7" sh papers/notes/19-grade-fina.sh     # fumaca (nao grava)
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
DESCONTOS=${DESCONTOS:-"0.88 0.90 0.92 0.94 0.95 0.96"}
PARES=${PARES:-"3_4 4_5 5_6 6_7 7_8 8_9 9_10 10_11 11_12 5_12 7_12 9_12"}

# O patch e o da nota 16, sem uma virgula de diferenca (mesmas ancoras, mesma
# consumacao de rng01()).
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
open(f"{tmp}/desc.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/desc" "$TMP/desc.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }

# Sanidade do patch (a mesma das notas 14/16): HI==HJ==6 -> hor_m == 6.
TORN_HI=6 TORN_HJ=6 "$TMP/desc" 7 50 0 --log "$TMP/san.csv" >/dev/null 2>&1
awk -F, 'NR>1 && ($6 < 5.99 || $6 > 6.01) { bad=1 } END { exit bad+0 }' "$TMP/san.csv" \
  || { echo "patch quebrou: hor_m != HI com HI==HJ"; exit 1; }

# Resumo de UMA corrida — IDENTICO ao da nota 16, campo a campo (e o G0).
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
echo "== grade fina: $NPARES pares x $NDESC descontos x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
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

SAIDA=${FUMACA:+"$TMP/grade-fina.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/grade-fina.csv"}
{
echo "desconto,seed,hi,hj,freq_hj,hor_m_fim,pop_fim,fixou"
cat "$TMP/rows/"*.row
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

# ---------------------------------------------------------------- G0
echo "== G0 (sanidade): fatias delta=0.90/0.95 x datasets/desconto.csv =="
if [ -f "$RAIZ/datasets/desconto.csv" ]; then
  awk -F, '
    NR==FNR { if (FNR>1) t[$1"_"$2"_"$3"_"$4]=$5","$6","$7","$8; next }
    FNR>1 && ($1=="0.90" || $1=="0.95") {
      k=$1"_"$2"_"$3"_"$4; mine=$5","$6","$7","$8
      if (!(k in t)) { falta++; next }
      n++; if (t[k]!=mine) { bad++; if (bad<=3) print "   DIVERGE em "k": desconto.csv="t[k]" | aqui="mine }
    }
    END {
      printf "   %d linhas comparadas (%d sem par — pares novos 5_12/7_12)\n", n, falta
      if (bad) { printf "   G0 FALHOU: %d de %d divergem — o patch NAO e o da nota 16\n", bad, n; exit 1 }
      print "   G0 ok: fatias identicas a desconto.csv linha a linha"
    }' "$RAIZ/datasets/desconto.csv" "$SAIDA" || exit 1
else
  echo "   (sem datasets/desconto.csv — G0 pulado)"
fi

# ---------------------------------------------------------------- G1/G2/G3/G4
echo ""
echo "== G1/G2/G3: a escada por delta — freq do fundo, cruzamento do 0.5, h* =="
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
      d=ds[a]
      printf "\n   delta=%s   (1/(1-delta)=%.1f — G3: o h* NAO deve segui-lo)\n", d, 1.0/(1.0-d)
      hstar=-1; ncruz=0; ultimo=-1
      for (h=3;h<=11;h++) {
        k=d"_"h; if (!(k in n)) continue
        m=n[k]; f=s[k]/m; e=sd(s[k],ss[k],m); nf=fx[k]+0
        marca=(f>0.5)?"sobe":"DESCE"
        if (ultimo==1 && f<=0.5) { ncruz++; if (hstar<0) hstar=h }
        ultimo=(f>0.5)?1:0
        printf "     %2d -> %2d   %.3f +- %.3f   fix %d/%d   %s\n", h, h+1, f, e, nf, m, marca
      }
      if (ultimo==1 && ncruz==0) printf "     h* = 12 (teto: subir paga ate 11->12)\n"
      else if (ncruz==1)         printf "     h* = %d (unico cruzamento)\n", hstar
      else                       printf "     h*: %d cruzamentos — nao-unimodal, reportar\n", ncruz
    }
  }' "$SAIDA"

echo ""
echo "== G5: os longos (h, 12) — o interior vence o teto em duelo direto? =="
echo "   freq do h=12; < 0.5 => o 12 PERDE para o interior"
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
    for (b=0;b<nh;b++) printf " %12s", "h=" hs[b] " vs 12"
    printf "\n"
    for (a=0;a<nd;a++) {
      printf "   %-7s", ds[a]
      for (b=0;b<nh;b++) {
        k=ds[a]"_"hs[b]
        if (!(k in n)) { printf " %12s", "-"; continue }
        printf "  %5.3f+-%.2f", s[k]/n[k], sd(s[k],ss[k],n[k])
      }
      printf "\n"
    }
  }' "$SAIDA"
echo "== fim =="
