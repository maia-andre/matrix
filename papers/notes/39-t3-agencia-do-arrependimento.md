# Nota 39 — T3: o arrependimento negativo baixa a `agencia`, mas pelo motivo errado

**Data:** 2026-11-02
**Pré-registro:** `ROADMAP.md` §4.12, commit `9ba7cf4`, antes de rodar.
**Construído em:** `440a79b` (script commitado antes de rodar).
**Serve ao:** gate de T3, aberto pela primeira vez desde o §4.5 (notas 32–38), com
pré-registro próprio, como a nota 38 exigiu.
**Reproduzir:** `sh papers/notes/39-t3-agencia-do-arrependimento.sh` (12 min 31 s de
relógio com `JOBS=12`, 1 h 48 de CPU: 120 corridas de 5 000 ticks, mais S1/S4).

---

## Resumo

**T3 literal confirma, e a régua que o confirma não consegue ver o mecanismo.** Com a
`agencia` do `main.c`, blocos `−2,0` leem **menos** agência que blocos `0,0` em
**24/30** seeds (`p = 7,2·10⁻⁴`, corte ≥ 21/30). É exatamente o que o §4.5 previu em
julho. Mas a álgebra do §4.12 mostrou, antes da máquina, que essa sonda **não tem
canal** para o traço: dado o mesmo estado, ela dá a mesma leitura para `w = −2,0` e
`w = 0,0`. A diferença é **ecológica**: ela vem de onde os blocos `−2,0` estão, não
de como decidem.

**O mecanismo empurra para o outro lado, e com o sinal invertido nos dois braços.**
Ligando o termo `w·r·E` na sonda (o mesmo bloco, no mesmo tick, com e sem o termo), a
agência **sobe** com `w = −2,0` em **26/30** seeds e **cai** com `w = +2,0` em
**30/30**. P1 e P2 falham, e falham do lado oposto do previsto, não perto do corte.
Pela tabela escrita antes, **a hipótese da nota 30 cai na forma mecânica**: o
arrependimento negativo não aproxima o bloco do reflexo. O que se aproxima do reflexo
é o **positivo**.

A palavra que quebra é "reflexo", na frase da nota 30: *"parar de responder ao espaço
é, por definição, aproximar-se do reflexo"*. O peso negativo não para de responder ao
espaço: ele torna essa resposta **condicional à fome** (§4, pós-hoc). Fugir **sempre**
da lotação, que é o que o peso positivo faz, é que é reflexo.

## 1. Sanidade: as quatro passaram

| | resultado |
|---|---|
| S1: a sonda não toca o mundo | CSV com sonda = CSV sem sonda, md5 idênticos nas 4 montagens da seed 201 |
| S2: a identidade (`w·r = 0` ⇒ sonda completa = original) | **0** divergências em `float` e **0** em `double`, em todos os blocos-tick das 120 corridas |
| S3: a coluna `agencia` do CSV = `(O_X+O_Z)/(n_X+n_Z)` a `%.3f` | **0** ticks divergentes, nas 120 corridas |
| S4: paralelismo | NEG/201/A repetida sozinha: md5 do CSV **e** do fluxo idênticos |

S2 é a que dá significado ao resto. Ela garante que a sonda completa **é** a original
onde o termo some, e que toda diferença `F − O` mora nos blocos-tick com `w·r ≠ 0`. O
painel confirma: "F−O fora de `r > 0`" dá exatamente 0 nos dois braços.

**O piso do `float32` (regra 6, P4):** 46 blocos-tick com `O ≠ O_double` e 50 com
`F ≠ F_double`, no painel inteiro (só a janela de 2 000 ticks já soma 34 milhões de blocos-tick `X`). Todas as contagens de P1/P2 são idênticas em `double`, nas três janelas. O piso existe, como a nota 36 já tinha
mostrado na decisão, e aqui ele está quatro ordens de grandeza abaixo do efeito.

## 2. P1 e P2: o mecanismo, com o sinal invertido

`δ = (F_X − O_X)/n_X`, média das montagens A e B por seed:

| | W = 500 | **W = 2000 (primária)** | W = 5000 |
|---|---|---|---|
| **P1** NEG, `δ < 0` (previsto) | 0/30 | **4/30**, mediana **+0,0064** | 10/30 |
| **P2** POS, `δ > 0` (previsto) | 0/30 | **0/30**, mediana **−0,0104** | 0/30 |

Lido no sentido em que saiu: NEG tem `δ > 0` em **26/30** (bilateral `p = 5,9·10⁻⁵`) e
POS tem `δ < 0` em **30/30** (`p = 1,9·10⁻⁹`). O Wilcoxon por permutação dá `p < 10⁻⁵`
nos dois. Os dois braços apontam em sentidos **opostos**, então o efeito depende do
**sinal** de `w`. Isso descarta a leitura "qualquer dose baixa a agência", a linha do
meio da tabela do §4.12. Só que o sinal é o contrário do previsto.

Na janela de 5 000 ticks o braço NEG enfraquece (20/30 positivas, mediana +0,0026)
enquanto POS segue 30/30. Não leio isso como desacordo de janelas: com o tempo, a
composição e o remorso acumulado mudam. Fica registrado, sem interpretação.

**Dose (P5, descritivo).** O remorso não é raro: **90%** dos blocos-tick `X` com
escolha têm `r > 0` nos dois braços. A razão é aritmética: `r` decai
geometricamente (`r·desconto`) e só volta a zero por underflow do `float`, de modo
que todo bloco que já perdeu uma disputa carrega um resíduo. Isso não contradiz a nota
30 Q2 (a **taxa** de arrependimento por tick é ~6%); quer dizer que o termo quase
sempre está ligado, quase sempre com dose pequena. Entre os `r > 0` do braço NEG,
**88%** têm `|s| < 1`, ou seja, o intervalo varrido **encolhe**, e mesmo assim a
agência sobe. Daí a "sugestão" do §4.12 ("encolher sugere menos trocas") estar errada.

## 3. P3: T3 literal confirma, e a ecologia faz o serviço

`Δ_orig = O_X/n_X − O_Z/n_Z` (com a régua do `main.c`, entre tipos, montagens espelhadas):

| | W = 500 | **W = 2000** | W = 5000 |
|---|---|---|---|
| **P3** NEG, `Δ_orig < 0` | 25/30 | **24/30** (`p = 7,2·10⁻⁴`), mediana −0,0090 | 24/30 |
| POS, `Δ_orig < 0` | 5/30 | 8/30 (22/30 **positivas**) | 6/30 |
| NEG, `Δ_full < 0` (total, régua completa) | 3/30 | 17/30 | 23/30 |

**P3 confirma**, contra a minha expectativa declarada ("não decide", confiança baixa).
Errei. E o espelho também aparece aqui: `+2,0` lê **mais** agência ecológica que
`0,0` em 22/30. Os dois efeitos têm sinais opostos em cada braço. A ecologia baixa a
agência de `−2,0` e sobe a de `+2,0`, e o mecanismo direto faz o contrário. Somados
(`Δ_full`), praticamente se cancelam em W = 2000 (17/30). Em W = 500 o direto vence
(27/30 positivas) e em W = 5000 a ecologia vence (23/30 negativas).

Isto merece ser dito do jeito mais simples: **a régua cega confirmou a hipótese, e a
régua que enxerga o mecanismo mostra que ele empurra para o lado contrário.** Se a
`agencia` do `main.c` fosse o único instrumento, T3 sairia como um ✅ limpo (24/30,
três janelas concordando) com uma história mecânica errada colada nele. É a mesma
família de mentira que o Paper 1 cataloga, a régua que mede outra coisa, só que agora
**a favor** de uma predição pré-registrada. O pré-registro não teria pegado isso
sozinho. Quem pegou foi a álgebra feita antes (regra 9), que mandou construir a
segunda régua.

**O que a ecologia é, não sei.** Esta nota não mede *por que* blocos `−2,0` estão em
posições de menos escolha. A suspeita óbvia, que eles ficam onde há disputa, é a
hipótese do item 2 da fila ("por que `−2,0` vence"), e lá deve ser testada, não aqui.

