#!/bin/sh
# Reproduz a nota 12: a JANELA LONGA — 50 seeds para o que so aparece em 30 000
# ticks. E o complemento da nota 11, que replicou tudo em 3000 e deixou a
# janela longa declarada como ameaca a validade.
#
# O que esta sob replicacao, com os valores de 3 seeds publicados:
#   L1 (nota 08 S6, 30k): hon_f final 0,83/0,90/0,88, blefe ~0,10, mudo
#      varrido; honestidade DOMINA SEM FIXAR (polimorfismo).
#   L2 (nota 05 fase 2): congelar peso_espaco (fesp) SEGURA a phi;
#      congelar horizonte+desconto (fdep) NAO segura — no ctl e no fdep a
#      phi cai do inicio ao fim (a evolucao extingue a integracao); no fesp
#      nao cai. Quem carrega a phi e o traco que carrega a agencia.
#   L3 (nota 03): a agencia DESBOTA em janela longa (ag fim < ag inicio) e o
#      traco peso_espaco cai junto (esp_m ~3,1 -> 0,5-1,5).
#   L4 (nota 05 fase 3): corr(phi, profundidade efetiva) e artefato de
#      janela — alta nos 30 000 ticks, some/despenca nos primeiros 3000 dos
#      MESMOS dados (co-tendencia, nao acoplamento).
#   L5 (novo, de graca): o destino da autocausa — a nota 09 P4 viu ela subir
#      ate o tick 3000; aqui se ve se satura, segue ou reverte ate 30 000.
#      Sem valor previo: e exploracao declarada, nao predicao.
#
# ATENCAO (licao da nota 11 §5): todos os valores acima SAO de corridas de
# 30 000 ticks — o horizonte confere com o das notas citadas.
#
# Custo: 3 variantes x 50 seeds x 30 000 ticks (~6 h de CPU; ~35 min com
# NPROC=12). Nao entra no datasets/gerar.sh. Cada corrida e resumida e o CSV
# bruto apagado dentro do proprio job (o /tmp e tmpfs; 150 CSVs de 30k linhas
# nao cabem na RAM de maquinas modestas). Proveniencia:
#   git log -1 --oneline -- datasets/janela30k.csv
#
#   sh papers/notes/12-janela-longa.sh                     # 50 seeds
#   SEEDS_LISTA="7" sh papers/notes/12-janela-longa.sh     # fumaca (nao grava)
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

open(f"{tmp}/ctl.c","w").write(src)

# fesp: congela peso_espaco em PESO_ESPACO (o traco nao evolui; RNG preservado)
s=troca(src,"b->peso_espaco = PESO_ESPACO * (0.5f + rng01());          /* ~0.5x..1.5x */",
            "b->peso_espaco = (rng01(), PESO_ESPACO);")
s=troca(s,"cria->peso_espaco = muta_traco(pai->peso_espaco, 2.0f * MUTACAO, 0.0f, 8.0f);",
          "cria->peso_espaco = muta_traco(PESO_ESPACO, 0.0f, 0.0f, 8.0f);")
open(f"{tmp}/fesp.c","w").write(s)

# fdep: congela horizonte e desconto (a profundidade nao evolui; RNG preservado)
s=troca(src,"b->desconto    = DESCONTO + (rng01() - 0.5f) * 0.2f;      /* +-0.1       */",
            "b->desconto    = (rng01(), DESCONTO);")
s=troca(s,"b->horizonte   = 1 + (int)(rng01() * HORIZONTE_MAX);      /* 1..MAX      */",
          "b->horizonte   = (int)(rng01(), HORIZONTE);")
s=troca(s,"cria->desconto    = muta_traco(pai->desconto,    0.4f * MUTACAO, 0.30f, 0.98f);",
          "cria->desconto    = DESCONTO;")
s=troca(s,"cria->horizonte   = muta_horizonte(pai->horizonte);",
          "cria->horizonte   = HORIZONTE;")
open(f"{tmp}/fdep.c","w").write(s)
PY

VARS="ctl fesp fdep"
for v in $VARS; do
    # warning conhecido do idioma '(rng01(), X)'
    gcc -std=c11 -O2 -o "$TMP/$v" "$TMP/$v.c" 2>/dev/null
done

# O resumo de UMA corrida (o job roda isto e apaga o CSV bruto): janelas ini
# (20-300) e fim (T-300..T), e corr(phi, profundidade efetiva) na janela cheia
# x so nos primeiros 3000 ticks dos MESMOS dados (L4). A profundidade efetiva
# e eff = min(hor_m, 1/(1-desc_m)) — o alcance que o desconto sustenta.
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

echo "== lote: 3 variantes x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
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

SAIDA=${FUMACA:+"$TMP/janela30k.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/janela30k.csv"}
{
echo "cond,seed,ticks,pop_fim,phi_ini,phi_fim,ag_ini,ag_fim,ac_ini,ac_fim,esp_ini,esp_fim,hor_ini,hor_fim,hon_fim,blef_fim,corr_full,corr_3k"
for v in $VARS; do for s in $SEEDS; do cat "$TMP/rows/${v}_$s.row"; done; done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo "== previa (media entre seeds, por condicao) =="
awk -F, 'NR>1 {
    n[$1]++
    pi[$1]+=$5; pf[$1]+=$6; ai[$1]+=$7; af[$1]+=$8
    ei[$1]+=$11; ef[$1]+=$12; hf[$1]+=$15; bf[$1]+=$16; cf[$1]+=$17; c3[$1]+=$18
  }
  END {
    printf "   %-5s %8s %8s %8s %8s %8s %8s %8s %8s %9s %9s\n",
      "cond","phi_ini","phi_fim","ag_ini","ag_fim","esp_ini","esp_fim","hon_fim","blef_fim","corr_full","corr_3k"
    for (c in n)
      printf "   %-5s %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f %9.3f %9.3f\n",
        c, pi[c]/n[c], pf[c]/n[c], ai[c]/n[c], af[c]/n[c],
        ei[c]/n[c], ef[c]/n[c], hf[c]/n[c], bf[c]/n[c], cf[c]/n[c], c3[c]/n[c]
  }' "$SAIDA"
echo "== fim =="
