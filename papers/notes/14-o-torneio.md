# Nota 14 — O torneio do horizonte: o ESS é o teto, e a Rainha Vermelha corre até a parede

**Data:** 2026-07-15
**`main.c`:** o de `079a3ce` (canônico intocado; a variante `torn` é patch
temporário — só o horizonte varia, o resto pregado, mutação desligada).
**Pré-registro:** cabeçalho de `papers/notes/14-torneio.sh` — **antes** de
rodar (T1/T2/T3).
**Serve ao:** Paper 2 ("Cognição como bem posicional") — entrega o **ESS** e o
grau de dependência de frequência que o "9 vence 3 em 3/3 seeds" (Fase 3) não
tinha. Agregados em `datasets/torneio.csv`.
**Reproduzir:** `sh papers/notes/14-torneio.sh` (~40 min com `NPROC=12`)

---

## Resumo

A Fase 3 mostrou que o horizonte de planejamento é um **bem posicional** —
individualmente vantajoso, coletivamente ruim — com uma invasão só (`h = 9`
desloca `h = 3` em 3/3 seeds). Isso é sugestivo, não um ESS. Esta nota roda o
torneio inteiro: **66 pares `(h_i, h_j)` × 8 seeds × 6000 ticks**, a população
50/50 com horizonte `h_i` e `h_j` e **só o horizonte variando** (urgência,
peso_espaço, desconto e estratégia pregados; mutação desligada — heranca
exata). Com dois valores na população, `hor_m` no CSV *é* a frequência.

O placar do pré-registro:

| # | predição (escrita antes) | resultado |
|---|---|---|
| **T1** | a vantagem satura ~h=5; pares ambos ≥5 empatam (deriva); o ESS é um **platô ~5..12**, não um pico | ⚠️ **meio certo**: a margem satura em cheio, mas **não zera** — o mais fundo vence *todos* os duelos, e o ESS é o **teto h=12**, não um platô onde os topos empatam. Ver §2 |
| **T2** | para `h_i < 5`, o mais fundo vence (freq > 0,5) | ✅ vence — e esmagadoramente: freq 0,84–1,00 contra os rasos |
| **T3** | sanidade: `HI==HJ` dá `hor_m==HI`; sem extinções | ✅ sanidade passou; **0 extinções em 528 corridas** |

## 1. A matriz é transitiva: deeper vence, sempre

A conta de vitórias, uma linha por horizonte (de quantos dos 11 duelos cada um
sai vencedor — freq final > 0,5):

```
 h= 1 vence  0 de 11        h= 7 vence  6 de 11
 h= 2 vence  1 de 11        h= 8 vence  7 de 11
 h= 3 vence  2 de 11        h= 9 vence  8 de 11
 h= 4 vence  3 de 11        h=10 vence  9 de 11
 h= 5 vence  4 de 11        h=11 vence 10 de 11
 h= 6 vence  5 de 11        h=12 vence 11 de 11
```

Uma escada perfeita: cada horizonte vence exatamente um duelo a mais que o
anterior. Isso é uma **ordem linear estrita** — nenhuma célula fora do lugar,
nenhum ciclo pedra-papel-tesoura. O torneio não tem estratégia mista escondida
nem intransitividade: **planejar mais fundo domina, par a par, sem exceção nos
66 duelos.** O `h = 12` vence os 11; o `h = 1` perde os 11.

**O ESS é o teto.** `HORIZONTE_MAX = 12` **censura** o resultado: a estratégia
não-invadível é a mais profunda que o mundo permite. Não há ESS interior — nada
segura a corrida antes da parede. É a Rainha Vermelha da Fase 3 levada ao
limite: cada bloco precisa pensar o mais fundo possível só para não ser
deslocado, e "o mais fundo possível" é onde o `#define` corta.

## 2. Mas a margem satura — e é por isso que T1 estava meio certo

A dominância é estrita; a **força** dela não é. A margem do passo de +1 (a
frequência que o horizonte `h+1` alcança contra o `h`, média ± sd de 8 seeds, e
quantas seeds o mais fundo **fixou**):

| `h → h+1` | freq(`h+1`) | fixou / misto |
|---|---|---|
| 1 → 2 | **1,000 ± 0,000** | 8/0 |
| 2 → 3 | 0,995 ± 0,009 | 7/1 |
| 3 → 4 | 0,949 ± 0,062 | 4/4 |
| 4 → 5 | 0,836 ± 0,094 | **0/8** |
| 5 → 6 | 0,766 ± 0,108 | 0/8 |
| 6 → 7 | 0,628 ± 0,126 | 0/8 |
| 7 → 8 | 0,630 ± 0,120 | 0/8 |
| 8 → 9 | 0,565 ± 0,163 | 0/8 |
| 9 → 10 | 0,529 ± 0,104 | 0/8 |
| 10 → 11 | 0,523 ± 0,058 | 0/8 |
| 11 → 12 | 0,560 ± 0,097 | 0/8 |

Duas coisas moram nesta tabela.

