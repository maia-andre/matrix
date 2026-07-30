# Nota 32 — A invasão direta do arrependimento não fecha o argumento: o efeito fundador domina 5 de 6 corridas

**Data:** 2026-07-29
**Pré-registro:** `ROADMAP.md` §4.5, commit `694e05a` — **antes** de rodar.
**Construído em:** este commit (nenhum mecanismo novo — reaproveita o `main.c`
canônico e o harness `invasao` que a nota 30 já validou).
**Serve ao:** tenta fechar a ameaça à validade que a própria nota 30 (Q5)
declarou em voz alta.
**Reproduzir:** `sh papers/notes/32-invasao-arrependimento.sh` (~15 min)

---

## Resumo

A nota 30 (Q5) achou `peso_arrependimento` convergindo consistentemente para
**negativo** sob mutação livre — mas registrou a ameaça de que isso pode ser
efeito de assimetria de mutação perto das bordas do domínio, não seleção de
verdade. Esta nota tentou fechar o argumento com o mesmo desenho exato do Q4
(invasão direta 50/50, sem mutação, montagens espelhadas), só trocando os
valores: negativo × zero (T1) e negativo × positivo (T2). **O resultado não
fecha o argumento — reabre a mesma dúvida.** Aplicando o diagnóstico de
paridade que a própria nota 30 usou para separar sinal de deriva: em **5 das
6 comparações**, é a mesma paridade de índice que vence nas duas montagens
espelhadas — a assinatura exata de efeito fundador, não de vantagem real do
traço. Só **1 de 6** (seed 42, negativo × positivo) mostra um vencedor
independente de paridade — e é `−2,0`, a direção que Q5 apostou. Um sinal
fraco demais para decidir sozinho. T3 não rodou: nem T1 nem T2 confirmaram
pelo critério pré-registrado ("desloca de forma consistente nas duas
montagens"), e o pré-registro foi explícito — sem confirmação, não há
hipótese para T3 testar.

## 1. T1 — negativo (−2,0) × zero (0,0): a mesma paridade vence nas duas montagens, em todas as 3 seeds

`arrep_m` (média da população) em `t=0` (sempre `−1,000`, a média exata de
50% em cada valor) e em `t=30000`:

| seed | `−2,0` residente (par) / `0,0` invasor (ímpar) | `0,0` residente (par) / `−2,0` invasor (ímpar) | quem venceu nas DUAS montagens |
|---|---|---|---|
| 7 | −1,000 → **0,000** (`0,0` fixa) | −1,000 → **−1,994** (`−2,0` fixa, ~99,7%) | **ÍMPAR** venceu as duas |
| 42 | −1,000 → **−2,000** (`−2,0` fixa) | −1,000 → **−0,128** (`0,0` domina, ~93,6%) | **PAR** venceu as duas |
| 1234 | −1,000 → −0,108 (`0,0` domina, ~94,6%, não fixou) | −1,000 → **−1,986** (`−2,0` domina, ~99,3%) | **ÍMPAR** venceu as duas (a maioria já) |

Nas três seeds, o vencedor **muda de identidade** (às vezes `−2,0`, às vezes
`0,0`) mas a **paridade** que carrega o vencedor é a mesma nas duas montagens
— exatamente o padrão que a nota 30 descreveu para Q4 ("a metade do espaço
que por acaso começou com um valor prosperou... por causa da vizinhança
local, não do valor em si"). T1 não confirma: **nenhuma** das três seeds
mostra `−2,0` vencendo de forma independente de paridade.

## 2. T2 — negativo (−2,0) × positivo (2,0): 2 de 3 seeds repetem o padrão; a seed 42 é a exceção genuína

| seed | `−2,0` residente (par) / `2,0` invasor (ímpar) | `2,0` residente (par) / `−2,0` invasor (ímpar) | quem venceu nas DUAS montagens |
|---|---|---|---|
| 7 | 0,000 → 1,738 (`2,0` domina, ~93,5%) | 0,000 → **−2,000** (`−2,0` fixa) | **ÍMPAR** venceu as duas |
| 42 | 0,000 → **−2,000** (`−2,0` fixa) | 0,000 → **−2,000** (`−2,0` fixa) | **`−2,0` venceu as duas, INDEPENDENTE de paridade** |
| 1234 | 0,000 → 1,956 (`2,0` domina, ~98,9%) | 0,000 → **−2,000** (`−2,0` fixa) | **ÍMPAR** venceu as duas |

Seeds 7 e 1234 replicam o mesmo padrão de T1: paridade, não valor, decide.
Mas a **seed 42 é diferente**: `−2,0` vence nas duas montagens — como
residente (par) **e** como invasor (par, na segunda montagem) — não, mais
precisamente: `−2,0` ocupa paridades **diferentes** nas duas montagens
(par na primeira, ímpar na segunda) e vence as duas vezes. É exatamente o
padrão que separaria sinal de deriva, e vai na direção que Q5 apostou — mas é
**1 seed em 3**, a mesma fração que zero seeds mostraram em T1.

## 3. Por que isto não fecha o argumento — e por que T3 não rodou

Cinco das seis comparações (T1: 3/3; T2: 2/3) têm a assinatura de efeito
fundador, não de seleção real — o mesmo confundidor que a nota 30 já
descreveu para Q4, agora replicado com valores diferentes. Uma seed (T2,
seed 42) foge do padrão e favorece `−2,0`, na direção prevista — mas 1/6 é
fraco demais para separar "há uma vantagem real, pequena, que o efeito
fundador afoga na maioria das corridas" de "essa seed também é deriva, só
que por acaso caiu do lado certo". O pré-registro (§4.5) declarou T3
condicional: *"se T1/T2 não confirmarem... T3 não roda — não há hipótese a
testar."* Nem T1 nem T2 confirmaram pelo critério declarado (deslocar de
forma consistente nas duas montagens, nas três seeds) — T3 (a checagem de
`agencia`) não rodou.

## Ameaças à validade

- **`n_blocos % 2` não é um sorteio espacialmente independente** (o mesmo
  ponto que a nota 30 já registrou) — mas, de novo, o padrão "a mesma
  paridade vence as duas montagens, mudando de identidade" é evidência
  **contra** um viés estrutural fixo de paridade (se houvesse, a MESMA
  paridade venceria em TODAS as seeds, não uma paridade em cada seed) — é
  evidência de efeito fundador **por seed**, não um artefato do desempate de
  `resolver()`.
- **3 seeds, e desta vez elas discordam entre si** — ao contrário de Q5 (nota
  30), onde as três concordavam limpo. A ausência de concordância aqui não
  refuta Q5 diretamente: deriva sob mutação livre (Q5) e invasão direta sem
  mutação (T1/T2) são regimes diferentes — a primeira dá tempo para o traço
  explorar o domínio inteiro por muitas gerações de mutação; a segunda
  congela dois valores e deixa só a demografia decidir en 30 000 ticks. É
  possível que `−2,0` carregue uma vantagem real pequena demais para vencer o
  efeito fundador numa única corrida de 30 000 ticks/~300 blocos, e que essa
  vantagem só apareça acumulada ao longo de muitas gerações de mutação e
  seleção (o que Q5 mede, e este desenho não).
- **Esta nota não teve pré-registro de "quantas seeds bastam para decidir"**
  — o critério declarado ("consistente nas duas montagens") não tinha um
  número mínimo de seeds fora do padrão que justificasse chamar 5/6 de
  "confirma" ou "refuta". Declarado aqui: 5/6 com assinatura de deriva foi
  lido como não-confirmação, seguindo o espírito (não a letra exata) do
  pré-registro.

## O que ficou em aberto

A ameaça à validade de Q5 (nota 30) **não foi fechada, foi aprofundada**: a
invasão direta não decide a favor nem contra a hipótese de que negativo é
geneticamente favorecido sobre zero/positivo. Um desenho que rodasse **mais
seeds** (10+, como a nota 11 fez para a régua inteira) poderia separar sinal
de ruído por contagem — não construído aqui, é o item natural se o André
quiser insistir neste fio. Alternativamente, repetir T1/T2 com uma
população **maior** (menos suscetível a efeito fundador) fecharia o mesmo
argumento por outro caminho — também não construído.
