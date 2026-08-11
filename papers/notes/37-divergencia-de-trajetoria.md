# Nota 37 — A divergência de trajetória: a ameaça fecha, e a régua pareada que estava lá desde o começo dá 28/30 contra um nulo de 15/30

**Data:** 2026-08-10
**Pré-registro:** `ROADMAP.md` §4.10, commit `1855873` — antes de rodar.
**Construído em:** `4664cf4` (script commitado antes de rodar).
**Serve ao:** fecha a ameaça à validade que a nota 35 declarou e nomeou sem medir
— se coerência espacial decorrelaciona as montagens espelhadas mais do que
incoerência de mesma magnitude, parte do vão 30% → 66,7% é decorrelação, não
vantagem. Nenhum mecanismo novo entra no `main.c`: os dois braços são os mesmos
binários das notas 33/34/35, e o que muda é o que o script **guarda**.
**Reproduzir:** `sh papers/notes/37-divergencia-de-trajetoria.sh` (~55 min: 120
corridas de 5 000 ticks mais 4 de 30 000 para a regressão)

---

## Resumo

A nota existia para responder uma pergunta e respondeu duas, e a segunda não
estava no plano.

**A pergunta que estava no plano — a ameaça — fecha.** Pela régua primária
pré-registrada, a escala de divergência de composição não difere entre os braços
(`p = 0,36`), e pela régua que é **cega a qual valor está vencendo** — divergência
da população — os dois braços são indistinguíveis em **todas** as três janelas
(`p = 1,00` na primária). Os 30% da nota 35 são linha de base justa; o `p = 0,0092`
dela fica de pé sem ressalva. A álgebra do §4.10, feita antes da máquina, já tinha
limitado o estrago: decorrelação sozinha não passa de 50% de REAL, então a coerência
nunca poderia explicar mais do que o vão de 30% até 50%.

**A pergunta que não estava no plano.** A P5 pedia a direção do traço medida de
forma **contínua e cedo** (`d̄`, a diferença de composição entre as duas montagens
na janela `1..2000`), com corte pré-registrado em ≥ 21/30 negativas. Deu **28/30**
(`p = 8,7·10⁻⁷`), contra um nulo que caiu **exatamente** em 15/30 (`p = 1,00`;
Wilcoxon `p = 0,80`). E o detalhe que reorganiza o fio inteiro: das **10 corridas
que o classificador binário descartou como FUNDADOR**, nove carregam o mesmo sinal
(`p = 0,0215`).

O motivo é estatística elementar, e é embaraçoso que três notas tenham passado por
cima dele: o classificador de T2 **limiariza cada montagem separadamente** e
pergunta se os rótulos coincidem. A **diferença pareada** das mesmas duas corridas
— que não custa uma corrida a mais, porque as duas já existem — tem muito mais
poder, e é **cega ao efeito fundador por construção**: um viés de paridade desloca
as duas frações igualmente e **cancela na diferença**. Era exatamente esse viés que
afogou as notas 32, 33, 34 e 35. A régua pareada estava disponível desde a nota 30.

## 1. A regressão — os binários são os que produziram os números publicados

O `main.c` não muda desde `65e83f3`, anterior às notas 32–36, então os dois braços
compilados hoje deveriam reproduzir bit a bit o que foi publicado. Conferido antes
do painel (regra 8 do protocolo: conferir a régua antes de aceitar o que ela diz):

| braço | seed | A → `arrep_m` | B → `arrep_m` | classe | publicado |
|---|---|---|---|---|---|
| T2 | 11 | −2,000 | −2,000 | **REAL** `−2,0` | nota 34: `−2,000` / `−2,000`, REAL |
| N2 | 2 | +2,000 | +1,955 | **REAL** `2,0` | nota 35: seed 2 é REAL |

## 2. P1 — a dose é a mesma, e o desvio que aparece vai contra a ameaça

