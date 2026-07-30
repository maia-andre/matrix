# Nota 31 — O custo da escuta: a desconfiança se espalha mais do que eu previ, e a seleção do início misto é o sinal mais limpo

**Data:** 2026-07-29
**Pré-registro:** `ROADMAP.md` §4.4, commit `694e05a` — **antes** de rodar.
**Construído em:** este commit (o mecanismo, permanente em `main.c`, + a nota).
**Serve ao:** fecha o fio que a nota 29 deixou aberto — `escuta` ganha a
primeira consequência real, diferenciando as três arquiteturas por
comportamento, não só pelo mostrador `relato`.
**Reproduzir:** `sh papers/notes/31-custo-da-escuta.sh` (~15 min)

---

## Resumo

A nota 29 instalou `escuta` sem nenhum custo, de propósito, e confirmou deriva
neutra. Esta nota liga o mecanismo que ficou como "próximo pré-registro
natural": um bloco com `escuta == ESC_MONITOR` passa a descontar o sinal de
vizinhos que ele viu sendo repetidamente **negados** por `resolver()` — um
sinal que nunca se confirma custa oportunidade real, não evita disputa real.
As cinco predições (R1–R5) rodaram. R1 confirmou limpo (instalação inócua
para quem não é `ESC_MONITOR`). R2 confirmou a direção mas **errou a
magnitude** — a desconfiança alcança bem mais interações do que a taxa de
negados sugeriria, por causa do próprio decaimento lento. R3 (descontar ajuda,
isolado) ficou **misto**, sem vencedor consistente. R4 (invasão direta) deu um
placar bruto de 4/6 a favor de `ESC_MONITOR`, mas só 1 das 3 seeds está livre
da assinatura de efeito fundador que a nota 30 já tinha documentado no mesmo
desenho. **R5 é o sinal mais limpo desta nota**: partindo de uma população
mista, `esc_monitor_f` sobe de forma consistente e substancial nas três
seeds — o oposto exato da deriva neutra que a nota 29 mediu sem o mecanismo.

## 1. O mecanismo instalado

`pretendentes_em()` contava, sem distinção, quantos vizinhos sinalizaram a
mesma célula — cada um desvaloriza via `ANTECIPACAO`, igual para todos.
`atualizar_remorso()` já calculava, tick a tick, se **qualquer** bloco (não só
o próprio) foi negado por `resolver()` — só faltava expor esse booleano
(`negado_tick[]`). Um bloco com `escuta == ESC_MONITOR` agora acumula, por
vizinho **atualmente visível** (`desconfianca[i][j]`, decaindo pelo próprio
desconto de `i` — o mesmo idioma de `remorso[]`), quantas vezes aquele vizinho
específico foi negado recentemente; `pretendentes_em`, só para quem tem
`ESC_MONITOR`, pesa cada sinal concorrente por `1/(1+desconfianca[i][j])` em
vez de contar 1 cheio. `ESC_ACAO`/`ESC_PLANO` continuam contando cheio,
comportamento de hoje, sem mudança nenhuma — é a primeira vez que as três
arquiteturas diferem por **comportamento**. Sem multa artificial: o "custo"
de não ser `ESC_MONITOR` é só a oportunidade perdida de descontar sinais que
a experiência local já desmentiu.

## 2. O placar do pré-registro

| pred. | resultado |
|---|---|
| **R1** instalação inócua (`ESC_ACAO`/`ESC_PLANO` puros) | ✅ bit-a-bit, 3 seeds cada |
| **R2** a desconfiança se acumula, rara-mas-real | ⚠️ acontece — mas bem **mais** que "rara": ver §3 |
| **R3** descontar ajuda, isolado | ~ misto, sem direção consistente — ver §4 |
| **R4** invasão direta | ~ 4/6 a favor de `ESC_MONITOR`, confundido por efeito fundador — ver §5 |
| **R5** deriva do início misto, mecanismo ligado | ✅ **e é o sinal mais limpo da nota** — ver §6 |

## 3. R1 — instalação inócua, confirmada nas duas arquiteturas que não mudam

