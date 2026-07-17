# Cognição como bem posicional

### O horizonte de planejamento não produz nada — e o desconto é o que impede a corrida de virar alucinação

*(rascunho — fonte do Paper 2; o PDF é artefato de build)*

---

## Resumo

Num mundo simulado mínimo e determinístico, blocos-agentes planejam `h` ticks à
frente, descontando o futuro por `δ`, e ambos os parâmetros são traços herdados
com mutação. Perguntamos quando vale a pena pensar. A resposta tem três camadas,
e cada uma derrubou a anterior.

**Primeira:** planejar fundo é **individualmente vantajoso e coletivamente
custoso**. A população de equilíbrio é máxima em `h = 1` e cai monotonicamente com
a profundidade; e num ensaio de invasão o planejador fundo **desloca** o raso. O
horizonte cognitivo é um **bem posicional** — uma corrida armamentista de Rainha
Vermelha.

**Segunda:** medimos *quanto* de bem posicional. Ele é **puro**. Numa população de
tipo único, sem rival de outro tipo, cada passo de plano além do segundo faz o
bloco **colher pior**: com `h = 12` sobram +20 de comida em pé contra `h = 1`
(`t = +12,5`). O horizonte **não produz nada**. Tudo o que ele compra é tomado de
um vizinho.

**Terceira, e é a que nos surpreendeu:** a corrida **tem freio endógeno**, e o
freio não é o preço da cognição — é a **imprecisão da própria previsão**. O
desconto não é impaciência: é um **regularizador**. Ele decide quanto peso a cauda
alucinada do plano recebe (`δᵏ`). Com `δ = 0,80` a cauda é descontada até a
irrelevância e a profundidade extra é inofensiva; com `δ = 0,95` ela entra com
metade do peso, e aí planejar fundo é *absolutamente* ruim — uma população de tipo
único com `h = 12` sustenta 5,5 blocos a menos que a mesma com `h = 8`
(`t = −4,3`), sem ninguém para lhe tomar a comida. O dano tem dose-resposta em
`δ` e **mais que triplica** de 0,80 a 0,95.

Disso decorre um resultado contra-intuitivo que reportamos como o mais forte do
trabalho: **mais paciência ⇒ horizonte ótimo mais raso.** Quanto mais peso se dá
ao futuro distante, menos longe se pode olhar sem ser envenenado pela própria
previsão.

E decorre a fronteira da tese: o horizonte é um bem posicional **onde o desconto o
protege**. Acima disso não é um bem caro — é um **erro**, e a seleção o corrige.

---

## 1. A pergunta

"A evolução aprende a planejar mais longe" é uma narrativa comum e, neste mundo,
mal formulada em dois sentidos.

O primeiro é metrológico: `horizonte` **não é identificável sozinho**. Um bloco com
horizonte 11 e desconto 0,66 pesa o 3º passo em `0,66³ ≈ 0,29` e o 11º em `0,01`:
ele *declara* um horizonte fundo e **pensa raso**. Os dois traços são
compensatórios — `corr(hor_m, desc_m)` = −0,93 / −0,46 / −0,72 no regime tardio —
e qualquer afirmação sobre profundidade de planejamento precisa do **par**
`(h, δ)`. Boa parte da divergência entre seeds que nos enganou por três hipóteses
era artefato de olhar um traço não-identificável isoladamente.

O segundo é substantivo, e é o assunto deste artigo: na parte em que a narrativa é
verdadeira, **ela não é a boa notícia que parece**.

## 2. O aparato, e por que um brinquedo

Um único arquivo C de ~56 KB, só libc. Blocos ocupam uma grade, comem manchas de
comida procedurais, gastam energia para existir, e se reproduzem. Cada bloco decide
olhando **só a vizinhança 3×3**; nenhum lê estado global. Quatro traços governam a
decisão (`urgencia`, `peso_espaco`, `desconto`, `horizonte`), herdados com mutação.

A propriedade que faz o aparato servir é o **determinismo total**: o universo
inteiro é `f(seed)`. Isso compra o que um sistema real não dá — **pregar um traço**
na população inteira e rodar o *mesmo* mundo; rodar **ensaios de invasão** com
herança exata, onde a média do traço no log *é* a frequência; e comparar condições
sem que o mundo mude embaixo.

