# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O projeto

Experimento meio filosófico, meio de programação: uma "Matrix" de brinquedo no terminal (ASCII) onde blocos-agentes sobem uma **escada de senciência** (níveis 0–6: reatividade → memória → valência → modelo de mundo → agência → auto-modelo → aprendizado/seleção natural). Tudo em **um único arquivo C** (`main.c`), só libc, sem dependências.

- `README.md` é o *como* (arquitetura, parâmetros, efeitos medidos) — mantê-lo em dia faz parte de qualquer mudança de comportamento.
- `FILOSOFIA.md` e `FILOSOFIA_v2.md` são o *porquê* (o manifesto; a bateria de desbotamento). Docs e UI em pt-BR; **código e commits sem acentos**.
- `ROADMAP.md` é o *para onde*: os eixos de pesquisa, os riscos de cada um, e o que o projeto escolhe **não** ser (paralelização/SIMD quebram o determinismo; um arquivo por experimento quebra a comparabilidade dos datasets).
- `datasets/` guarda CSVs congelados com manifesto de proveniência (comando + commit de `main.c`, em `datasets/README.md`); `datasets/gerar.sh` regenera tudo. Após mudança de comportamento intencional, regenerar e atualizar o manifesto. `notebooks/` analisa os datasets (commitar **sem outputs**); `papers/` é a escrita formal (fonte + PDF).

## Compilar e rodar

Não há Makefile neste repo (o `make matrix` do README vem do repo maior `c_training/` de onde o projeto foi extraído). Compilação direta, verificada limpa com:

```sh
gcc -std=c11 -Wall -Wextra -O2 -o matrix main.c
```

**Nunca adicione `<math.h>`/`-lm`** — o projeto compila sem `-lm` de propósito; o ruído usa aritmética inteira e o resto polinômios.

```sh
./matrix [seed] [ticks] [delay_ms] [foco]   # defaults: 20260628, 0 (infinito), 80, -1 (visão de deus)
./matrix 7 2000 0 --log run7.csv            # headless, gera CSV (1 linha de stats/tick)
```

A animação exige terminal de verdade (≥ ~70 colunas; ANSI). Teclas: `p`/`TAB` primeira pessoa, `,` `.` troca bloco, `espaço` pausa, `q` sai.

## Verificação (não há suíte de testes)

O teste do projeto é o **determinismo**: o universo inteiro é `f(seed)` — mesma seed ⇒ simulação e CSV **bit-a-bit idênticos**. Para verificar uma mudança:

```sh
./matrix 7 200 0 | grep -a -o 'pop [0-9]*' | tail -1     # checagem rápida de população
./matrix 7 2000 0 --log antes.csv                        # antes × depois: diff dos CSVs
```

Mudanças que não deveriam alterar comportamento devem produzir CSV idêntico. Mudanças de comportamento seguem a cultura do projeto: **medir o efeito** (A/B com algumas seeds, ex.: parâmetro em 0 vs default) e documentar o achado no README, como feito para `ANTECIPACAO` e a evolução dos traços.

## Arquitetura do main.c

Pipeline em 4 partes (marcadores `PART n` no arquivo; `main` em ~linha 1041):

| Parte | Onde | Papel |
|-------|------|-------|
| PART 1 — Mundo procedural | ~175 | mundo é `f(seed,x,y)`: hash → value-noise → manchas de comida (`gerar_mundo`, `ruido`, `hash2`) |
| PART 2 — Blocos / cognição | ~257 | a "mente": `prever_valor` (nv3), `utilidade` (nv4), `declarar`/`pretendentes_em` (nv5), traços herdados com mutação (nv6) |
| PART 3 — Simulação (o tick) | ~413 | fases: `declarar` → `decidir` → `resolver` → `aplicar_e_comer` → `reproduzir` → `rebrotar` |
| PART 4 — Render + laço | ~552 | buffer ASCII + HUD, teclado cru (termios), bateria de desbotamento, log CSV |

Quase toda evolução do projeto mexe **só na PART 2** (cognição) ou na reprodução; mundo, tick e render ficam de pé.

## Invariantes que não podem quebrar

- **Determinismo total**: geração do mundo E decisões/nascimentos usam o mesmo RNG semeado (`rng_estado`). Nada de `time()`, `rand()` sem seed, ou ordem dependente de ponteiros — quebraria a reprodutibilidade bit-a-bit dos CSVs.
- **Leitura × escrita separadas no tick**: todos decidem lendo o estado estável (preenchendo `alvo_x/alvo_y`), só depois o mundo aplica. As duas passagens do nível 5 (`intencao_*` → `alvo_*`) usam arrays separados. Misturar as fases reintroduz a "física fantasma" da ordem de varredura (bloco que anda mais rápido só porque o laço o visita antes).
- **Resolução de conflito** (`resolver`): só se move para célula **vazia no início do tick**; célula disputada vai para o pretendente de menor índice, os demais ficam parados. Simplicidade proposital — evita bugs de troca de lugar.
- **Estado em globais file-static**: `comida[][]`, `capacidade[][]`, `ocup[][]` (índice do bloco ou -1), `blocos[]`. `vivo == 0` marca slot livre; `alocar_slot()` reaproveita o buraco de **menor índice** antes de estender `n_blocos` (não reaproveitar impunha um teto de ~1348 nascimentos por simulação e congelava a evolução por volta do tick 10 000). Como `resolver()` desempata pelo menor índice, **o índice não é neutro**: no código antigo ele codificava a ordem de nascimento, e o mais velho vencia toda disputa.
- **Percepção estritamente local** (vizinhança 3×3): nenhum bloco lê estado global — o comportamento global deve *emergir*.
- As "leis da física" são os `#define` no topo do arquivo; `HORIZONTE`, `DESCONTO`, `URGENCIA`, `PESO_ESPACO` são apenas **médias iniciais** — os valores reais são traços por bloco (nível 6), herdados com mutação.

## Bateria de desbotamento e CSV

Os mostradores (`modelo`, `agencia`, `modelo_do_outro`, `phi`), todos em `[0,1]`, medem se uma faculdade **carrega o comportamento** (famílias: ablação e calibração) — função, nunca experiência. Aparecem no HUD e no CSV (`--log`). Colunas do CSV: `seed, tick, pop, energia_media, comida_total`, média e desvio dos 4 traços (`*_m`, `*_sd`), e os 4 mostradores. Ao adicionar/renomear coluna, manter a reprodutibilidade e atualizar o README (e o notebook, que lê colunas por nome). Mostrador pendente documentado: `relato`. (`modelo_do_outro` era `automodelo` — renomeado na nota 04: mede o outro, não o self. `phi` foi redefinida na nota 05: menor distância de Kendall aos módulos isolados; zero exato se um módulo só explica a decisão.)

## Commits

Estilo do histórico: `matrix: <descrição em pt-BR sem acentos>`, uma mudança conceitual por commit (um degrau da escada, um mostrador, uma seção de filosofia).
