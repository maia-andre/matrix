# Nota 33 — A extensão de 10 seeds fecha T1 a favor do fundador puro (o oposto do que a primeira leitura, com bug, dizia); T2 continua sem decidir

**Data:** 2026-07-31
**Pré-registro:** `ROADMAP.md` §4.6, commit `c0d6941` — antes de rodar.
**Construído em:** este commit (o script já estava commitado em `3937736`; esta nota
corrige um bug de classificação encontrado ao processar o resultado — ver §1).
**Serve ao:** estende a nota 32 (§4.5), que tentou fechar a ameaça à validade que a
nota 30 (Q5) declarou em voz alta. Nenhum mecanismo novo — mesmo `main.c` canônico,
mesmo harness `invasao` das notas 30/32.
**Reproduzir:** `sh papers/notes/33-invasao-arrependimento-10-seeds.sh` (~2h15,
sequencial — sem paralelização por desenho, `CLAUDE.md`)

---

## Resumo

A nota 32 rodou T1 (`−2,0` × `0,0`) e T2 (`−2,0` × `2,0`) em só 3 seeds e não decidiu:
5 das 6 comparações mostraram a assinatura de efeito fundador. O pré-registro desta
extensão (§4.6) prometeu 10 seeds novas e sequenciais (`1..10`) para contar através do
confundidor, com um critério numérico declarado antes de rodar: ≥7/10 confirma,
4–6/10 não decide, ≤3/10 lê como fundador puro.

A primeira execução do script terminou depois de 2h14 de simulação e imprimiu **T1:
CONFIRMA (9/10 REAL)** e **T2: NÃO DECIDE (4/10 REAL)** — um resultado que teria
revertido a leitura da nota 32 para T1. Antes de aceitar isso, conferi a lógica do
classificador automático linha a linha contra o diagnóstico de paridade que as notas
30/32 já usam à mão — e achei um bug: a fórmula da montagem B estava invertida (§1).
**Corrigindo o bug e recalculando a partir dos mesmos números brutos já coletados**
(sem precisar rerodar a simulação, que é determinística e cara), o veredito real é o
**oposto exato** para T1: **1/10 REAL → FUNDADOR PURO** (≤3/10), mais nítido que o 3/3
fundador da própria nota 32. T2 recalculado dá **6/10 REAL → NÃO DECIDE** — cai na
mesma faixa que o script (com bug) reportou, mas as seeds individuais que compõem essa
contagem estão invertidas, e todas as 6 seeds "reais" favorecem `−2,0` (nunca `2,0`).
T3 não roda: nem T1 nem T2 confirmam pelo critério pré-registrado.

## 1. O bug pego antes de escrever: a fórmula de `wB` estava invertida

O script (commit `3937736`) classifica cada seed comparando o valor para o qual
`arrep_m` convergiu em duas montagens espelhadas (A: valor-alvo no papel par/residente;
B: os mesmos dois valores com os papéis trocados). A ideia (documentada em `ROADMAP.md`
e nas notas 30/32): se o **mesmo valor** vence nas duas montagens, é sinal real,
independente de quem nasceu par ou ímpar; se é a **mesma paridade** que vence nas duas
montagens (mudando de valor), é efeito fundador.

`mid` é o ponto médio exato entre os dois valores em disputa — o mesmo limiar
absoluto nas duas montagens. Como a simulação roda **sem mutação no traço**, cada
população final só pode conter os dois valores originais, e `arrep_m < mid` significa
literalmente "a maioria da população carrega o valor mais negativo", **em qualquer
montagem** — a fórmula que traduz `af` em "valor vencedor" não deveria mudar entre A e
B. O código commitado tinha:

```sh
wA=$(awk ... 'BEGIN{print (af<mid)?vr:vi}')   # A: par=vr, impar=vi -- correta
wB=$(awk ... 'BEGIN{print (af<mid)?vi:vr}')   # B: vi e vr trocados -- bug
```

`wB` deveria usar a **mesma fórmula** de `wA` (`vr` se `af<mid`, senão `vi`) — o valor
vencedor não depende de qual papel o carrega, só de para onde `arrep_m` convergiu. Com
a troca, o script comparava "quem venceu, rotulado pelo papel que tinha em cada
montagem" em vez de "qual valor venceu nas duas" — e como papel e valor se inverte
entre A e B por construção, a fórmula com bug produz o **rótulo exato oposto** do
correto sempre que o valor vencedor coincide entre as montagens (e vice-versa).

