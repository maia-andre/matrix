# Quatro réguas da mente, quatro modos de errar

### Metrologia de uma bateria de senciência num mundo de 56 KB

*(rascunho — fonte do Paper 1; o PDF é artefato de build)*

---

## Resumo

Construímos uma bateria de seis mostradores para perguntar, de agentes num
mundo simulado mínimo, se faculdades como *modelo de mundo*, *agência*,
*auto-modelo* e *integração* **carregam o comportamento**. Depois tentamos
quebrá-la. Os quatro mostradores originais falharam — cada um de um modo
diferente, e **nenhuma das falhas era visível sem tentar quebrá-los**. Um dava
nota máxima a uma população extinta. Um tinha a âncora coevoluindo com o objeto
medido. Um era uma observação lida de graça, com um parâmetro escondido e um
nome que mentia sobre a faculdade. Um era infalseável: nenhuma ablação o zerava.

Este artigo registra os quatro modos, seus mecanismos e seus consertos, e extrai
dois resultados que não são sobre a simulação:

1. **Qualquer métrica da família *calibração* pode ser satisfeita por uma sonda
   que lê o ambiente em vez da representação do agente.** Um mapa que não pode
   errar não é um mapa; e a marca da representação é a possibilidade da
   *des*representação.
2. **Qualquer métrica *por-agente* de uma faculdade *relacional* lê zero num
   agente sozinho**, e nenhum refinamento por-agente conserta isso. Daí o **teste
   do eremita** como protocolo geral: rode a ablação da solidão em qualquer
   métrica por-agente; se ela zerar, ela mediu uma relação, não uma posse.

Um quinto modo apareceu depois, e é de aritmética, não de desenho: `float32` tem
um piso, e ele caiu exatamente sobre uma condição de falseamento. A auditoria em
`double` mostra que ele **tem alvo** — float32 não inverte ordens, **cria
empates**, e só vaza a sonda que dá significado a um empate.

Todas as condições de falseamento foram replicadas: 50 seeds por condição,
**zero violações em 500 corridas**.

---

## 1. O problema

Suponha que você queira saber se um agente tem um modelo de mundo. Você escreve
um número entre 0 e 1, chama de `modelo`, e o número sobe quando o agente prevê
bem. Está feito?

Não. A pergunta que fica de pé é: **o que esse número lê quando o agente não tem
modelo nenhum?** Se ele não despenca, ele nunca leu o modelo — leu outra coisa,
que por acaso andava junto.

Esta é uma pergunta de metrologia, não de filosofia da mente, e ela quase nunca
é feita porque quase nunca é *respondível*: em sistemas reais não se arranca a
faculdade e se roda o mesmo mundo de novo. Nós podemos. Este artigo é o relatório
do que aconteceu quando tentamos.

O achado central não é que nossos mostradores estavam errados — é que estavam
errados **de quatro maneiras estruturalmente diferentes**, e que cada uma delas
tem uma contraparte fora do brinquedo. As quatro sobrevivem à mudança de escala
porque nenhuma depende de o mundo ser pequeno: dependem de o instrumento ter sido
construído sem a pergunta do parágrafo anterior.

## 2. O aparato, e por que um brinquedo

O mundo é um único arquivo C de ~56 KB, sem dependências além da libc. Blocos
ocupam uma grade, comem manchas de comida procedurais, gastam energia para
existir, e se reproduzem. Cada bloco decide olhando **só a vizinhança 3×3** —
nenhum lê estado global; o comportamento coletivo tem de *emergir*. Quatro traços
governam a decisão (`urgencia`, `peso_espaco`, `desconto`, `horizonte`) e são
herdados com mutação, então a população **evolui**.

A propriedade que faz o aparato servir é o **determinismo total**: o universo
inteiro é `f(seed)`. Mesma seed, simulação bit-a-bit idêntica. Isso compra três
coisas que um sistema real não oferece:

- **Ablação exata.** Arrancar uma faculdade e rodar o *mesmo* mundo — mesmo
  ruído, mesma comida, mesma ordem de eventos.
