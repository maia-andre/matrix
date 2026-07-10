# Nota 06 — O intérprete leigo: `relato`, a confabulação selvagem e o eremita mudo

**Data:** 2026-07-10
**Pré-registro:** `ROADMAP.md` §2.0, commit `eee9511` — **antes** do mostrador existir.
**Mostrador construído em:** `ffb3014`.
**Serve ao:** Paper 1 (metrologia da mente) — e à `FILOSOFIA_v3.md` §2 (costura) e §5 (confabulação).
**Reproduzir:** `sh papers/notes/06-relato.sh` (~3 min)

---

## Resumo

O quinto e último mostrador prometido da bateria, `relato`, nasceu diferente dos
outros quatro: com **pré-registro commitado antes do código** (regra 2 levada ao
extremo — as condições de sanidade e cinco predições estão em `eee9511`, o
mostrador em `ffb3014`). Três predições confirmaram, uma era demonstrável, e uma
**falhou** — e a falha é o achado mais interessante da nota.

A arquitetura é a tese de Nisbett & Wilson como restrição de código: o intérprete
que relata **não lê o estado interno nem o plano** — vê o 3×3 e a ação executada,
como um vizinho veria, e infere o motivo dali. Resultados: o relato é falível mas
informativo (κ ≈ 0,67); a intervenção **que a física já roda de graça**
(`resolver()` negando células) produz **confabulação selvagem** — o intérprete
racionaliza ~21% das ações que o bloco não escolheu; e o eremita, que deveria ser
o primeiro agente da bateria a *ter* a faculdade sozinho, fica **mudo** — não por
defeito do intérprete, mas porque um self de um motivo só não tem nada a dizer
acima do acaso.

## 1. A arquitetura: introspecção é percepção do próprio comportamento

O `auto_relato()` do HUD sempre teve acesso privilegiado (lê `fome` direto — é a
voz poética, deus falando de dentro). O mostrador `relato` mede outra coisa: um
canal que **pode errar**. A lição da Fase 1 (um mapa que não pode discordar do
território não é mapa) vale dobrada para relato: *um relato que não pode mentir
não relata*.

O intérprete leigo infere o motivo da ação executada com a heurística de nível 2:

- a ação foi para o argmax da **comida crua** → *"fome"*;
- para o argmax do **espaço** → *"espaço"*; os dois → *"ambos"*; nenhum → *"não sei"*.

A verdade (observador, acesso total): o motivo que explicaria a **decisão** — o
alvo cognitivo (pré-`resolver`) contra os argmax de `prever_valor` (o mapa real,
com rebrota/partilha/desconto) e do espaço. Dois canais legítimos de erro: o
plano pode ter sido **negado** (o intérprete vê a ação, não a intenção), e a
heurística leiga **não entende o planejador** (comida crua ≠ colheita descontada).

Estatística: **κ de Cohen** clampado em `[0,1]` — concordância *acima do acaso*.
A escolha carrega a condição de falseamento: um intérprete constante tem
concordância observada igual à esperada, e o κ zera **exato** (provável em
aritmética de float com somas inteiras < 2²⁴; provado e medido).

## 2. O placar do pré-registro

| predição | resultado |
|---|---|
| **P1** intérprete cego (4 constantes) → 0 exato | ✅ **0,0000** (média e máx, 3 seeds × 4 constantes) |
| **P2** mundo intacto: `0 < relato < 1` | ✅ κ ≈ **0,67** (0,663–0,670 nas 3 seeds) |
| **P3** confabulação selvagem nos negados | ✅ calibração 0,78 → **0,47**; ver §3 |
| **P4** erros onde o mapa diverge da heurística | ✅ indireto: ~35% das escolhas *livres* recebem "não sei" |
| **P5** o eremita não zera | ❌ **FALHOU** — κ ≈ 0,005; ver §4 |

A simulação saiu **bit-a-bit idêntica** (colunas 1–17, 3 seeds): o relato v1 é
medido, não consumido.

## 3. A confabulação selvagem (P3)

`resolver()` é um Bandersnatch que ninguém precisou escrever: quando dois blocos
disputam a célula, um deles é **negado** — executa uma ação (ficar) que não
escolheu. O intérprete não tem como saber (não lê o plano). Média de 3 seeds,
3000 ticks (~940 mil relatos, ~6% negados):

| grupo | calibração (acc) | nomeia motivo positivo |
|---|---|---|
| obedecidos | **0,779** | 0,646 |
| **negados** | **0,477** | **0,212** |

