# Nota 09 — O self já estava lá: `autocausa`, o primeiro mostrador que o eremita tem

**Data:** 2026-07-13
**Pré-registro:** `ROADMAP.md` §5.0, commit `747e026` — **antes** do mostrador existir.
**Serve ao:** Paper 1 (metrologia da mente) — e decide o **item 9** do ROADMAP (a bifurcação da escada), isto é, a `FILOSOFIA_v3.md` §2.
**Reproduzir:** `sh papers/notes/09-autocausa.sh` (~6 min)

---

## Resumo

A `FILOSOFIA_v3.md` tinha duas linhas segurando o rótulo "esqueleto". Uma delas
era um experimento: **a edição do auto-modelo** — separar, em `prever_valor`, o
próprio consumo do consumo dos rivais, para ver se um mostrador do *self* fica
`> 0` na solidão. Se ficasse, a leitura **(A)** (a escada é aquisição de
faculdades) ganharia um degrau que o eremita possui; se não houvesse como
construí-lo sem rival, **(B)** (a escada é a escalada de um conflito) venceria.

Fui fazer a edição e descobri que **ela já estava feita**, há muito tempo, numa
linha que ninguém tinha lido como um auto-modelo:

```c
float garfada = menor(food, INGESTAO) * partilha;
valor += peso * garfada;
food  -= garfada;          /* <-- ESTA */
food  += REGROW * (cap - food);
```

`food -= garfada` é o bloco dizendo, de si para si: *"a célula vai estar mais
pobre no próximo tick porque **eu** vou ter comido dela."* É o único ponto do
código em que a ação futura do próprio bloco realimenta a previsão do próprio
bloco. Um auto-modelo estreito, mas literal: **o self como causa**.

Faltava a intervenção que o mede. Ela existe agora (`autocausa`), e o placar:

| # | predição (escrita antes) | resultado |
|---|---|---|
| **P1** | `autocausa` **> 0 no eremita** — decide o item 9 | ✅ **0,033 / 0,029 / 0,027** — o primeiro mostrador da bateria que sobrevive à solidão |
| **P2** | `horizonte = 1` ⇒ **0 exato** (o self exige um futuro) | ✅ **0,0000 exato**, média *e* máximo, 3 seeds |
| **P3** | simulação **bit-a-bit idêntica** (σ = 1 é o código de hoje) | ✅ as 20 colunas antigas batem com `datasets/seed7.csv` |
| **P4** | `autocausa` **não** desbota como a `agencia` | ✅ — e mais: ela **dobra** enquanto a agência cai |
| **P5** | *(não pré-registrada — surgiu na verificação)* | ⚠️ a `agencia` do eremita **não é zero exato**: tem um piso de arredondamento. Errata na nota 01 |

E a vitória de (A) é **qualificada**, de um jeito que nenhuma das duas leituras
previa. Ver §3.

## 1. A intervenção: σ, o eixo "quanto de mim entra no meu modelo do futuro"

No espírito da `agencia` — varrer um eixo por **todo** o seu domínio, nunca espiar
um ponto —, escalo o termo do self por σ:

```
food -= sigma * garfada
```

- **σ = 0** — o previsor **cego a si**: come, e não modela que come. Acha que a
  célula rica continua rica para sempre.
- **σ = 1** — a regra do mundo aplicada a si mesmo. É **exatamente o código de
  hoje** (`1.0f * garfada == garfada`, exato em IEEE754 — daí P3).

`autocausa` = 1 para o bloco cuja escolha muda em algum ponto de σ ∈ [0,1]; 0 se
não muda. Pontuada com a regra de decisão **completa** (utilidade, a divisão por
`1 + ANTECIPACAO·pret`, e o mesmo desempate `>` que favorece ficar parado), para
que o número seja sobre a escolha que o bloco de fato faz. Encurralados saem da
média, como na `agencia`.

