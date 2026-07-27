#!/bin/sh
# Reproduz a nota 29 (papers/notes/29-escuta-evolutiva.md).
#
# A ARQUITETURA DE ESCUTA (introspeccao, nota 07) instalada como traco
# herdavel nivel 6 (pre-registro: ROADMAP.md §4.2, ANTES de rodar), SEM
# nenhum custo ligado ao jogo — so troca qual formula medir_relato() usa por
# bloco (ESC_ACAO = a leitura de sempre, le a posicao final; ESC_PLANO = le o
# alvo pre-resolver, imune a negacao; ESC_MONITOR = compara os dois, admite
# NAOSEI quando divergem).
#
#   P1 (instalacao inocua, RNG preservado): 'escuta' livre x 'escuta' fixado
#      em ESC_ACAO via patch que ainda CONSOME o mesmo rng01() e descarta o
#      valor — todas as colunas fora relato/esc_plano_f/esc_monitor_f saem
#      bit-a-bit identicas.
#   P2 (compatibilidade retroativa): traco REMOVIDO (sem consumir RNG
#      nenhum) x o main.c canonico ANTES desta nota (commit 4df4da4) — as
#      21 colunas antigas saem bit-a-bit identicas.
#   P3 (ordem esperada do kappa): populacoes HOMOGENEAS (so ESC_ACAO / so
#      ESC_PLANO / so ESC_MONITOR, RNG preservado) — espera-se
#      ESC_PLANO >= ESC_ACAO >= ESC_MONITOR, efeito modesto (a maioria dos
#      ticks e "livre", onde as tres leituras coincidem).
#   P4 (deriva neutra): semeadura em tercos, MUTACAO ligada, 30000 ticks,
#      varias seeds — sem vencedor consistente entre seeds (ao contrario de
#      hon_f na nota 08).
#
# Patches numa copia temporaria do main.c canonico (>= 4df4da4). ~3 min.
#   sh papers/notes/29-escuta-evolutiva.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
ANTES_REV=4df4da4
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000
TICKS_LONGO=30000

gcc -std=c11 -O2 -o "$TMP/canon" "$MAINC"
git show "$ANTES_REV:main.c" > "$TMP/antes.c"
gcc -std=c11 -O2 -o "$TMP/antes" "$TMP/antes.c"

