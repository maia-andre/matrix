# Nota 27 (eixo microscópio) — O detector de nova estratégia: o sapo fervendo é o espelho da extinção rápida demais

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/27-detector-de-nova-estrategia.sh`,
commitado em `a828be6` — **antes** de rodar (F0/F1/F2/F3).
**Serve ao:** eixo "Matrix como microscópio" — terceiro e último módulo
declarado no ROADMAP. Agregados em `datasets/detector-estrategia.csv`.
**Reproduzir:** `sh papers/notes/27-detector-de-nova-estrategia.sh` (~10–15
min com `NPROC=16`)

---

## Resumo

O terceiro exemplo do ROADMAP ("emergiu uma nova estratégia") não tinha,
diferente do colapso (imposto das notas 15/21), um mecanismo de choque
pronto no projeto. Duas decisões antes de codar: **o que conta** como
estratégia nova — a fração honesta da população (`hon_f`, rastreada desde a
nota 08; honestidade é um ESS sem multa, então um desvio sustentado dela é
mudança de estratégia pelo próprio vocabulário do projeto) — e **que choque**
a move — inventado aqui: forçar todo nascimento, numa janela de ticks, a
herdar `SIN_BLEFE` em vez da herança normal.

O detector é o mesmo núcleo das notas 24/25 (janela recente × referência),
trocando população por `hon_f`. Passou pelo teste central (não confabula) e
detectou a maioria dos choques reais — mas as duas seeds que escapou têm um
padrão que **não é o mesmo** da extinção rápida demais das notas 24/25: aqui
o sinal é **lento demais**, não rápido demais. É o espelho exato do primeiro
achado do eixo, do outro lado da régua.

| # | predição | resultado |
|---|---|---|
| **F0a** | sem forçar nada, detector não muda a simulação (CSV bit a bit) | ✅ |
| **F1** | detecção positiva: dispara em ≥ 7/8 seeds | ⚠️ **6/8** — as 2 que não dispararam declinaram TANTO quanto as outras (41–46%), só que devagar |
| **F2** | não-confabulação: ≤ 1/8 falsos positivos | ✅ **0/8** |
| **F3** | colapso + recuperação: dispara ≥ 6/8; ativo_no_fim=0 em ≥ 6/8 | ✅ **6/8** dispararam; **6/6 (100%)** desligaram |

## 1. O teste central, de novo limpo

| condição | seeds | disparos |
|---|---|---|
| F2 — vanilla, sem forçar nada, 13000 ticks | 8 | **0** |

A flutuação natural de `hon_f` em torno do seu equilíbrio (~0,78–0,85, o
mesmo patamar que a nota 08/11/12 já tinham medido) fica bem abaixo do
limiar de 20% de queda relativa. É o terceiro detector deste eixo (colapso,
duas-linhagens, agora estratégia) a passar por este teste sem exceção — a
régua não inventa mudança de regime onde só há ruído saudável.

## 2. A detecção: 6/8, e o motivo dos dois que faltam não é o da nota 24

| seed | disparou | latência | queda_max (janela) |
|---|---|---|---|
| 1 | sim | 597 | 0,2792 |
| 2 | **não** | — | 0,1402 |
| 3 | sim | 600 | 0,2515 |
| 4 | **não** | — | 0,1396 |
| 5 | sim | 585 | 0,2612 |
| 6 | sim | 381 | 0,2805 |
| 7 | sim | 517 | 0,2617 |
| 8 | sim | 442 | 0,3216 |

Latência média (das que dispararam): 520 ticks — bem mais lenta que a
detecção de colapso populacional (~54–122 ticks, notas 24/25), consistente
com a alavanca aqui ser **substituição demográfica** (nascimentos
sucessivos), não um efeito direto de energia num único tick.

**As seeds 2 e 4 não são um "falso negativo" no sentido da nota 24.** Lá, o
detector ficava mudo porque a extinção acontecia RÁPIDO DEMAIS — mais rápido
que a janela de 250 ticks conseguisse reagir. Aqui é o oposto. Investigando a
trajetória completa das duas seeds:

| seed | `hon_f` em t=8000 | `hon_f` em t=12500 | declínio TOTAL |
|---|---|---|---|
| 2 | 0,783 | 0,461 | **41,1%** |
| 4 | 0,829 | 0,444 | **46,4%** |

O declínio acumulado dessas duas seeds (41–46%) é **maior** que o de várias
que dispararam. A diferença não é a magnitude do efeito — é o **ritmo**. O
declínio é aproximadamente linear e lento (~0,03–0,05 por 500 ticks); em
nenhum momento a janela de comparação (recente de 250 ticks contra uma
referência de 250 ticks, ~750–1000 ticks atrás) via mais que ~14% de queda
de uma vez — o `queda_max` das duas fica em 0,14, bem abaixo do limiar,
apesar do total acumulado passar de 40%. É o **sapo fervendo**: um detector
de janela fixa mede a *taxa* de mudança dentro de um lag específico, não a
*distância* a um baseline distante — uma deriva devagar o bastante nunca
cruza o limiar, não importa o quanto, no total, ela já tenha andado.

## 3. As duas faces do mesmo desenho

| falha | onde apareceu | mecanismo | tempo característico do evento | tempo da janela |
|---|---|---|---|---|
| Rápido demais | notas 24/25 (colapso) | extinção total | 11–14 ticks | 250 ticks |
| Devagar demais | esta nota (estratégia) | deriva sustentada | milhares de ticks | ~750–1000 ticks (o lag efetivo) |

O mesmo instrumento — janela recente vs. referência, um limiar de queda
relativa — tem uma faixa de frequências para a qual foi calibrado, e fica
cego nas duas pontas: eventos mais rápidos que a janela conseguir preencher,
e eventos mais lentos que o lag conseguir separar de "ainda não mudou muito".
Não é um defeito específico deste detector: é uma propriedade estrutural de
**qualquer** detector de janela fixa, e as notas 24/25/27 juntas são a
demonstração empírica dos dois lados.

## 4. A recuperação: confirma de novo

| | dispararam | desligaram até o fim |
|---|---|---|
| F3 (força liga 8000, desliga 12000, total 16000 ticks) | 6/8 | **6/6 (100%)** |

As mesmas 6 seeds que disparam em F1 disparam aqui (nos mesmos ticks — a
força desliga em `t=12000`, depois de todas já terem disparado); todas
desligam o sinal até o fim da corrida, coerente com o piloto (`hon_f`
recupera de ~0,42 a ~0,80 em ~2500 ticks após a remoção do choque). O
relatório acompanha o retorno também neste terceiro sinal.

## 5. Ressalvas honestas

- **O "sapo fervendo" foi um achado, não uma predição.** O pré-registro
  previa ≥7/8 sem antecipar esse mecanismo específico — a mesma disciplina
  das notas 23/25: reportar quando a predição erra, e por quê, é mais
  valioso que acertar o número.
- **O choque foi inventado, não emprestado.** Ao contrário do imposto
  (notas 15/21, já validado por várias notas antes de servir de "colapso
  conhecido" aqui), "forçar todo nascimento a `SIN_BLEFE`" foi desenhado só
  para este teste. Ele certamente move `hon_f` (confirmado no piloto e nas
  8 seeds), mas não tem o mesmo lastro de validação independente que o
  imposto tinha antes da nota 24.
- **Um só limiar, uma só janela.** Dado o achado do "sapo fervendo", a nota
  25 já mostrou que ajustar a janela (mais curta) ajuda com eventos rápidos
  demais; o oposto — uma janela mais LARGA, ou um lag maior entre recente e
  referência — provavelmente ajudaria a pegar deriva lenta, à custa de
  detectar mais devagar even os choques rápidos. Não testado aqui.
- **Só um alvo (`hon_f`), só um choque (força para `SIN_BLEFE`).** Não se
  testou o análogo para `SIN_MUDO`, nem detecção sobre outros traços
  (`urg_m`, `esp_m`) que também poderiam qualificar como "nova estratégia".

## 6. Método

- **Detector:** idêntico em estrutura ao das notas 24/25 (`recente` = média
  dos últimos 250 ticks, `referência` = média de 250 ticks terminando 500
  ticks antes, limiar 20% de queda relativa), lendo `hon_f` em vez de
  população.
- **Choque:** `cria->estrategia = SIN_BLEFE` (em vez de
  `muta_estrategia(pai->estrategia)`) para todo nascimento com
  `FORCA_INICIO <= tick < FORCA_FIM`. Sentinela `finicio = -1` (não `0`)
  para distinguir "nunca forçar" de "forçar desde o tick 0" — um bug pego
  pela própria sanidade F0a antes do pré-registro (o padrão inicial
  `finicio=0` forçava blefe em TODO nascimento mesmo sem a variável de
  ambiente setada; corrigido antes de commitar).
- **`geral_t`:** captura de `t` para uso dentro de `reproduzir()`, que (como
  `aplicar_e_comer()`) não recebe o tick como parâmetro — mesmo padrão das
  notas 24/25 (`imp_t`).
- **Dataset** `detector-estrategia.csv`: uma linha por condição×seed —
  `condicao,inicio,seed,disparou,tick_disparo,queda_max,tick_queda_max,
  ativo_no_fim`.
