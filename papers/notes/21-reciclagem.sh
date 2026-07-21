#!/bin/sh
# Nota 21 (Paper 2): O IMPOSTO QUE RECICLA — reter a energia restaura o bem-estar?
#
# A nota 15 achou que o imposto pigouviano ALINHA a escolha (a profundidade
# efetiva desce ao otimo de grupo h~1 em c~0.15) mas QUEIMA populacao (~35% em
# c=0.15, de 284 para 187): a receita e removida do bloco e SOME. O §3 da nota 15
# isolou o teste que falta: um imposto que DEVOLVE a energia mede se "internalizar
# a externalidade" melhora o bem-estar, ou se so a mecanica (a escolha) se alinha.
# O ROADMAP declara "o imposto que recicla e o proximo pre-registro" (§ Dois
# papers, ~linha 1033).
#
# O MECANISMO: dividendo per-capita (rebate lump-sum). Cada tick, o imposto
# c*profundidade cobrado de cada bloco entra num POOL; depois que o metabolismo e
# as mortes resolvem, o pool e dividido IGUALMENTE entre os sobreviventes e
# devolvido a energia de cada um. Isto e o rebate pigouviano de manual: o que voce
# recebe (pool/S) quase nao depende da SUA profundidade (voce e um bloco entre
# ~280), entao o gradiente privado de reduzir profundidade SOBREVIVE — mas a
# energia nao e destruida, volta a populacao. A externalidade e corrigida sem
# cavar o buraco de energia da nota 15.
#   - Faithful: tax e rebate sao dois fluxos; a MORTE, porem, e checada no fluxo
#     de comer (antes do rebate), como no canonico. Um bloco morto pelo pico do
#     imposto nao recebe o dividendo daquele tick — versao CONSERVADORA do
#     rebate (subestima a recuperacao, direcao segura). Documentado, nao escondido.
#   - Conservacao: soma dos impostos cobrados == soma dos rebates distribuidos,
#     cada tick (o pool e somado e integralmente redistribuido). E o R-cons.
#
# Um binario, dois modos por ambiente (RECICLA=0/1, CUSTO_H=c):
#   RECICLA=0, c=0   -> canonico bit-a-bit (o rebate de 0 e 0; imposto de 0 e 0);
#   RECICLA=0, c>0   -> o imposto QUEIMADO da nota 15 (patch textualmente identico
#                       ao da 15 no termo do imposto — reproduz imposto.csv);
#   RECICLA=1, c>0   -> o imposto RECICLADO (o novo).
# A comparacao-chave e QUEIMADO x RECICLADO no MESMO c, pareada por seed.
#
# PRE-REGISTRO (escrito e commitado ANTES de rodar; convencao da nota 13):
#   R0 (sanidade): RECICLA=0, c=0 reproduz datasets/seed7.csv BIT-A-BIT (2000
#       ticks). Se falhar, o patch mudou o mundo.
#   R-cons (conservacao): RECICLA=1 dumpa no stderr sum_tax e sum_rebate
#       acumulados; |sum_tax - sum_rebate| / sum_tax < 1e-5 (float). Se vazar, o
#       rebate nao esta conservando a receita e o resto da nota nao vale.
#   R1 (o alinhamento SOBREVIVE ao rebate): com RECICLA=1, a profundidade efetiva
#       ainda CAI com c — mesma direcao que D1 da nota 15. Predicao quantitativa:
#       a curva prof(c) do reciclado fica DENTRO de ~0.5 da do queimado em cada c
#       (o gradiente privado e o mesmo). SE a profundidade NAO cair (reciclado
#       fica em h fundo), o rebate matou o incentivo — meu rebate nao seria
#       lump-sum (o bloco estaria sendo compensado pela propria profundidade). E o
#       controle que falsearia o mecanismo, mutuamente exclusivo com R1.
#   R2 (o teste de bem-estar, o ponto): no c* que alinha a profundidade a h~1
#       (~0.15, nota 15), a populacao do RECICLADO e MAIOR que a do queimado (187)
#       e recupera a maior parte da perda para o baseline (284). Predicao: pop
#       reciclado(c=0.15) > 240 (recupera > 60% dos ~97 blocos perdidos). Pareado
#       por seed: pop_recicla - pop_queima > 0 com |t| > 3 em c >= 0.08.
#   R3 (alinhamento SEM bem-estar-destruido, decomposto): a profundidade efetiva
#       nos dois modos e ~igual no mesmo c (R1), entao a UNICA diferenca entre
#       queimado e reciclado e a populacao — isola "alinhar a escolha" de
#       "restaurar o bem-estar". A nota 15 disse "alinhamento != bem-estar quando
#       o instrumento e destrutivo"; R2+R3 dizem "reciclar torna o instrumento
#       nao-destrutivo, e o alinhamento vem DE GRACA".
#   R4 (a ressalva honesta, medida): o rebate redistribui para SOBREVIVENTES, que
#       tendem a estar perto do teto de reproducao (REPRO) — energia "desperdicada"
#       em quem ja ia se reproduzir. Se a recuperacao de pop for PARCIAL (R2 da
#       pop reciclado < baseline 284 mesmo com energia conservada), o residuo e
#       essa ineficiencia de redistribuicao — reportar pop_baseline - pop_recicla
#       como o custo que sobra mesmo reciclando.
#
# Custo: 2 modos x 7 custos x 8 seeds x 30000 ticks (o horizonte da nota 15). A
# nota 15 fez 56 corridas de 30000 em ~20 min com NPROC=12. Aqui 112 corridas —
# ~40-50 min com NPROC=16. Se passar de 3h, aborte.
#
# Nao entra no datasets/gerar.sh. Agregados em datasets/reciclagem.csv.
#   git log -1 --oneline -- datasets/reciclagem.csv
#
#   sh papers/notes/21-reciclagem.sh                     # 8 seeds, 30000 ticks
#   SEEDS_LISTA="7" sh papers/notes/21-reciclagem.sh     # fumaca (nao grava)
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TICKS=${TICKS:-30000}
NPROC=${NPROC:-16}
SEEDS=${SEEDS_LISTA:-$(seq 1 8)}
FUMACA=${SEEDS_LISTA:+sim}
CUSTOS=${CUSTOS:-"0 0.01 0.02 0.04 0.08 0.15 0.3"}
MODOS=${MODOS:-"0 1"}