## 3. O bem posicional (a primeira camada)

**Paisagem de grupo.** Fixando `horizonte = h` para toda a população, a população
de equilíbrio cai **monotonicamente**:

| h | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 12 |
|---|---|---|---|---|---|---|---|---|
| pop | **295,9** | 295,0 | 293,6 | 292,7 | 290,6 | 289,8 | 289,4 | 289,3 |

O ótimo de grupo é `h = 1`. Quanto mais fundo a população pensa, **menor** ela é.

**Aptidão individual.** Ensaio de invasão, 50/50 de `h = 3` e `h = 9`, sem mutação.
A frequência do `h = 9` sobe monotonicamente nas três seeds, a 0,91 / 0,87 / 0,85
em 4000 ticks. O planejador fundo **desloca** o raso.

O descasamento entre as duas medidas **é** o achado, e ele tem a forma clássica:
pensar fundo é individualmente vantajoso e coletivamente ruim. É também por isso
que zerar a competição faz os horizontes evoluídos ficarem **mais rasos** — a
competição não freia o pensamento, **alimenta** o pensamento. O ganho de olhar
fundo está em **ganhar a célula disputada do vizinho**, não em fazer o bolo
crescer.

## 4. O torneio, e um ESS que não era (a segunda camada)

O par 3×9 é sugestivo, não um ESS. Rodamos o torneio inteiro: **66 pares × 8 seeds
× 6000 ticks**, população 50/50, **só o horizonte variando** (o desconto pregado em
0,80, senão a compensação do §1 contamina o contraste).

A dominância é **transitiva e perfeita**: cada horizonte vence exatamente um duelo
a mais que o anterior; o `h = 12` vence os 11, o `h = 1` perde os 11. Nenhum ciclo,
nenhuma estratégia mista escondida. E a margem **satura**: de aniquilação total
(1,000 contra o `h = 1`) a quase moeda ao ar (0,52–0,56 no topo) — mas nunca vira
não-positiva, e por isso **o ESS é o teto** `h = 12`, censurado pelo máximo do
mundo. Uma corrida sem freio endógeno.

Lemos essa saturação como o **teto da profundidade efetiva** `min(h, 1/(1−δ))`:
com δ = 0,80, `1/(1−0,80) = 5`, e o joelho da curva caía em `h ≈ 4–6`. A transição
**fixação → polimorfismo** (exclusão embaixo, coexistência em cima) caía em
`h ≈ 4` — "exatamente no teto do desconto", escrevemos.

**Estava errado, e o erro era de um ponto só.** A profundidade efetiva costurava o
argumento inteiro e tinha sido medida num único δ; com δ = 0,80, `1/(1−δ) = 5` — e
`h ≈ 5` é também o **meio da faixa** 1..12. De um ponto ninguém distingue "o joelho
é o teto do desconto" de "o joelho caiu no meio da régua".

Varremos δ ∈ {0,30; 0,50; 0,80; 0,90; 0,95} (teto de 1,4 a 20), 15 pares × 8 seeds,
com o mesmo binário do torneio — a fatia δ = 0,80 reproduz o torneio original em
**120/120 linhas**, o que amarra as duas medições. Três resultados:

**(a) O joelho anda — até parar de andar.** O último degrau com vantagem
significativa vai de `h ≈ 2` (teto 1,4) a `h ≈ 3` (teto 2), `h ≈ 7` (teto 5) e
`h ≈ 9` (teto 10). A censura aparece onde devia. Mas em δ = 0,95 (teto 20) ele
**volta** para `h ≈ 6`. O `1/(1−δ)` é uma **aproximação de δ baixo**: ele descreve
quando a profundidade extra é *invisível*, e não sabe dizer quando ela é *nociva*.

**(b) A transição não anda.** É `h = 4` em δ = 0,50; 0,80; 0,90 **e** 0,95,
enquanto o teto vai de 2 a 20. Havíamos fundido **duas escalas** que só o δ = 0,80
aproxima: o joelho da margem, governado pelo fundo da escada (onde o desconto tem
alavanca), e a transição, governada pelo topo — onde o incremento *relativo* de
profundidade é grande (1→2 dobra; 11→12 acrescenta 9%) e o desconto não tem
alavanca nenhuma.

