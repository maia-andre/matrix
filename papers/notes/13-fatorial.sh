#!/bin/sh
# Nota 13: o FATORIAL de L5 — pregar o motivo E o horizonte JUNTOS.
# E a quarta celula do desenho que a nota 12 deixou em aberto: ctl (ambos
# livres), fesp (motivo pregado), fdep (profundidade pregada) ja estao em
# datasets/janela30k.csv, com o MESMO main.c (079a3ce), seeds 1..50, 30 000
# ticks. Esta variante (fambos) congela peso_espaco E horizonte+desconto —
# os dois patches da nota 12 combinados, ancoras distintas, RNG preservado.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; referencias da nota 12,
# medias de 50 seeds — Δac = ac_fim - ac_ini):
#   ctl  0,093 -> 0,204  (Δ +0,111)
#   fesp 0,088 -> 0,148  (Δ +0,060)   motivo pregado, horizonte sobe a ~9,7
#   fdep 0,100 -> 0,226  (Δ +0,126)   horizonte pregado em 6, motivo cai
#
#   F1 (predicao da explicacao por ESTREITAMENTO DO MOTIVO, nota 12 §4):
#      com os dois motores desligados, a autocausa quase nao sobe —
#      Δac(fambos) < +0,03 (menos da metade do residuo do fesp).
#   F2 (o refutador, declarado): Δac(fambos) >= +0,06 (da ordem do fesp ou
#      maior) => existe um TERCEIRO motor que o desenho fesp/fdep nao isolou;
#      a errata da nota 09 §4 estaria incompleta.
#   F3 (sanidade dos congelamentos): esp_fim = 3,0 e hor_fim = 6,0 exatos;
#      e a phi NAO cai (a nota 12 L2 mostrou que congelar o motivo a segura
#      sozinho; com os dois congelados tem de seguir de pe).
#   Zona cinzenta assumida: +0,03 <= Δac < +0,06 — o lote nao decide, e a
#   nota tera de dizer isso.
#
# Custo: 1 variante x 50 seeds x 30 000 ticks (~2 h de CPU; ~12 min com
# NPROC=12). Nao entra no datasets/gerar.sh. Agregados em
# datasets/fatorial30k.csv (mesmo esquema de 18 colunas do janela30k.csv).
# Proveniencia: git log -1 --oneline -- datasets/fatorial30k.csv
#
#   sh papers/notes/13-fatorial.sh                     # 50 seeds
#   SEEDS_LISTA="7" sh papers/notes/13-fatorial.sh     # fumaca (nao grava)
set -eu
export LC_ALL=C          # sem isso o awk imprime "0,85" e rele como 0
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=30000
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

# fambos = fesp + fdep da nota 12, na mesma ordem, mesmas ancoras
s=troca(src,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
            "b->peso_espaco = (rng01(), PESO_ESPACO);")
s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
          "cria->peso_espaco = muta_traco(PESO_ESPACO, 0.0f, 0.0f, 8.0f);")
s=troca(s,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
          "b->desconto    = (rng01(), DESCONTO);")
s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
          "b->horizonte   = (int)(rng01(), HORIZONTE);")
s=troca(s,"cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
          "cria->desconto    = DESCONTO;")
s=troca(s,"cria->horizonte   = muta_horizonte(pai->horizonte);",
          "cria->horizonte   = HORIZONTE;")
open(f"{tmp}/fambos.c","w").write(s)
PY

VARS="fambos"
for v in $VARS; do
    # warning conhecido do idioma '(rng01(), X)'
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

