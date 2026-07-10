# ROADMAP — para onde a Matrix vai

> `README.md` é o **como**. `FILOSOFIA.md` e `FILOSOFIA_v2.md` são o **porquê**.
> Este é o **para onde** — e, tão importante quanto, o **para onde não**.

## O que já aconteceu (e passou meio despercebido)

Até a v1, a Matrix era um simulador engenhoso: *o objeto de estudo*. A v2 fez
uma troca de papel que parece sutil e é enorme — com a bateria de desbotamento,
a Matrix virou **aparato experimental**. A frase deixou de ser "olhem o meu
mundo artificial" e passou a ser "construí um ambiente determinístico,
reprodutível e instrumentado onde posso formular hipóteses, executar
intervenções e medir resultados".

O projeto subiu uma escada (níveis 0–6) e então **parou de subir e construiu uma
régua**. Antes de usar a régua para medir qualquer coisa, é preciso descobrir se
a régua mede.

Ela não mede. Pelo menos não `modelo`. Ver a Fase 1.

---

# Fase 1 — Quebrar a régua *(em andamento)*

**Pergunta:** os mostradores medem a coisa, ou um correlato dela?

Este é o **portão**. Refinar `modelo` ou `Φ~` antes de tentar quebrá-los é
refinar no escuro; construir um quarto mostrador (`relato`) com uma metodologia
não validada é multiplicar o erro por quatro.

## 1.0 O primeiro resultado negativo do projeto

`modelo` não mede o modelo de mundo do bloco. Ele mede **taxa de conflito**.

Em `medir_decisao()`, a "previsão" é:

```c
pred_colheita[i] = menor(comida[alvo_y[i]][alvo_x[i]], INGESTAO);
```

Isso lê `comida[][]` — **o mundo** — e nunca chama `prever_valor()`. O mapa que
o bloco constrói (`horizonte`, `desconto`, `partilha` com rivais), o mapa que
*evolui*, jamais é confrontado com o território. Um tick depois, `medir_modelo()`
compara aquilo com `garfada = menor(comida[y][x], INGESTAO)` — **a mesma fórmula,
sobre a mesma célula**. Se o bloco chegou ao alvo, `real == pred` por construção.
`modelo ≈ 0,97` significa apenas "97% dos blocos não foram barrados".

Medido, em três seeds, 3000 ticks (`sh papers/notes/01-ablacoes.sh`):

| condição | modelo (@ `6da8c3a`) | destino da população |
|---|---|---|
| controle (intacto) | **0,973** | ~290, estável |
| `horizonte = 1` (lookahead lobotomizado) | **0,994** ↑ | ~300, estável |
| `prever_valor() ≡ 0` (sem modelo nenhum) | **1,000** ↑↑ | **extinção em 74–105 ticks** |

*(A coluna `modelo` é histórica — o mostrador quebrado, reprodutível com
`git show 6da8c3a:main.c`. A coluna da população foi **remedida** depois do
conserto do §1.6: o "cai ~25%" que eu havia reportado para `horizonte = 1` era
contaminação do teto de nascimentos.)*

Um bloco cego para comida, marchando para a extinção, tira **nota máxima** no
mostrador chamado "modelo". A leitura é **monotonicamente anti-correlacionada**
com a faculdade que ela nomeia: quanto mais lobotomizado o agente, melhor sua
nota. É Goodhart em estado puro, e é o primeiro resultado negativo que este
projeto produziu.

**Por que falhou, e a lição geral.** As duas famílias da bateria apontaram em
direções opostas. A **ablação** disse a verdade — arranca `prever_valor` e a
população morre, logo a faculdade carrega o comportamento. A **calibração** deu
nota 1,000 a um cadáver. Isso não é acidente:

> `pred_colheita` lê o array do mundo. Um mapa que é uma **fotocópia** do
> território não pode discordar dele. E um mapa que **não pode errar não é um
> mapa** — a marca da representação é a possibilidade da *des*representação.

O mostrador foi construído removendo justamente a condição que faria dele um
mostrador. Isso é matéria da `FILOSOFIA_v3.md` (Fase 5), não só de um patch.

## 1.1 Consertar `modelo` ✅ *feito*

A previsão agora sai do **mapa do bloco**: `prever_valor()` (com `horizonte`,
`desconto`, `partilha`), comparada contra a colheita realmente acumulada ao longo
dos `horizonte` ticks do bloco, descontada do mesmo jeito. A janela fecha no fim
do horizonte — ou na morte do bloco, que é a previsão mais errada possível.

Condição de sanidade, declarada antes de rodar: **a ablação `prever_valor ≡ 0`
tem de derrubar `modelo` a perto de zero.** Resultado: **0,000 exato** nas três
seeds (era 1,000). O controle passou de 0,973 para **0,638** — há folga nos dois
sentidos, o mapa pode errar. E o conserto **não mexeu na simulação**: todas as
outras colunas do CSV são bit-a-bit idênticas.

