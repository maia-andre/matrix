# Datasets

Cada CSV é `f(seed, código)`: reproduzível bit-a-bit **apenas** com o `main.c`
do commit que o gerou. Este manifesto é a proveniência; `./gerar.sh` (rodado
da raiz ou daqui) regenera tudo — e serve de teste de regressão: se o diff
contra os CSVs commitados não for vazio, o comportamento da simulação mudou.

| arquivo | comando | descrição |
|---------|---------|-----------|
| `seed7.csv` | `./matrix 7 2000 0 --log datasets/seed7.csv` | 2000 ticks da seed 7, a seed de verificação do projeto |
| `replicacao50.csv` | `sh papers/notes/11-replicacao.sh` | **agregado, não bruto**: uma linha por (condição × seed) — 9 variantes (controle + ablações do Apêndice A) × seeds 1..50 × 3000 ticks. Colunas: médias/máximos por mostrador, janelas início/fim, e a contagem f32×double da `agencia` (nota 11). ⚠️ **Não entra no `gerar.sh`**: custa ~2 h de CPU (~15 min com `NPROC=12`); a proveniência é o script da nota 11 |
| `janela30k.csv` | `sh papers/notes/12-janela-longa.sh` | **agregado, não bruto**: uma linha por (condição × seed) — ctl, `fesp` (congela `peso_espaco`), `fdep` (congela horizonte+desconto) × seeds 1..50 × **30 000 ticks**. Colunas: janelas início/fim por mostrador/traço, `hon_f`/`blef_f` finais, e corr(phi, profundidade efetiva) na janela cheia × primeiros 3000 (nota 12). ⚠️ **Não entra no `gerar.sh`**: ~6 h de CPU (~35 min com `NPROC=12`) |
| `fatorial30k.csv` | `sh papers/notes/13-fatorial.sh` | **agregado, não bruto**: a quarta célula do fatorial de L5 — `fambos` (congela `peso_espaco` **e** horizonte+desconto) × seeds 1..50 × **30 000 ticks**, mesmo esquema de 18 colunas do `janela30k.csv`. Com as três células da nota 12, fecha o 2×2: o motor da autocausa é o estreitamento do motivo, e o horizonte só age por **interação** (nota 13). ⚠️ **Não entra no `gerar.sh`**: ~2 h de CPU (~12 min com `NPROC=12`) |
| `torneio.csv` | `sh papers/notes/14-torneio.sh` | **agregado, não bruto**: o torneio de invasão do horizonte — 66 pares `(h_i,h_j)` × seeds 1..8 × 6000 ticks, população 50/50 com **só o horizonte variando** (resto pregado, mutação off). Colunas: `seed,hi,hj,freq_hj,hor_m_fim,pop_fim,fixou`. O ESS é o teto `h=12` (dominância transitiva), o retorno satura no joelho do desconto, e há transição fixação→polimorfismo em `h≈4` (nota 14). ⚠️ **Não entra no `gerar.sh`**: ~40 min com `NPROC=12` |

**Qual `main.c` gerou cada CSV?** O commit em que o arquivo foi atualizado pela
última vez — o próprio git responde, e a resposta nunca envelhece:

```sh
git log -1 --oneline -- datasets/seed7.csv
```

Um hash escrito à mão nesta tabela mentiria no dia em que alguém regenerasse o
CSV sem editar a linha. Por isso não há coluna de hash.

Colunas: ver a seção "Registrar dados (`--log`)" do `README.md` da raiz.

Para adicionar um dataset: acrescente o comando ao `gerar.sh`, rode-o e registre
a linha nova aqui. Depois de uma mudança de comportamento intencional, regenere
os CSVs **no mesmo commit** da mudança — assim o `git log` acima continua exato.

⚠️ **`modelo` mudou de definição.** CSVs gerados antes do conserto do mostrador
(`modelo` lia o array do mundo, não o mapa do bloco) trazem valores `~0,97` que
não são comparáveis com os `~0,63` de hoje. Ver
[`../papers/notes/01-quatro-modos-de-errar.md`](../papers/notes/01-quatro-modos-de-errar.md).

⚠️ **Coluna nova: `autocausa`** (o self como causa — nota 09), a **21ª**, no fim.
CSVs pós-nota-08 têm 20 colunas; os atuais, 21. As 20 primeiras são **bit-a-bit
idênticas**: o mostrador varre σ ∈ [0,1] mas a simulação roda em σ = 1, que é o
código de sempre (`1.0f * garfada == garfada`, exato em IEEE754). Foi assim que a
predição P3 do pré-registro (`ROADMAP.md` §5.0) foi verificada — contra este
próprio `seed7.csv`, antes de regenerá-lo.

⚠️ **Colunas novas: `hon_f`, `blef_f`** (fração honesta/blefe da população — o
relato causal, nota 08). CSVs pós-nota-06 têm 18 colunas; os atuais, 20. As 18
primeiras seguem bit-a-bit compatíveis (a passagem `emitir` com todos honestos é
idêntica à telepatia antiga).

⚠️ **Coluna nova: `relato`** (κ do intérprete leigo, nota 06). CSVs anteriores têm
17 colunas; os pós-nota-06, 18. As 17 primeiras são bit-a-bit compatíveis com a era
pós-nota-05.

⚠️ **`phi` mudou de definição.** A 1ª versão era a distância da ordem integrada à
comida do instante (×10, depois ÷10 no CSV) e lia ~`0,25`; a atual é a **menor**
distância aos três módulos isolados (comida, espaço, mapa) e lê ~`0,06` — os
valores não são comparáveis. Ver
[`../papers/notes/05-phi-media-o-segundo-motivo.md`](../papers/notes/05-phi-media-o-segundo-motivo.md).

⚠️ **A coluna `automodelo` foi renomeada `modelo_do_outro` e mudou de definição.**
Deixou de ser a observação `intencao ≠ alvo` (lida no ponto fixo `ANTECIPACAO`) e
virou uma **intervenção ancorada**, varrida por todo o domínio da antecipação — sem
depender daquela constante. Os valores sobem de leve (`~0,34 → ~0,35`); a simulação
é bit-a-bit idêntica (só o mostrador mudou). Ver
[`../papers/notes/04-o-automodelo-era-um-modelo-do-outro.md`](../papers/notes/04-o-automodelo-era-um-modelo-do-outro.md).
