# Nota 21 — O imposto que recicla: alinhar a escolha volta a ser de graça

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09; o patch da
nota 21 mexe só numa cópia temporária).
**Pré-registro:** cabeçalho de `papers/notes/21-reciclagem.sh`, commitado em
`6522c23` — **antes** de rodar (R0/R-cons/R1..R4).
**Serve ao:** Paper 2 §7 — fecha a pendência que a nota 15 deixou aberta ("o
imposto que recicla é o próximo pré-registro"). Agregados em
`datasets/reciclagem.csv`.
**Reproduzir:** `sh papers/notes/21-reciclagem.sh` (~40 min com `NPROC=16`)

---

## Resumo

A nota 15 achou que o imposto pigouviano sobre a profundidade efetiva **alinha**
a escolha ao ótimo de grupo (`h → 1` em `c ≈ 0,15`) mas **queima** ~35% da
população — a receita sai do bloco e some. Faltava o teste que separa as duas
coisas: um imposto que **devolve** a receita mede se internalizar a
externalidade melhora o bem-estar, ou se só a mecânica da escolha se alinha.

O mecanismo: dividendo per-capita. Cada tick, `c · profundidade_efetiva` entra
num pool; depois que metabolismo e morte resolvem, o pool é dividido igualmente
entre os sobreviventes e devolvido à energia de cada um — o rebate pigouviano de
manual, lump-sum (o que você recebe quase não depende da sua própria
profundidade).

**O resultado é mais forte do que o pré-registro previu.** O reciclado não só
recupera a perda do queimado — ele termina **levemente acima** do próprio
baseline sem imposto nenhum, em **todo** custo testado. Alinhar a escolha, sem
destruir a receita, sai de graça — e um pouco mais que de graça.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **R0** | `RECICLA=0,c=0` reproduz `seed7.csv` bit-a-bit | ✅ |
| **R-cons** | `\|sum_tax − sum_rebate\| / sum_tax < 1e-5` | ✅ rel = 2,00e-06 |
| **R1** | profundidade ainda cai com `c` no reciclado, dentro de ~0,5 do queimado | ✅ diferença máxima 0,16 (`c=0,08`); em 4 dos 7 custos, ≤ 0,01 |
| **R2** | `pop_reciclado(c=0,15) > 240` (recupera > 60% da perda); `\|t\| > 3` em `c ≥ 0,08` | ✅ e além — `pop = 289,6` (102% do baseline); `t = 26,86`; já `\|t\| > 20` em `c = 0,01` |
| **R3** | alinhamento sem bem-estar destruído: profundidade ~igual, só população diverge | ✅ decomposição limpa (R1 quase idêntico entre modos, R2 enorme) |
| **R4** | se recuperação parcial, relatar `pop_baseline − pop_reciclado` como custo residual | ❌ **não houve custo residual** — o resíduo é **positivo** (+0,7 a +5,8, isto é 0 a +2% acima do baseline) |

## 1. O alinhamento sobrevive ao rebate, quase intocado (R1)

| `c` | prof. queimado | prof. reciclado |
|---|---|---|
| 0 | 3,31 ± 0,24 | 3,31 ± 0,24 |
| 0,01 | 2,91 ± 0,50 | 2,91 ± 0,64 |
| 0,02 | 2,58 ± 0,72 | 2,46 ± 0,36 |
| 0,04 | 1,82 ± 0,23 | 1,82 ± 0,24 |
| 0,08 | 1,32 ± 0,41 | 1,16 ± 0,12 |
| 0,15 | 1,04 ± 0,02 | 1,03 ± 0,01 |
| 0,30 | 1,01 ± 0,01 | 1,01 ± 0,00 |

As duas curvas praticamente se sobrepõem. O gradiente privado de reduzir
profundidade **sobrevive** ao rebate — é a assinatura de um instrumento
lump-sum de verdade: o bloco não é recompensado pela própria profundidade, só
recebe de volta uma fração igual do pool comum. Se o rebate tivesse matado o
incentivo (reciclado preso em `h` fundo), R1 teria falseado o mecanismo; não foi
o que aconteceu.

## 2. O ponto — bem-estar, não só alinhamento (R2)

| `c` | pop. queimado | pop. reciclado | Δ pareado | `t` |
|---|---|---|---|---|
| 0 | 284,4 ± 38,0 | 284,4 ± 38,0 | +0,0 | 0,00 |
| 0,01 | 260,8 ± 35,9 | 285,0 ± 38,1 | +24,2 ± 0,9 | +26,74 |
| 0,02 | 247,3 ± 34,8 | 286,7 ± 38,0 | +39,4 ± 1,4 | +29,09 |
| 0,04 | 230,7 ± 35,0 | 287,6 ± 37,4 | +56,9 ± 2,5 | +22,38 |
| 0,08 | 218,2 ± 34,0 | 289,7 ± 37,4 | +71,5 ± 2,4 | +30,38 |
| 0,15 | 186,9 ± 26,5 | 289,6 ± 37,3 | +102,7 ± 3,8 | +26,86 |
| 0,30 | 133,0 ± 20,4 | 290,1 ± 37,5 | +157,2 ± 6,1 | +25,93 |

No `c ≈ 0,15` que a nota 15 identificou como o ponto de alinhamento (profundidade
≈ 1), a população queimada era 186,9 (66% do baseline); a reciclada é 289,6
(**102%** do baseline). A recuperação prevista era "> 60% dos ~97 blocos
perdidos" (R2); o que aconteceu foi recuperação total **e um excedente**.

## 3. A surpresa — o resíduo é positivo, não um custo (R4)

O pré-registro previa uma ressalva: o rebate redistribui para sobreviventes que
tendem a estar perto do teto de reprodução, então a recuperação poderia ser
**parcial**, e `pop_baseline − pop_reciclado` seria o custo residual dessa
ineficiência. Essa ressalva **não se confirmou** — o sinal do resíduo é o
oposto do previsto:

| `c` | pop. reciclado | resíduo | % do baseline |
|---|---|---|---|
| 0,01 | 285,0 | +0,7 | 100% |
| 0,02 | 286,7 | +2,3 | 101% |
| 0,04 | 287,6 | +3,2 | 101% |
| 0,08 | 289,7 | +5,4 | 102% |
| 0,15 | 289,6 | +5,3 | 102% |
| 0,30 | 290,1 | +5,8 | 102% |

Uma leitura candidata, não provada aqui: o §3 do Paper 2 já media a
externalidade posicional em si — a diferença entre a paisagem de grupo em
`h = 1` (295,9) e em `h = 12` (289,3) é de **~2,2%**. O excedente do reciclado
neste experimento também converge para **~2%**. Como a nota 17 mostrou que
planejar além de `h ≈ 2` colhe **estritamente pior** (não é só transferência
entre vizinhos — é ineficiência real de colheita), forçar a profundidade de
volta para perto de `h = 1` sem destruir energia deveria devolver
aproximadamente essa mesma fatia como população extra. A ordem de grandeza
bate; a nota não isola o mecanismo (não há uma variante que desligue a
ineficiência de colheita mantendo o alinhamento, para separar as duas fontes).

## 4. Ressalvas honestas

- **R4 como escrito foi falseado, na direção favorável.** O pré-registro previu
  um possível custo residual e mediu um excedente. Isso é registrado aqui como
  o pré-registro manda — a predição não bateu, e a direção do erro importa mais
  que o número.
- **A leitura do §3 é candidata, não isolada.** A convergência de ~2% entre o
  excedente do reciclado e a externalidade posicional medida na paisagem de
  grupo é sugestiva, não uma decomposição experimental. Faltaria uma variante
  que desacople "menos ineficiência de colheita" de "energia conservada" para
  atribuir o excedente a uma causa específica.
- **Conservador na morte, como documentado no pré-registro.** Um bloco morto
  pelo pico do imposto não recebe o dividendo daquele tick (a morte é checada
  no fluxo de comer, antes do rebate) — versão que **subestima** a recuperação.
  Mesmo assim o reciclado supera o baseline; a versão não-conservadora
  recuperaria ainda mais.
- **8 seeds, 30 000 ticks** — mesmo orçamento da nota 15, para comparação direta
  pareada por seed. Os `t` variam de 22 a 30; não é um efeito marginal.
- **Um custo, um mecanismo de reciclagem.** Não se testou dividendo
  proporcional (em vez de per-capita) nem atraso na distribuição; o resultado
  vale para o rebate lump-sum tal como especificado.

## 5. Método

- **Dois fluxos, uma conservação.** `imp_pool` acumula o imposto do tick;
  depois de `aplicar_e_comer` resolver metabolismo e morte, o pool é dividido
  pelos sobreviventes e somado à energia de cada um. `imp_sum_tax` e
  `imp_sum_reb` (em `double`) acumulam ao longo da corrida para o R-cons.
- **Um binário, dois modos por ambiente:** `RECICLA=0,c=0` → canônico
  bit-a-bit; `RECICLA=0,c>0` → o imposto queimado da nota 15 (patch
  textualmente idêntico no termo do imposto); `RECICLA=1,c>0` → o novo.
- **Pareado por seed** em todas as comparações R1–R4 — a mesma seed em queimado
  e reciclado, no mesmo `c`.
- **Dataset** `reciclagem.csv`: `recicla,custo,seed,hor_m,desc_m,prof_efetiva,pop_fim`.