Achado colateral, registrado na nota 01: com o mostrador funcionando, o bloco
revela uma **crença falsa**. Via `partilha`, ele acredita que os rivais dividem a
comida da célula que ele ocupa — e `ocup[][]` guarda **um** bloco por célula.
Zerar só `COMPETICAO` recupera a calibração (0,625 → 0,786) **sem mexer na
população** (290,3 × 290,0): ao nível do grupo, `partilha` é puro custo
epistêmico, e quem carrega o valor adaptativo de ver rivais é o termo `espaco`.

→ [`papers/notes/01-quatro-modos-de-errar.md`](./papers/notes/01-quatro-modos-de-errar.md)

## 1.2 Descontaminar `agencia` ✅ *feito — e a suspeita estava errada*

O mostrador antigo sondava a fome em **dois pontos arbitrários** (`0,1·SACIADO` e
`SACIADO`). Isso tem um defeito real: dividindo `utilidade` pelo fator positivo
`(1 + urgencia·fome)`, comum a todas as células, a decisão vira
`argmax(comida_prev + λ·espaco)` com `λ = peso_espaco·(1−fome)/(1+urgencia·fome)`.
Os dois pontos visitavam `λ ∈ [0,034·P, P]`, com o **extremo inferior dependendo de
`urgencia`** — um traço que evolui. A sonda media parcialmente a si mesma.

O conserto usa a estrutura: cada célula é uma **reta** em `λ`, a escolha é o
envelope superior dessas retas, e `λ` varre exatamente `[0, peso_espaco]` quando a
fome varre `[0,1]`. Varremos `λ` inteiro. A estatística continua a mesma de
propósito — trocar a sonda **e** a estatística no mesmo passo confundiria as duas
mudanças. Leitura: **0,388 → 0,435** (a sonda antiga perdia ~12% dos blocos). Só a
coluna `agencia` do CSV muda; a simulação é bit-a-bit idêntica. E o novo mostrador
não menciona `urgencia`: esse traço só desliza *onde* na fome a troca acontece, não
*se* ela acontece.

**Mas a suspeita central estava errada.** Eu disse que `corr(esp_m, agencia) = +0,98`
provava contaminação. Não prova. Congelando `peso_espaco` em 3,0, o mostrador fica
**plano** por 30 000 ticks (0,464 → 0,440); com o traço livre, desaba (0,430 →
0,049) junto com `esp_m` (2,76 → 0,08). A correlação é **mecanismo, não
contaminação**: `peso_espaco` é o *único* canal pelo qual o estado interno pode
mudar uma decisão, e quando ele morre a política vira reflexo.

O que a régua estava reportando, e ninguém ouviu: **a evolução extingue a
agência.** No ensaio de invasão, o reflexo (`peso_espaco = 0`) **fixa** contra o
agente (`3,0`) em ~6000 ticks: 0,997 / 1,000 / 1,000.

→ [`papers/notes/03-a-evolucao-extingue-a-agencia.md`](./papers/notes/03-a-evolucao-extingue-a-agencia.md)

## 1.3 `automodelo` não é uma intervenção

`automodelo` é `intencao != alvo` — lido de graça do estado que já existe. É uma
**observação**, não uma ablação. `agencia`, ao lado, faz um contrafactual de
verdade (dois clones, rerodagem). Plotar os dois no mesmo eixo `[0,1]` é somar
laranjas com maçãs. E, a rigor, "antecipar os rivais mudou minha escolha" é um
modelo **do outro**, não de si — o self entra só como "sou um dos pretendentes".

## 1.4 `phi` não está normalizado

`phi_proxy()` devolve `10.0f * disc/tot`, sem clamp, e a documentação afirma
`[0,1]`. Se a discordância passar de 10%, `phi > 1`. Nas corridas feitas o máximo
observado foi 0,372 — é uma **fragilidade latente**, não um bug que disparou. Mas
o `10.0f` é um fator de escala escolhido para o número *parecer* morar em `[0,1]`,
o que torna o valor absoluto sem significado.

E `phi` **não é independente** dos outros traços: ele acompanha a **profundidade
efetiva** de planejamento, `min(horizonte, 1/(1−desconto))` — `corr(efetiva, phi)`
= **+0,96 / +0,75 / +0,93**, sinal consistente nas três seeds. Contra o `hor_m`
bruto a correlação **troca de sinal** (**−0,94** na seed 7, **+0,97** na 1234), o
que é mais um sintoma de que `hor_m` sozinho não é identificável (Fase 3). Se `phi`
mede "integração" e integração é só profundidade efetiva com outro nome, o
mostrador não acrescenta uma dimensão — acrescenta um sinônimo. Testar.

