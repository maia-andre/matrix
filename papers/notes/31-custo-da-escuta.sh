#!/bin/sh
# Reproduz a nota 31 (papers/notes/31-custo-da-escuta.md).
#
# O CUSTO DA ESCUTA (pre-registro: ROADMAP.md Sec4.4, ANTES de rodar): a nota 29
# instalou 'escuta' sem nenhuma consequencia real, de proposito. Este pre-
# registro liga o mecanismo: pretendentes_em() pesa cada sinal concorrente por
# 1/(1+desconfianca[i][j]) so para blocos com escuta==ESC_MONITOR -- um
# vizinho cronicamente NEGADO por resolver() e um vizinho cujo sinal nunca se
# confirma, e continuar se afastando dele custa oportunidade real.
#
#   R1 (instalacao inocua p/ quem nao e MONITOR): ESC_ACAO/ESC_PLANO puros
#      batem bit a bit com o main.c de antes do mecanismo (commit 694e05a).
#   R2 (a desconfianca se acumula, rara-mas-real): populacao 100% MONITOR,
#      fracao de pares vizinho-atual que acabam com desconfianca>0.
#   R3 (descontar ajuda, ou nao -- em voz alta): MONITOR x ACAO homogeneas,
#      mesma seed, taxa de negados e pop/energia.
#   R4 (invasao): 50/50 MONITOR x ACAO, sem mutacao em escuta, montagens
#      espelhadas -- o desenho exato do Q4 da nota 30, aplicado a escuta.
#   R5 (deriva do inicio misto, mecanismo ligado): tercos + mutacao, 30000
#      ticks -- ao contrario da deriva neutra da nota 29 (P4, sem mecanismo).
#
# Patches (so pin/instrumentacao; o MECANISMO ja e permanente em main.c desde
# este commit) numa copia temporaria do main.c canonico.
#   sh papers/notes/31-custo-da-escuta.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
ANTES_REV=694e05a   # main.c ANTES do mecanismo do Sec4.4 (so o pre-registro)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000
TICKS_LONGO=30000

gcc -std=c11 -O2 -o "$TMP/canon" "$MAINC"
git show "$ANTES_REV:main.c" > "$TMP/antes.c"
gcc -std=c11 -O2 -o "$TMP/antes" "$TMP/antes.c"

# gen MODO [VALOR] -- MODO em {livre, pin, invasao}. VALOR: nome ESC_* p/ pin;
# "res,inv" p/ invasao. Toda variante ganha os contadores R2/R3 (negado_tick
# e desconfianca ja existem no main.c; so exponho totais via atexit).
gen() {
python3 - "$MAINC" "$TMP" "$1" "${2:-}" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; modo = sys.argv[3]
valor = sys.argv[4] if len(sys.argv) > 4 else ""

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    return t.replace(a, b, 1)

SEM_ORIG = "        b->escuta      = (int)(rng01() * 3.0f);                   /* tercos      */\n"
MUT_ORIG = "        cria->escuta      = muta_escuta(pai->escuta);\n"

s = src
if modo == "livre":
    pass   # semeadura e mutacao do main.c ficam como estao
elif modo == "pin":
    s = troca(s, SEM_ORIG, f"        b->escuta      = ((int)(rng01() * 3.0f), {valor});\n")
    s = troca(s, MUT_ORIG, f"        cria->escuta      = (muta_escuta(pai->escuta), {valor});\n")
elif modo == "invasao":
    res, inv = valor.split(",")
    s = troca(s, SEM_ORIG,
        "        b->escuta      = ((int)(rng01() * 3.0f), "
        f"(n_blocos % 2) ? {inv} : {res});   /* invasao 50/50 */\n")
    s = troca(s, MUT_ORIG,
        "        cria->escuta      = (muta_escuta(pai->escuta), pai->escuta);"
        "   /* SEM mutacao: invasao limpa */\n")
else:
    raise SystemExit(f"modo desconhecido: {modo}")

# instrumentacao R2/R3, sempre ligada: conta quantos ticks-de-bloco sao
# negados (a mesma logica de negado_tick, so exposta), e quantos pares (i,j)
# que atualizar_confianca visita terminam com desconfianca[i][j] > 0.
s = troca(s,
    "static void atualizar_confianca(void) {\n"
    "    for (int i = 0; i < n_blocos; i++) {\n"
    "        if (!blocos[i].vivo || blocos[i].escuta != ESC_MONITOR) continue;\n",
    "static long r2_negados, r2_total_blocos, r3_pares_total, r3_pares_pos;\n"
    "static void r2_dump(void) {\n"
    '    fprintf(stderr, "R2 negados=%ld total_blocos=%ld pares_total=%ld pares_pos=%ld\\n",\n'
    "        r2_negados, r2_total_blocos, r3_pares_total, r3_pares_pos);\n"
    "}\n"
    "static void atualizar_confianca(void) {\n"
    "    for (int i = 0; i < n_blocos; i++) {\n"
    "        if (blocos[i].vivo) { r2_total_blocos++; if (negado_tick[i]) r2_negados++; }\n"
    "        if (!blocos[i].vivo || blocos[i].escuta != ESC_MONITOR) continue;\n")
s = troca(s,
    "                float sinal = negado_tick[j] ? 1.0f : 0.0f;\n"
    "                desconfianca[i][j] = desconfianca[i][j] * blocos[i].desconto + sinal;\n",
    "                float sinal = negado_tick[j] ? 1.0f : 0.0f;\n"
    "                desconfianca[i][j] = desconfianca[i][j] * blocos[i].desconto + sinal;\n"
    "                r3_pares_total++;\n"
    "                if (desconfianca[i][j] > 0.0f) r3_pares_pos++;\n")
s = troca(s, "    signal(SIGINT, ao_interromper);",
              "    signal(SIGINT, ao_interromper);\n    atexit(r2_dump);")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/bin" "$TMP/v.c"
}