A leitura, na tabela do experimento do intérprete (ROADMAP, Fase 2):

- **~79% dos negados: "não sei"** — a linha *honesto* domina. O intérprete leigo,
  sem acesso ao plano, na maioria das vezes não acha um motivo que cole na ação
  imposta, e admite.
- **~21% dos negados: confabulação** — a célula onde o bloco foi barrado por acaso
  *parece* um argmax ("fiquei porque aqui é o melhor"), e o intérprete nomeia com
  convicção um motivo que **não operou**. É Gazzaniga em estado selvagem: a
  racionalização não precisa ser instalada, basta um intérprete que lê
  comportamento e um mundo que às vezes desobedece o plano — a **geometria dosa**
  quando ela acontece.
- E o dado inverso, dos obedecidos: **35% das escolhas livres recebem "não sei"**.
  São as escolhas do planejador (colheita descontada, rebrota, partilha) que a
  heurística leiga não acompanha — P4 por outro ângulo: *o bloco não entende
  justamente as suas decisões mais sofisticadas*.

## 4. O eremita mudo (P5 — a predição que falhou)

O pré-registro apostava que `relato` seria o primeiro mostrador da bateria a
sobreviver à solidão — a faculdade parece per-agente (um intérprete olhando o
próprio corpo). Medido: κ ≈ **0,004–0,006**. Colapso.

O mecanismo, visível a posteriori: sem rivais percebidos, `espaco ≡ 1` é constante
→ o termo social some do argmax → **toda decisão do eremita é "fome"**. A coluna
da verdade degenera numa classe só — e concordância *acima do acaso* com uma
constante é impossível, por definição de κ. O intérprete continua funcionando
(acerta "fome" o tempo todo!); o que não existe é **informação**: um self com um
único motivo não tem nada a relatar que o acaso já não diga.

Isso muda o desenho da costura (v3 §2). Os outros mostradores sociais zeram
porque a **sonda** é social (não há o que variar). O `relato` zera porque o
**conteúdo** degenera: a maquinaria introspectiva é per-agente, mas aquilo *sobre
o que* ela informa — a diversidade de motivos — é produto do conflito. Não é "o
eremita não sabe falar"; é "o eremita não tem biografia". A leitura (B) ganha
mais um ponto, por um mecanismo que ela ainda não tinha.

Ressalva honesta: o veredito depende do **vocabulário** do relato. O nosso taxonomiza
*motivos*; um relato sobre outra dimensão (profundidade do plano, sucesso da
previsão) poderia não degenerar na solidão. Fica como teste para quando houver
segundo vocabulário.

## Ameaças à validade

- **Epifenomenal por construção (v1).** Nenhum vizinho consome o sinal; a família
  *ablação* do relato lê zero hoje. Está escrito no pré-registro como escopo, e é
  um resultado (epifenomenalismo, medido) — mas significa que "relata" ainda não é
  uma palavra *causal* neste mundo. Torná-la causal é a Fase 4 (sinal com custo).
- **A confabulação dos ~21% é arquitetural no limite:** um intérprete que só lê
  comportamento *tem* de explicar pelo comportamento. O que a medição acrescenta é
  o **quanto** (a geometria dosa: ~1/5 das negações) e o contraste com a
  honestidade dominante — nada disso era derivável sem rodar. A comparação com a
  arquitetura rival (intérprete que lê o *plano* — deve *detectar* em vez de
  confabular) é o experimento seguinte, e as duas arquiteturas são um `#define`.
- **κ por tick com ~300 blocos** é ruidoso (desvio visível entre ticks); as médias
  de 3000 ticks são estáveis a 3 casas entre seeds.
- **3 seeds**, como sempre.

## O que ficou em aberto

1. **Bandersnatch forçado**: sobrescrever a escolha de um subconjunto
   determinístico (não só quem `resolver` nega) e comparar as **duas arquiteturas
   de introspecção** (ler a ação × ler o plano) sob a mesma intervenção — a tabela
   honesto/detecta/confabula vira um resultado de *seleção de arquitetura*, não de
   design.
2. **Tornar o relato causal** (Fase 4): vizinhos lendo o sinal, mentira custando.
   A régua está pronta para medir a palavra "relata" deixando de ser epifenomenal.
3. O **segundo vocabulário** do §4, para separar "intérprete mudo" de "self sem
   biografia".
