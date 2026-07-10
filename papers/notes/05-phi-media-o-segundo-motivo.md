# Nota 05 — `phi` não media integração: media o segundo motivo

**Data:** 2026-07-10
**Mostrador `phi` antigo:** até o commit `f09aa45`. **Consertado em:** `e151c45`.
**Serve ao:** Paper 1 (metrologia da mente) — e à `FILOSOFIA_v3.md` §2 (a costura da escada).
**Reproduzir:** `sh papers/notes/05-phi.sh` (phi nova) e, para a evidência da velha,
`git show f09aa45:main.c > /tmp/m.c && sh papers/notes/05-phi.sh /tmp/m.c` (~5–8 min cada).

---

## Resumo

A suspeita do ROADMAP §1.4 — `phi` seria um *sinônimo de profundidade efetiva de
planejamento* — estava **errada**, e é a **segunda vez** que a regra 4 do protocolo
("antes de acusar a régua, congele o traço") mata uma suspeita minha. A correlação
`+0,94/+0,70/+0,90` com a profundidade só existe na janela de 30 000 ticks; nos
primeiros 3 000 dos *mesmos dados* ela é fraca e negativa (`−0,31/−0,13/−0,42`).
Era **co-tendência** — duas séries que afundam juntas sob a mesma evolução — não
acoplamento. O teste do traço congelado dissocia: **congelar a profundidade não
segura a `phi`** (desaba igual ao controle); **congelar `peso_espaco` a segura**.

Quem carrega a `phi` é o mesmo traço que carrega a `agencia` (nota 03). E o defeito
real da `phi` velha era outro, pior que o suspeitado: ela era **infalseável** —
nenhuma ablação a zerava. A redefinição lhe dá a condição de falseamento que
faltava, e o que a régua nova mostra é o achado da nota 03 um andar acima: **a
evolução extingue a integração.**

## 1. O artefato da janela

`corr(phi, min(horizonte, 1/(1−desconto)))`, *phi velha*, nos mesmos controles:

| janela | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| 30 000 ticks | **+0,941** | **+0,704** | **+0,903** |
| 3 000 ticks | −0,312 | −0,131 | −0,421 |

Uma correlação que muda de sinal com a janela não é estrutura da régua; é o rastro
de duas séries não-estacionárias descendo a mesma ladeira evolutiva. (Contra o
`hor_m` bruto o sinal ainda **troca entre seeds** — `−0,93/+0,80/+0,96` — o
sintoma já conhecido de que `hor_m` sozinho não é identificável.)

## 2. O traço congelado dissocia

*Phi velha*, 30 000 ticks, início → fim:

| condição | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| controle | 0,333 → 0,140 | 0,326 → 0,121 | 0,297 → 0,114 |
| **congela `peso_espaco`** | 0,342 → **0,287** | 0,312 → **0,278** | 0,318 → **0,287** |
| congela profundidade | 0,335 → 0,155 | 0,329 → 0,130 | 0,305 → 0,141 |

Se `phi` fosse profundidade com outro nome, a terceira linha ficaria plana. Não
fica — desaba como o controle. A segunda linha fica de pé. O veredito é o mesmo da
nota 03, para o mesmo traço: `peso_espaco` é o único canal pelo qual um segundo
motivo entra na decisão, e `phi` media, sobretudo, **a presença do segundo motivo**.
As correlações fecham o caso: `corr(phi, esp_m) = +0,97` nas três seeds (uniforme;
a de profundidade varia), e `corr(phi, agencia) = +0,96/+0,97/+0,96`.

## 3. A `phi` velha era infalseável

A velha media a distância de Kendall da ordem integrada a **uma** referência — a
comida do instante — vezes um `10.0f` para o número "parecer" morar em `[0,1]`.
Tabela de ablações (média de 3 seeds, 3000 ticks, `01-ablacoes.sh` @ `d211569`):

| condição | `phi` velha | comentário |
|---|---|---|
| controle | 0,255 | |
| `horizonte = 1` | 0,263 | **sobe** com a lobotomia do plano |
| `prever_valor ≡ 0` | **0,131** | sem modelo nenhum, morrendo — e "integra" 0,13 |
| solipsista | 0,039 | a queda de 85% do §1.5 |
| `COMPETICAO = 0` | 0,192 | |

Nenhuma ablação a zera. Pela regra 2 do protocolo (*que ablação tem de derrubá-lo a
zero? se nenhuma, ele não mede nada*), a `phi` velha **não media nada** — no
sentido estrito de que nenhuma leitura dela podia obrigar a retirar a palavra.
E o motivo é estrutural: "discordar da ordem da comida" não é irredutibilidade.
Uma decisão 100% explicada pelo espaço discorda muito da comida — e é redutível a
**um** módulo. A régua chamava de "integração" qualquer coisa que não fosse o
reflexo alimentar.