## 1.5 O teste do eremita — três dos quatro mostradores são sociais

Ablação: o bloco deixa de **perceber** outros blocos (`rivais_em ≡ 0`,
`pretendentes_em ≡ 0`); eles continuam existindo e bloqueando fisicamente. Um
solipsista num mundo povoado. Média de 3 seeds, ticks 200–3000:

| | `modelo` | `agencia` | `automodelo` | `phi` | pop média |
|---|---|---|---|---|---|
| controle | 0,636 | 0,383 | 0,332 | 0,255 | 290,0 |
| **solipsista** | 0,783 | **0,0000** | **0,0000** | 0,039 | 283,1 |

`agencia` e `automodelo` não caem: dão **zero exato**. E isso é demonstrável antes
de rodar. Sem rivais, `espaco = (8 − 0)/8 ≡ 1` em toda célula, então o termo
`peso_espaco · espaco · (1 − fome)` vira **constante entre as células** e some do
argmax; e o outro termo é `comida_prev · (1 + urgencia · fome)`, um escalar
positivo multiplicando `comida_prev`, que também não move o argmax. **A fome não
pode mudar a escolha de um bloco solitário** — logo `agencia ≡ 0`. Já `automodelo`
é `intencao != alvo`, e as duas passagens só divergem via `pretendentes_em` — logo
`automodelo ≡ 0`.

Consequências, em ordem de gravidade:

- Os dois mostradores que nomeiam as faculdades mais "mentais" da escada —
  **agência** e **auto-modelo** — não medem nada que o bloco *tenha*. Medem algo
  que acontece **entre** blocos. `automodelo`, aliás, sempre foi um modelo *do
  outro* (ver 1.3); agora sabemos que sem o outro ele é identicamente nulo.
- `phi`, o proxy de integração, perde **85%** do valor na solidão: a "luz acesa"
  era social em quase toda a sua intensidade.
- `modelo` (já consertado) **sobe** (0,636 → 0,783): o solipsista prevê melhor,
  porque não carrega a crença falsa da `partilha` (§1.1). *(Com o mostrador ainda
  quebrado, esta mesma ablação o fazia **descer** — a terceira confirmação
  independente de que ele media congestionamento; ver a nota 01.)*

Perceber os outros custa pouco em aptidão de grupo: a população cai ~**2,4%**
(283,1 × 290,0). Não os perceber custa muito em vocabulário: dois mostradores
zeram.

**O teste do eremita como protocolo.** Isto generaliza para além do brinquedo:
*rode a ablação da solidão em qualquer métrica por-agente*. Se a métrica zera
para um agente sozinho, ela media uma relação, não uma posse — e nenhuma
quantidade de refinamento por-agente vai consertá-la.

## 1.6 O bug que congelava a evolução ✅ *corrigido*

Independente da bateria, e descoberto ao consertá-la. `reproduzir()` fazia
`j = n_blocos++` e **nunca reaproveitava o slot de um bloco morto**, parando em
`MAX_AG = 1408`: um teto de ~1348 **nascimentos** na vida inteira de uma
simulação. Medido com instrumentação, os slots esgotavam nos ticks **11 647 /
9 473 / 9 487** (seeds 7 / 42 / 1234). Dali em diante a reprodução parava para
sempre — sem cria, sem mutação, sem seleção — e `energia_media` divergia: **986**
no tick 30 000, contra ~6 no regime saudável.

`alocar_slot()` agora reaproveita o buraco de menor índice. Depois: energia
estável em ~6 e população em ~280–310 por 30 000 ticks, reprodução nunca para.

**O preço, e ele é conceitual.** `resolver()` concede a célula disputada ao
pretendente de **menor índice**. No código antigo o índice era a ordem de
nascimento — logo o mais **velho** vencia toda disputa. Havia uma **regra de
senioridade que ninguém escreveu**, e que dava vantagem sistemática a quem já
tinha sobrevivido. Reaproveitar slots a destrói (uma cria pode herdar um índice
baixo e ganhar de um ancião). Trocamos um desempate arbitrário por outro; nenhum
dos dois é principiado. Um desempate *escolhido* — por energia, ou por um hash
determinístico de `(x, y, tick)` — é uma decisão de física em aberto.

→ nota 02.

## 1.7 O protocolo, daqui em diante

Toda ablação reporta **duas** coisas: a leitura do mostrador **e** o efeito em
aptidão (população, sobrevivência). Foi o descasamento entre as duas que revelou
o problema. Um mostrador cuja leitura sobe enquanto a população morre está
medindo outra coisa.

---

# Fase 2 — Fechar a bateria: `relato`

