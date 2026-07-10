#!/bin/sh
# Reproduz a nota 07 (papers/notes/07-o-dedo-do-espectador.md).
#
# O BANDERSNATCH FORCADO (pre-registro: ROADMAP §2.2, commit d47c68c, ANTES de
# rodar): sobrescreve o alvo de um subconjunto deterministico de blocos
# (hash2(x,y,tick) — nao toca o RNG do mundo) e compara TRES arquiteturas de
# introspeccao sob a mesma intervencao:
#   A — le a ACAO executada (a v1 canonica): deve confabular (B1);
#   B — le o PLANO: deve ser imune na calibracao e cega ao mundo (B2);
#   C — monitora os dois: deve detectar a discrepancia, sem conseguir
#       distinguir o dedo do espectador da fisica de resolver() (B3).
# E a dose-resposta do kappa canonico (col 18) com a fracao forcada (B4),
# incluindo a sanidade: fracao 0 => CSV bit-a-bit identico ao canonico.
#
# Patch numa copia temporaria do main.c canonico (>= ffb3014). ~2 min.
#   sh papers/notes/07-bandersnatch.sh
set -eu
export LC_ALL=C
cd "$(dirname "$0")/../.."
RAIZ=$(pwd)
MAINC=${1:-$RAIZ/main.c}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SEEDS="7 42 1234"
TICKS=3000

# gera a variante com o dedo em 1/DIV (0 = desligado)
gen() {
python3 - "$MAINC" "$TMP" "$1" <<'PY'
import sys
src=open(sys.argv[1]).read(); tmp=sys.argv[2]; div=sys.argv[3]
def troca(t,a,b):
    assert a in t, f"ancora sumiu: {a[:60]!r} (o main.c mudou?)"
    return t.replace(a,b,1)

s=troca(src,"static float relato_ultimo;",
"static float relato_ultimo;\n"
"/* --- BANDERSNATCH (patch da nota 07; pre-registro ROADMAP §2.2) --- */\n"
f"static const uint32_t BS_DIV = {div}u;   /* 0 = dedo desligado; N = forca ~1/N */\n"
"static int bs_plano_x[MAX_AG], bs_plano_y[MAX_AG], bs_forcado[MAX_AG];\n"
"static const int BS_DX[8] = {-1,0,1,-1,1,-1,0,1};\n"
"static const int BS_DY[8] = {-1,-1,-1,0,0,1,1,1};\n"
"static long bs_n[3], bs_accA[3], bs_accB[3], bs_confA[3], bs_det[3];\n"
"static void bs_dump(void) {\n"
"    static const char *nome[3] = {\"livre\",\"negado\",\"forcado\"};\n"
"    for (int g = 0; g < 3; g++)\n"
"        fprintf(stderr, \"BS %-8s n=%-8ld accA=%.4f accB=%.4f confA=%.4f det=%.4f\\n\",\n"
"            nome[g], bs_n[g],\n"
"            bs_n[g]? (double)bs_accA[g]/bs_n[g]:0, bs_n[g]? (double)bs_accB[g]/bs_n[g]:0,\n"
"            bs_n[g]? (double)bs_confA[g]/bs_n[g]:0, bs_n[g]? (double)bs_det[g]/bs_n[g]:0);\n"
"}")

s=troca(s,"            if (interativo || logf) medir_decisao();",
"            if (interativo || logf) medir_decisao();\n"
"\n"
"            /* BANDERSNATCH: o dedo do espectador — depois da verdade da decisao\n"
"             * ser fotografada, antes de resolver(). Selecao e alvo imposto por\n"
"             * hash (deterministico, sem tocar o RNG do mundo). */\n"
"            for (int i = 0; i < n_blocos; i++) {\n"
"                if (!blocos[i].vivo) continue;\n"
"                bs_plano_x[i] = alvo_x[i]; bs_plano_y[i] = alvo_y[i];\n"
"                bs_forcado[i] = 0;\n"
"                if (BS_DIV == 0u) continue;\n"
"                /* o ternario evita o warning de /0 no build com o dedo desligado */\n"
"                if (hash2(blocos[i].x, blocos[i].y, (uint32_t)t + 0xB5B5u) % (BS_DIV ? BS_DIV : 1u) != 0u) continue;\n"
"                int ini = (int)(hash2(blocos[i].y, blocos[i].x, (uint32_t)t) % 8u);\n"
"                for (int k = 0; k < 8; k++) {\n"
"                    int d = (ini + k) % 8;\n"
"                    int nx = blocos[i].x + BS_DX[d], ny = blocos[i].y + BS_DY[d];\n"
"                    if (nx < 0 || nx >= LARG || ny < 0 || ny >= ALT) continue;\n"
"                    if (ocup[ny][nx] != -1) continue;\n"
"                    if (nx == bs_plano_x[i] && ny == bs_plano_y[i]) continue;\n"
"                    alvo_x[i] = nx; alvo_y[i] = ny; bs_forcado[i] = 1;\n"
"                    break;\n"
"                }\n"
"            }")

s=troca(s,"        conf[r][rel_verdade[i]]++;\n        n++;",
"        conf[r][rel_verdade[i]]++;\n        n++;\n"
"        {\n"
"            /* arquitetura B: o interprete le o PLANO, nao a acao */\n"
"            int r_b = rel_classifica(bs_plano_x[i], bs_plano_y[i],\n"
"                                     rel_cx[i], rel_cy[i], rel_ex[i], rel_ey[i]);\n"
"            /* arquitetura C: monitor — a acao executada difere do plano? */\n"
"            int difere = (blocos[i].x != bs_plano_x[i] || blocos[i].y != bs_plano_y[i]);\n"
"            int g = bs_forcado[i] ? 2 : (difere ? 1 : 0);\n"
"            bs_n[g]++;\n"
"            if (r   == rel_verdade[i]) bs_accA[g]++;\n"
"            if (r_b == rel_verdade[i]) bs_accB[g]++;\n"
"            if (r   != REL_NAOSEI)     bs_confA[g]++;\n"
"            if (difere)                bs_det[g]++;\n"
"        }")

s=troca(s,"    signal(SIGINT, ao_interromper);",
          "    signal(SIGINT, ao_interromper);\n    atexit(bs_dump);")
open(f"{tmp}/bs.c","w").write(s)
PY
gcc -std=c11 -O2 -o "$TMP/bs" "$TMP/bs.c"
}

