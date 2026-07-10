# Nota 07 — O dedo do espectador: Bandersnatch forçado e as três arquiteturas de introspecção

**Data:** 2026-07-10
**Pré-registro:** `ROADMAP.md` §2.2, commit `d47c68c` — **antes** de rodar.
**Experimento sobre:** `main.c` @ `d47c68c` (patch da nota; o código canônico não muda).
**Serve ao:** Paper 1 (metrologia da mente) — e à `FILOSOFIA_v3.md` §4 (tempo/Bandersnatch) e §5 (confabulação).
**Reproduzir:** `sh papers/notes/07-bandersnatch.sh` (~2 min)

---

## Resumo

O experimento do intérprete (Gazzaniga), na versão **forçada**: um dedo de fora do
mundo sobrescreve a escolha de ~25% dos blocos (seleção e alvo por `hash2`,
determinístico, sem tocar o RNG), e três arquiteturas de introspecção — idênticas
na heurística, diferentes só **no que leem** — relatam a mesma vida sob a mesma
intervenção. As cinco predições do pré-registro confirmaram, e o experimento
devolveu dois detalhes que ninguém pediu: as **brigas acontecem onde todo mundo
entende o porquê**, e existe uma classe de intervenção que **nenhuma introspecção
possível detecta** — o dedo que a física desfaz antes de ele deixar rastro.

A tabela de Gazzaniga (honesto / detecta / confabula) deixou de ser uma tipologia
e virou **uma linha por arquitetura**: quem lê a ação confabula, quem lê o plano
não percebe, quem monitora os dois detecta — mas nem o monitor sabe *de quem* é o
dedo.

## 1. O aparato

Depois de `medir_decisao()` (a verdade da decisão já fotografada) e antes de
`resolver()`, cada bloco vivo tem chance ~1/N de ter o `alvo` sobrescrito por um
vizinho livre diferente do escolhido. Seleção: `hash2(x, y, tick)`; alvo imposto:
varredura dos 8 vizinhos a partir de um deslocamento também hasheado. Nada disso
consome o RNG do mundo: o experimento inteiro continua `f(seed)`.

As três arquiteturas (mesma heurística leiga de motivo da nota 06):

| | lê | sob o dedo, deve… |
|---|---|---|
| **A** (a v1 canônica) | a **ação executada** | confabular — só vê o corpo |
| **B** | o **plano** | ficar imune e cega — nunca olha o mundo |
| **C** | os dois | **detectar**: "minha ação não é meu plano" |

Sanidade do patch (B4): com o dedo desligado (`BS_DIV = 0`), o CSV sai **bit-a-bit
idêntico** ao canônico, as 18 colunas.

## 2. A dose-resposta (B4): a régua sente o dedo

κ canônico (coluna 18, arquitetura A), média de 3000 ticks:

| fração forçada | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| 0 | 0,670 | 0,663 | 0,670 |
| 1/16 | 0,625 | 0,615 | 0,628 |
| 1/4 | 0,483 | 0,478 | 0,470 |
| 1/2 | 0,295 | 0,279 | 0,281 |

Monotônica nas três seeds. Um mundo onde metade das escolhas é do espectador tem
um `relato` que vale menos da metade do de um mundo livre — o mostrador mede, de
fora, **quanto do comportamento ainda pertence aos blocos**.

## 3. As três arquiteturas sob o dedo (B1–B3)

`BS_DIV = 4` (~25% forçado), média das 3 seeds, ~1M relatos por seed:

| grupo | `accA` (lê ação) | `accB` (lê plano) | `confA` | `det` (monitor) |
|---|---|---|---|---|
| livre | 0,797 | 0,797 | 0,587 | 0,000 |
| negado (física) | 0,441 | **0,888** | 0,261 | **1,000** |
| **forçado (dedo)** | **0,244** | **0,806** | 0,256 | **0,990** |