- **Contrafactual barato.** Reler a mesma corrida com uma sonda diferente, sem
  perturbá-la.
- **Um teste de que o conserto não trapaceou.** Se a régua mudou e a simulação
  não, todas as outras colunas do log saem idênticas. Foi assim que pegamos um
  `au / n` que arredondava diferente de `au * (1.0f/n)` e mexia numa coluna que
  não devia.

O preço é óbvio e o pagamos por escrito: um mundo de 56 KB não tem mente nenhuma.
Ele não é um modelo de cognição — é um **banco de provas de instrumentos**. As
conclusões deste artigo são sobre réguas, e réguas erram do mesmo jeito em
qualquer escala.

## 3. Método: duas famílias, e seis regras

A bateria tem duas famílias de sonda, e a diferença entre elas é o motor do
artigo:

- **Ablação** — arranque a faculdade e veja se o comportamento degrada. Responde
  "isto carrega o comportamento?".
- **Calibração** — compare a previsão do agente com o que aconteceu. Responde
  "isto acerta?".

As duas parecem redundantes. Não são: **elas podem apontar para lados opostos**,
e quando apontam, a ablação está certa (§4).

O protocolo tem seis regras. Nenhuma é *a priori*; cada uma foi paga com um erro
real:

1. **Toda ablação reporta duas coisas**: a leitura do mostrador *e* o efeito em
   aptidão. O descasamento entre as duas revelou o modo 1.
2. **Condição de sanidade declarada antes de rodar**: que ablação *tem de*
   derrubar este mostrador a zero? Se nenhuma derruba, ele não mede nada.
3. **Conserto de mostrador não pode mexer na simulação**: todas as outras colunas
   saem bit-a-bit idênticas.
4. **Antes de acusar a régua, congele o traço.** Se a leitura correlaciona com um
   traço que evolui, congele o traço: régua contaminada continua derivando, régua
   boa fica plana. Esta regra matou duas suspeitas nossas (§5 e §7).
5. **Mude uma coisa por vez.** Trocar a sonda e a estatística no mesmo passo torna
   as duas mudanças inseparáveis.
6. **Antes de escrever ✅ num "zera exato", recompute em `double`.** A demonstração
   algébrica vale em ℝ e não basta (§8).

E um corolário, aprendido três vezes: **uma seed não é um resultado** (§9).

## 4. Modo 1 — a sonda lê o território (`modelo`)

O mostrador `modelo` dava **0,973** no controle. Parecia ótimo. A previsão era:

```c
pred_colheita[i] = menor(comida[alvo_y[i]][alvo_x[i]], INGESTAO);
```

Isto lê `comida[][]` — **o array do mundo** — e nunca chama `prever_valor()`. O
mapa que o bloco constrói, e que evolui, jamais era confrontado com o território.
Um tick depois, comparava-se com `garfada = menor(comida[y][x], INGESTAO)`: a
mesma fórmula, sobre a mesma célula. Se o bloco chegasse ao alvo, `real == pred`
**por construção**. `modelo ≈ 0,97` significava *"97% dos blocos não foram
barrados"* — um medidor de **taxa de conflito** com nome de medidor de calibração.

Três ablações independentes, todas apontando para o mesmo lugar:

| condição | `modelo` (quebrado) | população |
|---|---|---|
| controle | 0,973 | 312 |
| `horizonte = 1` (mapa raso) | **0,994** ↑ | 321 |
| `prever_valor ≡ 0` (sem mapa) | **1,000** ↑↑ | **extinta** |
| solipsista (cego aos rivais) | 0,789 ↓ | 314 |

Lobotomizar o horizonte faz a nota **subir**. Remover o modelo de mundo por
inteiro dá **nota perfeita** — a uma população que se extingue em 51–121 ticks.
Cegar o bloco para os rivais faz a nota **descer**, porque sem aversão a multidão
os blocos se amontoam e a congestão sobe. Nenhuma das três tem a ver com a
qualidade de um modelo de mundo.