**(c) O ESS = teto era artefato do 0,80.** Em δ = 0,95 a escada **inverte**: os
três últimos degraus dão 0,344, 0,240 e 0,202 (`t` = −5,5, −13, −14). O **raso
vence**. Os duelos de longo alcance, uma medição independente com pares
não-adjacentes, concordam: o `h = 9` bate o `h = 12` (`t = −11`), o `h = 6` bate o
`h = 12` (`t = −4,4`). **Há ESS interior.** E o ótimo **desce** conforme δ sobe:
≥ 12 em 0,80; ~10 em 0,90; ~7–8 em 0,95.

## 5. O freio é ruído, não posição (a terceira camada)

A inversão admitia duas leituras, e elas fazem predições opostas:

- **Ruído** — a previsão funda é pior *contra o mundo*. O déficit é **absoluto** e
  aparece mesmo sem rival de outro tipo.
- **Teimosia / posicional** — a previsão está certa; o fundo só perde porque um
  raso chega antes na comida que ele planejou. Sem rival, o déficit **some**.

O discriminante é a distinção que este projeto já carrega (*população de
equilíbrio é proxy de grupo; para aptidão individual, ensaio de invasão*): rodar
populações de **tipo único** — todo bloco com o mesmo `h` e o mesmo δ — e ver se a
inversão do *duelo* tem contraparte **solitária**.

Tem. Diferença **pareada** por seed (a mesma seed em todo `h`), 8 seeds:

| δ | `pop(h=12) − pop(h=8)` | `comida_em_pé(h=12) − comida_em_pé(h=8)` |
|---|---|---|
| 0,80 | +2,04 ± 1,25 (`t = +1,6`) | +2,54 (`t = +2,1`) |
| 0,90 | −1,08 ± 1,25 (`t = −0,9`) | +13,55 (`t = +8,3`) |
| 0,95 | **−5,51 ± 1,27 (`t = −4,3`)** | **+31,45 (`t = +14,9`)** |

Em δ = 0,95, um mundo inteiro de blocos com `h = 12` sustenta **5,5 blocos a
menos** do que o mesmo mundo com `h = 8` — e **não há um `h = 9` ali para lhe tomar
a comida**. O déficit não é de posição: é contra o mundo. E o rastro material está
na comida que **ninguém colheu**.

**A dose-resposta é a assinatura.** Comida em pé, pareada contra `h = 1`:

| `h` | δ=0,80 | δ=0,90 | δ=0,95 |
|---|---|---|---|
| 2 | **−2,3** `t−4,3` | **−2,5** `t−3,8` | **−2,2** `t−3,1` |
| 6 | +11,0 `t+7,9` | +22,9 `t+10,2` | +27,6 `t+13,7` |
| 12 | +20,3 `t+12,5` | +45,2 `t+14,4` | **+73,6** `t+17,3` |

Três leituras, e a terceira é a tese:

**O pico de colheita é `h = 2`.** É o único degrau que colhe melhor que o míope,
nos três δ. Um passo de plano paga. **Do `h = 3` em diante, cada passo a mais piora
a colheita**, monotonicamente, sem exceção.

**O dano existe em todo δ — inclusive em 0,80**, onde a profundidade não custa
população (`t = +1,6`). Ou seja: neste mundo, **planejar fundo nunca colheu
melhor**.

**E o desconto controla quanto.** O mesmo `h = 12` deixa +20,3 / +45,2 / **+73,6**
conforme δ vai a 0,80 / 0,90 / 0,95: o dano **mais que triplica**. O erro da cauda
é o mesmo nos três — mesmo mundo, mesma profundidade. O que muda é `δᵏ`, **o peso
que a decisão dá a ele**. Em δ = 0,80, `0,8¹¹ ≈ 0,09`: a cauda errada entra
descontada a quase nada. Em δ = 0,95, `0,95¹¹ ≈ 0,57`: entra com mais da metade do
peso, e custa 5,5 blocos.

> **O desconto é um regularizador.** Não é impaciência: é o bloco se recusando a
> confiar numa previsão que ele não consegue fazer.

Isso dissolve o contra-intuitivo do §4(c) sem paradoxo: quanto mais peso se dá ao
futuro distante, menos longe se pode olhar sem ser envenenado pela própria
previsão. E reinterpreta a compensação do §1: o bloco que declara horizonte 11 e
desconto 0,66 **não está trapaceando a métrica** — está se protegendo da própria
alucinação. Baixar o desconto é adaptativo porque **regulariza**.

