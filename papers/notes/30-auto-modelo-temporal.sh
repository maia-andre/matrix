#!/bin/sh
# Reproduz a nota 30 (papers/notes/30-auto-modelo-temporal.md).
#
# O AUTO-MODELO TEMPORAL (pre-registro: ROADMAP.md §4.3, ANTES de rodar): o
# contrafactual que resolver() ja quase calcula. Um bloco NEGADO cuja
# vice-celula (a 2a melhor da varredura de melhor_celula) ninguem disputou
# tinha, sim, uma alternativa real. remorso[] acumula esse sinal (decai pelo
# desconto do proprio bloco); o traco herdavel peso_arrependimento (nivel 6)
# decide se ele volta a pesar em utilidade() — empurrando a escolha para
# celulas com mais espaco livre.
#
#   Q1 (ablacao natural): peso_arrependimento = 0 SEM consumir RNG produz
#      simulacao bit-a-bit identica ao main.c de antes do mecanismo existir
#      (commit da escuta, §4.2, sem custo).
#   Q2 (o remorso acontece, raro-mas-real): fracao de ticks com
#      arrependimento > 0 na mesma ordem de grandeza da taxa de negados da
#      nota 06 (~6%) — e um subconjunto dela (precisa TAMBEM da vice livre).
#   Q3 (aprender ajuda, ou nao — registrado em voz alta): peso fixo positivo
#      x fixo em 0, mesma seed, sem mutacao no traco — compara taxa de
#      negados e populacao/energia ao longo do tempo.
#   Q4 (invasao): 50/50 positivo x zero, sem mutacao no traco.
#   Q5 (deriva do diverso): tercos... digo, semeadura livre com folga em
#      torno de 0, MUTACAO ligada, 30000 ticks, varias seeds — arrep_m desliza
#      pra longe de 0 (Q4 decide a direcao) ou fica perto (indiferenca).
#
# Patches numa copia temporaria do main.c canonico (>= commit da nota 29).
# ~15 min.
#   sh papers/notes/30-auto-modelo-temporal.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
ANTES_REV=4927e08   # a escuta (§4.2), main.c sem o mecanismo de arrependimento
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000
TICKS_LONGO=30000

gcc -std=c11 -O2 -o "$TMP/canon" "$MAINC"
git show "$ANTES_REV:main.c" > "$TMP/antes.c"
gcc -std=c11 -O2 -o "$TMP/antes" "$TMP/antes.c"

# gen MODO [VALOR] — MODO em {livre, remove, fixa, invasao}. Toda variante
# ganha os contadores Q2 (atualizar_remorso instrumentada + atexit); MODO so
# controla como peso_arrependimento nasce/muta.
gen() {
python3 - "$MAINC" "$TMP" "$1" "${2:-}" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; modo = sys.argv[3]
valor = sys.argv[4] if len(sys.argv) > 4 else "0.0"

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:70]!r} (o main.c mudou?)"
    return t.replace(a, b, 1)

SEM_ORIG = "        b->peso_arrependimento = (rng01() - 0.5f) * 4.0f;          /* -2..2, folga */\n"
MUT_ORIG = ("        cria->peso_arrependimento =\n"
            "            muta_traco(pai->peso_arrependimento, 2.0f * MUTACAO, -6.0f, 6.0f);\n")

s = src
if modo == "livre":
    pass   # semeadura e mutacao do main.c ficam como estao
elif modo == "remove":
    s = troca(s, SEM_ORIG, "        b->peso_arrependimento = 0.0f;   /* SEM consumir RNG */\n")
    s = troca(s, MUT_ORIG, "        cria->peso_arrependimento = 0.0f;   /* SEM consumir RNG */\n")
elif modo == "fixa":
    s = troca(s, SEM_ORIG,
        "        b->peso_arrependimento = (rng01() - 0.5f) * 4.0f;   /* descartado */\n"
        f"        b->peso_arrependimento = {valor}f;\n")
    s = troca(s, MUT_ORIG,
        "        cria->peso_arrependimento =\n"
        "            (muta_traco(pai->peso_arrependimento, 2.0f * MUTACAO, -6.0f, 6.0f), "
        f"{valor}f);\n")
elif modo == "invasao":
    res, inv = valor.split(",")
    s = troca(s, SEM_ORIG,
        "        b->peso_arrependimento = (rng01() - 0.5f) * 4.0f;   /* descartado */\n"
        f"        b->peso_arrependimento = (n_blocos % 2) ? {inv}f : {res}f;   /* invasao 50/50 */\n")
    s = troca(s, MUT_ORIG,
        "        cria->peso_arrependimento =\n"
        "            (muta_traco(pai->peso_arrependimento, 2.0f * MUTACAO, -6.0f, 6.0f), "
        "pai->peso_arrependimento);   /* SEM mutacao no traco: invasao limpa */\n")
