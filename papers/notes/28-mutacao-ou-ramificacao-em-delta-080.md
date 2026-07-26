# Nota 28 — Carga de mutação ou ramificação real em δ=0,80? A resposta é mista

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/28-mutacao-ou-ramificacao-em-delta-080.sh`,
commitado em `58aeaf9` — a predição original ("é tudo carga de mutação") foi
derrubada por um piloto de 4 seeds **antes** deste commit; a predição escrita
já reflete a direção mista que o piloto achou.
**Serve ao:** corrige o veredito da nota 26 para δ=0,80 (que votava, sem
isolar, "carga de mutação"). Agregados em `datasets/mutacao-off.csv`,
comparados com `datasets/bimodalidade.csv` (nota 23, já commitado).
**Reproduzir:** `sh papers/notes/28-mutacao-ou-ramificacao-em-delta-080.sh`
(~2 min com `NPROC=16`)

---

## Resumo

A nota 26 generalizou a bimodalidade da nota 23 com um algoritmo que
descobre o vale sozinho, e votou "carga de mutação" para o resultado
ambíguo de δ=0,80 (0/8 bimodais pelo critério genérico, contra 4/8 pela
partição fixa da nota 23) — mas registrou, como ressalva, que decidir de
verdade exigia isolar o mecanismo: desligar a mutação de horizonte e ver se
o "lado baixo" da distribuição sobrevive sem novos mutantes alimentando-o.
Esta nota constrói esse isolamento.

**A resposta não é a que a nota 26 votou, nem o oposto dela — é mista.**
Das 8 seeds, **6 colapsam** para quase-monomorfismo no teto quando a
mutação desliga (massa do lado baixo cai a 0,1%–3,3%) — carga de mutação
confirmada nelas. Mas **2 fazem o oposto do previsto**: sem nenhum mutante
novo, a massa do lado baixo **cresce** (de ~0,39 para 0,58; de ~0,27 para
0,51) e o vale fica **mais limpo**, não mais raso — evidência de um
polimorfismo genuíno, independente de reposição de mutantes.

| # | predição (escrita antes, já revisada pelo piloto) | resultado |
|---|---|---|
| **G0** | com mutação ligada, reproduz exatamente o histograma da nota 23 | ✅ 12/12 bins idênticos |
| **G1** | entre 2 e 5 de 8 seeds continuam bimodais sem mutação (nem 0/8, nem 8/8) | ✅ **2/8** (seeds 3, 5) — no limite inferior da faixa prevista |
| **G2** | nas que colapsam, massa baixa cai a < 5% | ✅ as 6 restantes: 0,14% a 3,24% |
| **G3** | nas que sustentam, o vale fica tão ou mais limpo (prof ≤ 0,15–0,30) | ✅ prof = 0,2364 e **0,0000** (vale com população zero) |

## 1. Seis seeds: a mutação estava mesmo carregando a cauda

| seed | massa baixa, mutação ligada (nota 23) | massa baixa, mutação desligada |
|---|---|---|
| 1 | 0,0681 | **0,0152** |
| 2 | 0,1416 | **0,0324** |
| 4 | 0,1293 | **0,0014** |
| 6 | 0,2052 | **0,0174** |
| 7 | 0,0843 | **0,0265** |
| 8 | 0,2739 | **0,0226** |

Sem novos mutantes reintroduzindo horizontes baixos, a seleção varre a
população para perto do teto `h=12` em toda essa metade — inclusive a seed 8,
que com mutação tinha 27% da massa no lado baixo, cai a 2,3%. É exatamente o
que "carga de mutação" prevê: um equilíbrio móvel, mantido só pela chegada
constante de variantes deletérias, que desaparece assim que a fonte é
cortada.

## 2. Duas seeds: o oposto do previsto

| seed | massa baixa, mutação ligada | massa baixa, mutação desligada | profundidade do vale |
|---|---|---|---|
| 3 | 0,3885 | **0,5811** | 0,2364 |
| 5 | 0,2656 | **0,5099** | **0,0000** |

Nestas duas, cortar a fonte de mutantes não drenou o lado baixo — **encheu**
ele. A leitura mais simples: a seleção nessas duas populações não estava
"tolerando" um resíduo de baixa frequência por causa da mutação — estava
mantendo dois tipos em proporções que a mutação, quando ligada, na verdade
**perturbava** (introduzindo ruído de tipos intermediários que a seleção
frequência-dependente ainda não tinha limpado). Desligada a mutação, o
sistema decanta para o que parece ser um **equilíbrio bistável de verdade**:
seed 5 chega a um vale de massa **zero** em `h=11` — nenhum indivíduo, em
20 leituras ao longo de 5000 ticks, jamais passou por ali — a assinatura de
manual de dois bacias de atração separadas, não um gradiente contínuo.

## 3. A leitura que isso sustenta: δ=0,80 é uma zona de fronteira, não um veredito

As notas 19/20 já situavam δ=0,80 abaixo de onde o ótimo interior "sai do
teto" (entre δ=0,88 e 0,90, nota 19) — um regime de transição, não o centro
claro nem do platô nem da ramificação. O resultado desta nota dá a essa
fronteira um rosto quantitativo: **2 de 8 realizações (25%) caem na bacia da
coexistência; 6 de 8 (75%) caem na bacia do teto puro.** Não é uma médida
única "δ=0,80 tem X% de bimodalidade" — é uma **moeda historicamente
carregada**: qual bacia uma população específica visita depende de sua
trajetória inicial (quais tipos dominaram cedo, antes de a seleção
frequência-dependente decidir o resto), não só do parâmetro δ. A nota 26
tinha razão em duvidar que o resultado da nota 23 fosse ramificação limpa
**em toda seed** — mas errou ao votar que era **só** carga de mutação: o
fenômeno de verdade é mais raro (1 em 4, não a maioria) e mais real (o vale
aprofunda, não se mantém raso) do que qualquer uma das duas leituras
sozinha previa.

## 4. Ressalvas honestas

- **2/8 é uma fração pequena — e o desenho não explica por quê essas duas.**
  Não foi feita uma varredura de traços iniciais ou de trajetória early-tick
  que distinga as seeds 3/5 das outras 6; a hipótese de "bacias de atração
  historicamente carregadas" é a leitura mais simples dos números, não uma
  demonstração de mecanismo.
- **Mutação DESLIGADA DESDE O TICK 0** — não uma remoção tardia (ao
  contrário do choque das notas 24/27, que ligam/desligam no meio de uma
  corrida já assentada). A variação inicial (semeadura uniforme 1..12) é
  tudo que a seleção teve para trabalhar; um desenho que desligasse a
  mutação só depois de a população já ter "escolhido" um regime poderia dar
  números diferentes.
- **Só δ=0,80.** Não se testou se a mesma fração (2/8) ou o mesmo padrão
  qualitativo (poucas seeds bistáveis, maioria colapsando) aparece nos
  outros δ da grade das notas 19/20 sob mutação desligada — pode ser
  específico da fronteira de δ=0,80, ou pode ser um fenômeno mais geral.
- **`prof=0,0000` é exato porque a amostragem é de 20 leituras espaçadas.**
  Não significa necessariamente zero absoluto de trânsito por `h=11` ao
  longo dos 30000 ticks — significa que nenhuma das 20 janelas amostradas
  capturou alguém ali. Um vale genuinamente raro, mas não impossivelmente
  estreito, poderia produzir a mesma leitura.

## 5. Método

- **Reaproveita o fundo `uni_h_livre`** das notas 20/23/26 (desconto,
  urgência, peso_espaço, estratégia pregados) e o histograma + classificador
  genérico da nota 26 (vale descoberto por máximo corrido de cada lado).
- **`MUT_HORIZ`** (novo): comuta `cria->horizonte` entre
  `muta_horizonte(pai->horizonte)` (ligada, idêntico às notas 23/26) e
  `pai->horizonte` sem mutação nenhuma (desligada) — um único `rng01()`
  consumido em ambos os ramos, para manter o consumo de RNG comparável
  (embora `muta_horizonte` em si consuma 1 ou 2 chamadas dependendo do
  sorteio, então os dois modos **não** são bit-a-bit comparáveis entre si —
  não precisam ser, já que são trajetórias independentes, não um par).
- **G0 como âncora**: com `MUT_HORIZ=1`, reproduz o histograma exato que a
  nota 23 já tinha publicado para `(δ=0,80, seed 1)` — 12 bins idênticos,
  confirmando que a generalização do patch não mudou o comportamento no
  caso já medido.
- **Custo**: só a condição nova (mutação desligada) foi rodada — a de
  mutação ligada já está em `datasets/bimodalidade.csv` (nota 23),
  reaproveitada por join em Python, por seed.
- **Dataset** `mutacao-off.csv`: uma linha por seed —
  `seed,h1,...,h12,bimodal,h_vale,prof,massa_esq,massa_dir`.
