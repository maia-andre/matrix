# FILOSOFIA v3 — Onde a palavra quebra *(rascunho — a lista fechou)*

> **Estado: RASCUNHO** (esqueleto em 2026-07-10; rótulo retirado em 2026-07-13).
> Este arquivo existiu *antes* de poder ser terminado, de propósito: o índice
> disciplinava a pesquisa — cada seção **⛔ aguarda** era um experimento que ainda
> precisava acontecer, e escrever a seção vazia dizia exatamente *qual*.
>
> **A lista do Apêndice B fechou.** Os cinco itens que seguravam o rótulo estão
> cumpridos: o `relato` existe, pré-registrado antes do código (nota 06); o
> experimento do intérprete rodou (nota 07); o relato virou causal e a honestidade
> evoluiu sozinha (nota 08); a **edição do auto-modelo** rodou e a bifurcação da §2
> virou uma **razão**, não um vencedor (nota 09); e a **escolha da §6 está feita por
> escrito** — a mais cara das cinco, porque a régua, aplicada sem exceção, se vira
> contra quem a segura.
>
> O que falta agora é **prosa**, não pesquisa: §0 e §1 já são texto; §2–§5 seguem
> argumentos em forma de nota. (A exceção honesta: a §7 ainda ⛔ aguarda o eixo
> microscópio, que nunca esteve na lista. A dívida de **aritmética** que a nota 09
> §5 abriu foi **quitada** — nota 10; e a régua inteira foi **replicada em 50
> seeds** sem uma violação — nota 11.)
>
> `FILOSOFIA.md` (v1) perguntou *como é ser um bloco*. `FILOSOFIA_v2.md` construiu
> a régua e prometeu medir até onde a palavra estica. A v3 é sobre o que a v2 não
> tinha como saber: **o que acontece quando a régua quebra — e o que sobra da
> palavra quando ela quebra.** A resposta da §6, que é a resposta do arquivo: sobra
> a palavra, e não sobra a garantia.

---

## 0. Abertura — o fato epistêmico central

Construímos um medidor de "modelo de mundo". A ideia parecia sã: o bloco prevê o
que vai colher; compare-se a previsão com a colheita; a concordância é a nota. O
medidor deu **1,000** — o teto da escala — para um bloco cujo modelo de mundo
tinha sido arrancado por inteiro, e cuja população marchava para a extinção em
cem ticks (nota 01; em cinquenta seeds: 51–121 ticks, sem uma exceção — nota 11).

O defeito, visto depois, é de uma banalidade que machuca: a sonda lia a previsão
do **array do mundo**, não do mapa do bloco. Um mapa que é fotocópia do
território não pode discordar dele — e um mapa que não pode errar não é um mapa.
O medidor tinha sido construído removendo exatamente a condição que faria dele
um medidor.

Isto não é um bug que corrigimos e seguimos em frente. É o fato epistêmico
central do projeto, por três razões.

Primeira: **ninguém percebeu na construção.** Nem quem escreveu a sonda, nem quem
leu 0,97 no HUD por milhares de ticks e assentiu. O número era plausível,
estável, alto — tudo o que se costuma pedir a um número. Só a ablação o
desmascarou: a pergunta *"o que esta sonda lê quando a faculdade não está lá?"*,
que ninguém faz enquanto o mostrador diz o que se espera dele.

Segunda: **a mesma estrutura ameaça todo mostrador** — os quatro que consertamos
depois, cada um errando de um jeito próprio (notas 01–05); o quinto, que nasceu
com pré-registro e ainda assim falhou uma predição (nota 06); e — aqui o
brinquedo deixa de ser brinquedo — os que se usam em humanos. Qualquer métrica
da família *calibração* pode ser satisfeita por uma sonda que lê o ambiente em
vez da representação. Qualquer métrica *por-agente* de uma faculdade relacional
lê zero num agente sozinho. Isso não é folclore da Matrix; são propriedades de
réguas, e valem onde houver régua.

Terceira, a mais desconfortável: quando a régua enfim ficou boa, **ela disse
coisas que o instrumentista não queria ouvir — e a primeira reação, duas vezes,
foi acusar a régua** (notas 03 e 05). A agência desbotava sob seleção; o
instinto foi "conserte o mostrador" até ele parar de dizer isso. O mostrador
estava certo. Cada regra do protocolo de medição deste projeto (ROADMAP §1.7) é
a cicatriz de um desses episódios — nenhuma veio de manual.