Conferido contra a convenção PAR/ÍMPAR que a nota 32 já usa à mão: pego a seed 2 de
T1. Montagem A (`−2,0` residente/par, `0,0` invasor/ímpar): `arrep_m` fixa em `−2,000`
— **PAR venceu**. Montagem B (`0,0` residente/par, `−2,0` invasor/ímpar): `arrep_m` vai
a `−0,090` (95,5% em `0,0`) — **PAR venceu de novo** (o papel par carrega `0,0` nesta
montagem, e é ele que domina). Pela definição da nota 30/32, "a mesma paridade venceu
as duas montagens" **é** a assinatura de efeito fundador — mas o script (com bug)
rotulou essa seed como `REAL (vencedor=-2.0)`. O fix (aplicado neste commit, uma linha)
faz `wB` usar a mesma fórmula de `wA`; recalculado à mão nos 20 valores já impressos
(§2/§3), toda seed que o script (com bug) chamou de REAL é, pela convenção PAR/ÍMPAR,
uma seed FUNDADOR — e vice-versa. A simulação em si está correta e não foi
re-executada (é determinística; só a aritmética pós-hoc mudou).

## 2. T1 corrigido — negativo (`−2,0`) × zero (`0,0`): fundador em 9 das 10 seeds

`arrep_m` (col. 24) em `t=30000`, e a fração da população presa em `−2,0` (o traço não
muta: só há dois valores possíveis na população final).

| seed | A: `−2,0` par / `0,0` ímpar → `arrep_m` (%`−2,0`) | B: `0,0` par / `−2,0` ímpar → `arrep_m` (%`−2,0`) | quem venceu as duas | classe |
|---|---|---|---|---|
| 1  | −0,026 (1,3%)  | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 2  | **−2,000 (100%)** | −0,090 (4,5%)  | PAR | FUNDADOR |
| 3  | −0,025 (1,3%)  | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 4  | **−2,000 (100%)** | −0,267 (13,4%) | PAR | FUNDADOR |
| 5  | −0,178 (8,9%)  | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 6  | −0,530 (26,5%) | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 7  | 0,000 (0,0%)   | **−1,994 (99,7%)** | ÍMPAR | FUNDADOR |
| 8  | **−2,000 (100%)** | −0,978 (48,9%) | PAR | FUNDADOR |
| 9  | −0,017 (0,9%)  | −0,644 (32,2%) | (0,0 vence as duas, papéis diferentes) | **REAL** |
| 10 | 0,000 (0,0%)   | **−2,000 (100%)** | ÍMPAR | FUNDADOR |

**T1: REAL = 1/10, FUNDADOR = 9/10 → FUNDADOR PURO (≤3/10).** Mais nítido que o 3/3
fundador da nota 32 (n=3): com o triplo de seeds, o padrão não se dilui, se confirma —
e a única seed "real" (9) favorece `0,0`, não `−2,0`, a direção **oposta** à hipótese
que Q5 (nota 30) levantou.

## 3. T2 corrigido — negativo (`−2,0`) × positivo (`2,0`): não decide, mas as 6 "reais" apontam todas para `−2,0`

| seed | A: `−2,0` par / `2,0` ímpar → `arrep_m` (%`−2,0`) | B: `2,0` par / `−2,0` ímpar → `arrep_m` (%`−2,0`) | quem venceu as duas | classe |
|---|---|---|---|---|
| 1  | 1,912 (2,2%)   | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 2  | **−2,000 (100%)** | **−2,000 (100%)** | (`−2,0` vence as duas) | **REAL** |
| 3  | −1,963 (99,1%) | **−2,000 (100%)** | (`−2,0` vence as duas) | **REAL** |
| 4  | **−2,000 (100%)** | **−2,000 (100%)** | (`−2,0` vence as duas) | **REAL** |
| 5  | 1,973 (0,7%)   | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 6  | −1,988 (99,7%) | **−2,000 (100%)** | (`−2,0` vence as duas) | **REAL** |
| 7  | 1,738 (6,6%)   | **−2,000 (100%)** | ÍMPAR | FUNDADOR |
| 8  | **−2,000 (100%)** | **−2,000 (100%)** | (`−2,0` vence as duas) | **REAL** |
| 9  | −1,955 (98,9%) | −1,887 (97,2%) | (`−2,0` vence as duas) | **REAL** |
| 10 | 2,000 (0,0%)   | **−2,000 (100%)** | ÍMPAR | FUNDADOR |

