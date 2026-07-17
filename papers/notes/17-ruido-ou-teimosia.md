# Nota 17 — Ruído, não teimosia: o planejador fundo colhe pior, e o desconto é o que o protege

**Data:** 2026-07-17
**`main.c`:** o de `079a3ce` (canônico intocado; o patch é o da nota 16 **sem uma
vírgula de diferença**, rodado com `HI == HJ` — população de tipo único).
**Pré-registro:** cabeçalho de `papers/notes/17-tipo-unico.sh`, commitado em
`d747d4e` — **antes** de rodar (N0..N4).
**Serve ao:** Paper 2 — decide a leitura que a nota 16 §4 deixou como hipótese, e
põe uma **fronteira** na tese do artigo. Agregados em `datasets/tipo-unico.csv`.
**Reproduzir:** `sh papers/notes/17-tipo-unico.sh` (~125 min com `NPROC=16`)

---

## Resumo

A nota 16 mediu a inversão (em δ=0,95 o h=9 vence o h=12, `t = −11`) e ofereceu
uma leitura: o desconto não é o *regulador do valor posicional*, é um
**regularizador** — a cauda da previsão é ruído, `δᵏ` é o peso que ela recebe, e
em δ=0,95 ela envenena a decisão. A §4 marcou isso como **hipótese**.

Esta nota testa. O discriminante é a distinção que o protocolo do projeto já
carrega (*população de equilíbrio é proxy de **grupo**; para aptidão individual,
ensaio de invasão*): rodar populações de **tipo único** — todo bloco com o mesmo
`h` e o mesmo δ, **sem rival nenhum** de outro tipo — e perguntar se a inversão do
*duelo* tem contraparte **solitária**.

**Tem. O déficit é absoluto: N1 confirmada, N3 refutada.**

| # | predição (escrita antes) | resultado |
|---|---|---|
| **N0** | `HI==HJ==h` ⇒ `hor_m == h`, `desc_m == δ` | ✅ passou em h=3 e h=11 |
| **N1** | em δ=0,95 a pop de tipo único **cai** de h≈8 a h=12 (`\|t\|>2`); idem energia; e a comida sobrando **sobe** | ✅ na **pop** (−5,51 ± 1,27, `t = −4,3`) e na **comida** (+31,4, `t = +14,9`). ❌ na **energia**, que *sobe* — e o erro é instrutivo (§3) |
| **N2** | em δ=0,80 a mesma diferença é **não** significativa | ✅ +2,04 ± 1,25 (`t = +1,6`) — o tipo fundo não paga nada em δ=0,80 |
| **N3** | (alternativa) se a pop **não** cair, o déficit é relacional e a §4 da nota 16 está errada | ❌ **refutada** — a pop cai |
| **N4** | controle vacuoso: `modelo` cai com `h` | ✅ 0,915 → 0,592, como previsto **por construção** — não decide nada, e é por isso que está aqui |

E o **bônus não orçado** é o melhor dado da nota: o déficit de colheita tem
**dose-resposta em δ**. Ele não é um efeito de limiar que aparece em 0,95 — está
lá o tempo todo e **cresce com o desconto**, que é exatamente a assinatura que a
história do `δᵏ` prevê.

## 1. O déficit é absoluto

Diferença **pareada** por seed (a mesma seed em todo `h`; ver §4 sobre por que
pareada), 8 seeds:

| δ | `pop(h=12) − pop(h=8)` | `comida_de_pé(h=12) − comida_de_pé(h=8)` |
|---|---|---|
| 0,80 | +2,04 ± 1,25 (`t = +1,6`) | +2,54 ± 1,23 (`t = +2,1`) |
| 0,90 | −1,08 ± 1,25 (`t = −0,9`) | +13,55 ± 1,64 (`t = +8,3`) |
| 0,95 | **−5,51 ± 1,27 (`t = −4,3`)** | **+31,45 ± 2,12 (`t = +14,9`)** |

Em δ=0,95, um mundo inteiro de blocos com `h = 12` sustenta **5,5 blocos a menos**
do que o mesmo mundo com `h = 8` — e **não há um h=9 ali para lhe tomar a comida**.
O déficit que o duelo da nota 16 mediu (`t = −11`) não é uma desvantagem de
*posição*: é uma desvantagem contra **o mundo**. O planejador fundo, sozinho, come
menos.

E o rastro material está na comida: **+31,4 de comida em pé** que o tipo fundo não
colheu. Ele não está perdendo uma corrida — está **falhando em achar comida**.