media_col() {  # media_col ARQ COL -- media da coluna a partir do tick 500
    awk -F, -v c="$2" 'NR>1 && $2>500 {s+=$c;n++} END{if(n) printf "%.4f", s/n; else printf "--"}' "$1"
}
valor_tick() { awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"; }

printf '\n  nota 31 -- o custo da escuta (seeds %s)\n' "$SEEDS"

printf '\n  R1-instalacao inocua: ESC_ACAO puro e ESC_PLANO puro x main.c de antes (%s)\n\n' "$ANTES_REV"
for esc in ESC_ACAO ESC_PLANO; do
  gen pin "$esc"
  mv "$TMP/bin" "$TMP/pin_$esc"
  python3 - "$TMP/antes.c" "$TMP" "$esc" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; esc = sys.argv[3]
def troca(t,a,b):
    assert a in t; return t.replace(a,b,1)
SEM_ORIG = "        b->escuta      = (int)(rng01() * 3.0f);                   /* tercos      */\n"
MUT_ORIG = "        cria->escuta      = muta_escuta(pai->escuta);\n"
s = troca(src, SEM_ORIG, f"        b->escuta      = ((int)(rng01() * 3.0f), {esc});\n")
s = troca(s, MUT_ORIG, f"        cria->escuta      = (muta_escuta(pai->escuta), {esc});\n")
open(f"{tmp}/antes_pin_{esc}.c","w").write(s)
PY
  gcc -std=c11 -O2 -o "$TMP/antes_pin_$esc" "$TMP/antes_pin_$esc.c"
  for s in $SEEDS; do
    "$TMP/antes_pin_$esc" "$s" "$TICKS" 0 --log "$TMP/r1a_${esc}_$s.csv" >/dev/null
    "$TMP/pin_$esc"       "$s" "$TICKS" 0 --log "$TMP/r1d_${esc}_$s.csv" >/dev/null 2>/dev/null
    if cmp -s "$TMP/r1a_${esc}_$s.csv" "$TMP/r1d_${esc}_$s.csv"; then
      printf '      %-10s seed %-6s IDENTICO\n' "$esc" "$s"
    else
      printf '      %-10s seed %-6s DIFERE!\n' "$esc" "$s"
    fi
  done
done

printf '\n  R2/R3-populacao 100%% MONITOR: fracao de pares com desconfianca>0, taxa de negados\n'
printf '  e MONITOR x ACAO homogeneas (mesma seed): negado%%, pop, energia (tick>500)\n\n'
gen pin ESC_MONITOR
mv "$TMP/bin" "$TMP/pin_ESC_MONITOR_r2"
printf '      %-8s %14s %10s\n' 'seed' 'pares_pos%%(MONITOR)' 'negado%%'
for s in $SEEDS; do
  "$TMP/pin_ESC_MONITOR_r2" "$s" "$TICKS" 0 --log "$TMP/r2_$s.csv" 2>"$TMP/r2_$s.err" >/dev/null
  awk '/^R2/{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]}
    printf "      %-8s %20.3f%% %9.3f%%\n", "'"$s"'", 100*v["pares_pos"]/v["pares_total"], 100*v["negados"]/v["total_blocos"]}' "$TMP/r2_$s.err"