**T2: REAL = 6/10, FUNDADOR = 4/10 → NÃO DECIDE (4–6/10).** Cai na mesma faixa que o
script com bug reportou (que dizia 4/10 REAL) — mas por acidente aritmético, não
porque as seeds concordem: as 6 seeds que o script (com bug) chamava de FUNDADOR são
exatamente as 6 que a classificação corrigida chama de REAL, e vice-versa. Diferente
de T1, toda fixação aqui é limpa (nenhuma seed fica perto de 50%) — e as 6 seeds
"reais" **concordam** na direção: `−2,0` vence nas duas montagens em todas elas, nunca
`2,0`. É um sinal sub-limiar (6/10, abaixo do corte de confirmação de 7/10) que aponta
consistentemente para a direção que Q5 apostou — fraco demais para decidir, mas não
ruidoso na direção que aponta.

## 4. T3 não roda — critério de novo não atendido

O pré-registro (§4.6): T3 (condicional, `agencia` negativo × zero) só roda se T1 e/ou
T2 confirmarem (≥7/10). T1 corrigido é o oposto de confirmação (1/10); T2 fica em
6/10, abaixo do corte. T3 não roda — mesma conclusão da nota 32, agora sobre uma base
de 10 seeds em vez de 3.

## Ameaças à validade

- **T1 seed 8, montagem B, é quase um cara-ou-coroa** (48,9% em `−2,0`, contra o corte
  de 50% de `mid`): é a fixação menos limpa do painel inteiro. Se essa seed sozinha
  tivesse saído do outro lado do limiar, T1 seria 2/10 REAL em vez de 1/10 — ainda
  solidamente FUNDADOR PURO (≤3/10), mas vale registrar que a margem ali é fina, não
  uma fixação de ~100% como a maioria das outras 9 linhas.
- **O bug ficou em código nunca executado antes desta nota**: o script de `3937736`
  foi commitado (junto com o pré-registro) mas a lógica de classificação automática
  era nova — não existia versão equivalente nas notas 30/32 (que classificaram à mão,
  linha por linha). Nada no processo de commit rodou o script antes de commitá-lo;
  o bug só apareceu ao processar a saída real. Não foi possível pré-registrar "o
  script está correto" porque isso não é uma afirmação sobre o mundo simulado, é sobre
  a aritmética — mas o precedente do projeto ("recompute antes de escrever ✅", nota 09
  §5) generaliza: uma régua nova (mesmo que seja só um script de classificação)
  precisa ser conferida contra um caso já conhecido antes de decidir um veredito que
  reverte uma leitura anterior.
- **As mesmas ameaças estruturais das notas 30/32**: `n_blocos % 2` não é um sorteio
  espacialmente independente; população finita (~300 blocos) e 30 000 ticks podem não
  dar tempo para uma vantagem real pequena vencer o efeito fundador numa corrida sem
  mutação — Q5 (nota 30) mede um regime diferente (deriva sob mutação livre, muitas
  gerações), que T1/T2 não replicam.

## O que ficou em aberto

T1 fecha de forma muito mais decisiva que a nota 32 deixou (fundador puro, 9/10, e a
única exceção vai na direção errada para Q5). T2 continua sem decidir — 6/10 é o mais
perto que este desenho chegou de confirmar em qualquer uma das duas rodadas (nota 32:
2/3; esta nota: 6/10), com as seis seeds "reais" concordando de forma limpa na direção
`−2,0`. Um painel maior (20+ seeds, mesmo remédio que já dobrou a amostra uma vez) ou
uma população maior (a outra sugestão que a nota 32 deixou, ainda não construída)
poderia separar esse sinal sub-limiar de ruído — não construído aqui.