- **B1 ✓ — A confabula.** Nos forçados, a calibração de A desaba a 0,244 (a taxa
  de coincidência geométrica) e ainda assim A nomeia um motivo positivo para
  **~26%** das ações que o bloco nunca escolheu. A não tem canal para "fui
  movido": arquiteturalmente, todo relato seu é sobre o corpo.
- **B2 ✓ — B é imune e cega.** `accB` nos forçados = 0,806 ≈ livre (0,797): o
  dedo não encosta na calibração de quem não olha o mundo. O preço: B descreve,
  convicta, um passo que **não aconteceu**. B mente sobre o comportamento sem ter
  como saber que mente.
- **B3 ✓ — C detecta, sem atribuir.** 100% das negações da física, 99,0% dos
  dedos — e **zero falso alarme** nos livres. Mas o sinal de C é o mesmo nos dois
  casos: *detecção sem atribuição de fonte*. De dentro, `resolver()` e o
  espectador são a mesma coisa: *algo* me moveu.

## 4. Dois achados que o pré-registro não pediu

**As brigas acontecem onde todo mundo entende o porquê.** `accB` nos *negados* é
**0,888** — mais alta que nos livres (0,797). Explicação mecânica: célula
disputada é tipicamente célula rica, onde o argmax leigo (comida crua) e o real
(`prever_valor`) coincidem — planos negados são planos *legíveis*. A disputa
seleciona os alvos óbvios; as escolhas idiossincráticas (as do planejador fundo)
ninguém disputa — e são justamente as que o próprio intérprete não entende.

**O dedo que ninguém pode ver.** O ~1% de forçados que C não flagra: o dedo impôs
um alvo, `resolver()` o negou, e o bloco terminou onde o próprio plano mandava.
A intervenção existiu e **não deixou rastro contrafactual** — nem o monitor
perfeito tem o que detectar. Corolário para a v3 §4: a detectabilidade de uma
intervenção não é propriedade da introspecção, é propriedade do **rastro**; um
dedo sem consequência é, de dentro, indistinguível de nada.

## 5. B5, a linha filosófica

Nenhuma das três arquiteturas relata *"fui forçado pelo espectador"* — não por
limite de engenho, mas por princípio: o dedo entra pelo mesmo barramento da
física. O "detecta" de C é o **teto epistêmico** de um bloco: discrepância sim,
autoria jamais. Se vale para o bicho de 56 KB num universo `f(seed)`, a pergunta
que a v3 §4 herda é desconfortável: um relato de "algo me moveu contra o meu
plano" — num cérebro, num experimento de Libet, numa Matrix — jamais discrimina,
sozinho, *física de dentro* de *intervenção de fora*.

## Ameaças à validade

- **As arquiteturas B e C são do observador** nesta versão: computadas no patch,
  não instaladas nos blocos como traço. O passo evolutivo (qual arquitetura a
  seleção prefere, quando o relato custar — Fase 4) é o que transformaria a
  tabela em resultado de *seleção*; hoje ela é resultado de *intervenção*.
- **O dedo de 25% muda o mundo** (a dose-resposta é entre mundos diferentes, não
  dentro de um mundo). A comparação entre arquiteturas, porém, é dentro do
  *mesmo* mundo — cada linha da tabela do §3 compara as três sob a mesma corrida.
- **`confA` dos negados difere da nota 06** (0,26 × 0,21): mundos diferentes (lá
  sem dedo, aqui com 25% de forçados mexendo na densidade das disputas). A
  direção e a ordem de grandeza se mantêm.
- **3 seeds**, como sempre — mas as três concordam a ≤ 0,02 em toda célula da
  tabela.

## O que ficou em aberto

1. **Instalar as arquiteturas como traço herdável** e deixar a seleção escolher —
   depende do relato custar/valer algo (Fase 4). Predição barata registrável: sem
   custo, deriva neutra; com leitores que punem incoerência, C invade A.
2. O **relato causal** (vizinhos consumindo o sinal) continua sendo o passo que
   tira o `relato` do epifenomenalismo.
3. A ponte com a **v3 §4** está pronta para ser escrita: crença modal, teto
   epistêmico da detecção, e o dedo sem rastro.