done
printf '\n      %-8s %12s %12s %12s %12s %12s %12s\n' 'seed' 'neg%(mon)' 'neg%(acao)' 'pop(mon)' 'pop(acao)' 'en(mon)' 'en(acao)'
gen pin ESC_ACAO
mv "$TMP/bin" "$TMP/pin_ESC_ACAO_r3"
for s in $SEEDS; do
  "$TMP/pin_ESC_MONITOR_r2" "$s" "$TICKS" 0 --log "$TMP/r3m_$s.csv" 2>"$TMP/r3m_$s.err" >/dev/null
  "$TMP/pin_ESC_ACAO_r3"    "$s" "$TICKS" 0 --log "$TMP/r3a_$s.csv" 2>"$TMP/r3a_$s.err" >/dev/null
  nm=$(awk '/^R2/{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]};printf "%.2f",100*v["negados"]/v["total_blocos"]}' "$TMP/r3m_$s.err")
  na=$(awk '/^R2/{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]};printf "%.2f",100*v["negados"]/v["total_blocos"]}' "$TMP/r3a_$s.err")
  pm=$(media_col "$TMP/r3m_$s.csv" 3);  pa=$(media_col "$TMP/r3a_$s.csv" 3)
  em=$(media_col "$TMP/r3m_$s.csv" 4);  ea=$(media_col "$TMP/r3a_$s.csv" 4)
  printf '      %-8s %12s %12s %12s %12s %12s %12s\n' "$s" "$nm" "$na" "$pm" "$pa" "$em" "$ea"
done

printf '\n  R4-invasao: MONITOR (indices pares) x ACAO (impares), 50/50, sem mutacao em escuta\n'
printf '  esc_monitor_f (col 23) em t=0 e t=%s\n\n' "$TICKS_LONGO"
gen invasao "ESC_MONITOR,ESC_ACAO"
mv "$TMP/bin" "$TMP/inv_mon_vs_acao"
gen invasao "ESC_ACAO,ESC_MONITOR"
mv "$TMP/bin" "$TMP/inv_acao_vs_mon"
for par in "MONITOR residente / ACAO invasor:inv_mon_vs_acao" "ACAO residente / MONITOR invasor:inv_acao_vs_mon"; do
  desc=${par%%:*}; bin=${par##*:}
  printf '      %s\n' "$desc"
  for s in $SEEDS; do
    "$TMP/$bin" "$s" "$TICKS_LONGO" 0 --log "$TMP/${bin}_$s.csv" >/dev/null
    a0=$(valor_tick "$TMP/${bin}_$s.csv" 23 0)
    af=$(valor_tick "$TMP/${bin}_$s.csv" 23 $((TICKS_LONGO-1)))
    printf '      %-8s esc_monitor_f: %6s -> %6s\n' "$s" "$a0" "$af"
  done
done

printf '\n  R5-deriva do inicio misto (mecanismo LIGADO): tercos + mutacao, esc_monitor_f em t=0 e t=%s\n\n' "$TICKS_LONGO"
printf '      %-8s %10s %10s %14s\n' 'seed' 'monf@0' 'monf@fim' 'pop(0->fim)'
for s in $SEEDS; do
  "$TMP/canon" "$s" "$TICKS_LONGO" 0 --log "$TMP/r5_$s.csv" >/dev/null
  a0=$(valor_tick "$TMP/r5_$s.csv" 23 0); af=$(valor_tick "$TMP/r5_$s.csv" 23 $((TICKS_LONGO-1)))
  p0=$(valor_tick "$TMP/r5_$s.csv" 3 0);  pf=$(valor_tick "$TMP/r5_$s.csv" 3 $((TICKS_LONGO-1)))
  printf '      %-8s %10s %10s %8s -> %5s\n' "$s" "$a0" "$af" "$p0" "$pf"
done

printf '\n  R1 prova que o mecanismo, para quem nao e MONITOR, nao toca o mundo; R2 mede a\n'
printf '  raridade real da desconfianca; R3 decide se descontar ajuda; R4 decide se ajuda\n'
printf '  o bastante p/ vencer invasao direta; R5 confere se a selecao, a partir do\n'
printf '  misto, confirma R3/R4.\n\n'
