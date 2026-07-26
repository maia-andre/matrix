# Nota 26 (eixo microscópio) — "Há duas linhagens distintas?" sem conhecer o `h*` de antemão

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/26-duas-linhagens-sem-h-conhecido.sh`,
commitado em `b5f6a2f` — o algoritmo e os limiares foram fixados antes de ver
o resultado da reanálise (não há um "antes de rodar simulação nova" aqui — a
reanálise usa dado já coletado; ver §5).
**Serve ao:** eixo "Matrix como microscópio" — segundo módulo, generaliza a
classificação de bimodalidade da nota 23. Reanalisa `datasets/bimodalidade.csv`
(nenhum dataset novo).
**Reproduzir:** `sh papers/notes/26-duas-linhagens-sem-h-conhecido.sh` (~30s)

---

## Resumo

A nota 23 testou se o ponto de ramificação da nota 20 produz uma população
de fato bimodal — mas fazendo TRAPAÇA de propósito: a classificação flanqueava
um `h*(δ)` que as notas 19/20 já tinham descoberto. Legítimo para testar a
teoria; ilegítimo para um detector que devia "produzir conhecimento sobre a
Matrix" (ROADMAP) sem receber a resposta pronta. Esta nota generaliza: um
algoritmo que **descobre** o ponto de corte sozinho, a partir só do
histograma, e valida contra os mesmos cenários de terreno conhecido da
nota 23.

O algoritmo: para cada bin interior do histograma de horizonte, compara sua
massa com o **máximo corrido** de cada lado (não o vizinho imediato — a
correção exata do defeito que a própria nota 23 achou e descartou antes do
seu pré-registro: contar picos locais fragmentava um modo largo e ruidoso em
"3–4 picos" espúrios). O vale escolhido é o de menor profundidade relativa;
BIMODAL se essa profundidade ≤ 0,5 e cada lado tem ≥ 15% da massa — uma
extensão exata do critério da nota 23, só que agora o ponto de corte é
descoberto, não informado.

**O achado não era o que eu esperava: o detector genérico não só confirma a
nota 23 nos casos claros, como resolve uma ambiguidade que ela tinha deixado
em aberto.**

| # | predição | resultado |
|---|---|---|
| **E0** | classificador ao vivo (portado para o `main.c`) não muda a simulação | ✅ CSV bit a bit idêntico |
| **E1** | concorda com a nota 23 em ≥ 6/8 seeds em cada condição com veredito forte | ✅ δ=0,90/0,95/0,96: 6/8, 7/8, 7/8. δ=0,80 e `livre`: **discorda em massa** (ver E2) |
| **E2** | reportar toda discordância, sem limiar de "aceitável" | ✅ 10 discordâncias, listadas e explicadas abaixo |
| **E3** | veredito ao vivo bate com a reanálise post-hoc num caso bimodal conhecido | ✅ `δ=0,95`, seed 1: bimodal=1, vale em **h=8** — o próprio `h*` teórico, descoberto sem ser informado |

## 1. Nos casos de δ alto, o genérico confirma — com uma margem honesta

| condição | genérico | nota 23 (informado) | concordam |
|---|---|---|---|
| `uni_h_livre` δ=0,90 | 6/8 | 8/8 | 6/8 |
| `uni_h_livre` δ=0,95 | 7/8 | 8/8 | 7/8 |
| `uni_h_livre` δ=0,96 | 7/8 | 8/8 | 7/8 |

O detector que não sabe onde procurar ainda encontra a maioria esmagadora
dos casos bimodais que a nota 23, informada pelo `h*`, encontrou em 8/8. Nas
seeds em que discordam (δ=0,95 seed 7, δ=0,96 seed 7, δ=0,90 seeds 2 e 7), o
vale que o algoritmo acha É real — mas sua profundidade relativa fica acima
de 0,5 (0,52 a 0,65): um vale genuíno, só que raso demais para o limiar. Não
é um erro do algoritmo; é o mesmo tipo de caso-limite que a nota 25 achou
para o detector de colapso (uma seed a 0,0016 do limiar) — a fronteira entre
"sim" e "não" tem espessura, e alguns casos caem exatamente nela.

**A demonstração ao vivo (E3) mostra o melhor caso**: em δ=0,95, seed 1 (o
histograma mais limpo que a nota 23 já tinha visto), o classificador
descobre o vale **exatamente em h=8** — o mesmo `h*` que as notas 19/20
localizaram por invasão pareada, sem que o algoritmo soubesse disso. Quando
o sinal é forte, descobrir converge para o que a teoria já sabia.

## 2. Em δ=0,80, o genérico discorda em massa — e resolve uma dúvida da nota 23

| condição | genérico | nota 23 | concordam |
|---|---|---|---|
| `uni_h_livre` δ=0,80 | **0/8** | 4/8 | 4/8 |

Nenhuma das 8 seeds em δ=0,80 tem, pelo critério genérico, dois picos
genuinamente separados — mesmo as 4 que a nota 23 tinha marcado como
bimodais pela região fixa. Olhando o histograma de uma delas (seed 3):

```
h:    1  2   3    4    5    6    7    8    9    10    11    12
soma: 0  0  91  324  266  399  500  524  394   560  1320  2052
```

Isso não é dois picos com um vale entre eles — é uma **cauda enviesada**,
crescendo (com ruído) desde `h=3` até dominar perto do teto `h=12`. A nota 23
já tinha registrado essa possibilidade como uma ressalva não resolvida:
*"o resultado é consistente com duas leituras que este desenho não separa:
(a) existe algum grau de ramificação já em 0,80 (...) ou (b) é carga de
mutação"*. O detector genérico, que exige um vale de verdade (não só massa
suficiente dos dois lados de um corte arbitrário), vota pela leitura **(b)**:
o que a nota 23 viu como "bimodal" em δ=0,80 é o efeito de uma região fixa
(baixa ≤ 9, alta ≥ 11) capturar as duas pontas de uma distribuição
**unimodal com cauda longa**, não duas linhagens coexistindo. A partição
fixa da nota 23 não distinguia as duas leituras; o vale descoberto, sim.

## 3. Em `livre`, o genérico acha o que a partição fixa perdeu

| condição | genérico | nota 23 | concordam |
|---|---|---|---|
| `livre` (todos os traços evoluindo) | 1/8 | 0/8 | 7/8 |

A seed 5 é o caso interessante:

```
h:    1  2   3    4    5     6     7    8    9    10   11   12
soma: 0  0  74  115  665  1728  1252  638  215   381  522  332
```

Pico principal em `h=6` (1728), vale genuíno em `h=9` (215, profundidade
relativa 0,412), segundo agrupamento em `h=10–12` (massa 20,9%). A nota 23
usava uma partição genérica fixa (baixa ≤ 5 / alta ≥ 9) para `livre`, porque
ali δ também evolui e não há um `h*` único — mas essa partição cortava ANTES
do pico principal desta seed (em `h=6`), e sua `m_baixa` registrada foi
0,144 — **a um triz** do limiar de 0,15 (nota 23, tabela §2). O detector que
descobre o corte sozinho não erra esse limite porque não depende de uma
fronteira arbitrária coincidir com a estrutura real dos dados. Continua
sendo a exceção, não a regra — das 8 seeds livres, 7 seguem unimodais em
ambos os critérios, reafirmando o achado central da nota 23: a evolução
livre raramente comete a dois pontos ao mesmo tempo.

## 4. Ressalvas honestas

- **O algoritmo não teve seu próprio pré-registro "cego"** no sentido de uma
  corrida nova: ele reanalisa dados que a nota 23 já tinha publicado. A
  disciplina aqui foi fixar o algoritmo e os limiares *antes* de rodar a
  reanálise (não os ajustei depois de ver que dariam "bons" números) — mas é
  uma barra mais baixa que pré-registrar antes de gerar dado novo. A
  demonstração ao vivo (E3) mitiga isso parcialmente: o classificador roda
  dentro do `main.c`, sobre um histograma acumulado durante a simulação, não
  sobre uma cópia dos números já publicados.
- **`profundidade relativa ≤ 0,5` e `massa ≥ 0,15` são os MESMOS números da
  nota 23**, escolhidos lá sem uma teoria que os derive — só a exigência de
  "separação de pelo menos metade do pico menor". Não foram recalibrados
  aqui; um algoritmo genérico com limiares emprestados de um caso informado
  ainda carrega uma escolha arbitrária, só que uma só, não duas.
- **δ=0,80 não está decidido, só mais bem argumentado.** "O detector
  genérico vota por carga de mutação" é uma leitura, não uma prova —
  decidir de vez exigiria uma variante com mutação de horizonte desligada
  (equilíbrio sem introdução contínua de mutantes) comparada a uma com
  mutação, isolando os dois mecanismos. Não construída aqui.
- **O vale mais raso nem sempre é o mais informativo.** O algoritmo escolhe
  o vale de MENOR profundidade relativa; em histogramas com mais de um vale
  candidato, isso pode preferir um vale "limpo" mas pequeno a um vale mais
  largo e mais relevante biologicamente. Não observado como problema nos
  dados desta nota, mas não descartado por desenho.

## 5. Método

- **Reanálise (E1/E2):** puro Python sobre `datasets/bimodalidade.csv` — sem
  rodar simulação nova, sem consumir RNG, sem gerar dataset novo.
- **Ao vivo (E0/E3):** reaproveita o histograma da nota 23
  (`hist_soma[13]`, janela dos últimos 5000 ticks amostrada a cada 250) e
  adiciona `linh_classifica()`, chamada dentro de `hist_despeja()` — o
  mesmo algoritmo da reanálise, em C, sem `sqrt` (só `for` e comparações).
  E0 confirma leitura pura (CSV `--log` bit a bit idêntico ao vanilla).
- **Fundo `uni_h_livre`:** idêntico ao da nota 23 (desconto/urgência/
  peso_espaço/estratégia pregados, horizonte livre).
- **Sem dataset novo** — os números desta nota são reprodutíveis rodando o
  script, que reanalisa `datasets/bimodalidade.csv` (já commitado na
  nota 23) e roda uma única corrida de demonstração (não persistida).
