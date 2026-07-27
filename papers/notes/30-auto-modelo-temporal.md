# Nota 30 — O auto-modelo temporal: o contrafactual é real, e a seleção não vai para onde eu apostei

**Data:** 2026-07-27
**Pré-registro:** `ROADMAP.md` §4.3, commit `4df4da4` — **antes** de rodar.
**Construído em:** (este commit — a nota e o código juntos).
**Serve ao:** `FILOSOFIA_v3.md` §4 (fecha o segundo `⛔` interno: a faculdade
está instalada e tem consequência real — só não na direção que o
pré-registro apostou); Paper 2 (vida artificial — mais um traço de nível 6).
**Reproduzir:** `sh papers/notes/30-auto-modelo-temporal.sh` (~35 min)

---

## Resumo

A v3 §4 nomeou a faculdade que falta: memória da própria trajetória, o
substrato para "eu poderia ter ido para a esquerda". Esta nota instala essa
faculdade — não como mostrador, como **mecanismo**: um bloco negado por
`resolver()` cuja vice-célula (a segunda melhor da própria varredura de
`melhor_celula`) ninguém disputou tem um contrafactual **verificável**, não
especulativo. `remorso[]` acumula esse sinal e decai pelo desconto do
próprio bloco; o traço herdável `peso_arrependimento` decide se ele volta a
pesar em `utilidade()`. As cinco predições (Q1–Q5) rodaram. Q1/Q2
confirmaram limpo. Q3/Q4 — o par que testava se **aprender ajuda** —
deram um resultado **quase neutro**, sem vencedor consistente. E Q5, que só
devia confirmar a direção de Q3/Q4, revelou a direção *de verdade*: a
seleção, a partir de um início diverso, empurra o traço para o lado
**negativo** — nas três seeds, consistente — não para o positivo que o
mecanismo foi desenhado para recompensar.

## 1. O mecanismo instalado

`decidir()` já escolhia a melhor célula por uma varredura de `utilidade()`.
Passou a guardar também a **vice-célula** — a segunda melhor da mesma
varredura, sem custo extra — em `vice_x[i]/vice_y[i]`, e a fotografar o
próprio alvo decidido em `decidido_x[i]/decidido_y[i]` antes que
`resolver()` pudesse negá-lo. Logo depois de `resolver()` (nova função
`atualizar_remorso()`, lendo `reivindicado[][]` antes que o próximo tick o
zere):

- Um bloco foi **negado** se queria mover (`decidido_* != posição atual`) e
  `alvo_*` voltou a ser a posição atual.
- Se a vice-célula ficou com `reivindicado == -1` (**ninguém a
  reivindicou**), o contrafactual é verificável: ele podia mesmo ter ido
  para lá.
- O **arrependimento** do tick é `prever_valor(vice) − prever_valor(posição
  final)`, quando positivo. `remorso[i]` acumula esse sinal e decai pelo
  próprio `desconto` do bloco — a mesma curva que `peso_janela` usa na
  bateria do `modelo`.
- `utilidade()` ganha um termo: `peso_arrependimento · remorso[i] ·
  espaço` — o traço herdável (nível 6, semeado em `[-2, 2]` com folga,
  mutação `muta_traco`) decide **quanto**, e em que **direção**, o remorso
  pesa.

## 2. O placar do pré-registro

| pred. | resultado |
|---|---|
| **Q1** ablação natural (traço = 0, sem RNG) | ✅ bit-a-bit, 23 colunas, 3 seeds |
| **Q2** o remorso acontece, raro-mas-real | ✅ mesma ordem de grandeza dos negados |
| **Q3** aprender ajuda? | ~ quase neutro — ver §3 |
| **Q4** invasão 2,0 × 0,0 | ~ sem vencedor, 3×3 no placar — ver §3 |
| **Q5** deriva do diverso | ✅ **e a direção surpreende** — ver §4 |