**Pergunta:** um bloco pode dizer algo *sobre si* que carregue comportamento?

O único mostrador prometido e não entregue — e não é acaso que ficou por último.
Relato é a dobradiça de quase toda a ciência da consciência (workspace global,
teorias de ordem superior: tudo se apoia em *report*). Já existe um `auto_relato()`
no HUD da primeira pessoa, que narra o bloco em texto — **mas nada o mede**.

**Em pé com as invariantes:** o bloco emite um **sinal local** na própria célula,
computado do estado interno; vizinhos leem o 3×3. Inteiro, sem `math.h`,
`f(seed)`, percepção estritamente local. Duas famílias, como sempre — e desta vez
com a lição da Fase 1: a calibração só vale se o sinal **puder estar errado**.

## O experimento do intérprete (Gazzaniga)

Deve ser o **primeiro** experimento assim que o mostrador existir:

1. O bloco decide — e a separação leitura×escrita do tick já isola o instante
   exato (`intencao_*` antes de `alvo_*`).
2. **Intervimos**: trocamos a ação executada.
3. Perguntamos ao relato: *por que você fez isso?*

| desfecho | o relato diz | leitura |
|---|---|---|
| **honesto** | nada / "não sei" | o relato só reporta o que acessa |
| **detecta** | "minha ação não corresponde ao meu plano" | há monitoramento de discrepância |
| **confabula** | "porque eu estava com fome" | o relato *racionaliza* uma ação que não escolheu |

O terceiro é o achado do cérebro dividido, reproduzido num brinquedo de 56 KB de
C. E note o que ele faz com a régua: transforma `relato` de medida
**correlacional** em medida **intervencional** — exatamente a família que, na
Fase 1, foi a única a dizer a verdade.

**Risco:** confundir o sinal *emitido* com o estado *representado*. Um relato bem
calibrado é evidência de calibração, não de experiência. Escrever isso em letras
garrafais antes de o primeiro `@` "falar".

---

# Fase 3 — O custo de pensar

**Pergunta:** quando vale a pena pensar?

Esta seção foi reescrita quatro vezes porque a simulação derrubou três hipóteses
minhas — e depois o conserto do bug §1.6 invalidou metade dos números da quarta.
Vale registrar o cemitério, porque o cadáver de cada hipótese apontou a próxima, e
porque a cultura do projeto é essa: **medir, não achar**.

Todos os números abaixo vêm do `main.c` **com a reprodução consertada**.

## Três hipóteses mortas

**H1 — "pensar é de graça, logo o horizonte cresce até o teto."** Falso, mas
quase me enganou duas vezes. Em 30 000 ticks agora evolutivamente válidos, `hor_m`
termina em **11,04 / 4,88 / 3,40** (seeds 7 / 42 / 1234). A seed 7 encosta em
`HORIZONTE_MAX = 12`; as outras duas **caem**. Se eu tivesse olhado só a seed 7,
teria "confirmado" H1. *(A "subida inicial" que vi lá atrás em 2000 ticks é
transiente: `semear_blocos` sorteia `horizonte` **uniforme em 1..12**, média 6,5 —
não 6, como o `#define HORIZONTE` sugere.)*

**H2 — "a paisagem adaptativa é plana, o traço deriva."** Não sustentada. `hor_sd`
cai de ~3,45 (uniforme inicial) para 0,70–3,10, e as médias se estabilizam. Algo
segura o traço.

**H3 — "o freio é a competição: você planeja rebrota que o rival come antes."**
Falso, e ao contrário. Com `COMPETICAO = 0` os horizontes evoluídos ficam **mais
rasos**. A competição não freia o pensamento: **alimenta** o pensamento.

## E uma quarta descoberta, que explica as três

`horizonte` e `desconto` são **traços compensatórios**. No regime tardio,
`corr(hor_m, desc_m)` = **−0,93 / −0,46 / −0,72**. Um bloco com horizonte 11 e
desconto 0,66 pesa o 3º passo em `0,66³ ≈ 0,29` e o 11º em `0,01`: ele *declara*
um horizonte fundo e **pensa raso**. A profundidade que de fato importa é
`min(horizonte, 1/(1−desconto))`:

| seed | `hor_m` | `desc_m` | `1/(1−δ)` | **profundidade efetiva** |
|---|---|---|---|---|
| 7 | 11,04 | 0,661 | 2,95 | **2,95** |
| 42 | 4,88 | 0,873 | 7,86 | **4,88** |
| 1234 | 3,40 | 0,898 | 9,80 | **3,40** |