python3 - "$MAINC" "$TMP" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    assert t.count(a)==1, f"ancora ambigua: {a[:60]!r}"
    return t.replace(a,b,1)

# 1. o termo do imposto: IDENTICO ao patch da nota 15 (mesmo float, mesma ordem),
#    mais a acumulacao do pool. O modo (RECICLA) e o custo (CUSTO_H) vem do
#    ambiente, lidos uma vez.
s=troca(src,
  "        blocos[i].energia -= METABOLISMO;   /* existir custa               */",
  "        { static int lido=0; static float custo_h=0.0f;\n"
  "          if (!lido) { const char *e=getenv(\"CUSTO_H\"); if (e) custo_h=(float)atof(e);\n"
  "            const char *r=getenv(\"RECICLA\"); if (r) imp_recicla=atoi(r); lido=1; }\n"
  "          float ed = 1.0f/(1.0f - blocos[i].desconto);\n"
  "          if ((float)blocos[i].horizonte < ed) ed = (float)blocos[i].horizonte;\n"
  "          float imp = custo_h * ed;\n"
  "          blocos[i].energia -= METABOLISMO + imp;   /* imposto pigouviano */\n"
  "          imp_pool += imp; imp_sum_tax += imp; }")

# 2. globais do imposto (antes de aplicar_e_comer).
s=troca(s,
  "/* C. Move os blocos que ganharam o direito, e em seguida cada bloco vivo",
  "static int    imp_recicla = 0;      /* 0 = queima (nota 15); 1 = rebate  */\n"
  "static float  imp_pool = 0.0f;      /* imposto do tick corrente          */\n"
  "static double imp_sum_tax = 0.0, imp_sum_reb = 0.0;   /* R-cons          */\n\n"
  "/* C. Move os blocos que ganharam o direito, e em seguida cada bloco vivo")

# 3. o pool zera no comeco do comer, e o rebate distribui no fim de aplicar_e_comer.
#    Ancoras: a linha que zera e no topo do comer; o rebate antes do '}' final.
s=troca(s,
  "    /* comer + metabolismo (a valencia em acao) */\n"
  "    for (int i = 0; i < n_blocos; i++) {",
  "    /* comer + metabolismo (a valencia em acao) */\n"
  "    imp_pool = 0.0f;\n"
  "    for (int i = 0; i < n_blocos; i++) {")

s=troca(s,
  "        if (blocos[i].energia <= 0.0f) {     /* morte por inanicao          */\n"
  "            blocos[i].vivo = 0;\n"
  "            ocup[y][x] = -1;\n"
  "        }\n"
  "    }\n"
  "}",
  "        if (blocos[i].energia <= 0.0f) {     /* morte por inanicao          */\n"
  "            blocos[i].vivo = 0;\n"
  "            ocup[y][x] = -1;\n"
  "        }\n"
  "    }\n"
  "    /* rebate pigouviano: o pool volta, dividido entre os SOBREVIVENTES.\n"
  "     * Faithful ao lump-sum (o dividendo quase nao depende da propria\n"
  "     * profundidade); morte checada acima => versao conservadora. */\n"
  "    if (imp_recicla && imp_pool > 0.0f) {\n"
  "        int viv = 0;\n"
  "        for (int i = 0; i < n_blocos; i++) if (blocos[i].vivo) viv++;\n"
  "        if (viv > 0) {\n"
  "            float reb = imp_pool / (float)viv;\n"
  "            for (int i = 0; i < n_blocos; i++)\n"
  "                if (blocos[i].vivo) blocos[i].energia += reb;\n"
  "            imp_sum_reb += (double)reb * (double)viv;\n"
  "        }\n"
  "    }\n"
  "}")