**As duas famílias apontaram para lados opostos.** A ablação disse a verdade
(arranque `prever_valor`, a população morre: a faculdade carrega o comportamento).
A calibração deu nota máxima a um cadáver.

> A sonda lia o array do mundo. Um mapa que é **fotocópia** do território não pode
> discordar dele. E um mapa que **não pode errar não é um mapa** — a marca da
> representação é a possibilidade da *des*representação.

O mostrador fora construído removendo exatamente a condição que faria dele um
mostrador.

**O conserto.** A previsão passa a sair de `prever_valor(alvo, bloco)` — o mapa do
bloco, com o horizonte, o desconto e a partilha *dele*. A janela dura os
`horizonte` ticks do próprio bloco e fecha quando o horizonte se esgota, ou quando
o bloco morre — que é a previsão mais errada possível. Condição de sanidade,
declarada antes: se `prever_valor ≡ 0` não derrubar `modelo` a ~0, o conserto não
consertou. Resultado: **0,000 exato**. O controle passa a ler **0,63**: há folga
nos dois sentidos. O mapa agora pode errar, e erra.

**Achado colateral — o bloco tem uma crença falsa.** Com o mostrador honesto, o
controle lê 0,638 e o *solipsista* lê 0,783: um bloco que ignora os rivais prevê
**melhor**. A causa é uma crença falsa: via `partilha = 1/(1 + COMPETICAO·rivais)`
o bloco acredita que os rivais dividem a comida da célula que ele ocupa — mas o
mundo guarda **um** bloco por célula, e ninguém divide nada, nunca. Removê-la
recupera 0,16 de calibração e **não muda a população**. É custo epistêmico puro ao
nível do grupo. Se é *individualmente* vantajosa é outra pergunta — a de McKay &
Dennett (*The evolution of misbelief*, 2009), e ela é executável aqui.

## 5. Modo 2 — a âncora coevolui com o objeto (`agencia`)

`agencia` pergunta se o estado interno (a fome) muda a decisão. A sonda antiga
clonava o bloco em dois pontos de fome escolhidos a dedo:

```c
faminto.energia = 0.10f * SACIADO;
saciado.energia = 1.00f * SACIADO;
```

Escrevendo a utilidade de cada célula e dividindo pelo fator `(1 + urgencia·fome)`
— positivo e igual para todas as células, logo inofensivo ao `argmax`:

```
nota(k) = comida_prev(k) + λ · espaco(k),   λ = peso_espaco·(1 − fome)/(1 + urgencia·fome)
```

Cada célula é uma **reta em λ**; a escolha é o **envelope superior** dessas retas.
E `λ` decresce estritamente com a fome, varrendo `[0, peso_espaco]`. Isso expõe o
defeito: os dois pontos visitavam `λ ∈ [0,1·P/(1+0,9·u), P]` — com `u = urgencia`,
**um traço que evolui**. O extremo inferior da sonda coevoluía com a população
medida, e a faixa `λ ∈ [0; 0,034·P]` nunca era visitada.

**O conserto** varre `λ` inteiro em 33 amostras. Como no envelope superior cada
reta vence no máximo um intervalo contíguo, há no máximo `(opções − 1)` trocas, e
amostrar só pode *subestimar* trocas — nunca inventar uma. A estatística continua
a mesma de propósito (regra 5). Leitura no controle: **0,388 → 0,435** — a sonda
antiga perdia ~12% dos blocos.

E aqui vem a parte que interessa. Fomos consertar `agencia` **convencidos de que
ela estava contaminada**: sua leitura correlacionava +0,98 com `peso_espaco`, um
traço que evolui. A regra 4 diz: antes de acusar a régua, congele o traço.

| tick | 500 | 5 000 | 15 000 | 29 999 |
|---|---|---|---|---|
| `agencia`, `peso_espaco` **livre** | 0,430 | 0,360 | 0,059 | **0,049** |
| `esp_m`, livre | 2,760 | 1,677 | 0,131 | **0,079** |
| `agencia`, `peso_espaco` **congelado** | 0,464 | 0,486 | 0,447 | **0,440** |