O `hor_m` bruto varia **3,2×** entre as seeds; a profundidade efetiva varia
**1,7×**. Boa parte da "divergência entre seeds" que matou H1, H2 e H3 era um
artefato de olhar um traço **não identificável** isoladamente. **`hor_m` sozinho
não mede o quanto um bloco planeja.** Qualquer conclusão sobre profundidade de
planejamento precisa do par `(horizonte, desconto)`.

## O que os dados dizem de fato

**Paisagem de grupo.** Fixando `horizonte = h` para toda a população (preservando
o fluxo do RNG, então mundo e demais traços ficam idênticos), a população de
equilíbrio (média das 3 seeds, ticks 500–3000) cai **monotonicamente**:

| h | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 12 |
|---|---|---|---|---|---|---|---|---|
| pop | **295,9** | 295,0 | 293,6 | 292,7 | 290,6 | 289,8 | 289,4 | 289,3 |

Quanto mais fundo a população pensa, **menor** ela é. O ótimo de grupo é `h = 1`.
*(Com o bug §1.6, esta curva tinha um falso pico em `h = 2` e um vale artificial em
`h = 1`: blocos míopes se empacotam, nascem muito, esgotavam os slots primeiro.)*

**Aptidão individual.** Ensaio de invasão: população 50/50 de `h = 3` e `h = 9`,
**sem mutação**, herança exata. Frequência de `h = 9`:

| tick | 0 | 1000 | 2000 | 4000 |
|---|---|---|---|---|
| seed 7 | 0,42 | 0,71 | 0,84 | **0,91** |
| seed 42 | 0,55 | 0,76 | 0,83 | **0,87** |
| seed 1234 | 0,42 | 0,73 | 0,83 | **0,85** |

O planejador fundo **desloca** o raso, monotonicamente, nas três seeds.

## A conclusão, e ela é forte

> Pensar mais fundo é **individualmente vantajoso** e **coletivamente ruim**. O
> horizonte cognitivo é um **bem posicional** — uma corrida armamentista.

É por isso que a competição alimenta o pensamento em vez de freá-lo (H3): o ganho
de olhar fundo está principalmente em **ganhar a célula disputada do vizinho**,
não em fazer o bolo crescer. Cada bloco precisa pensar mais fundo só para
permanecer no lugar — Rainha Vermelha.

E o freio (H1, H2) não é energia nem deriva: é o **decaimento geométrico do peso
do futuro** — e, sobretudo, a compensação via `desconto`. Uma população pode
"comprar" horizonte barato baixando `desconto`, e é exatamente o que a seed 7 faz.

**Ressalvas honestas.** População de equilíbrio é proxy de *grupo*; a invasão mede
aptidão *relativa*. O descasamento entre os dois **é** o achado. Só testei o par
3×9, e bens posicionais são intrinsecamente **frequência-dependentes**. `HORIZONTE_MAX`
= 12 **censura** a seed 7 (`hor_m` 11,04). O ESS do horizonte é **desconhecido**.

## O que fazer, então

1. **Torneio de invasão par-a-par** (`h_i` × `h_j`, matriz 12×12, por seed): com só
   dois valores na população, `hor_m` no CSV *é* a frequência. Sai daí o ESS e o
   grau de dependência de frequência. Barato e informativo. Fixar `desconto` no
   torneio — senão a compensação contamina o resultado.
2. **O custo de pensar**, agora com um significado preciso. Ele não "cria um
   gradiente onde não há" (H2, morta) nem "contém uma catraca" (H1, morta). Ele
   **internaliza uma externalidade**: hoje o planejador fundo impõe ao comum um
   custo que não paga. `METABOLISMO + c · horizonte` faz o pensador pagar a própria
   corrida armamentista. É um **imposto pigouviano sobre a cognição**.

   Predições falseáveis:
   - o `h` evoluído deve **cair em direção ao ótimo de grupo** conforme `c` sobe —
     uma curva dose-resposta `h*(c)`;
   - existe um `c` em que o `h` evoluído **coincide** com o ótimo de grupo:
     interesse individual e coletivo alinhados. Uma coincidência *prevista* é um
     teste forte;
   - a **profundidade efetiva** (não o `hor_m` bruto) deve encolher, e a
     compensação via `desconto` deve aparecer como uma resposta correlacionada;
   - em manchas ricas a corrida vale o imposto; em manchas pobres, não → **nichos
     espaciais**, sem ninguém programar nicho. É a ponte para a Fase 4, e a razão
     de o custo vir antes dela.
3. **Cuidado com o custo escolhido.** Se `c` for cobrado por *passo declarado*
   (`horizonte`), um bloco escapa do imposto baixando `desconto` e mantendo o
   horizonte — pagaria por passos que já não pesam. Cobrar pela profundidade
   *efetiva* é mais honesto e mais difícil. A escolha é uma tese, não um detalhe.

## Corolário desconfortável