# O mesmo resumo por corrida da nota 12 (18 colunas), para os datasets serem
# comparaveis linha a linha.
cat > "$TMP/resumo.awk" <<'AWK'
NR>1 {
  t=$2+0; pop=$3+0; lt=t; lp=pop
  if (t>20 && pop>0) {
    eff=1.0/(1.0-$8); if ($6<eff) eff=$6
    n++;  sx+=$17;  sy+=eff;  sxx+=$17*$17;  syy+=eff*eff;  sxy+=$17*eff
    if (t<=3000) {
      m++; tx+=$17; ty+=eff; txx+=$17*$17; tyy+=eff*eff; txy+=$17*eff }
  }
  if (pop>0 && t>=20    && t<=300) { ni++; iphi+=$17; iag+=$15; iac+=$21
                                     iesp+=$12; ihor+=$6 }
  if (pop>0 && t>=T-300 && t<=T)   { nf++; fphi+=$17; fag+=$15; fac+=$21
                                     fesp+=$12; fhor+=$6; fhon+=$19; fblef+=$20 }
}
function med(s,c) { return c ? sprintf("%.6f", s/c) : "-1" }
function corr(n,sx,sy,sxx,syy,sxy,  d1,d2) {
  if (!n) return "-1"
  d1=n*sxx-sx*sx; d2=n*syy-sy*sy
  return (d1>0 && d2>0) ? sprintf("%.4f",(n*sxy-sx*sy)/sqrt(d1*d2)) : "0.0000"
}
END {
  printf "%s,%s,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
    cond, seed, lt, lp,
    med(iphi,ni),med(fphi,nf), med(iag,ni),med(fag,nf),
    med(iac,ni),med(fac,nf),   med(iesp,ni),med(fesp,nf),
    med(ihor,ni),med(fhor,nf), med(fhon,nf),med(fblef,nf),
    corr(n,sx,sy,sxx,syy,sxy), corr(m,tx,ty,txx,tyy,txy)
}
AWK

echo "== lote: 1 variante x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/csv" "$TMP/rows"
export TMP TICKS
for v in $VARS; do for s in $SEEDS; do echo "$v $s"; done; done | \
  xargs -P "$NPROC" -n 2 sh -c '
    "$TMP/$1" "$2" "$TICKS" 0 --log "$TMP/csv/$1_$2.csv" >/dev/null 2>&1 \
      || { echo "$1 $2" >> "$TMP/falhas"; exit 0; }
    awk -F, -v cond="$1" -v seed="$2" -v T="$TICKS" -f "$TMP/resumo.awk" \
      "$TMP/csv/$1_$2.csv" > "$TMP/rows/$1_$2.row"
    rm -f "$TMP/csv/$1_$2.csv"
  ' _
if [ -s "$TMP/falhas" ]; then
    echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1
fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/fatorial30k.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/fatorial30k.csv"}
{
echo "cond,seed,ticks,pop_fim,phi_ini,phi_fim,ag_ini,ag_fim,ac_ini,ac_fim,esp_ini,esp_fim,hor_ini,hor_fim,hon_fim,blef_fim,corr_full,corr_3k"
for v in $VARS; do for s in $SEEDS; do cat "$TMP/rows/${v}_$s.row"; done; done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== fambos (media +- sd entre seeds) contra as referencias da nota 12 =="
awk -F, 'NR>1 {
    n++
    aci+=$9;  acis+=$9*$9;   acf+=$10; acfs+=$10*$10
    d=$10-$9; dd+=d; dds+=d*d
    pi+=$5; pf+=$6; ei+=$11; ef+=$12; hi+=$13; hf+=$14
  }
  function sd(s,ss,c) { v=(ss-s*s/c)/(c-1); return v>0 ? sqrt(v) : 0 }
  END {
    printf "   ac_ini %.4f+-%.4f  ac_fim %.4f+-%.4f  Δac %+.4f+-%.4f\n",
      aci/n, sd(aci,acis,n), acf/n, sd(acf,acfs,n), dd/n, sd(dd,dds,n)
    printf "   phi %.4f->%.4f  esp_fim %.4f  hor_fim %.4f\n",
      pi/n, pf/n, ef/n, hf/n
    printf "   referencias (nota 12): ctl Δ+0.111  fesp Δ+0.060  fdep Δ+0.126\n"
    printf "   F1 pede Δac < +0.03; F2 dispara em Δac >= +0.06\n"
  }' "$SAIDA"
echo "== fim =="
