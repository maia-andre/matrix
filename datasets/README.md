# Datasets

Cada CSV é `f(seed, código)`: reproduzível bit-a-bit **apenas** com o `main.c`
do commit que o gerou. Este manifesto é a proveniência; `./gerar.sh` (rodado
da raiz ou daqui) regenera tudo — e serve de teste de regressão: se o diff
contra os CSVs commitados não for vazio, o comportamento da simulação mudou.

| arquivo | comando | `main.c` em | descrição |
|---------|---------|-------------|-----------|
| `seed7.csv` | `./matrix 7 2000 0 --log datasets/seed7.csv` | `36fc587` | 2000 ticks da seed 7, a seed de verificação do projeto |

Colunas: ver a seção "Registrar dados (`--log`)" do `README.md` da raiz.

Para adicionar um dataset: acrescente o comando ao `gerar.sh`, rode-o e
registre a linha nova aqui com o commit corrente de `main.c`. Depois de uma
mudança de comportamento intencional, regenere e atualize a coluna do commit.
