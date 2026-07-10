#!/bin/sh
# Regenera os datasets congelados a partir do main.c da raiz.
# Cada CSV e f(seed, codigo): depois de uma mudanca de comportamento,
# rode este script e atualize o manifesto (README.md desta pasta) com
# o commit novo. Diff nao-vazio contra os CSVs commitados = o
# comportamento mudou (teste de regressao de graca).
set -eu
cd "$(dirname "$0")/.."

gcc -std=c11 -Wall -Wextra -O2 -o matrix main.c

./matrix 7 2000 0 --log datasets/seed7.csv >/dev/null

echo "datasets regenerados com main.c @ $(git rev-parse --short HEAD)"