Plana. **A régua é estável; o objeto é que muda.** A correlação era mecanismo, não
contaminação: `peso_espaco` é o único canal pelo qual o estado interno pode mudar
uma decisão, e quando ele morre a política vira reflexo — `argmax(comida_prev)`, e
nada mais.

E o traço não morre por acaso. `esp_m` cai monotonicamente de 3,0 a 0,08; um traço
neutro em `[0, 8]` derivaria para o meio, não para a borda. O ensaio de invasão
decide: população 50/50 de `peso_espaco = 0` (**reflexo**) e `3,0` (**agente**),
herança exata. O reflexo **fixa** em ~6000 ticks (frequência final 0,997 / 1,000 /
1,000). Ao nível do grupo, ser agente custa ~0,9% de população — mas população de
grupo não é aptidão individual, e é a invasão que decide.

O bloco continua tendo valência: a energia sobe, desce, e a zero ele morre. O que
a evolução apagou não foi o estado interno — foi o **uso** dele na decisão. A
política vencedora computa um modelo de mundo com horizonte, desconto e partilha,
e não pergunta uma única vez como está se sentindo.

**A lição metrológica é a mais desconfortável do artigo.** O mostrador tinha um
defeito real, e o defeito real não era o que a leitura incômoda apontava. A régua
estava dizendo a verdade — *a agência desbota* — e nós estávamos prestes a
"consertar" o instrumento até ele parar de dizer isso. Vale registrar o viés: **a
primeira reação a uma leitura incômoda foi acusar a régua.**

## 6. Modo 3 — a observação disfarçada de intervenção (`modelo_do_outro`)

O mostrador `automodelo` tinha três defeitos de uma vez, e o conserto de todos foi
a mesma edição. O código era uma linha:

```c
if (intencao_x[i] != alvo_x[i] || intencao_y[i] != alvo_y[i]) au += 1.0f;
```

**(1) Observação, não intervenção.** `intencao` e `alvo` já existem porque o
*tick* precisa deles. O mostrador só os relia. `agencia`, ao lado, varre o domínio
inteiro do estado interno e conta trocas: uma intervenção construída de propósito.
Somar os dois no mesmo eixo `[0,1]` é somar uma medida a uma anedota.

**(2) Um parâmetro escondido.** A força da antecipação é `ANTECIPACAO = 0.5` — uma
lei da física, não um traço do bloco. Varrendo a força `α` de 0 a ∞ (a mesma
corrida relida), a leitura desenha uma curva:

| `α` | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| 0 | 0,0000 | 0,0000 | 0,0000 |
| 0,25 | 0,2872 | 0,2942 | 0,2566 |
| **0,5** *(a sonda antiga)* | **0,3407** | **0,3481** | **0,3070** |
| 1 | 0,3528 | 0,3596 | 0,3200 |
| 4 → ∞ | 0,3540 | 0,3608 | 0,3220 |

`0,5` é só **um ponto no meio da subida**. Tivesse `ANTECIPACAO` valido 0,25, o
mostrador leria ~0,29; a 0,125, ~0,19. O valor absoluto era função de uma
constante escolhida por outro motivo — não uma propriedade do que se dizia medir.

**(3) O nome mente.** "Antecipar os rivais mudou minha escolha" é um modelo **do
outro**, não de si. E o *teste do eremita* é definitivo: sem perceber rivais,
nenhuma célula é disputada, e a leitura é **zero exato** (média *e* máximo, 3
seeds). Uma faculdade que some quando o outro some não é uma posse do bloco.

**O conserto** troca a espiada num ponto por um critério exato. Com força `α ≥ 0`,
cada célula alcançável vale `nota_k(α) = u_k / (1 + α·pret_k)`. Como cada `nota_k`
só decresce em `α` (célula disputada) ou fica plana (`pret = 0`), a escolha muda
para algum `α > 0` **se, e só se** a escolha pré-social é disputada *e* existe
alternativa que a ultrapassa quando a disputa aperta. O critério não menciona
`ANTECIPACAO`, não amostra nada, e é por construção a assíntota `α → ∞` da curva
acima — a linha `4 → ∞` e a leitura ancorada batem a **quatro casas**. E o nome
honesto: `modelo_do_outro`.