## 4. A redefinição: irredutibilidade levada a sério

A caricatura IIT agora pergunta o que a intuição de integração pede: **o todo é
redutível a alguma parte?** Sobre as jogadas alcançáveis, compara-se a ordem
integrada (`utilidade`) com a ordem de **cada módulo isolado** — comida-agora
(nível 2), espaço (nível 4), mapa/`prever_valor` (nível 3) — e `phi` é a **menor**
das distâncias de Kendall, já em `[0,1]`, sem fator de escala:

```
phi = min( d(u, comida), d(u, espaco), d(u, mapa) )
```

Se um módulo sozinho reproduz a decisão, `phi = 0`: integrar uma coisa só não é
integrar. A estatística (fração de pares discordantes) é a mesma da velha, de
propósito (regra 5) — mudou a **referência**, de uma para o mínimo sobre três.

Três zeros **demonstráveis antes de rodar**, todos verificados exatos (média *e*
máximo, 3 seeds, 3000 ticks):

- **eremita**: `espaco` fica constante entre as células → `d(u, espaco) = 0`;
- **`peso_espaco ≡ 0`**: `utilidade = comida_prev·(1+urg·fome)` = escalar positivo
  × mapa → `d(u, mapa) = 0`;
- **`prever_valor ≡ 0`**: só resta o termo do espaço → `d(u, espaco) = 0`.

Medido: **0,0000 / 0,0000 / 0,0000** nas três ablações, nas três seeds. A
simulação sai **bit-a-bit idêntica** (colunas 1–16, 3 seeds; regra 3) — a `phi`
não toca o mundo, só o relê. E a régua não é degenerada: controle ≈ **0,065**.

## 5. O que a régua nova diz: a evolução extingue a integração

*Phi nova*, 30 000 ticks, início → fim:

| condição | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| controle | 0,044 → **0,005** | 0,042 → **0,008** | 0,044 → **0,005** |
| congela `peso_espaco` | 0,048 → 0,054 | 0,043 → 0,071 | 0,045 → 0,061 |

No controle, `esp_m` desaba para ~0,08 e a `phi` morre junto — a decisão vira
redutível ao módulo do mapa, e a régua, agora honesta, diz isso. Com o traço
congelado, a integração fica de pé (e até sobe). É a nota 03 no andar de cima:
a seleção não extingue só a agência; extingue **a irredutibilidade da decisão** —
neste mundo, integrar motivos é um luxo que não paga a própria conta.

Para a `FILOSOFIA_v3` §2: mais um mostrador "mental" alto que se revela, na
implementação, **social e conflitual** (o segundo motivo só pesa porque há
vizinhos: o eremita zera). E mais um degrau que a evolução desfaz.

## Ameaças à validade

- **A phi nova é mais exigente por construção** (mínimo sobre três referências), e
  seu valor absoluto (~0,065) não é comparável ao da velha (~0,25). O manifesto dos
  datasets avisa.
- **Módulos escolhidos à mão.** "Irredutível a {comida, espaço, mapa}" depende da
  decomposição; outra partição daria outra `phi`. É fiel ao espírito IIT (mínimo
  sobre partições), mas a nossa é uma amostra de três, não o ínfimo verdadeiro.
- **A fome não é um módulo separado**: ela entra como peso dos módulos, não como
  ordem própria. Uma decisão movida só pela fome apareceria como redutível — é o
  comportamento desejado (fome pura = reflexo modulado), mas é uma escolha.
- **3 seeds**, como sempre. Os zeros são demonstráveis (não dependem de seed); as
  trajetórias evolutivas, não.

## O que ficou em aberto

1. **A Fase 1 fecha com esta nota.** Os quatro mostradores têm agora mecanismo,
   ablação-zero declarada e conserto — o Paper 1 tem seus quatro modos de errar.
2. `phi` e `agencia` continuam **correlacionadas por mecanismo** (o mesmo traço
   carrega as duas). Não é defeito: são perguntas diferentes ("muda com o estado
   interno?" × "é redutível a um módulo?") que este mundo, com um só segundo
   motivo, responde junto. Um mundo com **terceiro motivo** (Fase 4) as separaria
   — e é um teste barato de que as réguas são mesmo distintas.
3. O `relato` (Fase 2) herda a lição: nasce com a condição de falseamento
   declarada **antes** (Apêndice A da v3, última linha).