A narrativa "a evolução aprende a planejar mais longe" é, na melhor das hipóteses,
mal formulada — `hor_m` não é identificável sozinho. E na parte em que é
verdadeira, **não é a boa notícia que parece**: a inteligência, aqui, não torna a
população melhor. É uma corrida que cada indivíduo precisa correr para ficar
parado, e que sai cara para todos. Se isso vale para o bicho de 56 KB, vale a
pergunta para os outros.

# Fase 4 — Vida artificial: instalar **mecanismos**, nunca **fenômenos**

**Pergunta:** que comportamentos emergem, sem que ninguém os programe?

Nichos, especiação, cooperação, comunicação, predação. Talvez seja aqui que mora
o ouro. Mas há uma armadilha de categoria que precisa estar escrita:

> **Não se adiciona um nicho. Não se adiciona cooperação.**
> Adiciona-se um *trade-off* e o nicho aparece — ou não aparece, e **isso é o
> resultado**. Adiciona-se uma estrutura de payoff e a cooperação evolui — ou
> não, e isso também é resultado.

Listar "nichos, especiação, cooperação, predação" é listar *desfechos desejados*.
A invariante do projeto — *o comportamento global deve **emergir*** — proíbe
instalá-los. O que se instala é a **pressão**. O custo de pensar (Fase 3) é a
primeira pressão real, e por isso ela vem antes desta fase.

## E o sinal precisa custar

A tentação é `float sinal;` — um bloco deixa, outro lê, "está aberta a porta da
comunicação evolutiva". Não está. **Cheap talk é instável**: se sinalizar é
grátis, a mentira domina e o sinal degenera em ruído (Maynard Smith; as saídas
clássicas são custo — Zahavi — ou interesse comum, como parentesco). Um sinal
que ninguém é *pressionado* a ler, e cuja mentira não *custa*, é decoração
determinística: o experimento nasce respondido.

---

# Fase 5 — Escrever: `FILOSOFIA_v3.md` e o paper

**Pergunta:** onde a palavra mental **quebra**?

As fases 1–4 são expansionistas: mais fenômenos, mais mostradores, mais
experimentos. Um projeto cuja tese é *"até onde a palavra estica"* precisa de uma
teoria do **ponto de ruptura**. Sem ela, a bateria vira uma catraca que só sabe
licenciar vocabulário mental, nunca retirá-lo — e aí não mede até onde a palavra
estica: apenas estica a palavra.

## O que a v3 precisa ter (e por que não pode ser escrita antes)

1. **Um resultado negativo.** Ela agora tem o primeiro: um mostrador chamado
   `modelo` deu nota 1,000 a um bloco sem modelo, morrendo. Até hoje todo degrau
   da escada "funcionou". Uma filosofia do limite escrita por alguém que nunca
   encontrou um limite é publicidade.

2. **Uma condição de falseamento por palavra.** Para cada mostrador: *que leitura
   me obrigaria a dizer que a palavra não se aplica a este bloco?* Para `modelo`,
   hoje, a resposta é **nenhuma** — ele lê ~1 até para um cadáver. Enquanto uma
   palavra não puder ser retirada, ela não foi testada.

3. **A distinção entre a régua e a palavra**, com espécime da casa. A abertura da
   v3 se escreve sozinha: *"construímos um medidor de 'modelo'. Ele deu nota
   máxima a um agente sem modelo. Isto não é um bug que corrigimos e seguimos em
   frente; é o fato epistêmico central do projeto."* A mesma estrutura ameaça
   todo mostrador — inclusive os que vamos consertar, e inclusive os que se usam
   em humanos.

4. **Uma hierarquia entre as duas famílias.** A Fase 1 mostrou que ablação e
   calibração podem apontar para **lados opostos**. A tese: *calibração sem
   ablação não vale nada*, porque a calibração pode ser satisfeita por um mapa
   que é fotocópia do território — isto é, por não ser mapa. **Representação
   exige a possibilidade de des-representação.** Isso é Dretske e Millikan caindo
   de um `sed` em C.

5. **A dobradiça da confabulação** (depende da Fase 2). Quando um bloco
   racionalizar uma ação que não escolheu, o projeto terá, dentro de casa, o
   fenômeno que torna o auto-relato humano pouco confiável (Gazzaniga; Nisbett &
   Wilson). E então a v3 tem de encarar o último reduto do "mas eu *sei* que sou
   consciente, por dentro" — porque esse reduto **é ele próprio um relato**. Se
   relatos confabulam, quanto peso probatório sobra ali?

6. **Uma escolha que a v2 evita.** "Função, nunca experiência" é (a) uma
   **contenção metodológica** — faltam-nos instrumentos; ou (b) uma **tese
   metafísica** — não há mais nada a medir? São afirmações radicalmente
   diferentes, e a v2 é ambígua entre as duas. A v3 escolhe, ou recusa escolher
   **explicando por que a recusa é estável** em vez de evasiva.