**Aqui o número quase não muda** (`~0,34 → ~0,35`). O achado desta seção não é um
número errado: é um **método** e um **nome** errados. Um mostrador pode acertar o
valor e ainda assim não medir o que diz.

A assimetria que denuncia o nome: na `agencia`, o eixo varrido (a fome) é um
estado interno que o bloco **de fato visita**. Aqui, `α` é uma força externa que o
bloco **nunca varia** — varrer `α` é rodar um contrafactual que não ocorre. Não há
estado interno para ancorar porque não há nada interno sendo medido. **O conserto
que a torna honesta e o nome honesto são a mesma coisa.**

## 7. Modo 4 — a régua infalseável (`phi`)

`phi_proxy()` devolvia `10.0f * disc/tot`, sem clamp, enquanto a documentação
afirmava `[0,1]`. O fator `10.0f` fora escolhido para o número *parecer* morar em
`[0,1]`, o que esvazia o valor absoluto. Mas o defeito real era pior, e a regra 2 o
encontra. Tabela de ablações:

| condição | `phi` velha |
|---|---|
| controle | 0,255 |
| `horizonte = 1` | 0,263 — **sobe** com a lobotomia do plano |
| `prever_valor ≡ 0` | 0,131 — sem modelo nenhum, morrendo, "integra" 0,13 |
| solipsista | 0,039 |
| `COMPETICAO = 0` | 0,192 |

**Nenhuma ablação a zera.** Pela regra 2, a `phi` velha **não media nada** — no
sentido estrito de que nenhuma leitura dela podia obrigar a retirar a palavra. E o
motivo é estrutural, não numérico: "discordar da ordem da comida" não é
irredutibilidade. Uma decisão 100% explicada pelo espaço discorda muito da comida
— e é redutível a **um** módulo. A régua chamava de "integração" qualquer coisa
que não fosse o reflexo alimentar.

Havia também uma suspeita registrada: `phi` seria sinônimo de profundidade efetiva
de planejamento (correlação +0,94/+0,70/+0,90). A regra 4 de novo, e de novo ela
mata a suspeita — mas por um caminho diferente do §5. A correlação **muda de sinal
com a janela**: nos primeiros 3 000 ticks *dos mesmos dados* ela é −0,31/−0,13/−0,42.
Uma correlação que troca de sinal com a janela não é estrutura da régua; é o rastro
de duas séries não-estacionárias descendo a mesma ladeira evolutiva. **Co-tendência,
não acoplamento.** E o traço congelado dissocia: congelar a profundidade **não**
segura a `phi` (desaba como o controle); congelar `peso_espaco` **segura**. Quem
carrega a `phi` é o mesmo traço que carrega a `agencia`.

**A redefinição.** A caricatura IIT passa a perguntar o que a intuição de
integração pede: *o todo é redutível a alguma parte?* Compara-se a ordem integrada
com a ordem de **cada módulo isolado** — comida-agora, espaço, mapa — e `phi` é a
**menor** das distâncias de Kendall, já em `[0,1]`, sem fator de escala:

```
phi = min( d(u, comida), d(u, espaco), d(u, mapa) )
```

Se um módulo sozinho reproduz a decisão, `phi = 0`: integrar uma coisa só não é
integrar. A estatística é a mesma da velha, de propósito (regra 5) — mudou a
**referência**, de uma para o mínimo sobre três. Três zeros, demonstráveis antes de
rodar e verificados exatos: eremita (`espaco` constante ⇒ `d(u,espaco) = 0`),
`peso_espaco ≡ 0` (utilidade = escalar × mapa ⇒ `d(u,mapa) = 0`), `prever_valor ≡ 0`
(só resta o espaço). E a régua não é degenerada: controle ≈ 0,065.