`t_div` (primeiro tick em que as montagens diferem em qualquer coluna invariante ao
rótulo) tem mediana **3** nos dois braços (`p = 0,2188`). `t_01` (primeiro tick com
`|d| ≥ 0,01`) dá mediana 15 em T2 contra 12 em N2, com T2 chegando **mais tarde** em
19 dos 27 pares discordantes (`p = 0,0522`). Fica abaixo do limiar, é limítrofe, e
vale registrar a direção: se há assimetria de dose, ela é a favor de N2 perturbar
**mais cedo**, não menos — o contrário do que a ameaça precisaria.

## 3. P2 e P3 — a ameaça fecha, e o desacordo entre janelas é meu erro de desenho

A P2 pré-registrou a escala de `d̄` por braço, com `s = |d̄ − mediana do braço|`: a
mediana tira o deslocamento de vantagem e o que sobra deveria ser decorrelação.

| janela | escala mediana T2 | escala mediana N2 | sinal pareado | `p` |
|---|---|---|---|---|
| 500 | 0,02486 | 0,01094 | 21 × 9 | **0,0428** |
| **2000 (primária)** | 0,08454 | 0,04030 | 18 × 12 | **0,3616** |
| 5000 | 0,11259 | 0,08810 | 17 × 13 | 0,5847 |

Companheiro da primária: razão de MADs T2/N2 = 1,546, `p = 0,1665` por permutação
pareada (10⁵ sorteios, semente fixa 20260810).

Pela primária, **não há diferença**: a leitura pré-registrada que dispara é a
primeira das três — ameaça fechada, os 30% são linha de base justa. Mas a janela de
500 discorda a 5%, e o pré-registro mandou **ler o desacordo em vez de escolher o
que agrada**. A leitura é um defeito do meu próprio desenho, e ele é anterior aos
dados: pré-registrei "vantagem é deslocamento, decorrelação é espalhamento", e essa
decomposição só vale se a vantagem for **homogênea entre seeds**. Não é — um mundo
em que `−2,0` rende mais produz `d̄` mais extremo, e vantagem heterogênea engorda o
espalhamento sem decorrelacionar coisa nenhuma. A escala de `d̄` não é, portanto,
medidor limpo de decorrelação num braço que tem vantagem; e é justamente o braço T2.

A régua que **não** tem esse defeito é a P3, `Δpop`, que só olha a divergência da
população e é cega a qual valor está vencendo:

| janela | mediana T2 | mediana N2 | sinal pareado | `p` |
|---|---|---|---|---|
| 500 | 0,01348 | 0,01392 | 17 × 13 | 0,5847 |
| **2000 (primária)** | 0,01469 | 0,01503 | **15 × 15** | **1,0000** |
| 5000 | 0,01513 | 0,01502 | 16 × 14 | 0,8555 |

Quinze a quinze, com medianas que batem no terceiro decimal, em todas as janelas.
As duas montagens de um braço se afastam **exatamente tanto** quanto as do outro.
É a evidência mais direta que este painel produz de que a ameaça está fechada, e
ela vem da régua sem o defeito, não da que discordou entre janelas.

## 4. P4 — o modelo que sustenta o argumento inteiro se sustenta

Toda a leitura da nota 35 depende de uma história: REAL é decorrelação, mais
vantagem quando existe vantagem. Nunca tinha sido testada. Dentro de N2, onde não
há vantagem por construção, REAL só pode vir de decorrelação — e vem:

| braço | `\|d̄\|` mediana REAL | `\|d̄\|` mediana FUNDADOR | `U` | `p` unilateral |
|---|---|---|---|---|
| **N2** (pré-registrado) | 0,07071 (n = 9) | 0,03885 (n = 21) | 133 | **0,0427** |
| T2 (descritivo) | 0,18550 (n = 20) | 0,12626 (n = 10) | 129 | 0,1066 |