7. **A colisão contrafactual × determinismo.** `medir_decisao()` já roda um
   contrafactual (dois clones, faminto × saciado) — mas quem o roda é o
   **observador**, não o bloco. No dia em que o bloco rodar isso por dentro
   ("eu poderia ter ido para a esquerda"), ele sustentará uma crença modal que,
   num universo `f(seed)`, é **falsa** — e ainda assim funcionalmente
   indispensável. Compatibilismo, executável. A v3 precisa de uma posição:
   crença falsa, ficção útil, ou verdade sobre o *tipo* e falsidade sobre a
   *ocorrência*?

8. **O regresso** (depende do eixo "microscópio", abaixo): quem calibra o
   calibrador?

9. **A costura da escada** — e é aqui que a v3 se bifurca *de verdade*.

   A metáfora fundadora (subir degraus rumo a mais mente) admite duas leituras:

   **(A) Aquisição de faculdades.** Os degraus catalogam o que o bloco *tem*. É
   uma leitura **internalista**, e a bateria está arquitetonicamente comprometida
   com ela: todo mostrador recebe um `Bloco *b` e é computado localmente. O
   ambiente é palco. O terminal natural desta leitura é "quantos degraus até a
   senciência?" — a pergunta da v1, que a v2 recusou.

   **(B) Escalada de um conflito.** Os degraus são lances numa corrida
   armamentista. É uma leitura **relacional**: a mente não é propriedade do bloco,
   é propriedade da *relação entre* blocos. "Senciência" nomearia uma posição num
   jogo, não uma posse. A deflação é bem mais dura que a da v2: não "a palavra não
   estica até aqui", mas "a palavra nunca foi sobre o que você pensava".

   **A bifurcação não é uma escolha de gosto — ela tem uma costura mensurável.**
   O teste do eremita (1.5) mostra que, *nesta implementação*, `agencia` e
   `automodelo` são **identicamente zero** para um bloco solitário, e `phi` perde
   88%. Para os degraus 4–5, (B) não é uma interpretação: é a implementação
   literal. Não há mais nada lá. Já os degraus 0–3 (reatividade, memória,
   valência, modelo do mundo/comida) não precisam de rival algum. **A escada tem
   uma costura, e ela cai entre o nível 3 e o nível 4.**

   Cada leitura paga um preço, e é isso que torna a bifurcação produtiva:

   - Escolher **(A)** obriga a aceitar que, pelos próprios mostradores do projeto,
     um bloco sozinho quase não tem mente. Para salvar (A) é preciso **redesenhar
     as faculdades** para que um eremita possa tê-las — e o projeto já sabe como:
     o item *"aprofundar o auto-modelo (nv5)"* do `README.md` (separar em
     `prever_valor` o **próprio** consumo do consumo dos rivais) é exatamente a
     edição que tornaria o auto-modelo não-social. O conserto do mostrador e a
     posição filosófica **são a mesma linha de código**. Predição de (A): feita
     essa edição, `automodelo` fica > 0 na solidão.
   - Escolher **(B)** obriga a jogar fora a bateria por-agente. Uma faculdade
     relacional não é mensurável num `Bloco *b`: os mostradores teriam de ser
     definidos sobre **pares** ou sobre a população. Predição de (B): a altura dos
     degraus escala com a intensidade da competição (já há um indício —
     `COMPETICAO = 0` ⇒ horizontes mais rasos).

   As duas predições são baratas e **decidem qual leitura sobrevive**. Isso é o
   que um laboratório de filosofia da mente pode fazer e uma poltrona não pode.
   A v3 não escolhe um lado por gosto: ela **localiza a costura** e reporta de que
   lado cada palavra caiu.

   **E há agora um dado duro para a v3 digerir** (§1.2, nota 03): a evolução
   **apaga um degrau**. A agência não desbota porque nós a ablacionamos — desbota
   porque a seleção natural a ablaciona, e o reflexo fixa contra o agente em 6000
   ticks. A escada, então, não é só "não-progressiva": ela é **reversível sob
   seleção**. Uma filosofia que trate os degraus como aquisições permanentes está
   descrevendo um mundo que não é este.

## Dois papers, não um

O material já reunido é de **dois** artigos, com públicos distintos. Empacotá-los
juntos enfraquece os dois: o fio comum ("o número não quer dizer o que parece") é
fino demais para sustentar um só.