O que a régua nova diz é o §5 um andar acima. Em 30 000 ticks, `phi` no controle
vai de 0,044 a **0,005**; com `peso_espaco` congelado, fica de pé. **A seleção não
extingue só a agência: extingue a irredutibilidade da decisão.** Neste mundo,
integrar motivos é um luxo que não paga a própria conta.

## 8. O quinto modo, que é de aritmética: o zero estrutural

Os quatro modos acima são de **desenho**. Há um quinto, que descobrimos tarde e
que é de **aritmética** — e ele caiu exatamente onde mais dói.

A demonstração do §6 (e a do eremita em geral) é uma prova em ℝ: sem rivais,
`espaco ≡ 1`, o termo vira constante entre as células e **some do argmax**. Logo
`agencia ≡ 0`. A prova está correta. A régua, porém, roda em `float32` — e lá "some
do argmax" **vaza**: somar a mesma constante a duas utilidades quase empatadas pode
inverter qual é estritamente maior. Medida no eremita, a `agencia` tem um piso de
~0,003–0,005. Recomputando só a comparação em `double`: **0,0000 exato**.

Um ✅ da nossa tabela era falso — não por erro de conceito, mas de arredondamento.
Daí a regra 6.

A dívida que isso criou (os outros três zeros nunca tinham sido recomputados) foi
paga com uma auditoria a nove casas, medida **na fonte** e não no log — porque o
log tem três esconderijos: o `%.3f` (um piso < 0,0005 é invisível), a média
populacional (um bloco não-zero some numa média de ~300), e o clamp do κ (um κ
negativo de arredondamento viraria 0 sem rastro).

| condição de falseamento | float32 | double |
|---|---|---|
| `modelo` sob `prever_valor ≡ 0` | **0, exato** | **0, exato** |
| `phi` sob eremita, `peso_espaco ≡ 0`, `prever_valor ≡ 0` | **0, exato** | **0, exato** |
| `relato` sob intérprete cego | **0, exato** | **0, exato** |

E o resultado negativo que **não** veio é o achado. O piso não era um aviso
genérico sobre float32: **ele tem alvo**.

> **Float32 não inverte ordens — cria e destrói empates.** Só vaza a sonda que dá
> *significado* a um empate.

Por mecanismo:

- **`modelo`**: com `pred = 0`, a nota é `1 − real/real`, e `x/x = 1` é identidade
  IEEE754 em qualquer precisão. **Zero por identidade.**
- **`phi`**: ou o módulo é constante entre células (diferenças exatamente 0, e
  *empate não é discordância*), ou a ordem é herdada por multiplicação por escalar
  positivo comum — e o arredondamento é monotônico: cria empates, nunca inversões
  estritas; e empate só *reduz* a contagem. **Zero por monotonia.**
- **`relato`**: `po` e `pe` do intérprete cego são o mesmo quociente real, e a
  divisão IEEE arredonda o mesmo real para o mesmo float. **Zero por igualdade de
  quociente.**
- **`agencia`** (a que vazou): a mesma constante **somada** a todas as notas. A soma
  arredondada não inverte ordem — mas cria empates onde ℝ não tem. E a agência conta
  **trocas de argmax sob desempate estrito `>`**: um empate fantasma entrega a
  vitória ao índice menor; no passo seguinte o empate se desfaz e a vitória volta.
  Cada ida-e-volta conta como troca. Piso.

Daí uma **regra de desenho** que exportamos: um mostrador que conte trocas de
argmax deve ter a condição de falseamento desenhada para produzir **o mesmo float
em todo o eixo varrido**, e não "termos que se cancelam em ℝ". O zero tem de ser
estrutural, não algébrico — senão a régua nasce com um piso exatamente onde menos
se pode ter um.

## 9. Replicação: 50 seeds

Todos os números acima nasceram de 3 seeds. "Uma seed não é um resultado" é o
corolário que aprendemos três vezes; pagá-lo custou 9 condições × 50 seeds × 3000
ticks, com os valores de 3 seeds publicados como pré-registro antes de rodar.