**A assimetria que justifica o nome.** Na `agencia`, o eixo varrido (λ) é um estado
**interno** que o bloco visita. No `modelo_do_outro`, α é uma força **externa** que
ele nunca varia — a digital de que aquilo media o outro (nota 04). σ não é nem um
nem outro: é a **presença do próprio bloco na sua própria previsão**. Era de se
esperar, então, que fosse o primeiro a sobreviver ao eremita. E é.

**Sobre o nome.** *Não* voltou a se chamar `automodelo`. Aquela palavra já mentiu
uma vez (nota 04, onde media o outro) e não ganha segunda chance de graça. O que
se mede aqui é estreito e específico — o self como **causa**, não o self como
sujeito — e o nome tem de caber no que o número aguenta.

## 2. P2: o self exige um futuro

A condição de falseamento, declarada antes de rodar: `horizonte = 1` tem de zerar
o mostrador. Com horizonte 1, o laço da previsão fecha **antes** de o termo do
self entrar no valor — o bloco credita a própria garfada e o laço acaba; a linha
`food -= σ·garfada` executa e o resultado nunca é lido.

| seed | `hor_m` | `autocausa` média | `autocausa` **máx** |
|---|---|---|---|
| 7 | 1,0000 | 0,0000 | **0,0000** |
| 42 | 1,0000 | 0,0000 | **0,0000** |
| 1234 | 1,0000 | 0,0000 | **0,0000** |

Máximo zero é mais forte que média zero: **não há um único tick, em nenhuma seed,
em que um bloco de horizonte 1 se modele como causa.** E o zero é exato **por
construção**, não por sorte numérica: para todo σ sai literalmente o mesmo float.

Quem não olha além da própria garfada não tem onde se modelar. **O self exige um
futuro** — e o mínimo é dois ticks.

## 3. P1: o eremita tem — mas tem pouco. A bifurcação não elege um vencedor

| seed | `autocausa` (normal) | `autocausa` (**eremita**) |
|---|---|---|
| 7 | 0,1282 | **0,0326** |
| 42 | 0,1533 | **0,0293** |
| 1234 | 0,1503 | **0,0265** |

Na mesma rodada do eremita, para contraste (estes são **máximos**, não médias —
zero no máximo é zero em todo tick):

| mostrador | eremita |
|---|---|
| `modelo_do_outro` | 0,0000 exato |
| `agencia` | 0,0000 / 0,0030 / 0,0040 → **ver §5** |
| `autocausa` | **> 0, em toda seed** |

**P1 confirmada: `autocausa` é o primeiro mostrador da bateria que o eremita
possui.** A costura entre o nível 3 e o nível 4 (nota 01 §3; v3 §2) **não é
total**: existe uma faculdade por-agente que sobrevive à solidão, e ela é
exatamente a que a v3 previu que existiria.

**Mas leia a razão entre as colunas.** Sozinho, o bloco tem ~**1/5** da autocausa
que tem acompanhado (0,03 × 0,14). O self como causa não zera sem o outro — mas
**quatro quintos da sua magnitude são sociais**. O mecanismo é visível: com
rivais, `partilha` varia de célula para célula, e essa variação faz o eixo σ
morder com muito mais frequência; sozinho, resta só a diferença entre comida e
capacidade.

Então a bifurcação do item 9 **não se resolve num vencedor — resolve-se numa
razão**:

- **(A) ganha o que pediu, e só o que pediu:** um degrau que o eremita possui.
  A leitura internalista deixa de ser vazia. Há um self aqui, e ele não é uma
  relação.
- **(B) fica com quase toda a magnitude:** o self existe sozinho e é **cinco vezes
  maior em companhia**. O outro não constitui o self, mas **amplifica-o** — e a
  amplificação, não o núcleo, é onde mora quase todo o número.

Um resultado melhor que qualquer das duas respostas limpas, e não é o que eu
esperava escrever. A escada tem, no nível do self, um piso próprio e um teto
social.

