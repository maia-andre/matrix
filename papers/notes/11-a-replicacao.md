# Nota 11 — 50 seeds: a replicação

**Data:** 2026-07-14
**`main.c`:** o de `079a3ce` (nenhuma linha do canônico mudou; variantes são
patches temporários, como sempre)
**Serve ao:** Paper 1 (metrologia da mente) — era a última dívida de dados dele.
Os agregados ficam em `datasets/replicacao50.csv` (uma linha por condição × seed).
**Reproduzir:** `sh papers/notes/11-replicacao.sh` (~15 min com `NPROC=12`;
~2 h de CPU total — não entra no `datasets/gerar.sh` por isso)

---

## Resumo

"Uma seed não é um resultado" — o corolário aprendido três vezes, agora pago:
**9 condições × 50 seeds (1..50) × 3000 ticks**, todas as condições de
falseamento do Apêndice A e as alegações direcionais das notas, com os valores
de 3 seeds publicados como pré-registro (cabeçalho do script, antes de rodar).

| alegação (3 seeds) | em 50 seeds | veredito |
|---|---|---|
| Z1–Z5: os dez zeros do Apêndice A | **0 violações em 10 × 50 corridas** | ✅ intactos |
| Z6: piso da `agencia` no eremita, 0,003–0,004 | 26/50 seeds, máx **0,005**, sempre f32 | ✅ e cresce um dígito |
| Q1 (aberta desde a nota 09): piso fora do eremita? | **1,4·10⁻⁷** dos blocos-tick | ✅ respondida: desprezível |
| V1: controles (`modelo` ~0,63, `phi` ~0,065...) | tudo dentro de ±2 sd | ✅ |
| V2: `autocausa` ctl/eremita ~5× | **4,78 ± 0,67**, eremita > 0 em 50/50 | ✅ |
| V3: eremita mudo, κ ~0,005 | 0,0046 ± 0,0005 | ✅ |
| V4: `autocausa` sobe × `agencia` cai | **as duas direções em 50/50 seeds** | ✅ |
| V5: honestidade domina sem fixar | domina sem fixar em 50/50 (0,76 ± 0,05 **aos 3000 ticks**) | ✅ estrutura; o número da nota 08 é de 30 000 ticks — ver §5 |
| extinção sob `prever_valor ≡ 0` em 74–105 ticks | 50/50 extintas — em **51–121** | ⚠️ intervalo alargou |

## 1. O aparato

Variantes: `ctl`, `erem`, `pv0`, `esp0`, `h1`, `cego0..3` — os mesmos patches
das notas 01/05/06/09/10, aplicados a uma cópia temporária. Corridas paralelas
por processo (`xargs -P`), o que **não** toca o determinismo: cada processo é
`f(seed)` inteiro. Sanidade da regra 3: a variante instrumentada reproduz
`datasets/seed7.csv` bit-a-bit antes de o lote começar.

A instrumentação nova (Q1): toda corrida computa a `agencia` **duas vezes** por
bloco-tick — a oficial (float32, que segue no CSV) e uma gêmea com a comparação
em `double` — e conta as discordâncias. É a pergunta que as notas 09/10
deixaram aberta: qual é o piso da régua *fora* do eremita, onde não há verdade
algébrica para comparar? Resposta: compara-se **a régua com ela mesma em outra
precisão**.

## 2. Os zeros: 10 condições, 500 corridas, nenhuma violação

`modelo`/pv0, `phi`×{erem, esp0, pv0}, `relato`×{cego 0,1,2,3},
`modelo_do_outro`/erem, `autocausa`/h1 — **máximo 0,000000 nas 50 seeds de cada
uma**. Nenhuma seed, em nenhuma condição, produziu um tick que viole um zero do
Apêndice A. Os zeros estruturais da nota 10 se comportam como estruturais.

## 3. O piso, fechado dos dois lados

| regime | blocos-tick discordantes | fração | seeds afetadas | direção |
|---|---|---|---|---|
| eremita | 42 de 42,0 M | **1,0·10⁻⁶** | 26/50 | **42× f32-fantasma**, 0× o contrário |
| normal (ctl) | 6 de 43,4 M | **1,4·10⁻⁷** | 6/50 | 5 f32-fantasma, 1 o contrário |
| `esp0` | 0 de 43,5 M | 0 | 0/50 | (λ ≡ 0: o eixo nem existe — estrutural) |

No CSV a 3 casas o piso do eremita aparece como `ag_max` ∈ {0,003; 0,004;
**0,005**} em 26 das 50 seeds (as outras 24 leem 0 limpo). A nota 09 viu
0,003–0,004 em 2 de 3 seeds; com 50, o teto sobe um dígito.

A leitura: **o piso é um fenômeno do regime eremita.** Com `espaco ≡ 1`, o
termo λ·E soma a *mesma* constante a células de valor quase igual — o
quase-empate é sistemático, e só numa direção (a troca fantasma que o `double`
desfaz). Na população normal os quase-empates são raros (1 evento a cada ~7
milhões de blocos-tick), **cinco ordens de grandeza abaixo do sinal**
(`agencia` ~0,4), e nas duas direções — precisão finita, não viés. A pergunta
desconfortável da nota 09 ("qual é o piso onde não há verdade para comparar?")
tem resposta: medível, minúsculo, e sem direção preferida.