**Os dez zeros do Apêndice A: zero violações em 500 corridas.** Nenhuma seed, em
nenhuma condição, produziu um tick que viole um zero. Os zeros estruturais do §8 se
comportam como estruturais.

Os controles, agora com barras:

| mostrador | 50 seeds |
|---|---|
| `modelo` | 0,6293 ± 0,0105 |
| `agencia` | 0,4175 ± 0,0265 |
| `modelo_do_outro` | 0,2672 ± 0,0538 |
| `phi` | 0,0649 ± 0,0039 |
| `relato` | 0,6310 ± 0,0111 |
| `autocausa` | 0,1381 ± 0,0113 |

E a pergunta desconfortável do §8 — *qual é o piso da régua fora do eremita, onde
não há verdade algébrica para comparar?* — tem resposta, obtida comparando **a
régua com ela mesma em outra precisão**:

| regime | blocos-tick discordantes | fração | direção |
|---|---|---|---|
| eremita | 42 de 42,0 M | 1,0·10⁻⁶ | 42× fantasma f32, 0× o contrário |
| normal | 6 de 43,4 M | **1,4·10⁻⁷** | 5 fantasma, 1 o contrário |
| `peso_espaco ≡ 0` | 0 de 43,5 M | 0 | (λ ≡ 0: o eixo nem existe) |

**O piso é fenômeno do regime eremita.** Lá o quase-empate é sistemático e tem
direção. Na população normal ele é um evento a cada ~7 milhões de blocos-tick —
cinco ordens de grandeza abaixo do sinal — e ocorre **nas duas direções**: precisão
finita, não viés.

A replicação também moveu três coisas, e é para isso que ela serve. A extinção sem
mapa passou de "74–105 ticks" para **51–121** (a cauda era mais larga que a
amostra). A referência do `modelo_do_outro` recalibrou de ~0,35 para 0,27 ± 0,05 —
e **não** por régua derivando: quando a estratégia de sinalização virou traço
herdável, mudos e blefadores entraram na população, e um mostrador que mede
"antecipar o outro pelo sinal dele" lê menos num mundo onde ~24% não sinaliza
honestamente. E um erro do nosso próprio pré-registro ficou registrado como erro:
comparamos um número de 30 000 ticks com um lote de 3 000. As seeds canônicas
(7, 42) eram, em mais de um mostrador, **sorteios altos**.

## 10. Os dois morais exportáveis

Nada nas duas conclusões abaixo depende de o mundo ter 56 KB.

**1. Qualquer métrica da família *calibração* pode ser satisfeita por uma sonda que
lê o ambiente em vez da representação do agente.** O teste é uma pergunta: *o que
esta sonda lê quando o agente não tem representação nenhuma?* Se ela não despenca,
ela nunca leu a representação. Note que o modo 1 não foi um bug — o código estava
correto, fazia exatamente o que dizia, e passava em qualquer revisão. O defeito era
que a sonda tinha acesso a uma variável à qual o *agente* não tem acesso. Em
qualquer sistema onde o instrumento e o objeto medido compartilham o mesmo espaço
de endereçamento, esse erro está disponível.

**2. Qualquer métrica *por-agente* de uma faculdade *relacional* lê zero num agente
sozinho** — e nenhum refinamento por-agente conserta isso. Daí o **teste do
eremita** como protocolo geral: rode a ablação da solidão em qualquer métrica
por-agente; se ela zerar, ela mediu uma relação, não uma posse. Isto não é um
defeito a consertar: é uma **descoberta sobre a faculdade**. Duas das palavras mais
"mentais" da nossa escada — agência e auto-modelo — não medem nada que o agente
*tenha*. Medem algo que acontece **entre** agentes. O conserto honesto do
`automodelo` não foi torná-lo internalista; foi **renomeá-lo**.

E um terceiro, mais barato de enunciar e mais caro de aceitar: **as duas famílias
de sonda podem discordar, e quando discordam a ablação ganha.** Um número de
calibração alto é compatível com a extinção. A pergunta "isto acerta?" e a pergunta
"isto carrega o comportamento?" são perguntas diferentes, e só a segunda tem a ver
com a faculdade.