## 4. Por que o sinal inverte (pós-hoc, não testado)

A forma fechada do §4.12 explica a inversão, mas a explicação foi escrita **depois**
do placar e fica rotulada assim. A sonda completa varre o coeficiente do espaço de
`c(fome total) = w·r/(1+u)` até `c(saciado) = P + w·r`.

- **`w > 0`:** `c > 0` no eixo inteiro, e maior que na sonda original. O desejo de
  espaço pesa mais, e com o mesmo sinal, em toda fome, então a escolha muda menos ao
  longo do eixo. É o reflexo de fugir da lotação.
- **`w < 0`:** `c` começa **negativo** na fome total (a célula lotada passa a valer
  mais) e, se `r < P/|w|`, termina positivo saciado. O **sinal** da preferência por
  espaço passa a depender da fome, e a escolha troca mais vezes ao longo do eixo.

Lida assim, a frase da nota 30 estava invertida. O peso negativo não faz o bloco
"parar de responder ao espaço": faz a resposta ao espaço **depender do estado
interno**, e isso é a definição operacional de agência desta bateria. A predição
testável que sai daqui, e **não** foi testada: `δ > 0` do braço NEG deveria se
concentrar nos blocos-tick com `r < P/2` (onde `c` cruza zero), e sumir nos de
`r > P/2`.

*(Uma confissão de calibração: antes de rodar o painel testei o encanamento na seed
31, fora da amostra, com 300 ticks, e ela já mostrava o sinal invertido nos dois
braços. O pré-registro estava commitado (`9ba7cf4`) e nada nele foi mudado. Registro
porque "eu já desconfiava" é o tipo de frase que não deve aparecer numa nota sem
evidência de quando a desconfiança começou.)*

## Ameaças à validade

- **A sonda completa é minha, não do `main.c`.** Ela foi verificada por identidade
  (S2, zero divergências) onde deve coincidir com a original, mas onde difere não há
  verdade de referência. Ela mede o que a forma fechada diz que mede: a sonda original
  sobre o intervalo deslocado.
- **`agencia` binária por bloco** (troca alguma vez ou não) é a estatística herdada
  da nota 03. A variante graduada (trocas/(opções−1)) poderia dar outra magnitude, e
  não rodou.
- **`δ` é pequeno em valor absoluto** (~1 ponto percentual da população com escolha).
  O placar é de direção, consistente nas 30 seeds, e não um efeito grande.
- **A explicação do §4 e a leitura "ecológica" do §3 são pós-hoc.** Esta última é
  necessária por álgebra (a régua original não tem outro canal), mas o *conteúdo* da
  ecologia não foi medido.
- **5 000 ticks, invasão sem mutação no traço.** Os outros traços continuam mutando,
  como em todas as notas do fio.

## O que isso faz com o fio

- **T3 fecha, com veredito duplo e explícito.** Literal: confirma (24/30). Mecânico:
  refutado com o sinal invertido (26/30 e 30/30). A frase "o arrependimento negativo
  aproxima o bloco do reflexo" não deve ser usada em lugar nenhum. Se for usada,
  precisa da qualificação de que só vale para a régua cega e por motivo ecológico.
- **A `agencia` do `main.c` é cega ao §4.3, e isso agora tem consequência medida.**
  Por decisão do André (§4.12), fica registrado e não é consertado: a coluna dos
  datasets congelados não muda. Qualquer leitura futura de `agencia` em população com
  `peso_arrependimento ≠ 0` deve dizer que a régua não vê esse termo.
- **O item 2 ("por que `−2,0` vence") herda uma pista:** a ecologia que baixa a
  agência de `−2,0` é candidata a fazer parte do mecanismo da vantagem.

## O que ficou em aberto

1. **A predição do §4**: `δ > 0` concentrado em `r < P/|w|`. Ela sai do fluxo da sonda
   com uma coluna a mais e custa um painel de ~12 min.
2. **O conteúdo da ecologia**: onde os blocos `−2,0` estão (lotação, riqueza da célula)
   em relação aos `0,0`. Isso é parte do item 2.
