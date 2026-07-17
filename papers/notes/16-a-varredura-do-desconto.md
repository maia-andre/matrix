# Nota 16 — A varredura do desconto: o joelho anda, a transição não, e em δ = 0,95 a escada inverte

**Data:** 2026-07-16
**`main.c`:** o de `079a3ce` (canônico intocado; a variante `desc` é o patch da
nota 14 com **uma** mudança — o desconto pregado vem do ambiente).
**Pré-registro:** cabeçalho de `papers/notes/16-desconto.sh`, commitado em
`4526cb1` — **antes** de rodar (P0/P1/P2/P3).
**Serve ao:** Paper 2 ("Cognição como bem posicional") — e o serviço que presta é
**derrubar o mecanismo central que a nota 14 lhe tinha dado**. Agregados em
`datasets/desconto.csv`.
**Reproduzir:** `sh papers/notes/16-desconto.sh` (~46 min com `NPROC=16`)

---

## Resumo

A nota 14 mediu a margem do horizonte saturando em `h ≈ 5` e leu isso como o teto
da profundidade efetiva `min(h, 1/(1−δ))`: com o desconto pregado em 0,80,
`1/(1−0,80) = 5`. A nota 15 cobrou o imposto por essa mesma grandeza. **A
profundidade efetiva costura o Paper 2 inteiro — e tinha sido medida num δ só.**
A própria nota 14 abriu as "Ameaças à validade" com isso: *"o joelho em h ≈ 5 é
artefato do 0,80"*.

Era. Esta nota varre `δ ∈ {0,30; 0,50; 0,80; 0,90; 0,95}` (teto = 1,43 / 2 / 5 /
10 / 20), 15 pares × 8 seeds × 6000 ticks, 600 corridas, 0 extinções.

**O placar: P0 ✅, e três das quatro predições substantivas falharam.**

| # | predição (escrita antes) | resultado |
|---|---|---|
| **P0** | a fatia δ=0,80 reproduz `datasets/torneio.csv` linha a linha | ✅ **120/120 idênticas** — o patch não mexeu no mundo |
| **P1** | o joelho segue `1/(1−δ)`; em δ=0,30 escada plana de h=2; em δ=0,95 **não satura** na faixa | ⚠️ **meio certo**: o joelho **anda** com δ (h≈2 → 3 → 7 → 9)... e aí **quebra**: em δ=0,95 ele **volta** para h≈6 e a escada **INVERTE** |
| **P2** | a transição fix→polim segue `1/(1−δ) − 1` | ❌ **falhou**: a transição é **h=4** em δ ∈ {0,50; 0,80; 0,90; 0,95} — **não anda** enquanto o teto vai de 2 a 20 |
| **P3** | a dominância persiste em todo δ; platô em δ=0,30; freq ≈1,0 em δ=0,95 | ⚠️ **meio**: o platô em δ=0,30 ✅ (a T1 da nota 14 redimida no δ certo); a dominância ❌ — em δ=0,95 o **h=9 vence o h=12** com t = −11,2 |

**A manchete: o "ESS = teto" da nota 14 é artefato do δ = 0,80.** Em δ = 0,95 há
um **ESS interior** — o h=12 perde para o h=9 e para o h=6. E a nota 14 fundiu
**duas escalas** que só coincidem em 0,80: uma que anda com o desconto (o joelho)
e uma que não anda (a transição).

## 1. P0 — a âncora segurou

O patch desta nota é o da nota 14 com uma linha diferente: `b->desconto` vem de
`TORN_DESC` (ambiente) em vez do `#define`. Como `TORN_DESC` cai por padrão em
`DESCONTO` e `(float)atof("0.80")` é exatamente `0.80f`, a fatia δ=0,80 tem de ser
o binário da nota 14. É: **120 de 120 linhas idênticas** a `datasets/torneio.csv`
— `freq_hj`, `hor_m_fim`, `pop_fim` e `fixou`, campo a campo, nos 15 pares × 8
seeds. Nada abaixo é artefato de patch.

## 2. P1/P2 — as duas escalas que a nota 14 fundiu

A escada (margem = freq do horizonte `h+1` contra o `h`; `t = (f − 0,5)/se`, 8
seeds; **fix** = seeds em que o fundo levou o raso à extinção):