else:
    raise SystemExit(f"modo desconhecido: {modo}")

# instrumentacao Q2, sempre ligada: conta quantos ticks-de-bloco sao negados,
# quantos tem vice livre (o contrafactual verificavel), e quantos viram
# arrependimento > 0 de fato.
s = troca(s,
    "static void atualizar_remorso(void) {\n"
    "    for (int i = 0; i < n_blocos; i++) {\n"
    "        if (!blocos[i].vivo) continue;\n"
    "\n"
    "        int queria_mover = (decidido_x[i] != blocos[i].x || decidido_y[i] != blocos[i].y);\n"
    "        int negado = queria_mover && alvo_x[i] == blocos[i].x && alvo_y[i] == blocos[i].y;\n"
    "\n"
    "        float arrependimento = 0.0f;\n"
    "        if (negado && reivindicado[vice_y[i]][vice_x[i]] == -1) {\n",
    "static long q2_total, q2_negado, q2_vice_livre, q2_regret;\n"
    "static void q2_dump(void) {\n"
    '    fprintf(stderr, "Q2 total=%ld negado=%ld vice_livre=%ld regret=%ld\\n",\n'
    "        q2_total, q2_negado, q2_vice_livre, q2_regret);\n"
    "}\n"
    "static void atualizar_remorso(void) {\n"
    "    for (int i = 0; i < n_blocos; i++) {\n"
    "        if (!blocos[i].vivo) continue;\n"
    "        q2_total++;\n"
    "\n"
    "        int queria_mover = (decidido_x[i] != blocos[i].x || decidido_y[i] != blocos[i].y);\n"
    "        int negado = queria_mover && alvo_x[i] == blocos[i].x && alvo_y[i] == blocos[i].y;\n"
    "        if (negado) q2_negado++;\n"
    "\n"
    "        float arrependimento = 0.0f;\n"
    "        if (negado && reivindicado[vice_y[i]][vice_x[i]] == -1) {\n"
    "            q2_vice_livre++;\n")
s = troca(s,
    "            if (perdido > 0.0f) arrependimento = perdido;\n"
    "        }\n"
    "        remorso[i] = remorso[i] * blocos[i].desconto + arrependimento;\n"
    "    }\n"
    "}\n",
    "            if (perdido > 0.0f) { arrependimento = perdido; q2_regret++; }\n"
    "        }\n"
    "        remorso[i] = remorso[i] * blocos[i].desconto + arrependimento;\n"
    "    }\n"
    "}\n")
s = troca(s, "    signal(SIGINT, ao_interromper);",
              "    signal(SIGINT, ao_interromper);\n    atexit(q2_dump);")

open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/bin" "$TMP/v.c"
}

media_col() {  # media_col ARQ COL — media da coluna a partir do tick 500
    awk -F, -v c="$2" 'NR>1 && $2>500 {s+=$c;n++} END{if(n) printf "%.4f", s/n; else printf "--"}' "$1"
}
valor_tick() { awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"; }

printf '\n  nota 30 — o auto-modelo temporal (seeds %s)\n' "$SEEDS"

printf '\n  Q1-ablacao natural: peso_arrependimento=0 SEM RNG x main.c de antes do mecanismo (%s)\n\n' "$ANTES_REV"
gen remove
mv "$TMP/bin" "$TMP/removido"
for s in $SEEDS; do
  "$TMP/antes"    "$s" "$TICKS" 0 --log "$TMP/antes_$s.csv"    >/dev/null
  "$TMP/removido" "$s" "$TICKS" 0 --log "$TMP/removido_$s.csv" >/dev/null 2>/dev/null
  cut -d, -f1-23 "$TMP/removido_$s.csv" > "$TMP/removido23_$s.csv"
  if cmp -s "$TMP/antes_$s.csv" "$TMP/removido23_$s.csv"; then
    printf '      seed %-6s IDENTICO (23 colunas)\n' "$s"
  else
    printf '      seed %-6s DIFERE!\n' "$s"
  fi
done

printf '\n  Q2-o remorso acontece: populacao livre (canonica), fracao de negado/vice_livre/regret\n\n'
gen livre
mv "$TMP/bin" "$TMP/livre_q2"
printf '      %-8s %10s %10s %10s %14s %14s\n' 'seed' 'total' 'negado' 'vice_livre' 'negado%' 'regret%(device)'
for s in $SEEDS; do
  "$TMP/livre_q2" "$s" "$TICKS" 0 --log "$TMP/q2_$s.csv" 2>"$TMP/q2_$s.err" >/dev/null
  awk '/^Q2/{print}' "$TMP/q2_$s.err" | \
    awk -v seed="$s" '{
      for(i=1;i<=NF;i++){split($i,a,"="); v[a[1]]=a[2]}
      printf "      %-8s %10d %10d %10d %13.2f%% %13.2f%%\n", seed, v["total"], v["negado"], v["vice_livre"],
        100*v["negado"]/v["total"], 100*v["regret"]/v["total"]
    }'
