# Nota 41 — O mecanismo: o arrependimento negativo manda o bloco para a comida disputada, e a moeda é a comida, não a disputa

**Data:** 2026-11-02
**Pré-registro:** `ROADMAP.md` §4.14, commit `d1f6bde`, antes de rodar.
**Construído em:** `84b723c` (script commitado antes de rodar).
**Serve ao:** item 2 da fila pós-nota 38 ("por que `−2,0` vence"), fase 2. A fase 1
(nota 40) mediu *contra quem*; esta mede *por onde*.
**Reproduzir:** `sh papers/notes/41-mecanismo-do-arrependimento.sh` (18 min 11 s de
relógio, 2 h 51 de CPU: 180 corridas de 5 000 ticks, mais S1/S3).

---

## Resumo

**A hipótese da nota 30 §4 se confirma na decisão, com placar máximo.** Desligando o
termo só na decisão final do próprio bloco (mesmo bloco, mesmo estado), o
arrependimento negativo **redireciona** o bloco para células com **mais comida**
(30/30) e **mais lotadas** (30/30). O positivo faz o espelho exato (30/30 e 30/30). E o
negativo **come mais** por bloco-tick que o zero no mesmo mundo (27/30), **apesar de
perder mais disputas** (30/30). É o "paga apesar de perder mais disputas" que a nota 30
conjecturou em julho.

**O nulo explica a escada, e de novo contra a minha expectativa.** Eu esperava que o
termo sem direção não redirecionasse nada em média. Ele redireciona para células **mais
pobres** (30/30) e **menos lotadas** (30/30), e perde **menos** disputas que o zero
(30/30), não mais. Isso derruba a explicação pós-hoc que a nota 40 deixou em aberto
("perde porque entra em mais disputas") e deixa uma só variável ordenando os quatro
tipos:

| | comida no alvo (`E_comida`) | disputas perdidas (`E_negado`) | garfada (`E_garfada`) | `ḡ` (nota 40) |
|---|---|---|---|---|
| `−2,0` | **+0,0089** | +0,024 | **+0,00075** | +0,072 |
| `0,0` | 0 | 0 | 0 | 0 |
| `+2,0` | **−0,0044** | −0,013 | **−0,00016** | −0,023 |
| sem direção | **−0,0086** | −0,022 | **−0,00087** | −0,079 |

*(medianas `X − Z` por bloco-tick, W = 2000; `ḡ` é da nota 40, com outras seeds)*

A ordem da comida no alvo é a ordem da garfada, e é a ordem da escada da nota 40. As
disputas perdidas **não** seguem essa ordem: o termo sem direção perde menos disputas
que o zero e mesmo assim é o pior. **A moeda é a comida, não a disputa.** O
arrependimento negativo vence porque, neste mundo, a célula disputada é a célula rica,
e perder mais disputas é o preço de mirar nelas.

## 1. Sanidade

- **S1:** o CSV com o patch é bit a bit igual ao sem patch nas 6 montagens da seed 401
  (três braços × A/B).
- **S2:** o alvo recalculado **com** o termo é igual ao alvo real em **todos** os
  blocos-tick `X` das 180 corridas (0 divergências). A chamada contrafactual reproduz
  `decidir`, e a única diferença entre alvo real e contrafactual é o termo.
- **S3:** NEG/401/A repetida sozinha tem md5 idêntico ao do painel, no CSV e no fluxo.

## 2. P1–P4: para onde o termo manda o bloco

Por bloco-tick `X` (zero onde o alvo não muda), média de A e B:

| | `R_comida` | `R_rivais` | redirecionados |
|---|---|---|---|
| **P1/P2** NEG | **30/30 > 0**, mediana +0,0077 | **30/30 > 0**, +0,083 | 5,0% |
| **P3** POS | **30/30 < 0**, −0,0039 | **30/30 < 0**, −0,026 | 1,8% |
| **P4** NUL | **30/30 < 0**, −0,0114 | **30/30 < 0**, −0,0065 | 8,3% |

As três janelas (500, 2000, 5000) dão o mesmo placar em todas as células, com uma única
exceção: NUL `R_rivais` fica em 29/30 na janela de 500. Pela tabela do §4.14, P1 ✓ e
P2 ✓ é "a nota 30 se confirma **na decisão**".

**Por que o nulo vai para o pobre e o aberto (pós-hoc, mas quase aritmética).** Sob o
campo de sinal, o termo de cada célula candidata é `±w·r·E`. Ele mexe pouco nas células
lotadas (`E` pequeno) e muito nas abertas, para cima ou para baixo conforme o campo.
Quando ele muda a escolha, quase sempre é para uma célula **aberta** do lado `+` do
campo, sem relação nenhuma com a comida. Como a escolha sem o termo já era a de melhor
comida prevista, qualquer redirecionamento que ignore a comida tende a piorá-la. O
positivo é a versão coerente disso (sempre para o aberto) e perde menos comida que o
nulo. O negativo é o único dos três cujo redirecionamento **aponta para onde a comida
está**, porque aqui a lotação é sinal de riqueza.