| `h→h+1` | δ=0,30 (teto 1,4) | δ=0,50 (teto 2) | δ=0,80 (teto 5) | δ=0,90 (teto 10) | δ=0,95 (teto 20) |
|---|---|---|---|---|---|
| 1→2 | 0,969 `t+15` | 1,000 | 1,000 | 1,000 | 1,000 |
| 2→3 | 0,799 `t+4,1` | 0,935 `t+11` | 0,995 `t+156` | 0,999 `t+459` | 0,997 `t+162` |
| 3→4 | 0,572 ~ | 0,844 `t+7,1` | 0,949 `t+20` | 0,932 `t+19` | 0,913 `t+13` |
| 4→5 | 0,644 ~ | 0,665 ~ | 0,836 `t+10` | 0,768 `t+6,6` | 0,713 `t+4,9` |
| 5→6 | 0,685 `t+2,4` | 0,580 ~ | 0,766 `t+6,9` | 0,627 `t+4,5` | 0,633 `t+4,3` |
| 6→7 | 0,527 ~ | 0,609 ~ | 0,628 `t+2,9` | 0,567 `t+2,7` | 0,551 `t+2,6` |
| 7→8 | 0,449 ~ | 0,490 ~ | 0,630 `t+3,1` | 0,598 `t+4,1` | 0,512 ~ |
| 8→9 | 0,567 ~ | 0,580 ~ | 0,565 ~ | 0,528 `t+2,7` | 0,449 ~ |
| 9→10 | 0,483 ~ | 0,477 ~ | 0,529 ~ | 0,529 `t+2,2` | **0,344 `t−5,5`** |
| 10→11 | 0,451 ~ | 0,599 ~ | 0,523 ~ | 0,479 ~ | **0,240 `t−13`** |
| 11→12 | 0,498 ~ | 0,484 ~ | 0,560 ~ | 0,455 ~ | **0,202 `t−14`** |
| **último degrau significativo** | **h=2** | **h=3** | **h=7** | **h=9** | **h=6**, depois inverte |
| **transição fix→polim** | (h=6, ruidosa) | **h=4** | **h=4** | **h=4** | **h=4** |

**O joelho anda — e a nota 14 estava certa nisso, para δ ≤ 0,90.** O último degrau
com vantagem significativa vai de h≈2 (teto 1,4) a h≈3 (teto 2), h≈7 (teto 5) e
h≈9 (teto 10). A ordem é a prevista e a censura aparece onde devia: em δ=0,30 e
δ=0,50, os degraus de baixo já vêm enfraquecidos (0,799 e 0,935 no 2→3, contra
0,995–0,999 nos δ altos) porque o teto já os alcançou. **P1, para δ ≤ 0,90,
confirmada.**

**A transição não anda — e essa é a refutação.** A leitura pré-registrada (o menor
`h` com 0/8 fixações, a definição operacional que a própria nota 14 usou, sem
limiar novo) dá **h=4 para δ = 0,50; 0,80; 0,90 e 0,95**, enquanto o teto do
desconto vai de **2 a 20**. As colunas de fixação nos três δ altos são limpas e
praticamente idênticas — `8 7 4 0 0 0…`, `8 8 1 0 0 0…`, `8 7 1 0 0 0…`. A
nota 14 §3 leu essa transição como caindo "exatamente no teto do desconto
(profundidade efetiva 5)". **Não cai: ela fica onde está enquanto o teto
quadruplica.** A coincidência com o 5 era coincidência.

São **duas escalas diferentes**, e o δ=0,80 as pôs perto o bastante para
parecerem uma. A transição fixação→polimorfismo é governada pelo *topo* da escada
(onde o incremento relativo de profundidade é grande: 1→2 dobra, 3→4 acrescenta
33%, 11→12 acrescenta 9%) — e isso não depende do desconto. O joelho da margem é
governado pelo *fundo* da escada, onde o desconto tem toda a alavanca.

*(Ressalva honesta: em δ=0,30 a definição operacional quebra. A coluna de fixação
é `7 2 2 1 1 0 1 1 1 1 1` — não-monótona, com 1/8 esparso até o topo — então "o
menor h com 0/8" devolve 6 por ruído, não por estrutura. Ali a transição efetiva
é h≈2. O readout pré-registrado é frágil quando a fixação é rara e esparsa; fica
registrado como frágil.)*

## 3. O achado não orçado: em δ = 0,95 a escada inverte

Os três últimos degraus de δ=0,95 são **0,344**, **0,240** e **0,202**, com
`t = −5,5`, `−13` e `−14`. Não é empate, não é deriva: **o horizonte mais raso
vence, e vence feio.**

Os duelos de longo alcance — uma medição independente, com pares não-adjacentes —
concordam:

| δ | h=1 vs 12 | h=3 vs 12 | h=6 vs 12 | h=9 vs 12 |
|---|---|---|---|---|
| 0,30 | 1,000 | 0,550 ~ | 0,455 ~ | 0,548 ~ |
| 0,50 | 1,000 | 0,951 `t+37` | 0,644 ~ | 0,491 ~ |
| 0,80 | 1,000 | 0,936 `t+18` | 0,734 `t+7,0` | 0,603 `t+3,0` |
| 0,90 | 0,956 `t+41` | 0,732 `t+8,3` | 0,522 ~ | 0,468 ~ |
| 0,95 | 0,859 `t+23` | 0,629 `t+4,6` | **0,387 `t−4,4`** | **0,200 `t−11`** |

*(freq do h=12; `~` = |t| < 2)*

Em δ=0,95 o h=12 ainda esmaga o h=1 (0,859) e bate o h=3 (0,629) — mas **perde
para o h=6 e é destroçado pelo h=9**. Isso é um **ESS interior**, em algum lugar
entre 7 e 9: nem o raso nem o teto. A escada e os duelos longos, medidos por pares
independentes, apontam para o mesmo lugar.

E o ótimo **desce conforme o δ sobe**:

| δ | onde está o ótimo |
|---|---|
| 0,80 | ≥ 12 (o teto — o resultado da nota 14) |
| 0,90 | ~10–12 (o 12 já empata com o 9; `t = −1,2`) |
| 0,95 | ~7–8 (o 9 bate o 12 com `t = −11`) |

**Mais paciência ⇒ horizonte ótimo mais raso.** É o contrário da intuição que
gerou o pré-registro, e é o resultado mais forte do lote.

## 4. A leitura — e o teste que a decide

O `1/(1−δ)` prevê que o joelho sobe para sempre. Ele sobe até δ≈0,90 e então **o
ótimo volta**. A fórmula do teto é, portanto, uma **aproximação de δ baixo**: ela
descreve quando a profundidade extra é *invisível*, e não sabe dizer quando ela é
*nociva*.

A interpretação que ofereço — **e ela é interpretação, não medição** — é que o
desconto não é o *regulador do valor posicional* do horizonte (a leitura da nota
14). Ele é um **regularizador**. `prever_valor` simula a trajetória do próprio
bloco `h` ticks à frente, e o erro dessa simulação cresce com a profundidade: os
vizinhos se movem, a comida rebrota, o caminho é bloqueado. O peso que a cauda
(errada) recebe é `δᵏ`:

- em δ=0,80, `0,8¹¹ ≈ 0,09` — a cauda ruidosa é descontada até a irrelevância. A
  profundidade extra é **inofensiva e inútil**, e é *por isso* que a nota 14 viu
  "ESS = teto" com margens de 0,52–0,56: nada segura a corrida porque nada a
  penaliza, não porque a profundidade pague.
- em δ=0,95, `0,95¹¹ ≈ 0,57` — a cauda ruidosa entra com mais da metade do peso.
  A profundidade extra **importa ruído para a decisão**, e aí ela custa.

Isso explicaria a inversão *e* o ótimo descendo com o δ: quanto mais peso você dá
ao futuro distante, menos longe pode olhar sem ser envenenado pela própria
previsão.

**O teste que decide é barato e o projeto já tem a régua:** o mostrador `modelo`
(nota 01) mede exatamente a calibração da previsão do bloco contra o que
aconteceu. Se a leitura acima está certa, `modelo` tem de **cair com `h`**, e o
dano à decisão tem de escalar com δ. Se `modelo` não cair, a história do ruído
está errada e a inversão tem outra causa (candidata: teimosia — o planejador
fundo se compromete com um alvo distante e passa reto por comida perto). Fica
pré-registrado como a nota 17; **até rodar, a §4 é hipótese e a §3 é o dado.**

