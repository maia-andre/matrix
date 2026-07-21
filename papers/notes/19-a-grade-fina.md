# Nota 19 — A grade fina do desconto: o ótimo desce enquanto `1/(1−δ)` sobe, e deixa o teto entre 0,88 e 0,90

> **Errata (2026-07-20, nota 20):** onde esta nota diz "ESS interior", leia "ponto
> singular interior **convergence-stable**". O invasor-raro (nota 20) mostrou que o
> `h*` localizado aqui atrai a evolução mas **não** resiste a invasores raros — é um
> **ponto de ramificação**, não um ESS. A curva `h*(δ)` e o platô mole que esta nota
> mede seguem exatos; é o *nome* do que `h*` é que a nota 20 corrige. (E o platô
> mole desta nota é, retrospectivamente, a cara do polimorfismo protegido da 20.)

**Data:** 2026-07-20
**`main.c`:** o de `079a3ce` (canônico **intocado**; o patch é o da nota 16 **sem
uma vírgula de diferença** — G0 prova isso reproduzindo `datasets/desconto.csv`
linha a linha).
**Pré-registro:** cabeçalho de `papers/notes/19-grade-fina.sh`, commitado em
`02d0e86` — **antes** de rodar (G0..G5).
**Serve ao:** Paper 2 — localiza em curva o que a nota 16 viu em 3 pontos: onde o
ESS sai do teto e que forma tem a descida. Agregados em `datasets/grade-fina.csv`.
**Reproduzir:** `sh papers/notes/19-grade-fina.sh` (~15 min com `NPROC=16`, MEDIDO)

---

## Resumo

A nota 16 mediu o ótimo de horizonte em 3 descontos (≥12 no teto em δ=0,80, ~10 em
0,90, ~7–8 em 0,95) e concluiu que o ótimo **desce** com a paciência. Três pontos
não dizem onde o ótimo sai do teto nem que forma tem a descida. Esta grade fina —
δ ∈ {0,88; 0,90; 0,92; 0,94; 0,95; 0,96}, a escada `(h, h+1)` inteira, 8 seeds,
6000 ticks — põe as duas coisas em curva.

**A descida é monótona e o topo tomba junto. `h*(δ)` = teto/platô (0,88) → 10
(0,90) → 9 (0,92) → 8 (0,94) → 8 (0,95) → 7 (0,96)**, enquanto `1/(1−δ)` **sobe**
de 8,3 a 25 no mesmo intervalo. As duas quantidades andam em **direções opostas**:
o medido não segue, nem de longe, a fórmula do joelho — G3, a predição negativa,
confirmada.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **G0** | fatias δ=0,90/0,95 reproduzem `desconto.csv` linha a linha | ✅ **160/160** idênticas |
| **G1** | `h*(δ)` não-crescente; ancoras da nota 16 (≈10 em 0,90; 7–8 em 0,95) | ✅ 10 em 0,90; **8** em 0,95 |
| **G2** | onde sai do teto: (a) `h*(0,88)<12` ⇒ δ_teto<0,88, ou (b) `=12` ⇒ δ_teto∈[0,88;0,90) | ✅ **(b)**: `h*(0,88)` é teto/platô ⇒ **δ_teto ∈ [0,88; 0,90)** |
| **G3** | `h*(δ)` **não** segue `1/(1−δ)` (que na grade cresce 8,3→25) | ✅ o medido **desce** 12→7, direção **oposta** |
| **G4** | transição fix→polim **não** anda (nota 16 P2) | ✅ fixações só no rung 3→4 (esporádicas), ~0/8 de 4→5 em diante, em todo δ |
| **G5** | o interior vence o teto em duelo direto onde `h*≤9` | ✅ `h=9` bate `h=12` de δ≥0,90; `h=12` esmagado (0,156) em 0,96 |

## 1. A descida, com barra