## 2. A dose-resposta: o desconto controla o dano

A comida em pé, pareada contra `h = 1` — a curva inteira, e é aqui que a leitura
da nota 16 §4 vira medição:

| `h` | δ=0,80 | δ=0,90 | δ=0,95 |
|---|---|---|---|
| 2 | **−2,3** `t−4,3` | **−2,5** `t−3,8` | **−2,2** `t−3,1` |
| 4 | +4,7 `t+4,9` | +8,6 `t+5,9` | +12,0 `t+9,4` |
| 6 | +11,0 `t+7,9` | +22,9 `t+10,2` | +27,6 `t+13,7` |
| 8 | +17,7 `t+9,2` | +31,7 `t+12,0` | +42,1 `t+13,8` |
| 10 | +19,4 `t+11,5` | +39,8 `t+13,3` | +56,6 `t+15,4` |
| 12 | +20,3 `t+12,5` | +45,2 `t+14,4` | **+73,6** `t+17,3` |

Três coisas moram nesta tabela.

**(a) O pico de colheita é `h = 2`, e é o único degrau que colhe melhor que o
míope.** O `h=2` deixa **menos** comida de pé que o `h=1` nos três δ (`t` de −3 a
−4). Um passo de plano paga. Do `h=3` em diante, cada passo a mais **piora** a
colheita, monotonicamente, sem exceção nos três δ.

**(b) O dano é real em todo δ — inclusive em 0,80.** O `h=12` deixa +20,3 de
comida de pé mesmo em δ=0,80 (`t = +12,5`). Ou seja: **planejar fundo sempre
colhe pior neste mundo.** A profundidade nunca foi útil; a nota 14 já suspeitava
disso ao ler margens de 0,52–0,56 no topo.

**(c) E o desconto controla *quanto*.** O mesmo `h = 12` deixa +20,3 / +45,2 /
**+73,6** conforme δ vai a 0,80 / 0,90 / 0,95: o dano **mais que triplica**. É a
assinatura pedida. O erro da cauda da previsão é o mesmo nos três (o mundo é o
mesmo, a profundidade é a mesma); o que muda é `δᵏ`, **o peso que a decisão dá a
ele**. Em δ=0,80, `0,8¹¹ ≈ 0,09` — a cauda errada entra descontada a quase nada e
o dano fica pequeno demais para custar população (N2: `t = +1,6`). Em δ=0,95,
`0,95¹¹ ≈ 0,57` — ela entra com mais da metade do peso, e aí custa 5,5 blocos.

**O desconto é um regularizador.** Não é impaciência: é o bloco se recusando a
confiar numa previsão que ele não consegue fazer. A nota 16 §4 estava certa, e
agora é medição.

Isso fecha o contra-intuitivo da nota 16 (*mais paciência ⇒ horizonte ótimo mais
raso*) sem paradoxo nenhum: quanto mais peso você dá ao futuro distante, menos
longe pode olhar sem ser envenenado pela própria previsão.

## 3. Onde N1 errou, e por que o erro é instrutivo

O pré-registro pediu que a **energia média** caísse junto com a população. Ela
**sobe** — em δ=0,95, de 5,85 (`h=1`) a 6,73 (`h=12`).

Não é contra-evidência; é uma sonda que eu não devia ter posto na predição.
`energia_media` é a energia **por bloco sobrevivente**, e a população é
justamente o que cai: menos blocos dividem a mesma comida do mundo, logo cada um
fica com mais. A leitura é **confundida por densidade** e anda para o lado errado
por um motivo mecânico. Ela mede quão apertado está o mundo, não quão bem o tipo
se sai. Fica o registro: `energia_media` **não é proxy de aptidão** neste
aparato, e eu a inclui na predição sem pensar. As duas sondas que decidiram —
população (aptidão de grupo) e comida em pé (colheita) — concordam entre si e
andam nos dois sentidos certos.

## 4. Sobre o teste pareado — e um erro do script

O script imprime, ele mesmo, um veredito automático "N1/N3" que diz **~ empate
(N3)** nos três δ, inclusive em 0,95. **Esse veredito está errado, e o erro é
meu.** Ele compara `pop(h=12)` e `pop(h=8)` com um teste **não-pareado**, e o
desenho é **pareado por construção**: as mesmas seeds 1..8 rodam em todo `h`.