## 11. Ameaças à validade

- **O mundo é um brinquedo.** Não há nenhuma alegação de que blocos tenham mente.
  As alegações são sobre instrumentos, e o brinquedo é o banco de provas — a
  ablação exata e a rerodada bit-a-bit são o que um sistema real não dá.
- **A ablação `horizonte = 1` é confundida**: o mapa enxerga 1 passo, mas a janela
  de comparação continua durando `horizonte` ticks do bloco. As conclusões do §4 não
  dependem dela.
- **A `phi` nova depende de uma decomposição escolhida à mão.** "Irredutível a
  {comida, espaço, mapa}" é fiel ao espírito IIT (mínimo sobre partições), mas a
  nossa é uma amostra de três, não o ínfimo verdadeiro.
- **33 amostras de λ subestimam trocas** em intervalos estreitos. Direção do erro
  conhecida, magnitude não medida.
- **A janela é de 3 000 ticks** na replicação. Os fenômenos de janela longa (30 000)
  não foram replicados no mesmo lote.
- **A auditoria em `double` recomputa a comparação**, não a acumulação. Para os zeros
  é irrelevante (`1 − x/x` não depende da precisão de `x`); para o *valor* dos
  controles, carrega precisão não auditada.
- **`phi` e `agencia` seguem correlacionadas por mecanismo** — o mesmo traço carrega
  as duas. Não é defeito: são perguntas diferentes que este mundo, com um só segundo
  motivo, responde junto. Um mundo com terceiro motivo as separaria, e é um teste
  barato.

---

## Apêndice A — condições de falseamento por mostrador

| mostrador | a ablação que TEM de zerá-lo | verificado |
|---|---|---|
| `modelo` | `prever_valor ≡ 0` | ✅ 0,000 exato — auditado em `double`: 0 exato nas duas precisões, média e pior janela |
| `agencia` | eremita (sem rivais percebidos) | ⚠️ 0 exato **em ℝ**; em `float32` tem piso de ~0,003–0,005 (§8). Zera exato em `double` |
| `modelo_do_outro` | eremita (sem pretendentes) | ✅ 0,0000 exato, média e máx. Imune ao piso: critério exato, sem varredura |
| `phi` (redefinida) | qualquer redução a um módulo só | ✅ 0 exato, demonstrável — auditado em `double`, bloco a bloco, nas três reduções |
| `relato` | intérprete cego (relato ≡ constante) | ✅ 0,0000 exato — pré-registrado **antes** do código; κ = +0 exato, inclusive antes do clamp |
| `autocausa` | `horizonte = 1` (sem futuro, não há onde se modelar) | ✅ 0,0000 exato, média **e máximo** — e exato **por construção**. **O eremita NÃO o zera** — é o único, e é o ponto |

Todas replicadas: 50 seeds por condição, **0 violações em 500 corridas**.

## Apêndice B — reprodução

Há **um** `main.c` canônico; toda ablação é um patch numa cópia temporária, e
todo script aceita um `main.c` alternativo para rodar contra versões passadas
(`git show <commit>:main.c`). Os scripts de cada seção:

| seção | script | nota |
|---|---|---|
| §4 modo 1 | `papers/notes/01-ablacoes.sh` | 01 |
| §5 modo 2 | (invasão e traço congelado) | 03 |
| §6 modo 3 | `papers/notes/04-modelo-do-outro.sh` | 04 |
| §7 modo 4 | `papers/notes/05-phi.sh` | 05 |
| §8 aritmética | `papers/notes/10-auditoria-double.sh` | 09, 10 |
| §9 replicação | `papers/notes/11-replicacao.sh` | 11 |

As notas em `papers/notes/` preservam a evidência que os consertos destruíram: ao
consertar um mostrador, o `main.c` muda e os CSVs congelados são regenerados. Sem
nota + script, o achado vira anedota. As notas registram também as **hipóteses
mortas** — num projeto cuja tese é sobre o que uma medida carrega, hipótese morta
é dado.