Frequência final do tipo **mais fundo** no duelo `(h, h+1)` — `>0,5` significa
"subir de `h` para `h+1` ainda paga". Média ± erro-padrão de 8 seeds, com o `t`
contra 0,5 (pareado por construção: as mesmas 8 seeds em todo par). Só o trecho
onde o ótimo mora:

| rung | δ=0,88 | δ=0,90 | δ=0,92 | δ=0,94 | δ=0,95 | δ=0,96 |
|---|---|---|---|---|---|---|
| 6→7 | 0,575 ↑ | 0,567 ↑ | 0,525 · | 0,572 ↑ | 0,551 ↑ | 0,554 · |
| 7→8 | 0,529 ↑ | 0,598 ↑ | 0,582 ↑ | 0,564 ↑ | 0,512 · | **0,457 ↓** |
| 8→9 | 0,572 ↑ | 0,528 ↑ | 0,501 · | **0,430 ↓** | 0,449 · | 0,407 ↓ |
| 9→10 | 0,535 · | 0,529 ↑ | 0,471 · | 0,389 ↓ | **0,344 ↓** | 0,290 ↓ |
| 10→11 | 0,501 · | 0,479 · | **0,425 ↓** | 0,325 ↓ | 0,240 ↓ | 0,178 ↓ |
| 11→12 | 0,511 · | 0,455 · | 0,379 ↓ | 0,264 ↓ | 0,202 ↓ | 0,150 ↓ |

(↑ = `t>2` acima de 0,5; ↓ = `t<−2` abaixo; · = dentro do ruído de 0,5.)

Leia por coluna: conforme δ sobe, a fronteira do "subir ainda paga" **desce pela
escada**. Em δ=0,88 o topo inteiro (de h≈9 a 12) é um **platô neutro** — nenhum
rung se distingue de 0,5: acrescentar profundidade lá em cima não paga **nem
cobra**, exatamente o "inofensivo e inútil" que a nota 16 §4 previu para o δ baixo.
Em δ=0,96 a mesma região é uma **ladeira** (`t` de −2,3 a −20): cada passo de
profundidade acima de 7 é ativamente **punido**. O ESS não *pula* de lugar; o
gradiente do topo **tomba continuamente** de neutro a negativo à medida que a
paciência aumenta.

`h*(δ)`, lido como o último rung ainda ≥ 0,5:

| δ | 0,88 | 0,90 | 0,92 | 0,94 | 0,95 | 0,96 |
|---|---|---|---|---|---|---|
| `h*` | ≥9 (platô/teto) | 10 | 9 | 8 | 8 | 7 |
| `1/(1−δ)` | 8,3 | 10,0 | 12,5 | 16,7 | 20,0 | 25,0 |

## 2. G3 — a fórmula do joelho anda para o lado errado

A linha `1/(1−δ)` na tabela acima **cresce** de 8,3 a 25; `h*` **cai** de ≥9 a 7.
Não é que a fórmula erre a constante — ela erra o **sinal da derivada**. A nota 16
já tinha dito por quê, e a grade fina fecha em curva: `1/(1−δ)` mede quando a
profundidade extra fica **invisível** (o peso `δᵏ` some), não quando ela fica
**nociva**. São dois regimes distintos, e a paciência os separa: quanto maior δ,
mais longe a cauda é *carregada* — e, pela nota 18, mais longe é carregado um sinal
que já em k=1 é **ruído** (e em δ alto, anticorrelação). O ótimo evolutivo recua
justamente porque o peso que multiplicaria o lixo cresceu. **Mais paciência não
compra mais profundidade ótima; compra menos**, porque amplifica o único uso da
cauda que existe neste mundo: envenenar a decisão.

## 3. G2 — o teto é abandonado entre 0,88 e 0,90