done

printf '\n  Q3-aprender ajuda? peso fixo 2.0 x fixo 0.0, mesma seed, sem mutacao no traco\n'
printf '  taxa de negado no total da corrida (Q2) e pop/energia media (tick>500)\n\n'
gen fixa 2.0
mv "$TMP/bin" "$TMP/fixa_pos"
gen fixa 0.0
mv "$TMP/bin" "$TMP/fixa_zero"
printf '      %-8s %10s %10s %10s %10s %10s %10s\n' 'seed' 'neg%(pos)' 'neg%(zero)' 'pop(pos)' 'pop(zero)' 'en(pos)' 'en(zero)'
for s in $SEEDS; do
  "$TMP/fixa_pos"  "$s" "$TICKS" 0 --log "$TMP/pos_$s.csv"  2>"$TMP/pos_$s.err"  >/dev/null
  "$TMP/fixa_zero" "$s" "$TICKS" 0 --log "$TMP/zero_$s.csv" 2>"$TMP/zero_$s.err" >/dev/null
  np=$(awk '/^Q2/{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]}; printf "%.2f", 100*v["negado"]/v["total"]}' "$TMP/pos_$s.err")
  nz=$(awk '/^Q2/{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]}; printf "%.2f", 100*v["negado"]/v["total"]}' "$TMP/zero_$s.err")
  pp=$(media_col "$TMP/pos_$s.csv" 3);  pz=$(media_col "$TMP/zero_$s.csv" 3)
  ep=$(media_col "$TMP/pos_$s.csv" 4);  ez=$(media_col "$TMP/zero_$s.csv" 4)
  printf '      %-8s %10s %10s %10s %10s %10s %10s\n' "$s" "$np" "$nz" "$pp" "$pz" "$ep" "$ez"
done

printf '\n  Q4-invasao: peso 2.0 (residente, indices pares) x 0.0 (invasor, impares), 50/50, sem mutacao\n'
printf '  fracao de populacao com peso>1.0 (== o residente 2.0) em t=0 e t=%s\n\n' "$TICKS_LONGO"
gen invasao "2.0,0.0"
mv "$TMP/bin" "$TMP/inv_pos_vs_zero"
gen invasao "0.0,2.0"
mv "$TMP/bin" "$TMP/inv_zero_vs_pos"
for par in "2.0 residente / 0.0 invasor:inv_pos_vs_zero" "0.0 residente / 2.0 invasor:inv_zero_vs_pos"; do
  desc=${par%%:*}; bin=${par##*:}
  printf '      %s\n' "$desc"
  printf '      %-8s %14s\n' 'seed' 'arrep_m (0->fim)'
  for s in $SEEDS; do
    "$TMP/$bin" "$s" "$TICKS_LONGO" 0 --log "$TMP/${bin}_$s.csv" >/dev/null
    a0=$(valor_tick "$TMP/${bin}_$s.csv" 24 0)
    af=$(valor_tick "$TMP/${bin}_$s.csv" 24 $((TICKS_LONGO-1)))
    printf '      %-8s %6s -> %6s\n' "$s" "$a0" "$af"
  done
done

printf '\n  Q5-deriva do diverso: semeadura livre (-2..2), MUTACAO ligada, arrep_m em t=0 e t=%s\n\n' "$TICKS_LONGO"
printf '      %-8s %10s %10s %14s\n' 'seed' 'arrep_m@0' 'arrep_m@fim' 'pop(0->fim)'
for s in $SEEDS; do
  "$TMP/canon" "$s" "$TICKS_LONGO" 0 --log "$TMP/q5_$s.csv" >/dev/null
  a0=$(valor_tick "$TMP/q5_$s.csv" 24 0); af=$(valor_tick "$TMP/q5_$s.csv" 24 $((TICKS_LONGO-1)))
  p0=$(valor_tick "$TMP/q5_$s.csv" 3 0);  pf=$(valor_tick "$TMP/q5_$s.csv" 3 $((TICKS_LONGO-1)))
  printf '      %-8s %10s %10s %8s -> %5s\n' "$s" "$a0" "$af" "$p0" "$pf"
done

printf '\n  Q1 prova que o mecanismo, desligado, nao toca o mundo; Q2 mede a raridade\n'
printf '  real do contrafactual; Q3/Q4 decidem se aprender com ele e adaptativo;\n'
printf '  Q5 confere se a selecao, a partir do diverso, confirma Q3/Q4.\n\n'
