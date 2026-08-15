# Nota 38 — O painel da régua pareada: 30/30 fora da amostra, e o nulo do classificador binário que não fica quieto

**Data:** 2026-08-15
**Pré-registro:** `ROADMAP.md` §4.11, commit `fceb6ca` — antes de rodar.
**Construído em:** `87584b3` (script commitado antes de rodar).
**Serve ao:** item 1 do "o que ficou em aberto" da nota 37 — repetir o fio com a
régua pareada **pré-registrada como primária**, fora da amostra, e com a potência
calculável pela primeira vez (agora existem um nulo medido e um tamanho de efeito).
Nenhum mecanismo novo entra no `main.c`: os binários são os mesmos das notas
33/34/35/37; o que muda são as seeds, o estatuto da régua e o tamanho da corrida.
**Reproduzir:** `sh papers/notes/38-painel-da-regua-pareada.sh` (~45 min de relógio
com `JOBS=12`; 5 h 43 de CPU: 120 corridas de 30 000 ticks, mais regressão e a
corrida solitária de conferência)

---

## Resumo

**A primária confirma com o placar máximo possível.** Em 30 seeds que nenhuma nota
deste projeto tinha rodado (101–130), a diferença pareada `d̄_2000` é negativa em
**30/30** (`p = 1,9·10⁻⁹`), mediana **−0,202**, contra um corte pré-registrado de
≥ 21/30 e uma potência declarada antes da máquina (0,99998 sob o efeito medido pela
nota 37; 0,947 sob o limite inferior dele). O nulo, nas mesmas seeds, dá **16/30** e
mediana −0,021 — a involução escrita no §4.11 *antes* de rodar previa simetria em
torno de zero, e a amostra entregou. Q5 deixa de depender de um achado lateral: a
resposta é **sim**, a seleção favorece `peso_arrependimento` negativo, e agora ela
está pré-registrada, é primária e é fora da amostra.

**A única falha do placar não é da régua nova — é do nulo da régua velha.** Eu
pré-registrei que o classificador binário produziria, no braço nulo, entre 4 e 15
REAL (o IC95 dos 9/30 publicados na nota 35). Deu **16/30**. O nulo do binário saiu
de 30% para **53%** entre duas amostras de 30 seeds, e duas réguas independentes
dizem por quê: **estas seeds decorrelacionaram mais** (`|d̄|` mediana 0,0403 → 0,0686;
`Δpop` 0,01503 → 0,01665, com T2 estável em 0,0147 → 0,0149). Os 30% da nota 35 não
são uma constante do desenho — são o nível de decorrelação **daquelas** 30 seeds.

**O que isso faz com a nota 35 é uma qualificação, não uma errata.** O contraste que
ela publicou (66,7% × 30%, Fisher `p = 0,0092`) vira, nas seeds novas, 80% × 53%
(`p = 0,0539`). Nenhum número dela muda; o que fica medido é **quanto peso o
contraste aguenta**, e a resposta é: menos do que parecia, porque metade dele é uma
estimativa de nulo com ruído amostral grande. O que **não** depende do nulo continua
de pé e ficou mais forte: pelo teto algébrico do §4.10 (`P(REAL) > 50% ⟺ vantagem`),
o binário fresco dá 24/30 **acima** do teto (`p = 0,00072`; pooled 44/60,
`p = 2,0·10⁻⁴`), e a direção entre as corridas REAL é **24/24** para `−2,0`
(`p = 6,0·10⁻⁸`; pooled **44/44**, `p = 5,7·10⁻¹⁴`).

## 1. A regressão e o determinismo sob paralelismo

O `main.c` não muda desde `65e83f3`, anterior às notas 32–37, então os binários
compilados hoje têm de reproduzir bit a bit o publicado (regra 8: conferir a régua
antes de aceitar o que ela diz):

| braço | seed | A → `arrep_m` | B → `arrep_m` | classe | publicado |
|---|---|---|---|---|---|
| T2 | 11 | −2,000 | −2,000 | **REAL** `−2,0` | nota 34 (e idêntico à nota 37) |
| N2 | 2 | +2,000 | +1,955 | **REAL** `2,0` | nota 35 (e idêntico à nota 37) |

Este painel roda as corridas em **processos simultâneos**, o que é novo no projeto e
foi declarado no §4.11 porque encosta na invariante. Nada dentro do tick muda: cada
corrida segue um processo single-thread, `f(seed)`, com o próprio CSV; o paralelismo
está no shell. O script não pede fé — guarda o md5 dos 120 CSVs e repete uma corrida
(T2/101/A) **sozinha** no fim:

```
T2/101/A  no painel: e6f45521d5dc800fe45a0d7378151aea
T2/101/A  sozinha:   e6f45521d5dc800fe45a0d7378151aea
```

## 2. P1 (primária) — a direção, fora da amostra

| janela | mediana `d̄` | negativas | `p` bilateral |
|---|---|---|---|
| 500 | −0,0546 | 29/30 | 5,8·10⁻⁸ |
| **2000 (primária)** | **−0,2023** | **30/30** | **1,9·10⁻⁹** |
| 5000 | −0,3730 | 30/30 | 1,9·10⁻⁹ |

Companheiro pré-registrado (P5), Wilcoxon signed-rank contra zero por permutação de
sinais (10⁵ sorteios, semente 20260815): **nenhum** sorteio tão extremo quanto o
observado, `p < 10⁻⁵`. No nulo, o mesmo teste dá `p = 0,556`.

O corte era ≥ 21/30 e o placar é 30/30 — a régua não deixou uma seed para trás.
Somados os dois painéis independentes: **58/60** (`p = 1,6·10⁻¹⁵`).

Vale marcar o que este número **não** é: 30/30 é proporção de seeds, não tamanho de
efeito populacional, e a mediana de `d̄` é diferença de **composição** (16 a 20 pontos
percentuais entre as montagens), não aptidão.

## 3. P2 e P3 — a magnitude e o nulo

**P2 confirma:** mediana `−0,2023`, dentro da faixa pré-registrada `[−0,30; −0,05]`,
e um pouco **maior** que a da nota 37 (`−0,164`). O sinal replicou e a ordem de
grandeza também.

**P3 confirma:** o nulo dá 16/30 negativas (`p = 0,86`) e mediana `−0,0214`
(critério: 10..20 e `|mediana| < 0,05`). Isso era previsão, não torcida: o §4.11
mostrou, antes da máquina, que complementar o campo `sinal_nulo` é uma **involução**
que troca o sinal de `d` — um bloco de peso `w` no campo `s` se comporta como um de
peso `−w` no campo `−s`, e como A e B só diferem em qual paridade carrega qual valor,
`A(−s)` **é** `B(s)`. Como o ensemble de campos é simétrico sob complemento, a
distribuição de `d` é simétrica em torno de zero por construção. Duas amostras
independentes: 15/30 e 16/30, pooled **31/60** (`p = 0,90`).

## 4. P4 — as duas réguas nas mesmas corridas, e a única falha do placar

Rodar 30 000 ticks (em vez dos 5 000 da nota 37) custa o mesmo trabalho e entrega as
duas réguas **das mesmas corridas**: o CSV longo contém o prefixo de 2 000.

| | régua pareada (`d̄_2000`) | classificador binário (fixação) |
|---|---|---|
| **T2**, seeds novas | 30/30 negativas | 24/30 REAL, **24/24** para `−2,0` |
| **T2**, nota 37 | 28/30 negativas | 20/30 REAL, 20/20 para `−2,0` |
| **N2**, seeds novas | 16/30 negativas | 16/30 REAL, 10/16 para `−2,0` |
| **N2**, nota 35/37 | 15/30 negativas | 9/30 REAL, 3/9 para `−2,0` |

**(a) O binário de T2 alcança o próprio corte.** 24/30 ≥ 21/30. O §4.11 declarou
antes que isso era *provável que não* acontecesse — errei a previsão — e declarou
também, antes, o que fazer se acontecesse: **registrar o fato, não fundir os
painéis** (60 seeds com um corte de 21/30 não é teste nenhum) e **não abrir o gate de
T3 por conta própria**. Fica registrado: uma réplica independente teria confirmado
T2 pelo critério do §4.7. O §4.7 continua sendo o que é — 20/30 contra corte de
21/30, "não decide" — porque mover a trave depois do placar é proibido também quando
o resultado agrada.

**(b) O sinal que o binário joga fora replica.** Das 6 corridas que ele carimba
FUNDADOR em T2, **6/6** têm `d̄ < 0` (`p = 0,0156`) — a réplica dos 9/10 da nota 37;
pooled **15/16** (`p = 0,00026`).

A seed 108 é a demonstração, e é o caso mais extremo do painel: `|d̄| = 0,306`, maior
que a mediana das 30, e o binário a descarta.

