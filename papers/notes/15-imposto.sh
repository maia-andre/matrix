#!/bin/sh
# Nota 15 (Paper 2): a DOSE-RESPOSTA h*(c) — o imposto pigouviano sobre a
# cognicao. A Fase 3 do ROADMAP mostrou que o horizonte e um BEM POSICIONAL
# (individualmente vantajoso, coletivamente ruim: o otimo de grupo e h=1). O
# custo de pensar INTERNALIZA a externalidade: METABOLISMO + c * profundidade.
# Aqui varre-se c e mede-se o h* evoluido.
#
# Custo cobrado pela PROFUNDIDADE EFETIVA, nao pelo horizonte declarado
# (ROADMAP §3.3): profundidade efetiva = min(horizonte, 1/(1-desconto)).
# Cobrar pelo horizonte declarado deixaria o bloco escapar do imposto baixando
# o desconto — pagando por passos que ja nao pesam. A escolha e uma tese.
#
# O horizonte E o desconto evoluem normalmente (mutacao LIGADA, main.c
# canonico): so muda a conta do metabolismo. c lido do ambiente (CUSTO_H).
#
# PRE-REGISTRO (escrito e commitado antes de rodar; predicoes do ROADMAP §3.2):
#   D0 (sanidade): c=0 reproduz o CSV canonico BIT-A-BIT (0.0f*ed some exato).
#   D1: h* (profundidade efetiva evoluida) CAI monotonicamente conforme c sobe.
#   D2: existe um c* onde a profundidade efetiva evoluida ENCOSTA no otimo de
#       grupo (~1-2): interesse individual e coletivo alinhados. Coincidencia
#       prevista = teste forte.
#   D3: a compensacao via desconto aparece como resposta correlacionada — sob
#       imposto, desc_m sobe (o bloco declara horizonte e desconta o futuro)
#       OU cai junto; o par (hor_m, desc_m) e que conta, nao o hor_m cru.
#
# Custo: 7 valores de c x NSEEDS seeds x TICKS ticks. Com NSEEDS=8,
# TICKS=30000, ~2 h de CPU (~11 min com NPROC=12). Nao entra no gerar.sh.
# Agregados em datasets/imposto.csv. Proveniencia:
#   git log -1 --oneline -- datasets/imposto.csv
#
#   sh papers/notes/15-imposto.sh                       # 8 seeds, 30000 ticks
#   SEEDS_LISTA="7" sh papers/notes/15-imposto.sh       # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-30000}
NPROC=${NPROC:-12}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
# Grade fina embaixo (onde a transicao deve estar) e um teto moderado: com
# METABOLISMO=0.35 e profundidade efetiva ~5, c=0.3 ja soma +1.5/tick (~4x o
# metabolismo) — perto do limite antes da extincao. Custos maiores sao dado de
# "o imposto mata", nao de h*(c), e nao valem a corrida.
CUSTOS=${CUSTOS:-"0 0.01 0.02 0.04 0.08 0.15 0.3"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# globalzinho lido uma vez do ambiente (no primeiro tick de --log, via main);
# aqui inicializo o global e leio no aplicar_e_comer com um guard de "so uma vez".
s=troca(src,
  "        blocos[i].energia -= METABOLISMO;   /* existir custa               */",
  "        { static int lido=0; static float custo_h=0.0f;\n"
  "          if (!lido) { const char *e=getenv(\"CUSTO_H\"); if (e) custo_h=(float)atof(e); lido=1; }\n"
  "          float ed = 1.0f/(1.0f - blocos[i].desconto);\n"
  "          if ((float)blocos[i].horizonte < ed) ed = (float)blocos[i].horizonte;\n"
  "          blocos[i].energia -= METABOLISMO + custo_h * ed; }   /* imposto pigouviano */")
open(f"{tmp}/imp.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/imp" "$TMP/imp.c" 2>/dev/null

# D0: c=0 tem de reproduzir o canonico bit-a-bit. datasets/seed7.csv tem 2000
# ticks (a seed de verificacao do projeto) — rodo d0 no mesmo horizonte.
if [ -f "$RAIZ/datasets/seed7.csv" ]; then
  CUSTO_H=0 "$TMP/imp" 7 2000 0 --log "$TMP/d0.csv" >/dev/null 2>&1
  if cmp -s "$TMP/d0.csv" "$RAIZ/datasets/seed7.csv"; then
    echo "   D0 ok: c=0 bit-a-bit == datasets/seed7.csv (2000 ticks)"
  else
    echo "   D0 FALHOU: c=0 nao reproduz o canonico — o patch mudou o mundo"
    cmp "$TMP/d0.csv" "$RAIZ/datasets/seed7.csv" | head -1; exit 1
  fi
else
  echo "   (sem datasets/seed7.csv — pulando D0; gere com datasets/gerar.sh)"
fi

# Resumo de UMA corrida: janela fim (T-300..T) — hor_m, desc_m, profundidade
# efetiva media, pop. A profundidade efetiva do CSV: min(hor_m, 1/(1-desc_m))
# e um proxy de grupo; a media POR BLOCO seria melhor, mas o CSV so da medias.
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0
  if (pop>0 && t>=T-300 && t<=T) {
    nf++; shor+=$6; sdesc+=$8; spop+=$3
    ed=1.0/(1.0-$8); if ($6<ed) ed=$6; sed+=ed
  }
}
function med(s,c){ return c ? sprintf("%.4f", s/c) : "-1" }
END {
  printf "%s,%s,%s,%s,%s,%s\n", cval, seed,
    med(shor,nf), med(sdesc,nf), med(sed,nf), med(spop,nf)
}
AWK

echo "== dose-resposta: $(echo $CUSTOS | wc -w) custos x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/rows"
export TMP TICKS
for c in $CUSTOS; do for s in $SEEDS; do echo "$c $s"; done; done | \
  xargs -P "$NPROC" -n 2 sh -c '
    CUSTO_H="$1" "$TMP/imp" "$2" "$TICKS" 0 --log "$TMP/c_$1_$2.csv" >/dev/null 2>&1 \
      || { echo "$1 $2" >> "$TMP/falhas"; exit 0; }
    awk -F, -v cval="$1" -v seed="$2" -v T="$TICKS" -f "$TMP/resumo.awk" \
      "$TMP/c_$1_$2.csv" > "$TMP/rows/$1_$2.row"
    rm -f "$TMP/c_$1_$2.csv"
  ' _
if [ -s "$TMP/falhas" ]; then
    echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1
fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/imposto.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/imposto.csv"}
{
echo "custo,seed,hor_m,desc_m,prof_efetiva,pop_fim"
for c in $CUSTOS; do for s in $SEEDS; do cat "$TMP/rows/${c}_$s.row"; done; done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== h*(c): media +- sd entre seeds, por custo =="
awk -F, 'NR>1 {
    n[$1]++
    h[$1]+=$3; hh[$1]+=$3*$3; d[$1]+=$4; e[$1]+=$5; ee[$1]+=$5*$5; p[$1]+=$6
    ord[$1]=1
  }
  function sd(s,ss,c){ v=(ss-s*s/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    printf "   %6s  %14s  %8s  %16s  %8s\n","c","hor_m","desc_m","prof_efetiva","pop"
    # imprime na ordem numerica de c
    ncu=0; for (k in ord) cu[ncu++]=k
    for (a=0;a<ncu;a++) for (b=a+1;b<ncu;b++) if (cu[a]+0>cu[b]+0){t=cu[a];cu[a]=cu[b];cu[b]=t}
    for (a=0;a<ncu;a++){ c=cu[a]; m=n[c]
      printf "   %6s  %6.2f +- %-4.2f  %8.3f  %6.2f +- %-5.2f  %8.1f\n",
        c, h[c]/m, sd(h[c],hh[c],m), d[c]/m, e[c]/m, sd(e[c],ee[c],m), p[c]/m
    }
    print "   D1: prof_efetiva deve CAIR com c; D2: encosta em ~1-2 para algum c*"
  }' "$SAIDA"
echo "== fim =="