O `sd` entre seeds é ~37 numa média de ~280 (13%) — é a variância **entre mundos**
(cada seed gera outras manchas de comida), comum a todos os `h` e irrelevante para
o contraste. Ela engole um efeito de 5,5 quando entra no denominador. Pareando,
o mesmo efeito tem `se = 1,27` e sai a `t = −4,3`.

O pré-registro dizia "a população cai de h≈8 para h=12, com |t| > 2" e **não
especificou o estimador** — o desenho já era pareado, então o teste pareado é a
leitura fiel dele, não um teste novo escolhido depois de ver os dados. Mas a linha
que o script cospe é um erro de análise que ficou commitado antes de rodar, e fica
no registro em vez de ser apagada: **duas notas seguidas em que a sonda que
escrevi não servia para a pergunta que fiz** (a outra é a errata da nota 16 §4).
É o Paper 1 cobrando a própria tese do autor.

## 5. O que isto faz com o Paper 2

A tese **sobrevive, com uma fronteira** — e a fronteira é o que a torna
publicável em vez de decorativa.

- **Onde o horizonte é bem posicional:** em δ ≲ 0,90, a profundidade extra é
  *inofensiva* (N2: não custa população) e ainda assim **vence duelos** (nota 14:
  o h=12 bate todos em δ=0,80). Isso é a definição de um bem posicional: não
  produz nada, e mesmo assim é preciso tê-lo para não ser deslocado. A Rainha
  Vermelha da nota 14 é real **nesse regime**.
- **Onde ele deixa de ser:** em δ=0,95 a profundidade extra é *absolutamente*
  ruim (−5,5 de população sozinho). Aí ela não é um bem posicional caro — é um
  **erro**, e a seleção o corrige, o que é a origem do ESS interior da nota 16.

Então o freio endógeno existe, e ele **não** é o preço da cognição (o imposto da
nota 15, exógeno e queimado). É a **imprecisão da própria previsão**. O produto
que a corrida armamentista compra **apodrece com a distância**, e o desconto é o
que decide quanto do produto podre entra na conta.

O título "Cognição como bem posicional" precisa da fronteira no corpo: neste
mundo, o planejamento profundo **nunca** colheu melhor (§2b) — o que ele compra é
posição, e só enquanto o desconto o impedir de acreditar na própria alucinação.

## Ameaças à validade

- **8 seeds.** O efeito de δ=0,95 sai a `t = −4,3` (pop) e `t = +14,9` (comida)
  **pareado**; não é questão de amostra. Os δ baixos são nulos *medidos*
  (`t = +1,6`), não "não distinguimos".
- **`h = 8` como referência** foi escolhido no pré-registro por ser o joelho da
  inversão da nota 16. A curva inteira (§2) não depende dessa escolha e conta a
  mesma história.
- **Tipo único ≠ eremita.** Os blocos continuam se vendo, disputando célula e
  sinalizando; o que não existe é um bloco de **outro `h`**. O déficit medido é
  contra o mundo *e* contra iguais — não é o teste do eremita (que a bateria usa
  para faculdades relacionais), é o controle de "sem rival de outro tipo".
- **A cadeia causal ainda tem um elo por medir.** Provei que o tipo fundo colhe
  pior e que o dano escala com δ. **Não** medi diretamente o erro da previsão a `k`
  passos — o que fecharia o argumento em vez de o deixar em inferência à melhor
  explicação. Precisaria de uma sonda nova (comparar `prever_valor` passo a passo
  com o realizado), e ela não existe.
- **`comida_total` é do mundo, não do bloco.** Mais comida de pé é evidência de
  colheita pior, mas é agregada: não distingue "cada bloco colhe menos" de "os
  blocos se concentram e deixam regiões intocadas". As duas são formas de colher
  pior; a segunda seria uma história espacial, não de ruído temporal.
- **6000 ticks**, as mesmas janelas das notas 14/16.

## O que ficou em aberto

1. **O elo que falta:** uma sonda do erro de previsão a `k` passos. Fecharia a
   §2 de inferência para medição — e é o desenho que o Paper 1 exigiria de si.
2. **Grade fina em δ ∈ [0,88; 0,96]**: onde exatamente o ótimo sai do teto.
3. **Invasor-raro** no ESS interior (nota 16).
4. **O imposto com reciclagem** (nota 15) — intocado, e agora mais interessante:
   com freio endógeno descoberto, o imposto exógeno compete com um mecanismo que
   o mundo já tinha.