## 6. A síntese: a evolução pousa além do ótimo produtivo, e a sobra é a posição

Três medições independentes se encontram num número:

| quantidade | valor | de onde |
|---|---|---|
| ótimo de **colheita** | `h ≈ 2` | tipo único (§5) |
| ótimo de **grupo** (população) | `h = 1` | paisagem de grupo (§3) |
| profundidade efetiva **evoluída**, sem imposto | **3,31 ± 0,24** | evolução livre (§7) |

A evolução pousa **além** do ótimo produtivo — cerca de um passo e meio além — e
essa sobra é **exatamente o bem posicional**. É profundidade que não colhe nada e
que existe só para ganhar a célula do vizinho. A Rainha Vermelha, medida em passos.

E agora a fronteira. O horizonte é um bem posicional **onde o desconto o protege**
(δ ≲ 0,90): ali a profundidade extra é *inofensiva* — não custa população — e ainda
assim **vence duelos**. É a definição de um bem posicional: não produz nada, e mesmo
assim é preciso tê-lo para não ser deslocado. Acima disso (δ = 0,95), a
profundidade extra é *absolutamente* ruim, e aí ela não é um bem caro: é um
**erro**, e a seleção o corrige. É essa correção que produz o ESS interior do
§4(c).

## 7. O imposto, e por que alinhar a escolha não é restaurar o bem-estar

Se o planejador fundo impõe ao comum um custo que não paga, a receita clássica é
internalizar a externalidade: `METABOLISMO + c · profundidade`. Um **imposto
pigouviano sobre a cognição**.

Varremos `c` em 7 valores × 8 seeds × 30 000 ticks, com horizonte e desconto
**livres** (só a conta do metabolismo muda). O imposto é cobrado pela **profundidade
efetiva**, não pelo horizonte declarado — do contrário o bloco escaparia baixando o
desconto, pagando por passos que já não pesam. A escolha do que taxar não é um
detalhe: é a diferença entre um instrumento que morde e um que escorrega, e o dado
que a justifica é a não-identificabilidade do §1 (o `hor_m` tem `sd` até **15×** a
da profundidade efetiva; só quando o imposto é forte o bastante para colar tudo em
`h = 1` as duas leituras convergem).

| `c` | profundidade efetiva | população |
|---|---|---|
| 0 | **3,31 ± 0,24** | 284,4 |
| 0,04 | 1,82 ± 0,23 | 230,7 |
| **0,15** | **1,04 ± 0,02** | 186,9 |
| 0,30 | 1,01 ± 0,01 | 133,0 |

A profundidade evoluída desce monotonicamente e **encosta no ótimo de grupo**
(`h = 1`) em `c ≈ 0,15`. A coincidência prevista — um `c` onde interesse individual
e coletivo se alinham — aconteceu sem ajuste: ela cai onde a profundidade bate no
`h = 1` que o §3 já tinha medido, independentemente. O mecanismo pigouviano
**funciona** no sentido preciso em que foi pedido.

**E o preço não estava no orçamento.** A população cai monotonicamente com o
imposto: o `c` que alinha a escolha já custou **~35% da população** (284 → 187). Num
imposto pigouviano de livro a receita é **redistribuída**; aqui ela é **queimada** —
metabolismo extra que some. Então o imposto não corrige a externalidade sem custo:
corrige **cavando um buraco de energia**. A externalidade posicional que o §3 mede é
pequena (~2% de população entre `h = 1` e `h = 12`); a "cura" custa uma ordem de
grandeza mais que a "doença".

> **Alinhar a escolha não é o mesmo que restaurar o bem-estar**, quando o
> instrumento do alinhamento é ele próprio destrutivo. Quem paga a conta da
> coordenação, paga.

E há agora uma ironia que o §5 acrescenta: **este mundo já tinha um freio**, e ele é
de graça. O imposto exógeno e queimado compete com um mecanismo endógeno — a
imprecisão da própria previsão — que produz um ESS interior sem cobrar nada de
ninguém.

## 8. Ameaças à validade

