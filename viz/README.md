# viz

Camada de visualização **aditiva**: só lê `datasets/*.csv` (e as tabelas
pequenas já publicadas, transcritas em `viz/data/` com comentário de
proveniência) e escreve PNGs em `papers/figs/`. Não toca `main.c`, não roda a
simulação, não é parte do determinismo que `datasets/gerar.sh` protege.

```sh
pip install --user pandas matplotlib   # nao vem com o resto do projeto (libc pura)
python3 viz/gerar_figuras.py           # regenera as 11 figuras, pt/ e en/
```

Cada figura sai duas vezes — `papers/figs/pt/*.png` (rótulos em português,
para os papers-fonte) e `papers/figs/en/*.png` (rótulos em inglês, para o
preprint) — com os mesmos dados nas duas.

## De onde vêm os dados

A maioria das figuras lê `datasets/*.csv` direto (a mesma proveniência do
`datasets/README.md`). Cinco tabelas — as do Paper 1 §4/§5/§6/§7 e a
"paisagem de grupo"/"ensaio de invasão" do Paper 2 §3 — não têm CSV bruto
commitado: são números de 3 seeds já publicados no texto, anteriores aos
datasets agregados de hoje. Para essas, `viz/data/*.csv` **transcreve** a
tabela do paper (com a nota/script de origem no comentário do cabeçalho) em
vez de refazer a corrida — refazê-la hoje, contra o `main.c` atual, daria
números **diferentes** dos publicados (traços novos desde então, como
`escuta` e `peso_arrependimento`, consomem `rng01()` a mais e deslocam o
fluxo — ver os avisos em `datasets/README.md`). Reproduzir os originais
exige o `main.c` do commit certo, exatamente como a nota de origem descreve.

## Figuras

| figura | paper/seção | fonte |
|---|---|---|
| `p1-fig1-modelo-ablacao` | Paper 1 §4 (modo 1) | `viz/data/p1_modo1_ablacao.csv` — transcrito, nota 01 |
| `p1-fig2-agencia-regra4` | Paper 1 §5 (modo 2) | `viz/data/p1_modo2_agencia.csv` — transcrito, nota 03 |
| `p1-fig3-modelo-do-outro-alpha` | Paper 1 §6 (modo 3) | `viz/data/p1_modo3_alpha.csv` — transcrito, nota 04 |
| `p1-fig4-phi-ablacao` | Paper 1 §7 (modo 4) | `viz/data/p1_modo4_phi_ablacao.csv` — transcrito, nota 05 |
| `p1-fig5-replicacao-50-seeds` | Paper 1 §9 | `datasets/replicacao50.csv` (real, calculado ao vivo) |
| `p2-fig1-bem-posicional` | Paper 2 §3 | `viz/data/p2_paisagem_grupo.csv` + `p2_invasao_h3_h9.csv` — transcritos, ROADMAP "Fase 3" |
| `p2-fig2-torneio-heatmap` | Paper 2 §4 | `datasets/torneio.csv` (real) |
| `p2-fig3-inversao-escada` | Paper 2 §4 | `datasets/desconto.csv` (real, pares adjacentes h/h-1) |
| `p2-fig4-dose-resposta-colheita` | Paper 2 §5 | `datasets/tipo-unico.csv` (real, diferença pareada contra h=1) |
| `p2-fig5-imposto` | Paper 2 §7 + adendo nota 21 | `datasets/reciclagem.csv` (real, recicla=0/1) |
| `p2-fig6-bimodalidade` | Paper 2 §8, adendo notas 23/26/28 | `datasets/bimodalidade.csv` (real, variante uni_h) |

## Replays (CSV → GIF, não CSV → PNG)

A segunda metade que este diretório já previa (ver ROADMAP, "Backlog
especulativo"): duas animações que mostram uma MUDANÇA ao longo do tempo, não
um estado final — a bifurcação do histograma de horizonte (nota 23) e o
detector de colapso disparando/desligando (nota 24). Diferente das figuras
acima, os dois CSVs de origem (`viz/data/replay_bimodal.csv` e
`replay_colapso.csv`) não são transcrições nem `datasets/*.csv` existentes:
são gerados por uma corrida **fresca**, sob o `main.c` de hoje, com a mesma
técnica de patch temporário que as notas 23/24/26 já usavam (env vars ligam
imposto/sonda; nada entra no binário canônico). Não são uma nota nova — não
testam hipótese, não produzem achado — só ilustram com uma seed demonstrativa
um fenômeno já estabelecido nos datasets reais. Por isso os números **não**
reproduzem as tabelas publicadas nas notas 23/24 (traços novos desde então —
`escuta`, `peso_arrependimento` — deslocam o fluxo de `rng01()`, o mesmo aviso
da seção acima), mas a forma qualitativa é a mesma.

```sh
sh viz/data/gerar_replay_bimodal.sh    # ~1 corrida, 30000 ticks -> replay_bimodal.csv
sh viz/data/gerar_replay_colapso.sh    # ~1 corrida, 8000 ticks  -> replay_colapso.csv
python3 viz/gerar_replay.py            # os dois CSVs -> viz/replays/*.gif
```

| replay | mostra | seed/condição |
|---|---|---|
| `replay-bimodal.gif` | histograma de horizonte (1..12) indo de quase-uniforme a dois picos separados por um vale, ao longo de 30000 ticks | `uni_h_livre`, δ=0,95, seed=1 (fundo da nota 20/23, só horizonte livre) |
| `replay-colapso.gif` | população + faixa vermelha quando `colapso ativo`: imposto liga em t=2000 (crash quase até a extinção), detector dispara em t=2054, população se recupera parcialmente sob o imposto, detector desliga em t=2861, segunda recuperação quando o imposto sai em t=5000 | imposto pigouviano `c=0,30`, liga 2000/desliga 5000, seed=2 |

Cada `gerar_replay_*.sh` confirma leitura pura antes de gerar dado (a sonda/
detector sozinhos, sem a intervenção que muda o comportamento, produzem CSV
`--log` bit a bit idêntico ao vanilla) — a mesma disciplina C0a/B0a das notas
23/24, só que sem pré-registro (não há predição sendo testada aqui).

## Paleta e estilo

Cores e regras de uso (categórica em ordem fixa, sequencial azul para
grandezas ordenadas por δ, divergente azul↔vermelho só para a matriz do
torneio, que tem ponto médio real em 0,5) seguem o skill `dataviz` do
Claude Code — ver `references/palette.md` daquele skill. `viz/gerar_figuras.py`
tem os hex direto no topo do arquivo.