> **Errata (nota 17) — o teste que este parágrafo propõe não serve, e o defeito é
> de desenho.** A janela de comparação do `modelo` dura `horizonte` ticks **do
> próprio bloco** (nota 01, "O conserto"). Um `h` maior alonga a janela e a torna
> mais difícil **por construção**: `modelo` cairia com `h` em qualquer mundo, com
> ou sem ruído na cauda. É **controle, não discriminante** — eu propus uma sonda
> que não pode falsear a hipótese que ela deveria testar, que é o modo 4 do
> Paper 1 (a régua infalseável) cometido por mim, três parágrafos depois de
> escrever "isto é interpretação, não medição".
>
> O discriminante correto usa a distinção que o protocolo do projeto já carrega
> (*população de equilíbrio é proxy de **grupo**; para aptidão individual, ensaio
> de invasão*): rodar populações de **tipo único** (todo bloco com o mesmo `h` e
> o mesmo δ) e perguntar se a inversão do **duelo** tem contraparte **solitária**.
> Se o h=12 em δ=0,95 é *absolutamente* pior — menos população sem rival nenhum
> para lhe tomar a comida — é ruído. Se o déficit **some** sem rival, é
> relacional, e a leitura desta §4 está errada. Ver
> [`17-tipo-unico.sh`](./17-tipo-unico.sh).
>
> **Desfecho (nota 17, 2026-07-17): a leitura desta §4 está CERTA, e agora é
> medição.** O déficit é **absoluto** — em δ=0,95, uma população de tipo único com
> `h=12` sustenta **5,5 blocos a menos** que a mesma com `h=8` (pareado,
> `t = −4,3`), **sem rival de outro tipo no mundo**, e deixa **+31,4** de comida em
> pé. E o dano tem a **dose-resposta em δ** que o `δᵏ` prevê: contra o `h=1`, o
> `h=12` deixa +20,3 / +45,2 / **+73,6** de comida de pé conforme δ vai a 0,80 /
> 0,90 / 0,95. **O desconto é um regularizador** — não é impaciência, é o bloco se
> recusando a confiar numa previsão que não consegue fazer. Ver
> [`17-ruido-ou-teimosia.md`](./17-ruido-ou-teimosia.md).

## 5. O que isto faz com a nota 14 e com o Paper 2

- **Nota 14 §1 ("o ESS é o teto"):** vale em δ=0,80 (P0 replica bit-a-bit), **não
  vale em geral**. Em δ=0,95 há ESS interior. Errata na nota 14.
- **Nota 14 §2 ("o joelho é o teto do desconto"):** a *direção* está certa até
  δ=0,90; a *fórmula* é uma aproximação de δ baixo e não sobrevive a δ=0,95.
- **Nota 14 §3 ("a transição cai exatamente no teto do desconto"):** **refutada**.
  A transição não anda. A coincidência com o 5 era coincidência.
- **Nota 15:** intacta no que importa. A escolha de taxar a *profundidade efetiva*
  e não o `hor_m` era um argumento de **identificabilidade** (o `hor_m` é ruído,
  sd até 15× maior), e esse argumento não depende de o `1/(1−δ)` ser o joelho.
  Mas a frase "o desconto reaparece como o regulador do valor posicional" (nota 14
  §4, item 2) cai junto.
- **Paper 2:** o mecanismo central muda. A tese ("cognição como bem posicional")
  **sobrevive e melhora**: o horizonte segue individualmente vantajoso e
  coletivamente custoso na maior parte do espaço, mas a corrida armamentista **tem
  freio endógeno** — e o freio não é o preço da cognição (nota 15), é a
  **imprecisão da própria previsão**. Um bem posicional que se auto-limita porque
  o produto que ele compra apodrece com a distância é um artigo melhor do que um
  que corre até a parede.

## Ameaças à validade

- **8 seeds.** As margens do topo em δ=0,95 têm `se ≈ 0,02–0,03` e estão a 5–14
  erros-padrão de 0,5 — a inversão não é questão de amostra. Os δ baixos (0,30 e
  0,50) têm `sd` de 0,2–0,4 e ali quase nada é significativo: **o platô de δ=0,30
  é "não distinguimos de 0,5 com 8 seeds"**, não "medimos 0,5".
- **Só o horizonte varia; o desconto é pregado por condição.** É o contraste limpo
  (ROADMAP §3.1), e é o desenho da nota 14 — mas significa que este lote não diz
  nada sobre o que a evolução faz com o **par** `(h, δ)` solto. A nota 15, que o
  soltou, achou profundidade efetiva 3,31 sem imposto: bem abaixo do teto, e
  agora isso tem uma explicação candidata.
- **A grade tem 5 pontos**, e a inversão mora entre 0,90 e 0,95. Onde exatamente o
  ótimo deixa de ser o teto, esta grade não diz.
- **A §4 é hipótese.** A inversão é dado (§3); o mecanismo do ruído é leitura, e o
  teste está pré-registrado como nota 17.
- **6000 ticks** e **50/50, não invasor-raro** — as mesmas da nota 14, de
  propósito, para o P0 poder amarrar as duas.

## O que ficou em aberto

1. **A nota 17** (§4): `modelo` × profundidade × δ. Decide entre ruído e teimosia.
2. **Onde o ótimo sai do teto** — uma grade fina em δ ∈ [0,88; 0,96].
3. **O invasor-raro no ESS interior.** Com ótimo interior, a distinção 50/50 ×
   invasor-raro passa a importar de verdade — muito mais do que importava quando o
   ESS era o teto.
4. **O imposto com reciclagem** (nota 15) segue em aberto e não é tocado aqui.