| tick | `f_ímpar^A` | `f_ímpar^B` | `d` |
|---|---|---|---|
| 500 | 0,378 | 0,597 | −0,219 |
| 2 000 | 0,342 | 0,784 | −0,442 |
| 5 000 | 0,431 | 0,872 | −0,440 |
| 8 000 | 0,589 | 0,906 | −0,317 |
| 16 000 | 0,876 | 0,994 | −0,118 |
| 29 999 | 0,954 | 1,000 | −0,046 |

Em A o ímpar (que ali carrega `+2,0`) termina em 95,4%; em B o ímpar (que ali carrega
`−2,0`) termina em 100%. O classificador lê "ÍMPAR venceu as duas" e carimba
FUNDADOR. E `d` é negativo do primeiro tick ao último, **sem trocar de sinal uma
vez**: nas duas montagens, quem carrega `−2,0` cresce em relação à montagem
espelhada. É o efeito fundador vencendo no nível do rótulo e cancelando na diferença,
que é a propriedade que a régua pareada tem **por construção**.

*(A tabela da seed 108 foi calculada fora do script do painel, com o mesmo patch do
braço T2 — mesma prática da nota 37, que calculou o Wilcoxon exato fora do script.)*

**(c) A falha: o nulo do binário saiu da faixa.** Pré-registrei 4..15 REAL para N2
(o IC95 Clopper–Pearson dos 9/30 da nota 35). Deu **16/30**. Registro como **falha do
pré-registro**, não como descoberta bonita — mas ela é informativa, e a explicação
está medida nos mesmos dados:

| | nota 35/37 (seeds 1–30) | agora (seeds 101–130) |
|---|---|---|
| N2, `\|d̄\|` mediana | 0,0403 | **0,0686** |
| N2, `Δpop` mediana | 0,01503 | **0,01665** |
| T2, `Δpop` mediana | 0,01469 | 0,01485 |
| N2, REAL pelo binário | 9/30 (30%) | **16/30 (53%)** |

Duas réguas independentes — uma que mede composição, outra que mede só a divergência
da população e é cega a qual valor vence — dizem a mesma coisa: **este nulo
decorrelacionou mais**, enquanto T2 ficou estável entre os painéis. E 53% é
exatamente onde o teto algébrico do §4.10 diz que a decorrelação total mora (50%).
Não há aqui nenhum mecanismo novo: há um nulo que, com `n = 30`, não fica quieto.
As duas estimativas não diferem significativamente entre si (Fisher `p = 0,115`;
pooled 25/60 = 41,7%), o que é outra forma de dizer a mesma coisa — 30 seeds não
fixam esse número.

**O que não replicou, e é da nota 37:** a P4 dela (dentro de N2, as corridas REAL
deveriam ter `|d̄|` maior que as FUNDADOR) dava 0,0707 × 0,0389, `p = 0,0427`. Aqui dá
**0,0683 × 0,0744, `p = 0,75`** — sumiu. A leitura mais econômica, e ela é
**post-hoc**: no teto, a relação satura. Se o desfecho binário já virou moeda
(53% ≈ 50%), decorrelacionar mais não compra mais REAL, e a correlação interna some.
Isso é consistente com os dois painéis e **não foi testado** — quem quiser tratar
como resultado precisa pré-registrar. Em T2, onde há vantagem, a mesma relação
aparece mais forte do que aparecia na nota 37 (0,216 × 0,124, `p = 0,037`).

## 5. Sensibilidade, e a ameaça da nota 37 numa segunda amostra

As três janelas concordam na primária (29/30, 30/30, 30/30) e concordam no nulo
(16/30 nas três). Nada aqui depende da escolha de janela.

O descritivo herdado da nota 37 volta, agora com uma segunda amostra, e continua
apontando **contra** a ameaça de decorrelação:

| observável | T2 | N2 | leitura |
|---|---|---|---|
| `t_01` (primeiro `\|d\| ≥ 0,01`) | mediana 13 | mediana 11 | T2 **mais tarde** em 20 dos 27 pares discordantes (`p = 0,019`) |
| `t_div` | mediana 3 | mediana 3 | T2 mais tarde em 7 de 7 discordantes (`p = 0,016`) |
| `Δpop_2000` | 0,01485 | 0,01665 | N2 diverge **mais** em 20/30 (`p = 0,099`) |

Na nota 37 o mesmo `t_01` deu 19/27 (`p = 0,052`) e ficou limítrofe; aqui cruza. A
direção é a que interessa: se há assimetria de perturbação entre os braços, ela é a
favor do **nulo** perturbar mais, não menos — o oposto do que a ameaça precisaria. A
ameaça segue fechada, agora em duas amostras.