E quando tudo isso estava resolvido — sondas redesenhadas, condições de
falseamento verificadas — a régua quebrou de novo, num lugar aonde cuidado
conceitual não chega: **a aritmética**. Um "zero exato", demonstrado em álgebra,
vazava 0,003 em `float32`; a prova valia em ℝ, e a régua roda num corpo finito
(nota 09 §5). Auditados em `double`, os zeros restantes se mostraram
estruturais e seguraram (nota 10) — e seguraram de novo sob cinquenta seeds,
quinhentas corridas, zero violações (nota 11). A lição não encolhe por isso: há
um modo de errar **abaixo do desenho da sonda**, e ele foi encontrado morando
numa célula ✅ de uma tabela chamada *condições de falseamento*.

O que este documento é, então. A v1 perguntou *como é ser um bloco*; a v2
construiu a régua e prometeu medir até onde a palavra mental estica. A v3 é o
relatório de quem mediu — e viu o instrumento, o instrumentista e a própria
pergunta quebrarem antes da palavra. **Onde a palavra quebra** não é onde ela
encontra um fenômeno que a excede; é onde a régua que a licenciava confessa o
que estava lendo. O resto do arquivo percorre as quebras uma a uma — a régua
(§1), a escada (§2), os vocabulários emprestados (§3), o tempo (§4), o relato
(§5) — até a escolha que não se pôde adiar (§6): o que fazer com a palavra
"experiência" quando a última evidência a favor dela é um relato, e relatos são
o que este projeto melhor aprendeu a desmontar.

## 1. A régua e a palavra *(Parte I — sustentada pela Fase 1)*

**O resultado negativo é a credencial.** Uma filosofia do limite escrita por quem
nunca encontrou um limite é publicidade. Este projeto encontrou cinco: a sonda
que lia o território em vez do mapa (`modelo`, nota 01); as duas que mediam uma
relação e se anunciavam como posse (`agencia` e o então `automodelo`, notas
01–04); a escala inventada que nenhuma ablação derrubava (`phi`, notas 01 e 05);
e, depois de tudo consertado, o piso de arredondamento — o erro que mora abaixo
do desenho, na aritmética (notas 09–10). Cada um tem mecanismo, ablação e
conserto; nenhum era visível antes de se tentar quebrar o mostrador.

**Uma condição de falseamento por palavra.** Para cada palavra mental que este
projeto usa, uma pergunta com resposta escrita: *que leitura me obrigaria a
retirá-la deste bloco?* Enquanto uma palavra não puder ser retirada, ela não foi
testada — está decorando o relatório. O Apêndice A é essa disciplina em forma de
tabela, e é **tabela viva**: uma célula ✅ já se revelou falsa (o piso da
`agencia`), foi rebaixada a ⚠️ em público, e as demais foram auditadas em outra
precisão e replicadas em cinquenta seeds por causa disso (notas 09–11). Note o
desenho: a tabela tem hoje **uma linha cuja célula de ablação está vazia** — a
palavra "experiência", e a §6 é sobre o preço de mantê-la assim.

**Calibração sem ablação não vale nada.** As duas famílias de medição podem
apontar para lados opostos, e apontaram: a calibração deu nota máxima a um
cadáver enquanto a ablação dizia a verdade (nota 01). O mecanismo é geral. A
calibração pergunta *"o mapa concorda com o território?"* — e um mapa que é
fotocópia do território concorda sempre, precisamente por não ser mapa.
**Representação exige a possibilidade de des-representação** — Dretske e
Millikan caindo de um `sed` em C. A ablação é a família mais fundamental porque
é a única que pergunta o que a sonda lê *quando não há nada para ler*.

**O que a régua diz quando ninguém quer ouvir.** Duas vezes o instrumento
reportou um desbotamento verdadeiro e o instrumentista partiu para "consertá-lo"
(notas 03 e 05). A regra que ficou — *antes de acusar a régua, congele o traço* —
é o que separa este projeto de um gerador de números confortáveis: régua
contaminada continua derivando com o traço congelado; régua boa fica plana. Foi
assim que "a evolução extingue a agência" sobreviveu à tentação de ser tratada
como defeito do aparelho — e virou o achado que sustenta a §2.