Com toda a população fixada em `ESC_ACAO` (consumindo o mesmo `rng01()` de
sempre, só descartando o valor — a mesma técnica que a nota 29 usou para P1)
e o mesmo teste repetido para `ESC_PLANO`, o CSV `--log` de 3000 ticks sai
**bit a bit idêntico** ao `main.c` de antes deste mecanismo (`694e05a`), nas
três seeds, nas duas arquiteturas. `desconfianca[]` nunca é lida nem escrita
quando ninguém é `ESC_MONITOR` — a mudança é estruturalmente inócua para 2/3
das arquiteturas possíveis, exatamente como o R1 previu.

## 4. R2 — a desconfiança não é rara: o decaimento lento a espalha bem além do evento que a gera

Numa população 100% `ESC_MONITOR`, a fração de visitas vizinho-atual em que
`desconfianca[i][j]` já está acima de zero:

| seed | pares com desconfiança>0 | taxa de negados (mesma corrida) |
|---|---|---|
| 7 | 53,16% | 7,99% |
| 42 | 58,49% | 11,05% |
| 1234 | 57,59% | 9,80% |

O pré-registro apostou que essa fração ficaria "na mesma ordem de grandeza"
da taxa de negados (~8–11%) — **errou por um fator de 5–6×**. A explicação é
o próprio desenho do decaimento: `desconfianca[i][j] = desconfianca[i][j] *
desconto + sinal`, com `desconto` tipicamente entre 0,7 e 0,9, significa que
um único evento de negação leva **dezenas a poucas centenas de ticks** para
decair de volta a um valor desprezível (a mesma cauda longa que `remorso[]`
já carrega). Um evento raro (~9% dos ticks-de-bloco) deixa um rastro que
cobre muito mais tempo do que o próprio evento — a desconfiança de um
`ESC_MONITOR` típico não está medindo "isto está acontecendo agora", está
medindo "isto aconteceu recentemente o bastante para ainda importar", e
"recentemente" aqui é um intervalo bem mais largo do que a taxa do evento
sozinha sugere.

## 5. R3 — descontar ajuda, isolado? O resultado não decide

`ESC_MONITOR` × `ESC_ACAO`, populações homogêneas, mesma seed, 3000 ticks
(tick > 500):

| seed | negado% (MONITOR) | negado% (ACAO) | Δ | pop (MONITOR) | pop (ACAO) | Δ | energia (MONITOR) | energia (ACAO) | Δ |
|---|---|---|---|---|---|---|---|---|---|
| 7 | 7,99 | 8,76 | **−0,77** | 315,65 | 314,73 | +0,92 | 6,139 | 6,044 | +0,095 |
| 42 | 11,05 | 8,65 | **+2,40** | 286,32 | 284,90 | +1,41 | 6,125 | 6,195 | −0,070 |
| 1234 | 9,80 | 9,70 | +0,10 | 272,45 | 271,74 | +0,71 | 6,362 | 6,246 | +0,116 |

A taxa de negados **não** cai de forma consistente para `ESC_MONITOR` — cai
na seed 7, sobe visivelmente na seed 42, fica praticamente igual na seed
1234. A população fica **marginalmente** maior para `ESC_MONITOR` nas três
seeds (+0,3% a +0,5%), e a energia sobe em duas e cai numa — margens pequenas
demais, numa única corrida por condição, para separar de ruído de
amostragem. R3 não confirma nem refuta a hipótese de que descontar ajuda;
fica exatamente no "quase neutro" que a nota 30 também mediu para Q3.

## 6. R4 — a invasão direta dá 4/6, mas o efeito fundador (o mesmo da nota 30) contamina 2 das 3 seeds

50/50 `ESC_MONITOR` × `ESC_ACAO`, sem mutação em `escuta`, duas montagens
espelhadas por paridade de índice, 30 000 ticks:

| seed | `ESC_MONITOR` residente (par) | `ESC_MONITOR` invasor (ímpar) | quem venceu nas DUAS montagens |
|---|---|---|---|
| 7 | 0,500 → **1,000** | 0,500 → **1,000** | `ESC_MONITOR`, **independente de paridade** |
| 42 | 0,500 → **1,000** | 0,500 → 0,141 | quem nasceu **par** venceu as duas (efeito fundador) |
| 1234 | 0,500 → 0,159 | 0,500 → **1,000** | quem nasceu **ímpar** venceu as duas (efeito fundador) |