## 6. O que isso faz — e o que não faz — com o fio

**Q5 fica respondida com estatuto próprio.** A nota 30 respondeu com uma média sob
mutação livre em 3 seeds; as notas 32/33/34 contaram seeds sem decidir; a nota 35
mostrou que a contagem se dava contra um zero imaginário; a nota 37 achou a régua
certa, mas como observável secundário e nas seeds já vistas. Este painel a põe como
primária, em seeds novas, com corte e potência declarados antes: **30/30,
`p = 1,9·10⁻⁹`, nulo de 16/30 nas mesmas corridas**. A pergunta *por que* `−2,0`
vence continua sem resposta — medir que vence não é medir o mecanismo.

**O §4.7 não se move, em direção nenhuma.** Está escrito acima e vale repetir porque
é o ponto em que seria mais fácil trapacear: o binário destas 30 seeds novas
confirmaria pelo próprio corte, e mesmo assim os painéis **não** se fundem e T3
**não** abre aqui. O que este painel entrega para essa decisão é material: duas
amostras independentes, 44/60 pelo binário (acima do teto de 50% com `p = 2,0·10⁻⁴`)
e 58/60 pela pareada, e a constatação de que o corte de 21/30 estava sendo cobrado de
uma régua cujo **nulo** oscila 23 pontos percentuais entre amostras.

**A nota 35 recebe qualificação de interpretação.** O `p = 0,0092` dela é correto
para as seeds que ela rodou; o que este painel mede é que o segundo termo do
contraste (o nulo) é instável, e por isso o contraste carrega menos peso do que o
número sugere. A outra afirmação dela — a direção 20/20 contra um nulo que é moeda —
não só sobrevive como replica: 24/24 contra 10/16.

## Ameaças à validade

- **A falha do P4(c) é minha, e o pré-registro é que a torna legível.** Se eu tivesse
  medido o nulo binário sem faixa declarada, teria escrito "o nulo é ~30–50%" e
  passado batido. A faixa 4..15 saiu do IC de um painel só, e um IC de 30 seeds não
  cobre a variação de outra amostra de 30.
- **A explicação por decorrelação é post-hoc**, e está rotulada como tal em duas
  frases do §4. Ela é apoiada por duas réguas independentes que apontam juntas, mas
  não foi predita.
- **A comparação entre painéis usa as medianas publicadas** da nota 37 — os valores
  por seed daquele painel não foram guardados em disco (ambos os painéis são
  reprodutíveis pelos scripts, mas não há um CSV congelado de um para diffar contra o
  outro).
- **O determinismo sob paralelismo foi conferido em uma corrida**, não nas 120: o
  script guarda o md5 de todas, mas só uma foi repetida sozinha. É verificação de
  amostra, não prova. `JOBS=1` roda o painel inteiro sequencial para quem quiser a
  conferência completa.
- **`d̄` mede vantagem de crescimento cedo; o binário mede quem fixa.** As duas réguas
  respondem perguntas diferentes, e esta nota não troca uma pela outra — a seed 108
  fixa `+2,0` em A e `−2,0` em B, e o `d̄` dela é o mais negativo do painel.
- **A janela primária foi calibrada na nota 37** (seeds 31/32, fora da amostra
  daquele painel) e é herdada aqui sem recalibração — o que é o certo a fazer, mas
  significa que `W = 2000` não é escolha independente entre os dois painéis.

## O que ficou em aberto

1. **T3, com pré-registro próprio.** O gate era "o pool de T2 confirmar", e o material
   para escrever um corte honesto agora existe (duas amostras, dois vereditos, um teto
   algébrico e um nulo instável). Escrever esse pré-registro é decisão do André, e
   exige corte declarado antes — não a fusão dos painéis.
2. **Por que `−2,0` vence** (item 2 da nota 37, intocado): se persistir na disputa é o
   que paga, o ganho deveria sumir num mundo sem disputa — `PESO_ESPACO` e a densidade
   inicial já são parâmetros.
3. **O nulo coerente** (item 3 da nota 37): segue sem rodar, e este painel o torna
   menos urgente ainda — a ameaça que ele fecharia já falhou em aparecer em duas
   amostras, pelas duas réguas.
4. **O classificador binário não deveria ser mais a régua deste fio.** Ele tem nulo
   instável (30% → 53%), joga fora sinal que a régua pareada lê (15/16 das FUNDADOR),
   e precisa de fixação para dizer qualquer coisa. Não é um convite a reescrever as
   notas antigas: é um critério para as próximas.