**Q1.** `peso_arrependimento = 0` para toda a população, sem consumir
`rng01()` nenhum, contra o `main.c` de antes do mecanismo existir (o commit
da escuta, `4927e08`): as 23 colunas saem bit-a-bit idênticas nas três
seeds. O termo novo em `utilidade()` é `0 · remorso · espaço`, e zero vezes
qualquer finito é zero exato em IEEE754 — a demonstração algébrica bateu
com o dado.

**Q2.** Contando cada tick-de-bloco na população livre (canônica, três
seeds, 3000 ticks):

| seed | negado | vice livre (do total) | regret (do total) |
|---|---|---|---|
| 7 | 8,76% | 6,89% | 5,46% |
| 42 | 8,65% | 6,88% | 4,19% |
| 1234 | 9,70% | 7,21% | 5,02% |

A taxa de negados (8,7–9,7%) é mais alta que o ~6% que a nota 06 cita — são
regimes diferentes (a nota 06 mede numa população já estabilizada; aqui a
janela de 3000 ticks inclui a fase de crescimento inicial, mais densa). A
taxa de **regret** de fato (4,2–5,5% do total de decisões) é um
**subconjunto** da de negados, como tinha que ser — e fica na mesma ordem
de grandeza. Nem todo negado gera regret: só ~75–80% deles têm vice
desocupada, e desses, a maioria (mas não todos) tem valor previsto positivo
para a vice.

## 3. Q3/Q4 — aprender (no sentido literal, "buscar mais espaço") não ajuda nem atrapalha de forma consistente

**Q3** (peso fixo 2,0 × fixo 0,0, mesma seed, mutação do traço desligada,
3000 ticks):

| seed | Δ negado% (2,0 − 0,0) | Δ pop (2,0 − 0,0) | Δ energia (2,0 − 0,0) |
|---|---|---|---|
| 7 | −1,26 | +0,05 | **−0,10** |
| 42 | +1,09 | +0,55 | **−0,35** |
| 1234 | −1,33 | +0,77 | **−0,06** |

A taxa de negados **cai** com o traço positivo em 2 das 3 seeds, como a
predição Q3 apostou — mas sobe na seed 42. A população não se move fora do
ruído. E a **energia** é consistentemente **menor** com o traço positivo,
nas três seeds — pequeno, mas sem exceção. O risco que o pré-registro
declarou em voz alta se confirmou: "reforçar `peso_espaco` de forma cega
prejudica quem não estava mesmo perto de uma disputa" — o desconto continua
carregando o remorso por vários ticks depois do evento, então o viés
persiste para decisões que não têm nada a ver com a disputa que o gerou.

**Q4** (invasão 50/50, mutação do traço desligada, 30 000 ticks, duas
montagens espelhadas — qual valor nasce nos índices pares):

| seed | 2,0 par / 0,0 ímpar | 0,0 par / 2,0 ímpar |
|---|---|---|
| 7 | 0,0 vence | 2,0 vence |
| 42 | 2,0 vence | 0,0 vence |
| 1234 | 0,0 vence | 2,0 vence |

Seis corridas, três vitórias para cada valor — **placar exato de 3×3**. E o
padrão por seed é revelador: nas seeds 7 e 1234, quem quer que tenha
nascido nos índices **ímpares** venceu nas duas montagens; na seed 42,
quem nasceu nos **pares** venceu nas duas. Índice de nascimento não
carrega vantagem estrutural neste projeto além do desempate de
`resolver()` (CLAUDE.md), e a reciclagem de slots em `alocar_slot()`
dissolve a correlação índice↔linhagem em poucas centenas de ticks — o
padrão não é um artefato de paridade, é a assinatura de **deriva com
efeito fundador**: a metade do espaço que por acaso começou com um valor
prosperou ou não por causa da vizinhança local, não do valor em si. Nem
2,0 nem 0,0 é ESS um contra o outro.

## 4. Q5 — a direção real, e ela não é a que o desenho apostava

Semeando `peso_arrependimento` livre em `[−2, 2]` com mutação **ligada**,
30 000 ticks, três seeds:

| seed | `arrep_m` início | `arrep_m` fim | população |
|---|---|---|---|
| 7 | −0,201 | **−1,406** | 60 → 320 |
| 42 | −0,270 | **−2,147** | 60 → 286 |
| 1234 | −0,080 | **−1,391** | 60 → 270 |

As três seeds começam perto de zero (a semeadura é simétrica; a leitura em
t=0 é ruído de amostragem de 60 blocos) e terminam **consistentemente
negativas** — entre um terço e mais da metade do caminho até o piso da
mutação (`−6`). Isto não é o que Q3/Q4 foram desenhadas para testar: elas
compararam positivo × zero, porque a intuição de projeto (§4.3 do
pré-registro) era que "aprender" significa reforçar a fuga do espaço
disputado. A régua discorda. Um `peso_arrependimento` **negativo** inverte
o termo: quando `remorso` é alto, a célula com mais espaço livre fica
**menos** atraente, não mais — o bloco, depois de ser barrado, passa a
valorizar a comida concreta da vizinhança em vez de perseguir espaço
aberto. Uma hipótese mecânica, não comprovada por esta nota: se as
disputas acontecem sobretudo em células **ricas** (a mesma geometria que a
`FILOSOFIA_v3` §5 já registrou — "as brigas acontecem onde todo mundo
entende o porquê"), um bloco que aprende a *não* fugir da lotação depois de
perder uma disputa continua competindo pelo recurso que valia a disputa,
em vez de se deslocar para uma célula pobre só porque está vazia. Reforçar
a fuga (o desenho positivo, Q3) tem o custo de energia que a tabela acima
mediu; reforçar a permanência (o oposto) parece pagar mais — o suficiente
para a seleção convergir para lá em três seeds independentes, um sinal bem
mais forte que qualquer coisa que Q3/Q4 produziram na região que elas
testaram.

## Ameaças à validade

- **Q3/Q4 testaram a região errada do traço.** A predição original apostava
  que positivo ajudaria; a régua mostra que a seleção vai para negativo.
  Uma invasão direta negativo × zero (ou negativo × positivo) fecharia o
  argumento com o mesmo rigor de Q4 — não rodada aqui, é o item natural em
  aberto.
- **A hipótese mecânica do §4 é pós-hoc e não testada diretamente** — não
  há, nesta nota, uma medida de "as disputas concentram-se em células
  ricas" cruzada com o sinal de `remorso`. A `FILOSOFIA_v3` §5 já mediu
  esse padrão para outro mecanismo (a calibração de `modelo_do_outro` nos
  negados); a hipótese aqui só empresta a analogia.
- **3 seeds**, como sempre — mas Q5 é a predição com o sinal mais limpo
  desta nota (mesma direção, ordem de grandeza parecida, nas três), o
  oposto do padrão ruidoso de Q3/Q4.
- **`n_blocos % 2` como sorteio de residente/invasor em Q4** não é um
  sorteio independente da posição espacial (o índice é a ordem de
  semeadura, que segue a busca aleatória de `semear_blocos`) — mas o placar
  3×3 exato, com o padrão de "quem nasceu em tal paridade venceu as duas
  montagens" variando por seed, é evidência **contra** um viés estrutural
  fixo, não a favor de um.

## O que ficou em aberto

Fechar o argumento de Q5 com uma invasão de verdade — negativo (digamos,
`−2,0`) contra zero, e negativo contra o positivo que Q3/Q4 já testaram —
para confirmar que o lado para onde a seleção converge também **vence** em
competição direta, não só domina a média de uma população em mutação
livre (que pode refletir taxa de mutação assimétrica perto das bordas do
domínio, não seleção). E, se isso se confirmar, vale medir se blocos com
`peso_arrependimento` muito negativo mostram menos `agencia` (parar de
responder ao espaço é, por definição, aproximar-se do reflexo que a nota
03 já documentou matando a agência por outro caminho).