Placar bruto: `ESC_MONITOR` venceu 4 das 6 corridas — mais que o empate 3×3
que a nota 30 (Q4) mediu para `peso_arrependimento` positivo × zero, mas
longe de um veredito limpo. Aplicando o mesmo diagnóstico que a nota 30 usou
(qual paridade venceu nas duas montagens espelhadas): só a **seed 7** mostra
`ESC_MONITOR` vencendo **independente** de qual paridade ele ocupa — a
assinatura de uma vantagem real do traço. Nas seeds 42 e 1234, é sempre a
mesma paridade de índice que vence, trocando de identidade (`ESC_MONITOR` ou
`ESC_ACAO`) entre as duas montagens — a assinatura exata de **deriva com
efeito fundador** que a nota 30 já descreveu para o mesmo harness: a metade
do espaço que por acaso começou vizinha de um recurso melhor prospera, não
importa qual traço ela carregava. R4, sozinho, não decide — 1 seed em 3 é
pouco para separar sinal de deriva.

## 7. R5 — o sinal mais limpo: da mistura, a seleção converge para `ESC_MONITOR`

Semeando `escuta` em terços com mutação (o desenho exato do P4 da nota 29,
agora com o mecanismo ligado), 30 000 ticks, três seeds:

| seed | `esc_monitor_f` início | `esc_monitor_f` fim | população (início→fim) |
|---|---|---|---|
| 7 | 0,400 | **0,805** | 60 → 313 |
| 42 | 0,333 | **0,764** | 60 → 288 |
| 1234 | 0,383 | **0,768** | 60 → 271 |

As três seeds sobem, de forma consistente e substancial (mais que o dobro do
valor inicial em todas), para uma maioria de `ESC_MONITOR` — o oposto exato
da nota 29 (P4), que mediu essa mesma fração **sem** direção comum entre
seeds (deriva neutra confirmada, sem o mecanismo). É o mesmo padrão que a
nota 30 encontrou em Q5: quando R3/R4 (as comparações isoladas/pareadas)
davam resultado ambíguo, a deriva a partir de uma população diversa foi o
teste que revelou a direção real da seleção — aqui, a favor de `ESC_MONITOR`.

## Ameaças à validade

- **R2 mede uma mistura que esta nota não separa.** A fração alta de pares
  com `desconfianca > 0` pode refletir tanto memória genuína recente (um
  vizinho negado há poucas dezenas de ticks) quanto ruído de índice reciclado
  (a coluna `j` da matriz não é limpa quando o slot troca de dono — declarado
  no pré-registro, §4.4). Não há, nesta nota, instrumentação para separar as
  duas fontes; a magnitude real do primeiro componente pode ser menor que
  53–58%.
- **R3/R4 usam uma única corrida por condição/seed** (como toda a série de
  invasão deste projeto) — o diagnóstico de efeito fundador em R4 é o mesmo
  método da nota 30, não uma prova adicional, e depende de só 3 seeds.
- **R4 e R5 parecem discordar, mas medem coisas diferentes.** R4 testa se
  `ESC_MONITOR` desloca `ESC_ACAO` numa disputa **direta**, par a par; R5
  mede se a seleção, a partir de uma mistura de três estratégias (incluindo
  `ESC_PLANO`, ausente em R4), favorece `ESC_MONITOR` **em média**. R5 sendo
  o sinal mais limpo não invalida a contaminação por deriva que R4 expôs —
  os dois achados podem conviver se a vantagem de `ESC_MONITOR` for real mas
  pequena o bastante para o efeito fundador dominar em corridas curtas
  (30 000 ticks, população ~300) enquanto ainda desloca a média ao longo de
  muitas rodadas de mutação/seleção.
- **3 seeds**, como sempre — mas R5 é a predição com o sinal mais limpo desta
  nota (mesma direção, magnitude parecida, nas três), o padrão que a nota 30
  também usou para declarar Q5 como o achado central quando Q3/Q4 saíram
  mistas.

## O que ficou em aberto

Separar, em R2, quanto da desconfiança observada vem de memória genuína
contra quanto vem de índice reciclado — precisaria de uma instrumentação que
rastreie identidade além do índice (não trivial neste projeto, onde blocos
não têm um "nome" além do slot). E, se o André quiser fechar R4/R5 com mais
força: repetir a invasão direta com mais seeds (a nota 30 deixou o mesmo
convite em aberto para `peso_arrependimento`), ou medir se populações com
`ESC_MONITOR` dominante (o resultado de R5) mostram menos energia perdida em
disputas que nunca se confirmam — o efeito que R3, isolado, não conseguiu
separar do ruído.