# 4. dump de R-cons no stderr, no fim do main (antes de restaurar o terminal).
s=troca(s,
  "    fputs(CUR_ON, stdout);\n"
  "    if (interativo) termios_restaura();",
  "    if (imp_recicla)\n"
  "        fprintf(stderr, \"RCONS sum_tax=%.6f sum_reb=%.6f\\n\", imp_sum_tax, imp_sum_reb);\n"
  "    fputs(CUR_ON, stdout);\n"
  "    if (interativo) termios_restaura();")

open(f"{tmp}/rec.c","w").write(s)
PY

gcc -std=c11 -O2 -o "$TMP/rec" "$TMP/rec.c" 2>"$TMP/gcc.err" \
  || { echo "gcc falhou:"; cat "$TMP/gcc.err"; exit 1; }

# R0: RECICLA=0, c=0 tem de reproduzir o canonico bit-a-bit.
if [ -f "$RAIZ/datasets/seed7.csv" ]; then
  RECICLA=0 CUSTO_H=0 "$TMP/rec" 7 2000 0 --log "$TMP/r0.csv" >/dev/null 2>&1
  if cmp -s "$TMP/r0.csv" "$RAIZ/datasets/seed7.csv"; then
    echo "   R0 ok: RECICLA=0,c=0 bit-a-bit == datasets/seed7.csv"
  else
    echo "   R0 FALHOU: nao reproduz o canonico — o patch mudou o mundo"
    cmp "$TMP/r0.csv" "$RAIZ/datasets/seed7.csv" | head -1; exit 1
  fi
else
  echo "   (sem datasets/seed7.csv — R0 pulado; gere com datasets/gerar.sh)"
fi

# R-cons: RECICLA=1 conserva a receita (sum_tax == sum_reb).
RECICLA=1 CUSTO_H=0.15 "$TMP/rec" 7 3000 0 >/dev/null 2>"$TMP/rcons.err"
awk '/RCONS/ { split($2,a,"="); split($3,b,"=")
    tax=a[2]; reb=b[2]; d=(tax>reb)?tax-reb:reb-tax
    rel=(tax>0)?d/tax:0
    printf "   R-cons: sum_tax=%.3f sum_reb=%.3f  rel=%.2e  %s\n", tax, reb, rel,
      (rel<1e-5)?"ok (receita conservada)":"FALHOU (rebate nao conserva)"
    if (rel>=1e-5) exit 1 }' "$TMP/rcons.err" || { echo "   R-cons FALHOU"; exit 1; }

# Resumo de UMA corrida: janela fim (T-300..T) — identico ao da nota 15.
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
  printf "%s,%s,%s,%s,%s,%s,%s\n", mode, cval, seed,
    med(shor,nf), med(sdesc,nf), med(sed,nf), med(spop,nf)
}
AWK

NM=$(echo $MODOS | wc -w); NC=$(echo $CUSTOS | wc -w)
echo "== reciclagem: $NM modos x $NC custos x $(echo $SEEDS | wc -w) seeds, $TICKS ticks, -P $NPROC =="
mkdir -p "$TMP/rows"
export TMP TICKS
for m in $MODOS; do for c in $CUSTOS; do for s in $SEEDS; do
  echo "$m $c $s"
done; done; done | xargs -P "$NPROC" -n 3 sh -c '
    RECICLA="$1" CUSTO_H="$2" "$TMP/rec" "$3" "$TICKS" 0 --log "$TMP/l_$1_$2_$3.csv" \
      >/dev/null 2>&1 || { echo "$1 $2 $3" >> "$TMP/falhas"; exit 0; }
    awk -F, -v mode="$1" -v cval="$2" -v seed="$3" -v T="$TICKS" \
      -f "$TMP/resumo.awk" "$TMP/l_$1_$2_$3.csv" > "$TMP/rows/$1_$2_$3.row"
    rm -f "$TMP/l_$1_$2_$3.csv"
  ' _
if [ -s "$TMP/falhas" ]; then echo "   CORRIDAS FALHARAM:"; cat "$TMP/falhas"; exit 1; fi
echo "   $(ls "$TMP/rows/"*.row | wc -l) corridas resumidas"