- **O elo que falta.** Provamos que o tipo fundo colhe pior e que o dano escala com
  δ. **Não** medimos diretamente o erro da previsão a `k` passos. O §5 é inferência
  à melhor explicação, não medição do elo — fechá-lo exige uma sonda que compare
  `prever_valor` passo a passo com o realizado, e ela não existe.
- **`comida_em_pé` é do mundo, não do bloco.** Mais comida de pé é evidência de
  colheita pior, mas é agregada: não distingue "cada bloco colhe menos" de "os
  blocos se concentram e deixam regiões intocadas". As duas são formas de colher
  pior; a segunda seria uma história espacial, não de ruído temporal.
- **8 seeds** nos torneios e no tipo único; **3 seeds** na Fase 3 (§3). Os efeitos
  que decidem saem a `t` de 4 a 17; os nulos são nulos *medidos* (`t = +1,6`), não
  "não distinguimos" — exceto em δ = 0,30, onde o `sd` é de 0,2–0,4 e o platô é
  honestamente "não distinguível de 0,5 com 8 seeds".
- **Tipo único ≠ eremita.** Os blocos continuam se vendo e disputando célula; o que
  não existe é um bloco de **outro `h`**.
- **Grade de 5 descontos.** A inversão mora entre 0,90 e 0,95; onde exatamente o
  ótimo sai do teto, esta grade não diz.
- **50/50, não invasor-raro.** Com ESS interior, a distinção passou a importar de
  verdade — muito mais do que importava quando o ESS era o teto.
- **`HORIZONTE_MAX = 12` censura** o topo em δ baixo e médio.
- **Um mundo.** "A profundidade não produz nada" é uma propriedade *deste* mundo —
  manchas de comida procedurais, vizinhança 3×3, um passo por tick. Um mundo com
  estrutura de recompensa mais previsível deveria mover o ótimo de colheita para
  cima, e é um experimento, não uma opinião.

## 9. O que isto quer dizer, se quiser dizer algo

A narrativa "a evolução aprende a planejar mais longe" é, aqui, três coisas ao
mesmo tempo. É **mal formulada** (o horizonte não é identificável sem o desconto).
É **verdadeira num regime estreito** (um passo de plano paga; o segundo já não). E,
onde é verdadeira, **não é uma boa notícia**: a profundidade que a evolução
acrescenta além do segundo passo não faz o bolo crescer — ela transfere. Cada bloco
precisa pensar mais fundo só para ficar parado, e sai caro para todos.

O que o mundo de 56 KB acrescenta ao lugar-comum da Rainha Vermelha é o **freio**.
Ele não veio de um imposto, nem de um custo metabólico, nem de uma catraca de
desenho. Veio de o produto **apodrecer com a distância**: o plano fundo é uma
previsão que o mundo não honra, e o desconto é o único órgão que decide quanto
dessa mentira entra na decisão. Uma corrida armamentista por um bem que não existe
se auto-limita — não por virtude, e sim porque em algum ponto a arma passa a
disparar para trás.

Se isso vale para o bicho de 56 KB, vale a pergunta para os outros.

---

## Apêndice — reprodução

Há **um** `main.c` canônico; toda variante é um patch numa cópia temporária, e todo
script aceita um `main.c` alternativo (`git show <commit>:main.c`). Cada afirmação
deste artigo tem nota, script e dataset:

| seção | nota | script | dataset |
|---|---|---|---|
| §1, §3 (bem posicional, compensação) | Fase 3 do `ROADMAP.md` | — | — |
| §4 (torneio, ESS a δ=0,80) | 14 | `14-torneio.sh` | `torneio.csv` |
| §4 (varredura de δ, ESS interior) | 16 | `16-desconto.sh` | `desconto.csv` |
| §5, §6 (ruído × teimosia; a colheita) | 17 | `17-tipo-unico.sh` | `tipo-unico.csv` |
| §7 (imposto pigouviano) | 15 | `15-imposto.sh` | `imposto.csv` |

As notas registram as **hipóteses mortas** — três na Fase 3, e o mecanismo inteiro
do §4, que a nota 16 derrubou depois de a nota 14 o ter publicado. Num projeto cuja
tese é sobre o que uma medida carrega, hipótese morta é dado. **A ordem em que os
erros foram cometidos e corrigidos está no histórico do git, e o pré-registro de
cada nota foi commitado antes de a corrida rodar.**