No nulo, as corridas que saem REAL são as que divergiram mais — o mecanismo é o
previsto. Em T2 a mesma relação existe mas é mais fraca, o que é coerente com REAL
ali não ser só decorrelação.

## 5. P5 — a régua pareada, e o que ela vê que a binária não vê

`d(t) = (arrep_m^A + arrep_m^B)/4`. A álgebra do §4.10 diz que isso é
`f_ímpar^A − f_ímpar^B`, a diferença de composição entre as montagens em fração da
população; a segunda régua confirmou a álgebra contra os dados, prevendo `arrep_sd`
a partir de `arrep_m` com erro máximo **0,000714** — o piso do `float32`, de novo.

| janela | braço | mediana `d̄` | negativas | `p` bilateral |
|---|---|---|---|---|
| 500 | T2 | −0,06363 | 27/30 | 8,4·10⁻⁶ |
| 500 | N2 | −0,01245 | 20/30 | 0,0987 |
| **2000** | **T2** | **−0,16386** | **28/30** | **8,7·10⁻⁷** |
| **2000** | **N2** | −0,00130 | **15/30** | **1,0000** |
| 5000 | T2 | −0,33283 | 28/30 | 8,7·10⁻⁷ |
| 5000 | N2 | −0,00322 | 15/30 | 1,0000 |

Pareado, T2 é mais negativo que N2 em **27/30** (`p = 8,4·10⁻⁶`). Wilcoxon exato,
calculado fora do script na segunda régua: T2 contra zero `p = 5·10⁻⁸`; N2 contra
zero `p = 0,798`. O nulo é um nulo de manual — 15/30 exato, mediana −0,0013 — e é
isso que dá crédito ao outro número.

**O corte pré-registrado era ≥ 21/30. Deu 28/30. A P5 confirma, e com folga.**

**Por que a régua pareada enxerga o que a binária não enxerga.** O classificador de
T2 limiariza `arrep_m` **em cada montagem separadamente** e pergunta se os dois
rótulos coincidem. `d` compara as duas montagens **uma com a outra**. A diferença
prática é o efeito fundador: um viés de paridade — o índice par vencendo por deriva,
que é o confundidor que as notas 30–35 documentaram e que o N1 da nota 35 mediu em
9/10 seeds — desloca `f_ímpar` **igualmente nas duas montagens** e **cancela na
diferença**. A régua pareada é cega ao confundidor **por construção**, não por sorte.

A seed 1 é a demonstração, e eu a olhei antes de escrever esta seção justamente
porque ela parecia contradizer o resto:

| tick | `f_ímpar^A` | `f_ímpar^B` | `d` |
|---|---|---|---|
| 500 | 0,447 | 0,674 | −0,227 |
| 2 000 | 0,368 | 0,833 | −0,465 |
| 8 000 | 0,573 | 0,943 | −0,370 |
| 16 000 | 0,885 | 1,000 | −0,115 |
| 29 999 | 0,978 | 1,000 | −0,022 |

Na montagem A os portadores de `−2,0` (par) sobem até o tick ~4 000 e depois perdem
tudo para a deriva; na B os portadores de `−2,0` (ímpar) tomam 100%. O classificador
lê "ÍMPAR venceu as duas" e carimba **FUNDADOR**. E `d` é negativo do tick 10 ao
tick 30 000, **sem trocar de sinal uma vez**. Nove das dez FUNDADOR de T2 são assim
(`p = 0,0215`): o sinal estava lá, e o desfecho binário o jogava fora.

## 6. O que isso faz — e o que não faz — com o fio do arrependimento

**Não muda o veredito de T2, e não é para mudar.** T2 é um teste sobre o desfecho de
fixação, com corte pré-registrado em 21/30 (§4.7) e placar de 20/30. O corte fica.
Mover critério depois do placar é o que a §7 da `FILOSOFIA_v3` proíbe, e ter achado
uma régua melhor **depois** não é licença para reescrever o resultado da pior.