**A saturação (T1, a parte certa).** A vantagem marginal de um passo a mais
desaba de **aniquilação total** (1,000 contra o `h = 1`, o raso extinto em 8/8
seeds) para **quase moeda ao ar** (0,52–0,56 no topo). O joelho da curva está
em `h ≈ 4–6`, e não por acaso: com o desconto pregado em 0,80, a profundidade
efetiva satura em `1/(1 − 0,80) = 5`. Acima disso, cada passo declarado a mais
pesa `0,8ʰ` — um bocado que encolhe geometricamente. O horizonte 12 *enxerga*
mais que o 8, mas o que enxerga a mais está descontado a quase nada. **O teto
do desconto é o joelho da curva de retorno.**

**Por que o ESS ainda é o teto (T1, a parte errada).** Eu havia previsto que os
pares do topo **empatariam** (freq ~0,5, deriva neutra) e que o ESS seria um
**platô** onde qualquer `h ≥ 5` valesse igual. Não é o que aconteceu: os passos
do topo ficam a ~1 sd de 0,5 (0,523; 0,529), mas **sempre acima**, nunca abaixo
— e como são consistentemente positivos, eles **compõem**. O `h = 12` bate o
`h = 9` por 0,603 ± 0,097 (≈ 3 erros-padrão acima de 0,5), soma de três passos
que isolados quase somem no ruído. O gradiente **satura, mas nunca vira
não-positivo** — e por isso não há platô onde a corrida pare: ela vai até a
parede porque a parede é o único lugar onde o próximo passo deixa de existir.
Um bem posicional com retorno decrescente **mas não anulado** não tem ESS
interior; tem só o teto.

## 3. Fixação × polimorfismo: uma transição em h ≈ 3–4

O terceiro achado não estava no pré-registro e é o mais bonito. Olhe a coluna
`fixou / misto`: até `h = 3`, o horizonte mais fundo **fixa** — dirige o raso à
**extinção** (exclusão competitiva). A partir de `h = 4`, ele **domina mas
coexiste**: 0 fixações em 8 seeds, um **polimorfismo estável** em que o fundo
leva a maioria e o raso persiste.

A transição cai exatamente no teto do desconto (profundidade efetiva 5). A
leitura: quando a diferença de profundidade é **real** (rasos, abaixo do teto),
a seleção é forte e **exclui**; quando a diferença é **marginal** (fundos, no
teto ou acima), a seleção vira **frequência-dependente** e os tipos coexistem —
o fundo invade quando raro, mas o ganho some quando ele fica comum. É a
assinatura de manual de um bem posicional saturado: exclusão embaixo,
coexistência em cima.

## 4. O que isto entrega ao Paper 2

O "9 vence 3" da Fase 3 vira três afirmações com barra:

1. **O ESS existe e é o teto** (`h = 12`, censurado por `HORIZONTE_MAX`) — a
   corrida armamentista não tem freio endógeno; nada a segura antes da parede.
2. **O retorno é decrescente e o joelho é o desconto** (profundidade efetiva
   `1/(1−δ)`): a Fase 3 disse que `hor_m` não é identificável sem o desconto;
   aqui o desconto reaparece como o **regulador do valor posicional** do
   horizonte. Pregá-lo em 0,80 põe o joelho em `h ≈ 5`.
3. **A dependência de frequência é uma transição, não um regime** — exclusão
   abaixo do teto, coexistência acima. Isto prepara a dose-resposta `h*(c)`
   (nota 15): o imposto pigouviano tem de mover o joelho, não só a altura.

## Ameaças à validade

- **Desconto pregado em 0,80.** Todo o resultado é a preços de desconto fixo. É
  o desenho pedido (ROADMAP §3.1: senão a compensação contamina), mas significa
  que o joelho em `h ≈ 5` é **artefato do 0,80** — outro desconto move o joelho.
  Varrer `δ` diria se o teto de profundidade efetiva prevê o joelho em geral.
- **50/50, não invasor-raro.** O torneio mede quem chega à maioria partindo de
  metade-metade; um teste de ESS estrito injetaria o invasor **raro**. Os dois
  concordam quando a seleção é forte (baixo `h`); no topo, onde a seleção é
  fraca, a distinção importaria — o "ESS = teto" vale para o sinal de 50/50, e a
  fraqueza do gradiente lá em cima está honestamente reportada.
- **6000 ticks.** Os pares baixos fixam bem antes disso; os pares do topo
  **não fixam** (polimorfismo) — mais ticks não os resolveriam, é coexistência
  genuína, não corrida inacabada.
- **8 seeds.** As margens do topo (0,52–0,56) têm erro-padrão ~0,02–0,03;
  distinguíveis de 0,5 por ~1–3 sd conforme o par. Mais seeds apertariam a
  barra, não mudariam a ordem.
- **Só o horizonte varia.** Urgência, peso_espaço, estratégia pregados nas
  médias — é o contraste limpo do horizonte, não o mundo evolutivo pleno (onde
  o desconto compensaria e a Fase 3 mostrou `hor_m` cair).

## O que ficou em aberto

1. A **dose-resposta `h*(c)`** (nota 15, o imposto pigouviano): com o horizonte
   e o desconto livres e um custo por profundidade, medir se `h*` cai em direção
   ao ótimo de grupo. É a metade que falta do Paper 2.
2. **Varrer o desconto** para testar se o joelho segue `1/(1−δ)` em geral.
3. **Invasor-raro** para o ESS estrito no topo, onde 50/50 é fraco.