media18() { awk -F, 'NR>1 && $2>20 && $3>0 {s+=$18;n++} END{if(n) printf "%.4f", s/n; else printf "--"}' "$1"; }

printf '\n  nota 07 — o dedo do espectador (seeds %s, %s ticks)\n' "$SEEDS" "$TICKS"

printf '\n  B4-sanidade: dedo desligado (BS_DIV=0) => CSV bit-a-bit identico ao canonico\n'
gcc -std=c11 -O2 -o "$TMP/canon" "$MAINC"
gen 0
"$TMP/canon" 7 "$TICKS" 0 --log "$TMP/canon.csv" >/dev/null 2>&1
"$TMP/bs"    7 "$TICKS" 0 --log "$TMP/off.csv"   >/dev/null 2>&1
cmp -s "$TMP/canon.csv" "$TMP/off.csv" && printf '      seed 7: IDENTICO (18 colunas)\n' \
                                       || printf '      seed 7: DIFERE — PATCH SUJO!\n'

printf '\n  B4-dose-resposta: kappa canonico (col 18, arquitetura A) x fracao forcada\n\n'
printf '      %-10s' 'fracao'; for s in $SEEDS; do printf ' %9s' "seed$s"; done; echo
printf '      %s\n' '---------------------------------------------'
for div in 0 16 4 2; do
  gen "$div"
  case $div in 0) f="0";; 16) f="1/16";; 4) f="1/4";; 2) f="1/2";; esac
  printf '      %-10s' "$f"
  for s in $SEEDS; do
    "$TMP/bs" "$s" "$TICKS" 0 --log "$TMP/d_${div}_$s.csv" 2>"$TMP/d_${div}_$s.err" >/dev/null
    printf ' %9s' "$(media18 "$TMP/d_${div}_$s.csv")"
  done
  echo
done

printf '\n  B1-B3: as tres arquiteturas sob o dedo (BS_DIV=4, ou seja ~25%% forcado)\n'
printf '      accA/accB = calibracao vs o motivo da DECISAO; confA = A nomeia motivo\n'
printf '      positivo; det = C flagra "minha acao nao e meu plano"\n\n'
for s in $SEEDS; do
  printf '      seed %s\n' "$s"
  sed 's/^/        /' "$TMP/d_4_$s.err"
done

printf '\n  A nunca detecta (nao tem como); B e imune ao dedo mas descreve um passo\n'
printf '  que nao aconteceu; C detecta o dedo E resolver() sem distingui-los.\n\n'
