# Nota 02 — O teto de nascimentos, a senioridade que ninguém escreveu, e o traço que não era identificável

**Data:** 2026-07-10
**Bug presente:** até o commit `45deba4`. **Corrigido em:** `0487269`.
**Serve ao:** Paper 2 (cognição como bem posicional) — e às erratas do Paper 1.

**Reproduzir o A/B:**

```sh
git show 45deba4:main.c > /tmp/main_bugado.c
gcc -std=c11 -O2 -o /tmp/antes /tmp/main_bugado.c
gcc -std=c11 -O2 -o /tmp/depois main.c
for s in 7 42 1234; do /tmp/antes $s 30000 0 --log /tmp/A_$s.csv; /tmp/depois $s 30000 0 --log /tmp/D_$s.csv; done
# compare a coluna energia_media no tick 29999: ~980 (antes) contra ~6 (depois)
```

---

## Resumo

`reproduzir()` nunca reaproveitava o slot de um bloco morto. Como `MAX_AG = 1408`
é um bloco por célula, existia um teto de **~1348 nascimentos na vida inteira de
uma simulação**: por volta do tick 10 000 a reprodução parava para sempre, a
evolução congelava, e `energia_media` divergia até ~1000. Corridas longas eram
**silenciosamente ininterpretáveis**. Consertar isso revelou duas coisas que o bug
escondia: uma **regra de senioridade** implícita no desempate de disputas, e o fato
de que `hor_m` — a média do horizonte de planejamento, a estatística que o projeto
vinha usando para falar de "aprender a planejar mais longe" — **não é
identificável sozinha**.

## 1. O bug

```c
int j = n_blocos++;                  /* novo slot */
...
if (n_blocos >= MAX_AG) break;       /* e um dia isso para de vez */
```

`n_blocos` só cresce; mortos deixam buracos que ninguém reusa. Instrumentando o
binário antigo para gritar quando `n_blocos` toca `MAX_AG`:

| seed | 7 | 42 | 1234 |
|---|---|---|---|
| slots esgotados no tick | 11 647 | 9 473 | 9 487 |

Depois disso: sem cria, sem mutação, sem seleção. E como `REPRO` é o único
sorvedouro de energia (o bloco se divide e a energia se parte ao meio), a energia
passa a se acumular sem limite.

| tick | 2 000 | 10 000 | 20 000 | 29 999 |
|---|---|---|---|---|
| `energia_media` **antes** | 6,68 | 6,22 | **361,12** | **985,76** |
| `energia_media` **depois** | 6,14 | 6,08 | 6,11 | **6,29** |
| `pop` antes | 316 | 312 | 265 | 259 |
| `pop` depois | 311 | 317 | 318 | 310 |

*(seed 7. As outras duas seeds: energia final 976,0 e 779,3 antes; 6,10 e 5,78
depois.)*

O conserto é `alocar_slot()`: reaproveita o buraco de **menor índice**, e só
estende `n_blocos` quando não há buraco. Varredura linear, determinística, barata
(a população vive em ~300 slots, não em 1408).

## 2. O preço: uma regra de senioridade que ninguém escreveu

`resolver()` concede a célula disputada ao pretendente de **menor índice** — o
`CLAUDE.md` chama isso de "simplicidade proposital". Mas no código antigo o índice
**era a ordem de nascimento** (`j = n_blocos++`, monotônico). Logo:

> A célula disputada ia sempre para o bloco **mais velho**. Havia uma regra de
> senioridade na física deste mundo, e ela não estava escrita em lugar nenhum.

Não é inócua: dava vantagem sistemática a quem já havia sobrevivido — exatamente
a população cujos traços a seleção estava avaliando. Reaproveitar slots destrói a
regra (uma cria pode herdar um índice baixo e ganhar de um ancião). Trocamos um
desempate arbitrário por outro, e **nenhum dos dois é principiado**. Um desempate
*escolhido* — por energia, ou por um hash determinístico de `(x, y, tick)` — é uma
decisão de física ainda em aberto.

Consequência metodológica: as trajetórias antes/depois divergem já no primeiro
reuso de slot. O A/B não compara "a mesma corrida com e sem o teto"; compara duas
físicas. O que se compara com segurança são **regimes** (energia estável × energia
divergente) e **conclusões** (abaixo).

## 3. O que o bug contaminou

**Contaminou todas as comparações de população**, porque uma ablação que faz os
blocos se amontoarem (solipsista, `horizonte = 1`) os faz nascer mais, e portanto
esgotar os slots antes. As quedas de 25–35% que a nota 01 reportava evaporaram:

| condição | pop (com bug) | pop (corrigido) |
|---|---|---|
| controle | 307 | 312 |
| `horizonte = 1` | 245 (−25%) | 321 (≈0) |
| solipsista | 199 (−35%) | 314 (−2,4% na média) |

**Não contaminou os mostradores.** `modelo` controle: 0,638 → 0,636. `agencia` e
`automodelo` do solipsista: zero exato, antes e depois. `prever_valor ≡ 0` continua
extinguindo a população e continua lendo `modelo = 0,000`. As conclusões da nota 01
sobre a **bateria** sobrevivem inteiras; as sobre **aptidão** foram reescritas.

**Não contaminou a Fase 3 do roadmap.** A paisagem adaptativa e o ensaio de invasão
rodavam em 3000–4000 ticks, bem antes do esgotamento. Revalidados com o `main.c`
consertado, ambos **melhoram**:

- a paisagem de grupo, que tinha um falso pico em `h = 2` e um vale artificial em
  `h = 1` (blocos míopes esgotavam slots primeiro), agora cai **monotonicamente**
  de 295,9 (`h = 1`) a 289,3 (`h = 12`): quanto mais fundo a população pensa, menor
  ela é;
- a invasão de `h = 9` sobre `h = 3` fica mais rápida (0,91 / 0,87 / 0,85 no tick
  4000, contra 0,87 / 0,85 / 0,82).

A tese do bem posicional sai **mais forte**: o ótimo de grupo é o pensamento mais
raso possível, e ainda assim o planejador fundo invade.

## 4. O achado: `hor_m` não é identificável

Com 30 000 ticks agora evolutivamente válidos, `hor_m` termina em **11,04 / 4,88 /
3,40** (seeds 7 / 42 / 1234). Olhando só a seed 7, eu teria ressuscitado a hipótese
"o horizonte cresce até o teto" que havia declarado morta. Duas seeds a mataram de
novo.

A razão é que `horizonte` e `desconto` são **traços compensatórios**:
`corr(hor_m, desc_m)` = **−0,93 / −0,46 / −0,72**. Um bloco com horizonte 11 e
desconto 0,66 pesa o 11º passo em `0,66¹¹ ≈ 0,01`: ele **declara** um horizonte
fundo e **pensa raso**. A profundidade que importa é `min(horizonte, 1/(1−δ))`:

| seed | `hor_m` | `desc_m` | **profundidade efetiva** |
|---|---|---|---|
| 7 | 11,04 | 0,661 | **2,95** |
| 42 | 4,88 | 0,873 | **4,88** |
| 1234 | 3,40 | 0,898 | **3,40** |

`hor_m` bruto varia **3,2×** entre seeds; a profundidade efetiva varia **1,7×**.

E há uma validação independente do construto: `phi` — o proxy de integração —
correlaciona com o `hor_m` bruto com **sinal inconsistente** (−0,94 na seed 7,
+0,83 na 42, +0,97 na 1234), mas com a profundidade efetiva de forma consistente:
**+0,96 / +0,75 / +0,93**. A quantidade que a "luz acesa" acompanha é a efetiva.

**Consequência.** Qualquer afirmação do tipo "a evolução aprendeu a planejar mais
longe", baseada em `hor_m`, está mal formulada. O par `(horizonte, desconto)` tem
uma direção de quase-neutralidade, e a média marginal de um dos dois não diz nada.
Isto vale também para o **imposto pigouviano** proposto na Fase 3: cobrar `c` por
passo *declarado* deixa o bloco fugir do imposto baixando `desconto`. Cobrar pela
profundidade *efetiva* é mais honesto — e mais difícil.

## 5. Ameaças à validade

- **3 seeds.** De novo, e de novo quase me custou caro: a seed 7 sozinha teria
  "confirmado" H1. Uma seed não é um resultado. Duas quase não são.
- `HORIZONTE_MAX = 12` **censura** a seed 7 (`hor_m` = 11,04). Resultados perto do
  teto são suspeitos por construção.
- A profundidade efetiva `min(h, 1/(1−δ))` é uma **construção minha**, plausível e
  bem correlacionada com `phi`, não uma grandeza derivada da matemática de
  `prever_valor`. Merece uma derivação, ou uma refutação.

## 6. Em aberto

- Escolher um desempate principiado para `resolver()` — e medir o efeito de cada
  escolha. Hoje o vencedor de uma disputa depende de um número de slot.
- Torneio de invasão par-a-par com `desconto` **fixo**, para isolar o horizonte.
- Cobrar o custo de pensar pela profundidade efetiva, e ver se a compensação
  aparece como resposta correlacionada.