## 4. Os valores, agora com barras

Controles (média ± sd [min..máx] das 50 seeds; média por corrida em
ticks > 20, população viva):

| mostrador | 50 seeds | as 3 seeds diziam |
|---|---|---|
| `modelo` | 0,6293 ± 0,0105 [0,60..0,66] | ~0,63 ✅ |
| `agencia` | 0,4175 ± 0,0265 [0,30..0,46] | ~0,42–0,44 ✅ |
| `modelo_do_outro` | 0,2672 ± 0,0538 [0,15..0,40] | ver §5 |
| `phi` | 0,0649 ± 0,0039 [0,046..0,070] | ~0,06–0,07 ✅ |
| `relato` | 0,6310 ± 0,0111 [0,60..0,65] | κ ~0,62–0,67 ✅ |
| `autocausa` | 0,1381 ± 0,0113 [0,11..0,16] | ~0,13–0,15 ✅ |

As direcionais:

- **Nota 09 P1/P3 (o self do eremita):** `autocausa` > 0 em **50/50** eremitas;
  razão acompanhado/sozinho **4,78 ± 0,67 [3,2..6,3]**. O "~5×" era honesto.
- **Nota 09 P4 (o campo, não a seta):** `autocausa` **sobe** (0,093 ± 0,006 →
  0,162 ± 0,016) e `agencia` **cai** (0,464 ± 0,011 → 0,384 ± 0,048) — **as
  duas, na mesma seed, em 50 de 50**. `hor_m` final 8,7 ± 1,1 (a Rainha
  Vermelha compareceu em todas). É o resultado mais robusto do lote.
- **Nota 06 P5 (o eremita mudo):** κ = 0,0046 ± 0,0005 em 50/50. Mudo mesmo.

## 5. O que a replicação moveu (e é para isso que ela serve)

1. **Um erro do próprio pré-registro desta nota.** O cabeçalho do script
   esperava `hon_f` final ~0,85 citando a nota 08 S6 — mas aquele número é de
   corridas de **30 000 ticks**, e este lote roda 3000. A comparação era
   inválida e fica registrada como inválida. O que o lote *pode* afirmar: aos
   3000 ticks a honestidade já lê **0,76 ± 0,05 [0,65..0,88]** (blefe 0,16 ±
   0,04), **domina sem fixar em 50/50 seeds** (fixação > 0,99 em zero delas) —
   a estrutura da nota 08 (polimorfismo, mudo varrido) já está de pé no décimo
   do horizonte. Os ~0,85–0,90 de 30 000 ticks seguem **não replicados** (ver
   Ameaças). A nota 08 não ganha errata: ela não errou; eu li o horizonte errado.
2. **Extinção sob `prever_valor ≡ 0`: 74–105 → 51–121 ticks** (mediana 76,
   50/50 extintas). A alegação ("sem mapa, a população morre em ~cem ticks")
   segue; o intervalo de 3 seeds subestimava a cauda. Errata na nota 01.
3. **`modelo_do_outro`: a referência atual é 0,27 ± 0,05**, não os ~0,35 da era
   da nota 04. Não é régua derivando: é a nota 08 — quando a estratégia de
   sinalização virou traço, mudos e blefadores entraram na população, e um
   mostrador que mede "antecipar o outro **pelo sinal dele**" lê menos num
   mundo onde ~24% não sinaliza honestamente. As seeds 7/42 (0,29–0,30) eram,
   de novo, sorteios altos.

## Ameaças à validade

- **3000 ticks.** Os fenômenos de janela longa não foram replicados aqui — nem
  os 30 000 ticks do traço congelado (nota 05, fases 2/3), nem o `hon_f`
  ~0,85–0,90 da nota 08 S6 (também 30 000; ver §5). Este lote replica o que as
  notas mediram em 3000. Um lote de janela longa é 10× este custo.
- **Seeds 1..50** — aritméticas, não sorteadas; escolhidas antes de rodar e
  declaradas no script. As três canônicas (7, 42) estão contidas; 1234 não.
- **Janelas fixas** (início 20–300, fim 2700–3000), as mesmas da nota 09 — não
  foram variadas.
- A gêmea em `double` da `agencia` mede **sensibilidade à precisão**, não erro:
  fora do eremita não há verdade algébrica, e o `double` é referência, não
  gabarito.

## O que ficou em aberto

1. **Torneio de invasão 12×12** e a dose-resposta `h*(c)` — a dívida do Paper 2,
   intocada por este lote.
2. **Varredura de densidade** (a razão de ~4,8× do eremita é piso ou curva?) —
   agora com a barra: 4,78 ± 0,67.
3. **A edição honesta da partilha** (muda a simulação; pré-registro §5.0).
