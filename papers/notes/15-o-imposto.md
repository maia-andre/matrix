# Nota 15 — A dose-resposta `h*(c)`: o imposto pigouviano lê a profundidade, não o horizonte

**Data:** 2026-07-15
**`main.c`:** o de `079a3ce` (canônico intocado; a variante `imp` é patch
temporário — só a linha do metabolismo muda: `+ custo_h · profundidade`).
**Pré-registro:** cabeçalho de `papers/notes/15-imposto.sh` — **antes** de
rodar (D0/D1/D2/D3).
**Serve ao:** Paper 2 ("Cognição como bem posicional") — a segunda metade, ao
lado do ESS da nota 14. Agregados em `datasets/imposto.csv`.
**Reproduzir:** `sh papers/notes/15-imposto.sh` (~20 min com `NPROC=12`)

---

## Resumo

A Fase 3 propôs o imposto pigouviano sobre a cognição: o planejador fundo impõe
ao comum um custo que não paga (bem posicional), e `METABOLISMO + c · profundidade`
faz o pensador pagar a própria corrida armamentista. Esta nota varre o imposto:
**7 custos × 8 seeds × 30 000 ticks**, com o horizonte e o desconto **evoluindo
livres** (mutação ligada, canônico) — só a conta do metabolismo muda. O custo é
cobrado pela **profundidade efetiva** `min(horizonte, 1/(1−desconto))`, não pelo
horizonte declarado, para o bloco não escapar do imposto baixando o desconto
(ROADMAP §3.3).

O placar do pré-registro:

| # | predição (escrita antes) | resultado |
|---|---|---|
| **D0** | `c = 0` reproduz o CSV canônico **bit-a-bit** | ✅ idêntico a `datasets/seed7.csv`, 2000 ticks |
| **D1** | a profundidade efetiva **cai** com `c` | ✅ **3,31 → 1,01**, monótona na média (6/8 seeds sem um degrau para cima) |
| **D2** | há um `c*` onde a profundidade encosta no **ótimo de grupo** (~1) | ✅ `c* ≈ 0,15` (profundidade 1,04); o ótimo de grupo da Fase 3 é `h = 1` |
| **D3** | a compensação via desconto aparece; o par `(hor, desc)` é que conta | ✅ **e forte**: `hor_m` é ruído (sd até 15× a da profundidade); ver §2 |

E, de brinde, um achado não orçado que muda a leitura econômica: o imposto que
**alinha a escolha destrói população** — a receita é *queimada*, não
redistribuída. Ver §3.

## 1. D1/D2 — a curva desce até o ótimo de grupo

Média ± sd de 8 seeds, janela 29 700–30 000:

| `c` | profundidade efetiva | população |
|---|---|---|
| 0 | **3,31 ± 0,24** | 284,4 |
| 0,01 | 2,91 ± 0,50 | 260,8 |
| 0,02 | 2,58 ± 0,72 | 247,3 |
| 0,04 | 1,82 ± 0,23 | 230,7 |
| 0,08 | 1,32 ± 0,41 | 218,2 |
| 0,15 | **1,04 ± 0,02** | 186,9 |
| 0,30 | 1,01 ± 0,01 | 133,0 |

A profundidade efetiva evoluída desce **monotonicamente** de 3,31 (sem imposto)
a 1,01 (imposto alto), e **encosta no ótimo de grupo** `h = 1` (Fase 3: a
população é máxima em `h = 1`) por volta de `c ≈ 0,15`. É a predição central do
imposto pigouviano cumprida: um preço por profundidade **desarma a Rainha
Vermelha** e traz o planejamento evoluído para o nível que seria bom para o
grupo. A corrida que a nota 14 mostrou correr até o teto (`h = 12` sem imposto)
recua até o piso quando cada passo de profundidade custa energia.

A coincidência prevista — um `c` onde interesse individual e coletivo se
alinham — é o teste forte da tese, e ele passou: não foi preciso ajustar o
custo para achar o alinhamento; ele aparece onde a profundidade efetiva bate no
`h = 1` que a Fase 3 já tinha medido como ótimo de grupo, de forma independente.

## 2. D3 — o imposto morde o que é identificável, e só isso

A Fase 3 avisou: `hor_m` **não é identificável sozinho** — um bloco declara
horizonte fundo e "pensa raso" baixando o desconto. Esta varredura mostra o
aviso em ação, e o transforma numa vantagem do desenho. Compare a dispersão das
duas leituras entre as 8 seeds:

| `c` | sd(`hor_m`) | sd(prof. efetiva) | razão |
|---|---|---|---|
| 0 | 2,23 | 0,24 | **9,1×** |
| 0,01 | 3,45 | 0,50 | 6,9× |
| 0,02 | 2,52 | 0,72 | 3,5× |
| 0,04 | 3,41 | 0,23 | **14,9×** |
| 0,08 | 0,55 | 0,41 | 1,4× |
| 0,15 | 0,02 | 0,02 | 1,0× |
| 0,30 | 0,01 | 0,01 | 1,0× |