SAIDA=${FUMACA:+"$TMP/reciclagem.csv"}
SAIDA=${SAIDA:-"$RAIZ/datasets/reciclagem.csv"}
{
echo "recicla,custo,seed,hor_m,desc_m,prof_efetiva,pop_fim"
for m in $MODOS; do for c in $CUSTOS; do for s in $SEEDS; do
  cat "$TMP/rows/${m}_${c}_${s}.row" 2>/dev/null || true
done; done; done
} > "$SAIDA"
echo "   resumo em: $SAIDA ($(wc -l < "$SAIDA") linhas)"

echo ""
echo "== R1/R2/R3/R4: queimado (recicla=0) x reciclado (recicla=1), por custo =="
awk -F, 'NR>1 {
    k=$1"_"$2; p[k]+=$7; pp[k]+=$7*$7; e[k]+=$6; ee[k]+=$6*$6; n[k]++; cs[$2]=1 }
  function sd(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    nc=0; for (c in cs) cc[nc++]=c
    for (a=0;a<nc;a++) for (b=a+1;b<nc;b++) if (cc[a]+0>cc[b]+0){t=cc[a];cc[a]=cc[b];cc[b]=t}
    printf "   %-6s | %-18s %-18s | %-18s %-18s\n", "c",
      "prof queima", "prof recicla", "pop queima", "pop recicla"
    for (a=0;a<nc;a++) { c=cc[a]; kq="0_"c; kr="1_"c
      if (!(kq in n) || !(kr in n)) continue
      printf "   %-6s | %6.2f +- %-8.2f %6.2f +- %-8.2f | %6.1f +- %-8.1f %6.1f +- %-8.1f\n",
        c, e[kq]/n[kq], sd(e[kq],ee[kq],n[kq]), e[kr]/n[kr], sd(e[kr],ee[kr],n[kr]),
           p[kq]/n[kq], sd(p[kq],pp[kq],n[kq]), p[kr]/n[kr], sd(p[kr],pp[kr],n[kr])
    }
  }' "$SAIDA"

echo ""
echo "== R2 (PAREADO por seed): pop_recicla - pop_queima, por custo =="
awk -F, 'NR>1 { pop[$1"_"$2"_"$3]=$7; cs[$2]=1; ss[$3]=1 }
  function sd(a,b,c){ v=(b-a*a/c)/(c-1); return v>0?sqrt(v):0 }
  END {
    nc=0; for (c in cs) cc[nc++]=c
    for (a=0;a<nc;a++) for (b=a+1;b<nc;b++) if (cc[a]+0>cc[b]+0){t=cc[a];cc[a]=cc[b];cc[b]=t}
    for (a=0;a<nc;a++) { c=cc[a]; np=0; sx=0; sxx=0
      for (s in ss) { kq="0_"c"_"s; kr="1_"c"_"s
        if ((kq in pop) && (kr in pop)) { x=pop[kr]-pop[kq]; np++; sx+=x; sxx+=x*x } }
      if (!np) continue
      m=sx/np; e=sd(sx,sxx,np)/sqrt(np); t=(e>0)?m/e:0
      printf "   c=%-5s  dpop=%+7.1f +- %5.1f  t=%+6.2f  %s\n", c, m, e, t,
        (t>3)?"*** reciclar recupera pop ***":((t<-3)?"reciclar PIOR (?!)":"~ nulo") }
  }' "$SAIDA"

echo ""
echo "== R4: o custo que SOBRA mesmo reciclando (pop_baseline - pop_recicla) =="
awk -F, 'NR>1 { pop[$1"_"$2"_"$3]=$7; cs[$2]=1; ss[$3]=1 }
  END {
    base=0; nb=0; for (s in ss) { k="0_0_"s; if (k in pop) { base+=pop[k]; nb++ } }
    base=(nb)?base/nb:0
    nc=0; for (c in cs) cc[nc++]=c
    for (a=0;a<nc;a++) for (b=a+1;b<nc;b++) if (cc[a]+0>cc[b]+0){t=cc[a];cc[a]=cc[b];cc[b]=t}
    printf "   baseline (c=0) pop = %.1f\n", base
    for (a=0;a<nc;a++) { c=cc[a]; np=0; sp=0
      for (s in ss) { k="1_"c"_"s; if (k in pop) { sp+=pop[k]; np++ } }
      if (!np) continue
      printf "   c=%-5s  pop_recicla=%.1f  residuo=%+.1f (%.0f%% do baseline)\n",
        c, sp/np, sp/np-base, 100*(sp/np)/base }
  }' "$SAIDA"
echo "== fim =="