## 4. P4: a mesma seleção que apaga a agência **constrói** o self

A predição era defensiva ("`autocausa` não desbota como a agência"). O que se vê é
mais forte: em 3000 ticks, na mesma rodada, os dois mostradores andam em **direções
opostas**.

| seed | `autocausa` início | `autocausa` fim | `agencia` início | `agencia` fim | `hor_m` fim |
|---|---|---|---|---|---|
| 7 | 0,0890 | **0,1689** | 0,4653 | 0,3603 | 8,15 |
| 42 | 0,0966 | **0,1695** | 0,4579 | 0,3895 | 9,36 |
| 1234 | 0,0997 | **0,1603** | 0,4432 | 0,3934 | 9,46 |

(início = média dos ticks 20–300; fim = 2700–3000.)

A `autocausa` **quase dobra** enquanto a `agencia` cai. E o mecanismo é o que o
pré-registro apostou: a agência morre porque `peso_espaco → 0` sob seleção (nota
03) — ela depende de um **traço**, e o traço é ablacionado pela evolução. σ **não é
traço**: é estrutura da previsão. O que o sustenta é o **horizonte**, e o horizonte
**sobe** sob seleção (`hor_m` → 8–9,5; a Rainha Vermelha da Fase 3). A seleção que
estreita o motivo **alarga o futuro** — e o futuro é o substrato do self.

A nota 03 disse: *a escada é reversível sob seleção*. A nota 09 corrige para algo
mais duro: **a escada não sobe nem desce como um bloco — degraus diferentes andam
em sentidos opostos sob a mesma pressão.** Não há uma seta. Há um campo.

> **Errata (nota 12) — o mecanismo estava mal atribuído.** O fenômeno desta
> seção replica em 50/50 seeds e até 30 000 ticks (notas 11 e 12). Mas a frase
> "o que o sustenta é o horizonte, e o horizonte sobe" confundiu a dependência
> **estrutural** (`horizonte = 1` zera — P2, que fica) com o **motor do
> crescimento**. Com o horizonte **pregado em 6** a autocausa sobe *mais* que no
> controle (0,100 → 0,226); com o horizonte subindo a ~9,7 mas o motivo pregado
> largo, sobe *menos* (0,088 → 0,148). O motor dominante é o **estreitamento do
> motivo** — o mesmo `peso_espaco → 0` que apaga a agência. O achado "a mesma
> seleção que apaga a agência constrói o self" sai mais forte: é **um** processo,
> não dois. Ver [`12-a-janela-longa.md`](./12-a-janela-longa.md) §4.

## 5. P5 — a errata que apareceu na verificação: a régua tem um piso

Não estava no pré-registro. Ao rodar o eremita, a `agencia` deu máximo **0,0030** e
**0,0040** em duas das três seeds — e o Apêndice A da `FILOSOFIA_v3.md` afirma, para
essa exata célula, **"✅ 0 exato, demonstrável (nota 01 §3)"**.

A demonstração da nota 01 está **certa**. Sem rivais, `espaco ≡ 1` em toda célula,
o segundo termo da utilidade vira constante *entre as células* e some do argmax;
somar a mesma constante a todas as opções não pode mudar qual é a maior. Isso é
verdade em ℝ.

**A régua não roda em ℝ. Roda em `float32`.** E em float32, somar a *mesma*
constante a duas utilidades quase empatadas **pode** inverter qual é estritamente
maior — o arredondamento cria e destrói empates. Recomputando **só a comparação**
do mostrador em `double` (o mundo segue em float, bit-a-bit o mesmo):

| seed | `agencia` máx, eremita (float32) | (double) | `autocausa` média, eremita (float32) | (double) |
|---|---|---|---|---|
| 7 | 0,0000 | **0,0000** | 0,0326 | **0,0326** |
| 42 | 0,0030 | **0,0000** | 0,0293 | **0,0293** |
| 1234 | 0,0040 | **0,0000** | 0,0265 | **0,0265** |