Onde o imposto é fraco ou médio (`c ≤ 0,04`), o horizonte declarado é **ruído**
— sd de 2 a 3,5, uma seed pousando em `hor_m = 11` e outra em `hor_m = 1` com a
*mesma* profundidade efetiva, porque cada uma acha um par `(horizonte, desconto)`
diferente que dá o mesmo alcance. A profundidade efetiva, essa, responde com sd
de 0,2–0,7. A razão de dispersão chega a **15×**. Só quando o imposto é forte o
bastante para colar tudo em `h = 1` (`c ≥ 0,15`) as duas leituras convergem
(razão 1,0×), porque aí não há grau de liberdade para compensar.

A moral operacional: o imposto foi cobrado pela **profundidade efetiva** de
propósito (ROADMAP §3.3), e é exatamente essa a quantidade que ele consegue
mover de forma limpa. Um imposto sobre o horizonte *declarado* teria sido
evadido pela compensação do desconto — o bloco pagaria por passos que já não
pesam. A escolha do que taxar não era um detalhe: era a diferença entre um
instrumento que morde e um que escorrega.

## 3. O achado não orçado: o imposto que alinha a escolha queima a população

Olhe a coluna população da §1: ela **cai monotonicamente** com o imposto, de
284,4 para 133,0 — uma perda de ~53% no custo mais alto. E o `c*` que alinha a
profundidade ao ótimo de grupo (`c ≈ 0,15`) já custou ~35% da população
(284 → 187).

Aqui a analogia pigouviana range, e é honesto dizer onde. Num imposto pigouviano
de livro, a receita é **redistribuída** — o Estado devolve o que arrecadou, e o
que sobra líquido é só a externalidade corrigida. Neste mundo **não há
redistribuição**: a energia do imposto é *removida do bloco e some* — é
metabolismo extra, queimado. Então o imposto não corrige a externalidade sem
custo; ele a corrige **cavando um buraco de energia** proporcional à
profundidade taxada. A externalidade posicional que a Fase 3 mediu é pequena
(~2% de população entre `h = 1` e `h = 12`); a "cura" via imposto queimado
custa uma ordem de grandeza mais que a "doença".

Isso não derruba a tese — o mecanismo pigouviano **funciona** no sentido
preciso que D1/D2 pediam: alinha a escolha individual ao ótimo de grupo. Mas
qualifica a boa notícia: alinhar a *escolha* não é o mesmo que restaurar o
*bem-estar*, quando o instrumento do alinhamento é ele próprio destrutivo. A
Rainha Vermelha desarmada por um imposto queimado troca uma corrida cara por um
imposto caro. **Quem paga a conta da coordenação, paga.**

## Ameaças à validade

- **A receita é queimada, não reciclada.** O ponto do §3 é uma propriedade do
  desenho (custo = metabolismo extra). Um imposto que **devolvesse** a energia
  (à comida do mundo, ou às crias) seria o teste honesto de "internalizar a
  externalidade melhora o bem-estar?" — e é o experimento que o §3 pede. Sem
  ele, a afirmação segura é a mecânica (a escolha se alinha), não a de bem-estar.
- **O "ótimo de grupo `h = 1`" vem da Fase 3**, medida com horizonte *fixo* na
  população e janela curta (500–3000). A comparação de nível é aproximada; a
  afirmação forte é a **direção** (a profundidade evoluída desce à borda `h = 1`
  quando o imposto sobe), não o casamento exato de população entre experimentos.
- **Grade de 7 custos.** A transição mora em `c ∈ [0,02; 0,15]`; três pontos a
  cobrem (0,04; 0,08), o suficiente para a forma, não para o `c*` fino. Uma
  grade densa ali daria o joelho com mais casas.
- **8 seeds.** A média é monótona; 2 das 8 (seeds 1 e 7) têm um degrau para cima
  no `c` baixo — o regime onde o par `(hor, desc)` é mais errático (§2). Mais
  seeds apertariam a barra do `c` baixo, onde a sd da profundidade é maior (0,7).
- **30 000 ticks, janela fixa** no fim (as mesmas das notas 12/13).

## O que ficou em aberto

1. **O imposto que recicla** (a receita vira comida ou dote da cria): o teste de
   bem-estar que o §3 isola. Muda a simulação — pré-registro antes.
2. **Varrer o desconto** junto com o imposto: a nota 14 pôs o joelho do valor
   posicional em `1/(1−δ)`; aqui o desconto é livre e compensa. As duas varreduras
   cruzadas fechariam a identificabilidade do par.
3. **Nichos espaciais** (ROADMAP §3.2): em manchas ricas a corrida vale o
   imposto, em pobres não → nicho sem ninguém programar nicho. É a ponte para a
   Fase 4.