Em δ=0,88 o topo é platô: `11→12 = 0,511 ± 0,027` (`t = +0,4`, indistinguível de
0,5). Operacionalmente `h*(0,88)=12` (não há cruzamento), mas a leitura honesta é
"o topo é neutro, o teto é um dos muitos ótimos empatados lá em cima". Em δ=0,90 o
`10→11` e o `11→12` já pendem para baixo (0,479 e 0,455) — o teto **deixou** de ser
ótimo. Logo **δ_teto ∈ [0,88; 0,90)**: é nessa janela estreita que a corrida ao
`HORIZONTE_MAX` — que a nota 14 leu como *o* resultado, com δ=0,80 — vira ESS
interior. Confirma a alternativa (b) do pré-registro, e a transição não é abrupta:
é um platô que **tomba**, não um degrau que cai.

## 4. G4/G5 — o que replicou e o que o duelo direto mostra

**A transição fixação→polimorfismo não anda** (G4). Fixações do tipo fundo
aparecem só no rung `3→4` e de forma esporádica (3, 1, 2, 0, 1, 0 seeds em 8,
pelos seis δ), e são **0/8 de `4→5` para cima em todo δ**. A transição fica em
`h≈3–4` sem se mexer com o desconto — exatamente o que a nota 16 achou (P2) ao
derrubar a leitura da nota 14 §3, que fundia a transição com o joelho. Duas escalas
independentes: o joelho anda, a transição não.

**Os longos confirmam o interior por duelo direto** (G5) — freq do `h=12` contra um
interior:

| δ | h=5 vs 12 | h=7 vs 12 | h=9 vs 12 |
|---|---|---|---|
| 0,88 | 0,619 | 0,552 | 0,516 |
| 0,90 | 0,565 | 0,495 | 0,468 |
| 0,92 | 0,516 | 0,443 | 0,349 |
| 0,94 | 0,493 | 0,375 | 0,238 |
| 0,95 | 0,452 | 0,326 | 0,200 |
| 0,96 | 0,441 | 0,297 | **0,156** |

O `h=12` domina em duelo só onde ainda está perto do ótimo (δ baixo); de δ=0,90 em
diante um `h=9` o **derrota diretamente** (0,468 → 0,156), e um `h=7` o alcança em
δ≈0,90. A dominância transitiva "o mais fundo vence" da nota 14 era, também ela, um
fato do δ=0,80: acima do joelho ela **inverte**.

## 5. Uma seed não é um resultado (nota de método)

O smoke test desta nota, rodado com a seed 7 sozinha, deu `h*(0,88)=10`,
`h*(0,90)=10`, `h*(0,92)=10` — uma história limpa e **errada** de ótimo achatado em
10. As 8 seeds movem `h*(0,88)` para o teto/platô e `h*(0,92)` para 9. A seed 7
sorteou baixo no `10→11` de δ=0,88 (0,460 nela, 0,501 na média) e o cruzamento
apareceu onde não há. É a terceira vez que o corolário do protocolo se paga
([[matrix-protocolo-de-medicao]]): esperei as 8 seeds de propósito, e o platô de
δ=0,88 — o achado central do G2 — só existe na média.

## 6. Método

- **h\* operacional** (pré-registrado): o `h+1` do último par com freq > 0,5 quando
  há **um** cruzamento; teto se subir paga até `11→12`; múltiplos cruzamentos =
  não-unimodal (não ocorreu). Resolução ±1.
- **G0** compara campo a campo com `desconto.csv` nas fatias δ=0,90/0,95 (mesmo
  binário, mesmas seeds) — 160 linhas, 0 divergências. As fatias novas (5\_12,
  7\_12) não têm par lá e são puladas na checagem.
- **Pareado por seed** em toda a estatística (as mesmas 8 seeds em todo par e todo
  δ); o `t` contra 0,5 usa o erro-padrão entre seeds.
- **Dataset** `grade-fina.csv`: mesmas colunas de `desconto.csv`
  (`desconto,seed,hi,hj,freq_hj,hor_m_fim,pop_fim,fixou`).
