# Nota 22 — A sonda ordinal: o plano erra o valor, mas acerta o rank

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/22-sonda-ordinal.sh`, commitado em
`19464c3` — **antes** de rodar (O0/O0b/O1..O4).
**Serve ao:** Paper 2 §8 — fecha a fronteira que a nota 18 deixou aberta ("a
sonda mede o plano como previsão, não como *ranking* entre células
candidatas"). Agregados em `datasets/sonda-ordinal.csv`.
**Reproduzir:** `sh papers/notes/22-sonda-ordinal.sh` (~8 min seriais, poucos
minutos com `NPROC=16`)

---

## Resumo

A nota 18 mediu o plano (`prever_valor`) como **previsão** e o viu falhar cedo:
`corr(ĝ_k, r_k)` cai de 0,60–0,73 em `k = 0` para ≤ 0,19 já em `k = 1` —
`k* = 0` em toda condição povoada. Mas a decisão (`melhor_celula`) nunca usa o
valor absoluto — ela faz um `argmax` entre até 9 células candidatas (ficar +
vizinhos vazios). A pergunta que sobrou: o plano pode errar o **valor** e ainda
assim acertar a **ordem**? Isso explicaria o pico de colheita `h = 2 > h = 1`
da nota 17 — o termo `ĝ_1` muda o rank mesmo errando o número.

A sonda enumera, a cada decisão, os candidatos alcançáveis (mesma ordem/regra
de `melhor_celula`) e guarda dois valores previstos por candidato: `u` (a
decisão completa, com o ajuste de antecipar do nível 5) e `m` (só o mapa,
`prever_valor`). `h` ticks depois, acumula quanto foi **realmente** extraído de
cada célula candidata **por quem quer que seja** — um fato observável na única
trajetória, não um contrafactual (as outras ≤ 8 opções nunca serão visitadas
por este bloco; o que sobrevive é "quanto essa célula valeu", não "quanto EU
teria comido"). Concordância = fração de pares discordantes entre os dois
ranks, o mesmo Kendall que `phi_proxy` já usa (nota 05) — nunca precisa de
`sqrt`.

**O plano ordena muito melhor do que prevê.** Discordância de 0,17–0,20 (acaso
= 0,5) em toda condição povoada; o argmax do mapa bate 3,8–4,5× mais que o
acaso; a discordância quase não piora de `h = 4` a `h = 12` (a curva que a
nota 18 viu desabar em `k = 1`); e a decisão completa rastreia o realizado
melhor quando o bloco está **faminto** — o termo de espaço recua exatamente
quando deveria, por desenho.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **O0a** | sonda não muda a simulação: CSV bit a bit == vanilla | ✅ |
| **O0b** | reconstrução exata: argmax(u) recomputado == alvo real, 100% | ✅ 74 048 980/74 048 980 (100,000000%) |
| **O1** | discordância rank(m)×rank(real) < 0,25 em toda condição povoada | ✅ 0,082–0,203 (todas abaixo) |
| **O2** | P(argmax(m)==argmax(real) \| houve garfada) > 3× o acaso | ✅ 3,79×–5,75× |
| **O3** | discordância não cresce muito de `h=4` a `h=12` (\|Δ\| < 0,05) | ✅ \|Δ\| ≤ 0,015 nos 3 δ; em 0,90/0,95 até melhora |
| **O4** | discordância de `u` menor com fome ≥ 0,5 que com fome < 0,5 | ✅ 8/8 seeds, todo `t` > 1,9; ere (controle) inverte, `t = −29,5` |

## 1. O ranking sobrevive onde o valor já tinha morrido (O1/O2)

| condição | discordância (rank m × rank real) | argmax bate × acaso |
|---|---|---|
| ere | 0,082 ± 0,002 | 5,75× |
| livre | 0,165 ± 0,003 | 4,46× |
| uni δ=0,80, h=4/8/12 | 0,165 / 0,178 / 0,181 | 4,31× / 4,22× / 4,25× |
| uni δ=0,90, h=4/8/12 | 0,181 / 0,184 / 0,181 | 4,06× / 4,03× / 4,09× |
| uni δ=0,95, h=4/8/12 | 0,201 / 0,203 / 0,196 | 3,79× / 3,86× / 3,88× |

Toda condição fica bem abaixo do acaso (0,5) e bem acima da razão-1× do acaso
no argmax. A nota 18 já havia mostrado que o **valor** absoluto do plano
(`ĝ_k`) não presta para prever `k ≥ 1`; esta tabela mostra que o **rank**
entre as opções continua informativo mesmo ali. É a resposta ao que ficou em
aberto no §8 do Paper 2: o plano não precisa prever para ajudar a escolher —
precisa só ordenar certo.

## 2. A dose-resposta com `h` — o porquê do pico de colheita (O3)

| δ | disc(h=4) | disc(h=8) | disc(h=12) | Δ(h12−h4) pareado | `t` |
|---|---|---|---|---|---|
| 0,80 | 0,166 | 0,179 | 0,181 | +0,0154 ± 0,0020 | +7,71 |
| 0,90 | 0,182 | 0,184 | 0,181 | −0,0004 ± 0,0023 | −0,17 |
| 0,95 | 0,202 | 0,203 | 0,196 | −0,0049 ± 0,0025 | −2,01 |

Em δ=0,80 há um crescimento pequeno mas mensurável (`t=+7,71`) — ainda assim
`Δ = 0,015`, um terço do limiar pré-registrado (0,05). Em δ=0,90/0,95 a
discordância não cresce — no maior desconto, até **cai** de leve com `h`
maior. Contraste com a nota 18: `corr(g_k,r_k)` desaba de ~0,65 para ≤ 0,19
entre `k=0` e `k=1` — uma queda de mais de 70% num único passo. A discordância
ordinal aqui varia no máximo 8% (relativo) entre `h=4` e `h=12`. **O rank não
degrada como o valor degrada** — é o candidato a mecanismo, medido, para o
pico de colheita `h=2` que a nota 17 encontrou sem explicação: o segundo passo
do plano (`ĝ_1`) já erra como previsão, mas ainda ordena as opções bem o
bastante para valer a pena escutá-lo.

## 3. O espaço recua quando deveria — e o controle algébrico confirma (O4)

| condição | disc(faminto) | disc(saciado) | Δ pareado (saciado−faminto) | `t` |
|---|---|---|---|---|
| livre | 0,292 | 0,365 | +0,0746 ± 0,0040 | +18,67 |
| uni δ=0,80, h=4/8/12 | 0,280/0,321/0,333 | 0,383/0,387/0,388 | +0,110/+0,067/+0,055 | +28,7/+22,7/+19,6 |
| uni δ=0,90, h=4/8/12 | 0,298/0,362/0,382 | 0,391/0,387/0,399 | +0,097/+0,025/+0,017 | +24,3/+19,4/+10,6 |
| uni δ=0,95, h=4/8/12 | 0,314/0,390/0,401 | 0,394/0,401/0,406 | +0,083/+0,010/+0,004 | +20,6/+5,8/+2,0 |
| **ere (controle)** | 0,099 | 0,072 | **−0,0272 ± 0,0009** | **−29,5** |

Em toda condição populada, a decisão completa (`u`, que mistura comida prevista
e busca por espaço aberto) rastreia o alimento real **melhor** quando o bloco
está com fome — exatamente onde a comida deveria pesar mais na escolha. Isto
não é "a decisão ficando pior em rastrear comida quando saciada": é o termo de
espaço fazendo o que foi desenhado para fazer.

O controle é algébrico, não estatístico: no `ere` (ablação que zera
`rivais_em`/`pretendentes_em`), `espaço = (8 − rivais_em(...))/8` vale **1,0
para toda célula candidata** — uma constante. Como `u[k] = m[k]·(1 +
urgência·fome) + peso_espaço·espaço·(1−fome)`, e o segundo termo é o MESMO
para todo `k` quando `espaço` é constante, `u` é uma transformação afim de `m`
com inclinação positiva `(1+urgência·fome) > 0` — que preserva rank
**exatamente**, para qualquer fome. Logo `rank(u) ≡ rank(m)` no `ere`, ponto
por ponto, e a comparação faminto×saciado ali não testa o mesmo mecanismo. A
predição não era "nula" — era **invertida por construção**, e saiu invertida:
`t = −29,5`, o maior `|t|` de toda a tabela.

## 4. Ressalvas honestas

- **"Quem quer que seja" não é "este bloco".** O realizado mede o que qualquer
  agente extraiu da célula candidata, não o que o bloco que decidiu teria
  comido lá. É a única grandeza observável sem ramificar a simulação (violaria
  o determinismo — ver ROADMAP "Engenharia"), e é exatamente a que um
  planejador que compara opções deveria tentar acertar: "essa célula tende a
  valer mais", não "eu, especificamente, vou comer X".
- **`n` médio de candidatos é 6,1–6,6, não 9.** Células ocupadas no início do
  tick saem do conjunto (mesma regra de `melhor_celula`); o "acaso" (1/n) usado
  no O2 já é o baseline correto para o `n` real de cada condição, não um 1/9
  fixo.
- **O `ere` não é um eremita solitário.** É a população evoluída inteira sob
  uma ablação perceptiva (cada bloco cego a rivais) — não um mundo de um bloco
  só. Isso é o que torna o "realizado" não-degenerado ali (há gente comendo
  em toda célula o tempo todo) e é também a premissa do controle algébrico do
  O4.
- **δ=0,80 tem um O3 significativo, ainda que pequeno.** `t=+7,71` não é ruído
  — mas `Δ=0,015` é um terço do limiar pré-registrado. Reportado, não
  escondido: a dose-resposta com `h` existe, só que é fraca onde a nota 16/19
  já haviam mostrado que a profundidade extra é "inofensiva" (δ baixo).
- **A árvore de decisão é local (3×3), a pontuação não é micro-causal.**
  `comido[][]` soma tudo que qualquer bloco extraiu da célula, incluindo
  disputas resolvidas por `resolver()` no meio do caminho — o "realizado" já
  incorpora a competição social, não é o mundo físico isolado.
- **3000 ticks, burn-in 500** — mesmo desenho da nota 18, para comparação
  direta. `ere`/`uni`/`livre` com 8 seeds cada (88 corridas no total).

## 5. Método

- **Enumeração idêntica a `melhor_celula(antecipar=1)`:** self (`ficar
  parado`) + vizinhos vazios, mesma ordem `dy,dx`, mesmo ajuste
  `u /= 1 + ANTECIPACAO·pret`. A prova de que a réplica é fiel é o próprio O0b
  (100,000000% de reconstrução em 74 milhões de decisões).
- **`comido[y][x]`:** acumulador novo, zerado no início de cada tick, somado no
  mesmo ponto do laço de `aplicar_e_comer` onde `comida[y][x] -= garfada`
  acontece — leitura pura, não altera `comida[][]` nem estado de bloco algum
  (O0a confirma: CSV `--log` bit a bit idêntico ao vanilla).
- **Concordância = fração de pares discordantes** (Kendall), o mesmo critério
  de `phi_proxy` (nota 05): `dm·dr < 0` conta como discordante; empates não
  contam nem a favor nem contra. Nunca precisa de `sqrt` — soma em `double`,
  agregável entre seeds sem recomputar por decisão.
- **Morte censura todos os planos pendentes do bloco** (mesma regra da nota
  18) — evita que um slot reciclado por uma cria herde um plano do morto.
- **Dataset** `sonda-ordinal.csv`: uma linha por variante × δ × h × seed, já
  resumida (`n_check,ok_check,disc_m,tot_m,hit,hit_tot,sum_n_hit,disc_u_fam,
  tot_u_fam,disc_u_sac,tot_u_sac,n_dec,sum_n_dec`) — sem despejo por decisão.