**Paper 1 — "Quatro réguas da mente, quatro modos de errar."** *(quase pronto)*
Público: metrologia da mente, filosofia experimental, interpretabilidade. Tese: a
bateria falha de quatro maneiras independentes, cada uma com mecanismo, ablação e
conserto. O achado exportável não é sobre a Matrix: **(i)** qualquer métrica da
família *calibração* pode ser satisfeita por uma sonda que lê o ambiente em vez da
representação do agente — um mapa que não pode errar não é um mapa; **(ii)**
qualquer métrica **por-agente** de uma faculdade **relacional** lê zero num agente
sozinho, e nenhum refinamento por-agente conserta isso (o *teste do eremita* como
protocolo geral).

Falta, e é essencial: **consertar `modelo`** (Fase 1.1) e mostrar a régua corrigida
desabando a ~0 sob `prever_valor ≡ 0`. Sem isso temos um relatório de bug, não um
método — a primeira pergunta de qualquer revisor é "e como deveria ser?". Falta
também **replicação** (3 seeds é pouco; a infraestrutura torna 50 baratas: relatar
média ± dispersão).

**Paper 2 — "Cognição como bem posicional."** *(a meio caminho)*
Público: vida artificial, evolução da cognição. Tese: o horizonte de planejamento
é individualmente vantajoso e coletivamente custoso (paisagem de grupo com pico em
`h = 2–3`; invasão de `h = 9` sobre `h = 3` em 3/3 seeds). Rainha Vermelha num
mundo de 56 KB.

Falta: o **torneio de invasão par-a-par 12×12** (para o ESS e o grau de dependência
de frequência) e a **curva dose-resposta do custo de pensar** `h*(c)`, com a
predição do imposto pigouviano. Sem o torneio temos "9 vence 3", que é sugestivo,
não um ESS.

---

# Eixo paralelo — A Matrix como microscópio

**Pergunta:** a Matrix pode produzir conhecimento sobre a Matrix?

Detecção automática de regime: *"a população entrou em colapso"*, *"emergiu uma
nova estratégia"*, *"há duas linhagens distintas"*. A simulação escrevendo o
próprio relatório.

**E aqui está a coisa mais interessante deste documento:** este eixo é
secretamente a Fase 2, subida um nível. Uma Matrix que emite um relatório sobre o
próprio estado **é um sistema com faculdade de `relato`** — e todas as perguntas
da bateria recaem sobre ela. O relatório é calibrado? Ele **carrega
comportamento**, ou é saída inerte (ninguém age sobre ele)? E sobretudo:

> Um detector de mudança de regime que dispara em cima de ruído está
> **confabulando**.

É o intérprete de Gazzaniga um andar acima: um módulo que produz narrativa
plausível para eventos cuja causa ele não observou. Valida-se do mesmo jeito, por
**intervenção**: injete um colapso conhecido e veja se o relatório é honesto;
injete ruído sem colapso e veja se ele inventa.

A régua se vira contra quem mede. É a coisa mais elegante que este projeto pode
fazer. Entra a qualquer momento **depois da Fase 2**, cuja metodologia ele
reaproveita.

---

# Engenharia — o que serve e o que ameaça

**Serve** (tudo reforça a invariante do determinismo):

- replay determinístico, serialização de estados;
- **testes de regressão por seed** — `datasets/gerar.sh` já é um embrião: diff
  não-vazio ⇒ o comportamento mudou;
- proveniência de dados (feito).

**Ameaça:**

- **paralelização e SIMD** vão de frente contra o coração do projeto. Todo o
  método de verificação é "mesma seed ⇒ CSV bit-a-bit idêntico". Ordem de redução
  não-determinística e reassociação de ponto flutuante *quebram isso*. Trocar a
  única propriedade que torna a Matrix um aparato experimental por desempenho que
  ninguém pediu é um mau negócio.
- **otimização (spatial hashing, ECS)** resolve um problema que não existe: ~300
  blocos, percepção 3×3, `ocup[][]` já é lookup O(1). Não há gargalo.
- **`experiment_001.c`, `experiment_002.c`…** — um arquivo por pergunta duplica o
  núcleo da física e, no primeiro descuido, os datasets deixam de ser comparáveis
  porque vieram de *simulações diferentes*. Se os experimentos diferem só em
  parâmetros, eles **são parâmetros** (flags, um struct de config), não unidades
  de tradução. A reprodutibilidade inteira depende de haver **um `main.c`
  canônico por commit**.
- **explodir em `engine/ agents/ …`** — o arquivo único e só-libc é uma
  *identidade*, não um acidente. Quebrá-lo pode ser certo um dia, mas por uma dor
  real, não pelo default de "amadurecer".

## O que a Matrix escolhe não ser

Um benchmark de performance. Um exercício de arquitetura de software. Uma
demonstração de ECS. São coisas boas — em outro projeto. Aqui cada uma custa
determinismo, simplicidade ou identidade, e não compra nenhuma pergunta nova.