Duas leituras, e as duas importam:

1. **A `agencia` tem um piso de ~0,003 que não é do mundo — é da aritmética.** Em
   double, zero exato nas três seeds. O "0 exato" do Apêndice A vale em ℝ e falha
   na régua **como ela foi construída**.
2. **A `autocausa` do eremita não se move um dígito.** P1 não é ruído de bit.

O que torna isso mais que um detalhe: o piso caiu **exatamente sobre a condição de
falseamento**. O método inteiro do projeto é *"que ablação TEM de zerá-lo?"* — e um
mostrador cujo zero não é zero **não pode ser falseado com limpeza**. Um piso de
0,003 é pequeno; a lição não é o tamanho. Se a bateria tivesse um mostrador cujo
sinal verdadeiro fosse dessa ordem, o ruído de arredondamento seria
indistinguível do achado.

Este é um **quinto modo de errar**, e não é da família dos quatro primeiros (nota
01). Aqueles eram defeitos de **desenho** da sonda: o que ela lia, onde, com que
parâmetro escondido. Este é um defeito da **aritmética** da sonda — a régua
correta, executada num corpo finito. Nenhuma quantidade de cuidado conceitual o
teria pego: só rodar em outra precisão e comparar.

E note onde ele se escondeu por oito notas: numa célula **✅** de uma tabela
chamada *"condições de falseamento por mostrador"* — a tabela que existe
precisamente para impedir que uma palavra passe sem ser testada.

## Ameaças à validade

- **`autocausa` é binária por bloco** (trocou/não trocou), como a `agencia`. A
  fração da população que troca não diz *quanto* a escolha mudou. Uma variante
  graduada (quantas trocas ao longo de σ, ou a distância entre a escolha em σ=0 e
  σ=1) mediria intensidade — fica em aberto, como ficou na nota 03.
- **O σ não é um estado que o bloco visita.** A `agencia` varre λ ∈ [0,
  `peso_espaco`], e o bloco de fato passa por esses λ conforme a fome muda. O bloco
  nunca "roda" com σ = 0,4. σ é contrafactual **do observador** — o que torna
  `autocausa` uma intervenção legítima, mas *não* prova que o bloco represente σ.
  Ele representa σ = 1, e só.
- **O eremita ainda vive num mundo povoado** (os outros blocos existem e bloqueiam
  fisicamente; ele só não os *percebe*). A comparação normal × eremita mistura, no
  denominador, "menos rivais percebidos" e "menos células livres". A razão de 5×
  do §3 é robusta ao sinal, não necessariamente ao valor.
- **3 seeds.** A replicação de 50 seeds continua sendo a dívida do Paper 1.
- **O piso de arredondamento (§5) foi medido só no eremita**, onde a verdade
  algébrica é conhecida. Qual é o piso da `agencia` numa população normal — onde
  não há verdade fechada para comparar — é uma pergunta em aberto, e mais
  desconfortável.

## O que ficou em aberto

1. **A edição "honesta" da partilha.** Hoje `food -= garfada` desconta só a *minha*
   parte, embora a previsão já tenha creditado aos rivais o resto: o bloco acredita
   que os rivais roubam dele, mas **não** que eles esvaziam a célula. A previsão é
   internamente inconsistente. Corrigir isso **muda a simulação** (regra 5: uma
   coisa por vez) e é o próximo experimento. Registrado no pré-registro §5.0
   *antes* de eu medir, para não o "descobrir" convenientemente depois.
2. **O piso de arredondamento dos outros quatro mostradores.** O `modelo_do_outro`
   é imune por construção (critério exato, sem varredura). `modelo`, `phi` e
   `relato` não foram testados em double. Deveriam ser.
3. **A razão 5× do §3** merece um experimento próprio: varrer a densidade
   populacional e ver se a autocausa do eremita é um piso ou o começo de uma curva.