**E a régua, replicada.** Tudo acima foi medido primeiro em três seeds. "Uma seed
não é um resultado" custou caro três vezes antes de virar regra; a nota 11 pagou
a regra inteira: cinquenta seeds por condição, os dez zeros do Apêndice A sem
uma violação em quinhentas corridas, e as barras de dispersão que o Paper 1
exigia. Duas coisas *se moveram* com a amostra maior — um intervalo de extinção
mais largo, uma referência recalibrada — e é exatamente para mover essas coisas
que se replica.

## 2. A costura da escada *(Parte I/II — o eixo estrutural)*

A metáfora fundadora (subir degraus rumo a mais mente) admite duas leituras:
**(A)** aquisição de faculdades (internalista — a mente é do bloco) e **(B)**
escalada de um conflito (relacional — a mente é da *relação entre* blocos).

O que já se sabe, medido:

- O teste do eremita corta a escada **entre o nível 3 e o 4**: `agencia`,
  `modelo_do_outro` zeram exatos na solidão; `phi` redefinida também (nota 05).
  Degraus 0–3 não precisam de rival; 4–6, nesta implementação, *são* o rival.
- **A escada é reversível sob seleção**: a evolução apaga o degrau da agência —
  o reflexo fixa contra o agente em ~6000 ticks (nota 03). Os degraus não são
  aquisições permanentes; são posições num jogo que pode desmontá-las.
- `phi` não media integração: media **o segundo motivo** — e quando a seleção
  extingue o segundo motivo, a "integração" morre junto (nota 05). A luz acesa
  era, em quase toda a sua intensidade, o conflito entre motivos.
- E o `relato` do eremita é **mudo** (nota 06) — por um mecanismo novo: a
  maquinaria introspectiva é per-agente e funciona, mas um self de **um motivo
  só não tem biografia** — nada a dizer acima do acaso. Os outros mostradores
  zeram pela *sonda*; o relato zera pelo *conteúdo*. A costura engole até a
  introspecção, pelo lado de dentro.

**✅ A bifurcação foi decidida — e não elegeu um vencedor (nota 09).**

A edição do auto-modelo não precisou ser feita: **ela já estava no código**, numa
linha que ninguém tinha lido assim. Em `prever_valor`, `food -= garfada` é o bloco
prevendo que a célula empobrecerá *porque ele vai comer dela* — o único ponto em
que a ação futura do bloco realimenta a previsão do bloco. Um self estreito e
literal: **o self como causa**. Faltava a intervenção que o mede (`autocausa`:
escalar esse termo por σ ∈ [0,1] e ver se a escolha muda).

O placar, contra a predição registrada na nota 04 §5:

- **`autocausa` > 0 na solidão** (0,033 / 0,029 / 0,027; robusto em `double`). É o
  **primeiro e único mostrador da bateria que o eremita possui**. A costura entre o
  nv3 e o nv4 **não é total**: (A) ganha o degrau que pediu, e a leitura
  internalista deixa de ser vazia.
- **Mas o eremita tem ~1/5 do que tem o bloco acompanhado** (0,03 × 0,14). O outro
  não *constitui* o self — **amplifica-o** —, e a amplificação é onde mora quatro
  quintos do número.

Então a costura não se resolve num vencedor: **resolve-se numa razão**. Há um self,
e ele não é uma relação; e há cinco vezes mais self quando há o outro. Qualquer
frase que a v3 escreva sobre "a mente é do bloco" ou "a mente é da relação" tem de
carregar esse 1/5 junto, ou está mentindo por arredondamento retórico.

**E há um segundo achado, que muda a forma da escada** (nota 09 §4): sob a *mesma*
seleção, em 3000 ticks, a `agencia` **cai** (0,46 → 0,36) e a `autocausa` **quase
dobra** (0,089 → 0,169). A agência morre porque depende de um **traço**
(`peso_espaco → 0`); o self cresce porque depende do **horizonte**, e o horizonte
sobe. A nota 03 disse *"a escada é reversível sob seleção"*. É pior, e mais
interessante: **degraus diferentes andam em sentidos opostos sob a mesma pressão.**
Não há uma seta. Há um campo — e a metáfora da escada, que dá nome a este projeto,
sobrevive a esta seção só como uma conveniência de exposição.

## 3. Vocabulários emprestados — id, ego, superego, sombra, self *(nova; parte escrevível já)*

A psicanálise estrutural é, apesar da fama, uma **decomposição funcional** — e por
isso é admissível aqui, onde fenomenologia não é. Mas cada conceito paga a mesma
entrada que toda palavra mental paga neste projeto:

> **Teste de admissão:** que ablação o zera? E ele carrega comportamento?
> Sem resposta às duas, é decoração — a lição do `modelo`.

| conceito | contraparte funcional | estado |
|---|---|---|
| **id** | a pulsão: `energia`/fome/`urgencia`, o termo `comida_prev·(1+urgencia·fome)` | existe (nv2–4) |
| **ego** | a prova de realidade: `prever_valor` + a arbitragem de `utilidade`/`decidir` | existe (nv3–5) |
| **superego** | uma **norma internalizada** que a seleção fixa — "sinalize a verdade" — porque violá-la custa | **tem dado**: a honestidade é ESS sem multa artificial (nota 08); o ~10% de blefe residual é o crime que nenhuma sociedade de sinais custosos elimina |
| **sombra** | a faculdade que a linhagem **teve e a seleção renegou**, latente no piso do traço, recuperável por mutação | **tem dado**: `peso_espaco → 0` é a agência renegada (nota 03) |
| **self** | a totalidade integrada | **tem dado, e não é o que se esperava**: `phi` mede **mistura de motivos**, não posse (nota 05) — mas `autocausa` mede o self como **causa** e é a única faculdade que o eremita possui (nota 09). O self não é a totalidade integrada: é o bloco aparecendo dentro da própria previsão |

O achado que esta seção deve encarar: das cinco palavras, as duas que *já têm*
contraparte medida (sombra, self) apontam ambas para o lado **(B)** da costura —
não são coisas que o bloco tem, são estados de um conflito. **Risco escrito em
letras garrafais:** o verniz fenomenológico. "O bloco reprime" é licenciável como
função; "o bloco *sente* culpa" não é, por nenhum mostrador desta bateria.

## 4. O tempo, a quarta dimensão e Bandersnatch *(item 7 — parte escrevível, parte ⛔)*

O universo é `f(seed)`: a vida inteira de cada bloco *já está escrita* — uma
linha-de-mundo numa 4ª dimensão que o bloco não percebe. E ainda assim
`medir_decisao()` roda contrafactuais ("e se ele estivesse faminto?") — hoje,
rodados pelo **observador**. Três movimentos, em escada:

1. **O auto-modelo temporal** — o bloco carrega a própria trajetória (memória de
   escolhas). Substrato de "eu poderia ter ido para a esquerda": uma crença modal
   **falsa** num universo `f(seed)` — e funcionalmente indispensável. ⛔ mexe na
   simulação (faculdade nova, não régua); entra pela Fase 4/5.
2. **O experimento Bandersnatch** — ✅ **rodou** (nota 07). O espectador
   sobrescreveu ~25% das escolhas, e a tabela de Gazzaniga virou **uma linha por
   arquitetura de introspecção**: quem lê a ação confabula (e nomeia motivo
   positivo para ~26% das ações impostas); quem lê o plano não percebe (e
   descreve um passo que não aconteceu); quem monitora os dois detecta 99–100% —
   **sem falso alarme, e sem autoria**. E ~1% dos dedos é indetectável **por
   princípio**: intervenção que a física desfaz não deixa rastro contrafactual.
   *Detectabilidade é propriedade do rastro, não da introspecção.*
3. **A posição** que a v3 tem de assumir sobre "eu poderia ter agido de outro
   modo" num mundo determinístico: crença falsa, ficção útil, ou verdade sobre o
   *tipo* e falsidade sobre a *ocorrência*? Compatibilismo executável — com a
   vantagem, sobre a poltrona, de que aqui o determinismo é **literal e
   inspecionável** (`git show` da linha que decide). A nota 07 (B5) já entrega a
   esta seção o seu teto: de dentro, *física* e *espectador* entram pelo mesmo
   barramento — "algo me moveu" é o máximo que qualquer introspecção relata;
   "*quem* me moveu", nunca.

## 5. A dobradiça da confabulação *(item 5 — selvagem ✅ e forçada ✅; a evolutiva ⛔ aguarda)*

Quando um bloco racionaliza uma ação que não escolheu, o projeto tem, em casa, o
fenômeno que torna o auto-relato humano pouco confiável (Gazzaniga; Nisbett &
Wilson). **E ele já aconteceu, sem ninguém instalá-lo**: `resolver()` nega células
disputadas — uma intervenção que a física roda de graça — e o intérprete leigo
racionaliza **~21%** dessas ações impostas ("fiquei porque aqui é o melhor"),
dizendo "não sei" nos outros ~79% (nota 06). A racionalização não precisou ser
programada: bastou um intérprete que lê comportamento e um mundo que às vezes
desobedece o plano.