**Muda a resposta a Q5, que é a pergunta de fundo.** A nota 30 perguntou se a
seleção favorece `peso_arrependimento` negativo e respondeu com uma média sob
mutação livre em 3 seeds. A nota 32 pôs em dúvida (efeito fundador). As notas 33/34
contaram seeds e nunca decidiram. A nota 35 mostrou que a contagem se dava contra um
zero imaginário. Esta nota mede a coisa diretamente, com observável pré-registrado,
nulo medido no mesmo painel (15/30 exato) e `p = 8,7·10⁻⁷`. **A resposta a
Q5 é sim, e não depende mais do classificador binário.** A hipótese mecânica da nota
30 — persistir onde a disputa valia a pena paga mais que fugir para uma célula vazia
só por estar vazia — continua **não provada**: medir que `−2,0` vence não é medir
*por quê*.

**T3 continua sem rodar.** O gate pré-registrado é o pool de T2 confirmar, e ele não
confirmou. Esta nota não abre o gate — ela mostra que o gate estava trancado por uma
régua de baixo poder, o que é uma afirmação sobre o instrumento, não sobre o gate.

## Ameaças à validade

- **`d̄` cedo e o desfecho medem coisas diferentes, e a nota não deve trocar uma
  pela outra.** A seed 1 é o caso: `d` negativo o tempo todo, desfecho FUNDADOR. O
  que `d̄` mede é vantagem de crescimento; o que o classificador mede é quem fixa. Num
  harness onde 9/10 das corridas vão a fixação quase total por deriva pura (nota 35,
  N1), os dois divergem por motivo estrutural, não por erro de ninguém.
- **A escala de `d̄` (P2) não é medidor limpo de decorrelação onde há vantagem
  heterogênea** — declarado no §3 acima, e é a razão de a P2 discordar entre janelas.
  A conclusão sobre a ameaça se apoia na P3, que não tem o defeito. Se alguém quiser
  derrubar o fechamento da ameaça, é a P3 que precisa cair.
- **N2 continua sendo "direção destruída", não "vantagem comprovadamente nula".**
  Esta nota mediu a ameaça que a nota 35 declarou, não todas as concebíveis. O nulo
  coerente (o mesmo termo multiplicado por um campo suave arbitrário em vez de ±1 por
  célula) continua sendo o teste que responderia na moeda do desfecho; ele ficou sem
  rodar porque a P3 tornou a pergunta muito menos urgente, não porque é impossível.
- **A janela é uma escolha, ainda que calibrada fora da amostra** (seeds 31/32). As
  três janelas concordam na P5 e na P3; discordam na P2. Nada aqui depende de uma
  janela única, exceto o número exato de negativas em `W = 500` (27, não 28).
- **28/30 é uma proporção de seeds, não um tamanho de efeito populacional.** A
  mediana de `d̄` em `W = 2000` é −0,164: dezesseis pontos percentuais de composição
  entre as montagens. É grande neste harness; não é uma medida de aptidão, e não foi
  convertida em uma.

## O que ficou em aberto

1. **Repetir o fio com a régua pareada, pré-registrada como primária.** Esta nota a
   usou como observável secundário de um teste sobre outra coisa. Um painel próprio
   — com corte declarado antes, e potência calculável pela primeira vez, já que
   agora existe um nulo medido (15/30) **e** um tamanho de efeito (−0,164) — é o
   próximo passo natural e é barato: as corridas duram 2 000 ticks.
2. **Por que `−2,0` vence.** Q5 tem resposta e não tem mecanismo. A hipótese da nota
   30 é testável: se persistir na disputa é o que paga, então o ganho de `−2,0`
   deveria sumir num mundo sem disputa (comida abundante, ou população esparsa) — e
   `PESO_ESPACO`/densidade inicial já são parâmetros do mundo.
3. **O nulo coerente**, se alguém quiser fechar a ameaça na moeda do desfecho em vez
   de na do proxy — 60 corridas de 30 000 ticks.