# gera as variantes de patch. modo:
#   fixa_rng   escuta FIXADO em $2, mas ainda CONSOME o(s) rng01() (P1, P3)
#   remove_rng escuta FIXADO em ESC_ACAO SEM consumir nenhum rng01() (P2)
gen() {
python3 - "$MAINC" "$TMP" "$1" "$2" <<'PY'
import sys
src = open(sys.argv[1]).read(); tmp = sys.argv[2]; modo = sys.argv[3]
valor = sys.argv[4] if len(sys.argv) > 4 else "ESC_ACAO"

def troca(t, a, b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    return t.replace(a, b, 1)

SEM_ORIG = ("        b->escuta      = (int)(rng01() * 3.0f);                   /* tercos      */\n"
            "        if (b->escuta > ESC_MONITOR) b->escuta = ESC_MONITOR;\n")
MUT_ORIG = ("static int muta_escuta(int e) {\n"
            "    if (rng01() < 2.0f * MUTACAO) {\n"
            "        e = (int)(rng01() * 3.0f);\n"
            "        if (e > ESC_MONITOR) e = ESC_MONITOR;\n"
            "    }\n"
            "    return e;\n"
            "}\n")

if modo == "fixa_rng":
    sem_novo = (f"        b->escuta      = (int)(rng01() * 3.0f);                   /* descartado  */\n"
                f"        b->escuta      = {valor};\n")
    mut_novo = ("static int muta_escuta(int e) {\n"
                "    (void)e;\n"
                "    if (rng01() < 2.0f * MUTACAO) {\n"
                "        (void)(rng01());   /* consumido, descartado */\n"
                "    }\n"
                f"    return {valor};\n"
                "}\n")
elif modo == "remove_rng":
    sem_novo = f"        b->escuta      = {valor};   /* SEM consumir RNG */\n"
    mut_novo = ("static int muta_escuta(int e) {\n"
                "    (void)e;\n"
                f"    return {valor};   /* SEM consumir RNG */\n"
                "}\n")
else:
    raise SystemExit(f"modo desconhecido: {modo}")

s = troca(src, SEM_ORIG, sem_novo)
s = troca(s,   MUT_ORIG, mut_novo)
open(f"{tmp}/v.c", "w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/bin" "$TMP/v.c"
}

media_col() {  # media_col ARQ COL — media da coluna a partir do tick 500
    awk -F, -v c="$2" 'NR>1 && $2>500 {s+=$c;n++} END{if(n) printf "%.4f", s/n; else printf "--"}' "$1"
}
valor_tick() { # valor_tick ARQ COL TICK
    awk -F, -v c="$2" -v t="$3" '$2==t {printf "%.4f", $c}' "$1"
}

printf '\n  nota 29 — a escuta evolutiva (seeds %s)\n' "$SEEDS"

printf '\n  P1-sanidade: escuta LIVRE x FIXADA em ESC_ACAO (RNG preservado)\n'
printf '      fora de relato(18)/esc_plano_f(22)/esc_monitor_f(23), tudo bit-a-bit identico?\n\n'
gen fixa_rng ESC_ACAO
mv "$TMP/bin" "$TMP/fixado"
for s in $SEEDS; do
  "$TMP/canon"  "$s" "$TICKS" 0 --log "$TMP/livre_$s.csv"  >/dev/null
  "$TMP/fixado" "$s" "$TICKS" 0 --log "$TMP/fixado_$s.csv" >/dev/null
  cut -d, -f1-17,19-21 "$TMP/livre_$s.csv"  > "$TMP/l17_$s.csv"
  cut -d, -f1-17,19-21 "$TMP/fixado_$s.csv" > "$TMP/f17_$s.csv"
  if cmp -s "$TMP/l17_$s.csv" "$TMP/f17_$s.csv"; then
    printf '      seed %-6s IDENTICO\n' "$s"
  else
    printf '      seed %-6s DIFERE — PATCH SUJO OU EFEITO REAL!\n' "$s"
  fi
done

printf '\n  P2-compatibilidade: escuta REMOVIDA (sem RNG) x main.c canonico pre-nota-29 (%s)\n\n' "$ANTES_REV"
gen remove_rng ESC_ACAO
mv "$TMP/bin" "$TMP/removido"
for s in $SEEDS; do
  "$TMP/antes"    "$s" "$TICKS" 0 --log "$TMP/antes_$s.csv"    >/dev/null
  "$TMP/removido" "$s" "$TICKS" 0 --log "$TMP/removido_$s.csv" >/dev/null
  cut -d, -f1-21 "$TMP/antes_$s.csv"    > "$TMP/a21_$s.csv"
  cut -d, -f1-21 "$TMP/removido_$s.csv" > "$TMP/r21_$s.csv"
  if cmp -s "$TMP/a21_$s.csv" "$TMP/r21_$s.csv"; then
    printf '      seed %-6s IDENTICO (21 colunas)\n' "$s"
  else
    printf '      seed %-6s DIFERE!\n' "$s"
  fi
done

printf '\n  P3-ordem do kappa: populacoes homogeneas (RNG preservado), media do relato (col 18), tick > 500\n\n'
printf '      %-12s' 'arquitetura'; for s in $SEEDS; do printf ' %9s' "seed$s"; done; echo
printf '      %s\n' '-----------------------------------------------'
for arq in ESC_ACAO ESC_PLANO ESC_MONITOR; do
  gen fixa_rng "$arq"
  mv "$TMP/bin" "$TMP/homog_$arq"
  printf '      %-12s' "$arq"
  for s in $SEEDS; do
    "$TMP/homog_$arq" "$s" "$TICKS" 0 --log "$TMP/h_${arq}_$s.csv" >/dev/null
    printf ' %9s' "$(media_col "$TMP/h_${arq}_$s.csv" 18)"
  done
  echo
done

printf '\n  P4-deriva neutra: tercos + mutacao (canonico), esc_plano_f/esc_monitor_f em t=0 e t=%s\n\n' "$TICKS_LONGO"
printf '      %-8s %14s %14s\n' 'seed' 'plano_f (0->fim)' 'monitor_f (0->fim)'
for s in $SEEDS; do
  "$TMP/canon" "$s" "$TICKS_LONGO" 0 --log "$TMP/longo_$s.csv" >/dev/null
  p0=$(valor_tick "$TMP/longo_$s.csv" 22 0);         pf=$(valor_tick "$TMP/longo_$s.csv" 22 $((TICKS_LONGO-1)))
  m0=$(valor_tick "$TMP/longo_$s.csv" 23 0);         mf=$(valor_tick "$TMP/longo_$s.csv" 23 $((TICKS_LONGO-1)))
  printf '      %-8s %6s -> %6s   %6s -> %6s\n' "$s" "$p0" "$pf" "$m0" "$mf"
done

printf '\n  Sem custo instalado: P1/P2 provam que o traco nao toca o mundo; P3 mede\n'
printf '  a ordem do kappa por arquitetura; P4 checa se a selecao favorece alguma\n'
printf '  mesmo sem ninguem ler "escuta" — se favorecer, o desenho tem um vazamento.\n\n'