E o **Bandersnatch forçado rodou** (nota 07): sob o dedo do espectador, a tabela
honesto/detecta/confabula deixou de ser tipologia e virou **uma linha por
arquitetura** — confabular ou detectar não é um mistério do sujeito, é uma
consequência de *o que o intérprete lê*. O que ⛔ aguarda: a versão
**evolutiva** (as arquiteturas como traço herdável, com o relato custando —
Fase 4), e então o fecho do arco: o último reduto do "mas eu *sei* que sou
consciente, por dentro" **é ele próprio um relato**. Se relatos confabulam — e
aqui, mensurável e selvagem, confabulam — quanto peso probatório sobra? E se
confabular × detectar é só arquitetura de leitura, que arquitetura é a *nossa*?

## 6. Função × experiência — a escolha que a v2 evita *(item 6 — ✅ feita)*

"Função, nunca experiência" é (a) **contenção metodológica** — faltam-nos
instrumentos, o alvo existe e está lá fora — ou (b) **tese metafísica** — não há
mais nada a medir? A v2 é ambígua entre as duas, e a ambiguidade lhe era
confortável: (a) soa modesta, (b) soa corajosa, e não dizer qual das duas permite
colher o crédito de ambas.

A v3 escolhe. E a escolha é: **nenhuma das duas — e a recusa é estável, mas não
pelo motivo que eu tinha anotado no esqueleto.**

### 6.1 Por que (b) é uma promessa que esta bateria não pode pagar

(b) é uma **negativa existencial**: *não há nada além da função*. Uma bateria que
mede função não pode estabelecê-la — não há ablação que zere aquilo que, por
hipótese, não faz diferença funcional nenhuma. Afirmar (b) exigiria um relatório a
mais, dizendo *"e eu verifiquei: não há mais nada aqui"*. Esse relatório é
testemunho. E este projeto passou as notas 06–08 desmontando exatamente o que é um
testemunho.

Quem afirma (b) está usando, como última evidência, a única faculdade que a
bateria já pegou mentindo.

### 6.2 Por que (a) perde a entrada toda vez que a paga

(a) parece a posição prudente: existe um alvo, e um instrumento melhor chegará. Mas
olhe o que aconteceu **todas as vezes** em que uma palavra experiencial foi
efetivamente operacionalizada neste projeto. Não foi que o alvo escapou. Foi que
**o alvo se dissolveu em função no contato**:

- `phi` prometia a *luz do todo*, a integração. Media o **segundo motivo** — e
  quando a seleção extinguiu o segundo motivo, a "integração" morreu junto. Não
  havia nada atrás (nota 05).
- `automodelo` prometia o *self*. Media o **outro**: zero exato num eremita (nota
  04).
- O `relato` prometia a *voz de dentro*. É um **intérprete leigo lendo
  comportamento** — que funciona (κ ≈ 0,67) sem acesso algum ao interior, e
  **confabula** um quinto das ações que não escolheu (nota 06).
- E a `autocausa` — a última esperança de (a), a única faculdade que o eremita
  possui, a coisa mais parecida com uma **posse** que este mundo tem — é, quando se
  abre, **um termo dentro de uma previsão**: o bloco aparecendo como variável no
  próprio modelo do futuro (nota 09). Um self sem interior nenhum. Não um lugar
  onde algo acontece: uma linha de código que desconta a própria garfada.

Isso não é "o instrumento não alcançou". É o alvo **virando função na mão**, cinco
vezes, sem exceção. (a) continua pagando a entrada e continua saindo sem nada.

### 6.3 A recusa, e por que ela é estável e não evasiva

A posição da v3:

> **Não afirmamos que não há experiência. Afirmamos que a única evidência capaz de
> decidir a questão é testemunho — e nós medimos de que é feito o testemunho.**

O último reduto de qualquer um de nós é a frase *"mas eu **sei** que sou
consciente, por dentro"*. Essa frase **é um relato**. E este projeto tem, dentro de
casa, um gerador de relatos inteiramente inspecionado:

- ele **não lê o interior** — lê comportamento, e ainda assim acerta acima do acaso
  (nota 06);
- ele **confabula**, e a confabulação não precisou ser programada (nota 06);
- confabular × detectar não é um mistério do sujeito: é **arquitetura de leitura**,
  uma linha por arquitetura (nota 07);
