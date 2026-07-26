# Nota 25 (eixo microscópio) — A dose-resposta do detector: o limiar entre "colapso sobrevivível" e "silêncio rápido demais"

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/25-dose-resposta-do-detector.sh`,
commitado em `419a1cf` — **antes** de rodar (D0a/D0b/D1/D2).
**Serve ao:** eixo "Matrix como microscópio" — aprofunda o limite honesto que
a nota 24 encontrou no detector de colapso. Agregados em
`datasets/dose-detector.csv` e `datasets/janela-detector.csv`.
**Reproduzir:** `sh papers/notes/25-dose-resposta-do-detector.sh` (~5–10 min
com `NPROC=16`)

---

## Resumo

A nota 24 achou que o detector de colapso (janela recente × referência sobre
a própria história de população) fica **mudo** diante de uma extinção rápida
demais: em `c=0,30` (o imposto pigouviano das notas 15/21, ligado no meio de
uma corrida já estável), 2 das 8 seeds se extinguiram por completo em 11–14
ticks — antes de a janela de 250 ticks conseguir refletir a queda. Esta nota
pergunta duas coisas que ficaram em aberto: **(D1)** esse limite é uma
transição estreita ou uma dose-resposta suave? **(D2)** uma janela mais curta
resolveria, e a que custo?

**As duas respostas vieram limpas e na direção prevista pelos pilotos.**

| # | predição (escrita antes) | resultado |
|---|---|---|
| **D0a** | detector parametrizável não muda a simulação (CSV bit a bit) | ✅ |
| **D0b** | reproduz a extinção da nota 24 (seeds 1 e 8, `c=0,30`, janela 250) | ✅ mesmos ticks (2013/2010) |
| **D1** | extinção é 0/8 em todo custo ≤ 0,25; só sobe em `c=0,30` | ✅ **exato** — 0/8 extintas em 0,04 a 0,25; 2/8 em 0,30 |
| **D2** | janela=30 detecta ≥ 7/8 em `c=0,30` (vs 6/8 da janela=250); falso-positivo ≤ 2/8 | ✅ **7/8** detectados; **0/8** falso-positivo (nenhum aumento) |

## 1. D1 — não é dose-resposta suave, é transição de fase

| custo | extintas | detectadas | latência média | queda_max média |
|---|---|---|---|---|
| 0,04 | 0/8 | 8/8 | 121,9 ticks | 0,408 |
| 0,08 | 0/8 | 8/8 | 85,5 ticks | 0,548 |
| 0,15 | 0/8 | 8/8 | 66,6 ticks | 0,664 |
| 0,20 | 0/8 | 8/8 | 60,6 ticks | 0,704 |
| 0,25 | 0/8 | 8/8 | 56,8 ticks | 0,738 |
| **0,30** | **2/8** | 6/8 | 54,3 ticks | 0,763 |

Duas curvas limpas e monotônicas para quem sobrevive: quanto maior o custo,
**mais rápida** a detecção (122 → 54 ticks) e **maior** o pico de queda (41% →
76%) — o detector escala com a severidade do choque exatamente como se
esperaria de um instrumento calibrado. E então, exatamente em `c=0,30`, duas
das oito seeds somem do mapa por completo. Não há um degrau intermediário:
`c=0,25` já produz uma queda de 74% em média e ainda assim **nenhuma** das 8
seeds se extingue; um incremento de 0,05 no custo (17% a mais) empurra 2 das
mesmas 8 seeds para zero. É uma **transição de fase estreita** entre 0,25 e
0,30, não uma cauda esperada de uma curva suave — o mesmo tipo de achado que
a nota 19 fez para o `h*(δ)` (o ótimo "tomba" de neutro a punido entre
δ=0,88 e 0,90), agora para a sobrevivência sob choque agudo.

As seeds que se extinguem são **exatamente** as duas que a nota 24 já tinha
achado (seed 1, tick 2013; seed 8, tick 2010) — determinismo confirmando
determinismo, não coincidência.

## 2. D2 — a janela curta ajuda, sem custo aparente, mas não resolve por completo

| janela | condição | disparou | extintas |
|---|---|---|---|
| 250 | vanilla | 0/8 | 0/8 |
| 250 | c=0,30 | 6/8 | 2/8 |
| 30 | vanilla | 0/8 | 0/8 |
| **30** | **c=0,30** | **7/8** | 2/8 |

Trocar a janela de 250 para 30 ticks pega **uma seed a mais** (seed 1, que
dispara em `t=2010` — **3 ticks antes** de a população chegar a zero em
`t=2013`) sem custar **nenhum** falso positivo adicional em população
saudável (0/8 nos dois tamanhos de janela, 16 corridas de 6000 ticks cada).
Um "quase de graça": mais sensível ao choque agudo, sem pagar em ruído.

Mas não resolve por completo. A seed 8 (extinta em `t=2010`, a mais rápida
das duas) **continua muda** mesmo com a janela de 30: seu `queda_max` chega a
**0,1984** — a um triz do limiar de 0,20 — no exato instante em que a
população zera, e nunca cruza. A extinção dessa seed é rápida até para uma
janela de 30 ticks: dado o limiar de 20% e a velocidade da queda, faltou
literalmente um fio de cabelo estatístico. Uma janela ainda mais curta
poderia pegá-la, mas o piloto não testou até onde esse encolhimento continua
"de graça" — ver Ressalvas.

## 3. Ressalvas honestas

- **D2 testou só dois pontos (250 e 30), não uma curva.** O verdadeiro
  trade-off (sensibilidade × falso-positivo em função do tamanho da janela)
  provavelmente tem uma curva contínua entre esses extremos, e pode inverter
  em algum ponto (uma janela de 5–10 ticks quase certamente aumentaria falso
  positivo, dado que a variação natural tick-a-tick é maior que a média de
  uma janela de 30). Não medido.
- **A seed 8 mostra que "janela curta" não é uma solução geral.** Fica a
  0,0016 do limiar — um caso em que o critério binário (≥0,20 ou não) esconde
  o quão perto o detector chegou. Um relato mais honesto talvez devesse
  reportar a `queda_max` contínua, não só o disparo binário — mas isso é
  decisão de desenho para uma nota futura sobre COMO o relatório é consumido
  (ROADMAP: "ele carrega comportamento, ou é saída inerte?").
- **Custo único de onset (`t=2000`) e um único par de seeds extremas (1, 8).**
  A transição de fase D1 foi caracterizada usando as mesmas 8 seeds da nota
  24; não se sabe se o intervalo exato [0,25, 0,30] se mantém com outro tick
  de início ou outra semente de população.
- **O detector ainda mede só população.** As mesmas ressalvas da nota 24 sobre
  o escopo (não é dose-resposta de outros sinais, não testa dois módulos
  declarados no eixo microscópio) seguem valendo.

## 4. Método

- **Detector parametrizável:** o mesmo núcleo da nota 24
  (`col_hist`/janela-recente-vs-referência), agora lendo `COL_JANELA`,
  `COL_VAO`, `COL_LIMIAR` do ambiente em vez de `#define` fixos — permite
  reusar o mesmo binário para D1 (janela padrão, custo variável) e D2
  (custo fixo, janela variável) sem recompilar.
- **`col_extinta`/`col_tick_extincao`:** instrumentação nova, pura leitura —
  marca o primeiro tick em que a população chega a zero, independente do
  detector ter disparado ou não (permite distinguir "não disparou porque não
  havia colapso" de "não disparou porque o mundo acabou antes").
- **D0b como âncora:** em vez de recomputar a extinção do zero, verifica que
  o binário parametrizável, com os MESMOS parâmetros da nota 24
  (`COL_JANELA=250, COL_VAO=500`), reproduz exatamente as mesmas duas
  extinções — a garantia de que generalizar o código não mudou o
  comportamento no caso já medido.
- **Datasets:** `dose-detector.csv`
  (`custo,seed,disparou,tick_disparo,queda_max,tick_queda_max,ativo_no_fim,
  extinta,tick_extincao`) e `janela-detector.csv` (mesmas colunas, com
  `janela` e `custo` como chaves).