## 3. P5: a ponte para a aptidão

| janela | NEG `E_garfada > 0` | POS `< 0` | NUL `< 0` |
|---|---|---|---|
| 500 | 28/30 | 23/30 | 29/30 |
| **2000** | **27/30** (`p = 4,2·10⁻⁶`) | 22/30 | 28/30 |
| 5000 | 25/30 | 20/30 | 27/30 |

**P5 confirma**, e a escada da nota 40 se repete, em seeds novas, na moeda próxima: o
que cada tipo come. A expectativa descritiva sobre as disputas acertou em NEG (mais
negados, 30/30) e **errou em NUL** (eu disse "mais negados", e ele tem **menos**,
30/30). O positivo é o mais fraco dos três na garfada, como já era o mais fraco em `ḡ`
na nota 40 (POS no corte em W = 5000 lá; 20/30 aqui).

**A ecologia da nota 39, explicada de passagem.** Lá, os blocos `−2,0` liam menos
`agencia` na régua do `main.c` por razões que a nota não sabia nomear. Aqui eles miram
células com **+0,19 rivais** a mais que os `0,0` (`E_rivais`, 30/30), e lotação é menos
células livres em volta, menos opções na varredura e menos trocas de argmax. Isso é
consistente com a nota 39, mas não foi testado como causa: fica como pós-hoc.

## 4. O que fica respondido

**"Por que `−2,0` vence" tem resposta mecânica, em três camadas medidas:**

1. **Decisão** (dentro do bloco, sem ecologia): o termo negativo redireciona para
   células mais ricas e mais lotadas, 30/30 e 30/30.
2. **Ecologia** (entre tipos): os `−2,0` miram comida melhor, perdem mais disputas e
   **comem mais** por tick que os `0,0` no mesmo mundo, 27/30.
3. **Composição** (nota 40): os `−2,0` crescem contra os `0,0`, 28/30.

E a mesma variável, a comida no alvo, ordena os quatro tipos nas três camadas.

**A frase da nota 30 pode ser usada agora, com uma correção.** *"Depois de perder uma
disputa, continuar competindo pelo recurso que valia a disputa"* está medido. Só que o
"depois de perder uma disputa" é mais frouxo do que soa: a nota 39 mostrou que 90% dos
blocos-tick carregam algum remorso residual, então o termo está quase sempre ligado. A
descrição exata é: **um bloco que já perdeu disputas passa a descontar o espaço aberto
na proporção do que perdeu, e neste mundo isso o empurra para onde a comida está.**

**A palavra "arrependimento" não ganha nada com isto.** O mecanismo é um termo que
desloca o coeficiente do espaço. O que a seleção encontrou não foi "aprender com o
erro" no sentido que o §4.3 imaginava (fugir da lotação que o barrou), e sim o
contrário: usar a lotação como pista do que vale a pena. A §4 da v3 já registrava a
surpresa da direção. Esta nota diz por que a direção paga.

## Ameaças à validade

- **O contrafactual é local.** Ele desliga o termo só na decisão final do bloco, com as
  intenções dos vizinhos (formadas com o termo, em `declarar`) fixas. Um mundo sem o
  termo teria outras intenções. `R` mede a decisão do bloco, não a dinâmica sem o traço.
- **`R_comida` é comida real no alvo, não comida comida.** A ponte para o que o bloco
  ingere é `E_garfada`, entre tipos, e por isso misturada com ecologia. As duas réguas
  concordam, mas cada uma mede uma coisa.
- **Efeitos pequenos em valor absoluto.** A garfada do `−2,0` excede a do `0,0` em
  ~0,0007 por bloco-tick. O placar é de direção, consistente; o tamanho de cada passo
  é pequeno e se acumula em composição ao longo de milhares de ticks.
- **"A célula disputada é a célula rica"** é a geometria que a v3 §5 já registrava, mas
  aqui ela entra como explicação **pós-hoc** do sinal de `R_comida`. A correlação
  lotação × comida não foi medida diretamente.
- **Seed 31 vista antes.** No teste do encanamento (300 ticks, fora da amostra) os
  sinais de NEG e POS já apareciam, e NUL saiu negativo nos dois `R`. O pré-registro
  estava commitado, e a expectativa "não detectado" para NUL não foi mudada.

## O que ficou em aberto

1. **A correlação lotação × comida**, que sustenta o sinal de `R_comida`: medida
   diretamente, por célula e por tick. Se ela for fraca ou variar por seed, a vantagem
   de `−2,0` deveria variar junto. É um teste barato de dose-resposta entre seeds.
2. **O mundo onde a lotação não é sinal de riqueza.** Se a disputa e a comida forem
   descorrelacionadas (comida uniforme, por exemplo), a previsão desta nota é que a
   vantagem de `−2,0` some. É o teste que a nota 37 item 2 imaginou, agora com um
   mecanismo a quebrar.