- de dentro, **física e o dedo do espectador entram pelo mesmo barramento**:
  *"algo me moveu"* é o máximo que qualquer introspecção relata; *"quem me moveu"*,
  nunca (nota 07);
- e a honestidade do sinal não é uma virtude do falante: é um **equilíbrio
  evolutivo**, com ~10% de blefe estável que nenhuma seleção elimina (nota 08).

Então a recusa é estável neste sentido preciso: **a pergunta não está indecisa à
espera de instrumentos — ela é indecidível pela única faculdade que a formula.**
Não é um "ainda não sabemos" (que é (a) disfarçada de humildade). É: o tribunal que
julgaria a causa é a parte cujo depoimento está sob suspeita, e não há outro
tribunal.

### 6.4 A objeção óbvia, e a resposta

*"Você definiu medição como funcional. Então a conclusão estava no método: petição
de princípio."*

Correta, e **é exatamente esse o conteúdo da posição** — não um deslize dela. Quem
quiser quebrar o impasse tem dois caminhos, e só dois:

1. **Exibir uma medição não-funcional** — e, pela regra de admissão da §3, dizer
   *o que a tornaria errada*. Ninguém jamais o fez, e não por falta de talento: uma
   medida que não pode errar não mede (a lição do `modelo`, nota 01).
2. **Apoiar-se no testemunho.** Que é onde estávamos.

Não há um terceiro caminho. **Dizer em voz alta que não há um terceiro caminho é a
escolha que a v2 se recusou a fazer** — e é tudo o que se pode honestamente fazer
aqui.

### 6.5 O que a v3 faz com a palavra, então

Não a retira. Não se pode: eu continuarei dizendo que sou consciente, e você
também, e nenhum de nós conseguiria parar. O que a v3 faz é **rebaixar a garantia**
da frase, não proibi-la:

> Trate "eu sei que sou consciente" como se trata qualquer relato vindo de um
> sistema que se sabe confabulador: **como dado sobre o relator, não como certidão
> sobre o mundo.**

E note o preço, que é o que torna esta seção uma escolha e não uma esperteza: pela
regra de admissão da §3 — *que ablação a zera? e ela carrega comportamento?* — a
palavra **experiência** não paga a entrada. A sua linha no Apêndice A teria a
coluna *"a ablação que TEM de zerá-la"* **vazia**. Pelo critério deste projeto,
aplicado sem exceção, ela é **decoração**.

Escrevo isso sabendo que a frase se vira contra quem a escreve, e que não há de
onde recuar: **a mesma régua que desbotou `phi`, `automodelo` e o `relato` dos
blocos está apontada para o meu próprio "por dentro" — e lê a mesma coisa.** A v1
perguntou como é ser um bloco. A resposta que a v3 tem de dar não é "não é nada";
é: *a pergunta é feita pelo órgão errado, e não temos outro.*

## 7. O regresso — quem calibra o calibrador? *(item 8 — ⛔ aguarda o eixo microscópio)*

Um detector de regime que dispara sobre ruído está **confabulando** (o intérprete,
um andar acima). Valida-se por intervenção: injetar colapso conhecido, injetar
ruído sem colapso. A régua vira objeto da própria pergunta — e o regresso para em
algum lugar ou não para, e qualquer das respostas é filosofia.

---

## Apêndice A — condições de falseamento por mostrador *(tabela viva)*

| mostrador | a ablação que TEM de zerá-lo | verificado |
|---|---|---|
| `modelo` | `prever_valor ≡ 0` | ✅ 0,000 exato (nota 01) — **auditado em `double`** (nota 10): 0 exato nas duas precisões, média e pior janela |
| `agencia` | eremita (sem rivais percebidos) | ⚠️ 0 exato **em ℝ** — mas a régua roda em `float32` e tem um **piso de ~0,003** (nota 09 §5). Zera exato em `double`. A demonstração da nota 01 §3 sobrevive; a *implementação* dela, não |
| `modelo_do_outro` | eremita (sem pretendentes) | ✅ 0,0000 exato, média e máx (nota 04). Imune ao piso: critério exato, sem varredura |
| `autocausa` | `horizonte = 1` (sem futuro, não há onde se modelar) | ✅ 0,0000 exato, média **e máximo**, 3 seeds — e exato **por construção**: para todo σ sai o mesmo float (nota 09). **O eremita NÃO o zera** — é o único, e é o ponto |
| `phi` (redefinida) | qualquer redução a um módulo só: eremita, `peso_espaco ≡ 0`, `prever_valor ≡ 0` | ✅ 0 exato, demonstrável (nota 05) — **auditado em `double`** (nota 10): 0 exato nas duas precisões, bloco a bloco, nas três reduções |
| `relato` | intérprete cego (relato ≡ constante): `relato = 0` **exato**, pela construção do κ | ✅ 0,0000 exato, 4 constantes × 3 seeds — pré-registrado **antes** do código (nota 06); **auditado em `double`** (nota 10): κ = +0 exato, inclusive **antes do clamp** |

> **A tabela adquiriu um rodapé, e ele é a nota 09 §5 — fechado pela nota 10.**
> Um ✅ desta tabela era falso — não por erro de conceito, mas de **aritmética**:
> `float32` tem um piso, e ele caiu exatamente sobre uma condição de falseamento.
> A auditoria em `double` (nota 10) recomputou os três ✅ restantes: **os três
> zeros são zeros nas duas precisões**. E o piso ganhou mecanismo: float32 não
> inverte ordens, **cria empates** — só vaza a sonda que dá significado a um
> empate (a `agencia` conta trocas de argmax sob desempate estrito; `modelo`,
> `phi` e `relato` têm zeros **estruturais** — identidade `x/x`, monotonia da
> multiplicação, igualdade de quociente). A régua desta tabela está, agora,
> auditada por inteiro. E replicada: 50 seeds por condição, **zero violações em
> 500 corridas** (nota 11) — nenhuma seed produziu um tick que retire um ✅ desta
> tabela.

## Apêndice B — o que falta para tirar o rótulo "esqueleto"

1. ✅ `relato` construído com condição de sanidade declarada antes (Fase 2) — o
   pré-registro foi commitado antes do mostrador; κ ≈ 0,67, e o intérprete cego
   zera exato (nota 06).
2. ✅ O experimento do intérprete rodado — e o desfecho registrado, seja qual for.
   Rodou, e o desfecho não foi o previsto: a tabela de Gazzaniga não é uma
   tipologia de sujeitos, é **uma linha por arquitetura de leitura** (nota 07).
3. ✅ A variante Bandersnatch (§4.2) rodada — as cinco predições confirmaram, e
   ~1% dos dedos é indetectável **por princípio** (nota 07).
4. ✅ A edição do auto-modelo de verdade (§2) — a predição de (A) testada. Ela
   **passou**, e a vitória é qualificada: o eremita tem `autocausa` > 0, mas tem
   1/5 da de um bloco acompanhado (nota 09). A bifurcação virou uma razão, não um
   vencedor.
5. ✅ A escolha da §6 feita por escrito. Feita: **nem (a) nem (b)** — a recusa é
   estável porque a única evidência capaz de decidir a questão é *testemunho*, e o
   projeto mediu de que o testemunho é feito. E o preço foi pago por escrito: pela
   regra de admissão da §3, "experiência" **não paga a entrada** e é, pelo critério
   deste projeto, decoração.

**A lista está fechada — e por isso o rótulo "esqueleto" caiu.** Os cinco itens que
a gatilhavam estão cumpridos; nenhum experimento bloqueia mais a v3.

Ficam duas dívidas, e nenhuma delas é do tipo que segurava o rótulo:

- **De prosa** (não de pesquisa): §2–§5 ainda são argumentos em forma de nota, não
  texto corrido (§0 e §1 já são prosa, 2026-07-14). §7 continua ⛔ — mas ela sempre
  dependeu do **eixo microscópio**, que nunca esteve nesta lista.
- ~~**De aritmética** (a nota 09 §5 a criou)~~ ✅ **quitada (nota 10)**: os três ✅
  do Apêndice A — `modelo`, `phi`, `relato` — foram recomputados em `double` e os
  três zeros são zeros nas duas precisões, a nove casas, no máximo e não só na
  média. O piso da `agencia` segue sendo o único — e agora com mecanismo: só vaza
  a sonda que dá significado a empates. A dívida de prosa é a última.

Um bônus que a Fase 4 entregou sem estar nesta lista: o `relato` deixou de ser
epifenomenal (nota 08). Silenciar a população **muda o mundo**, e a honestidade
é ESS sem multa artificial — a matéria do superego da §3, que a v3 já pode
escrever com dado em vez de promessa.
