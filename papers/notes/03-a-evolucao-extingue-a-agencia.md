# Nota 03 — A evolução extingue a agência (e a régua não tinha culpa)

**Data:** 2026-07-10
**Mostrador `agencia` antigo:** até o commit `764cbbe`. **Consertado em:** `a34cd79`.
**Serve ao:** Paper 1 (metrologia da mente) — e, com força, à `FILOSOFIA_v3.md`.

---

## Resumo

Fui consertar o mostrador `agencia` convencido de que ele estava contaminado: sua
leitura correlacionava **+0,98** com `peso_espaco`, um traço que evolui. Consertei
um defeito real (a sonda visitava dois pontos arbitrários da fome, com o extremo
inferior dependendo de `urgencia`). Mas a suspeita central estava **errada**. A
correlação era mecanismo, não contaminação. Congelando `peso_espaco`, o mostrador
fica plano por 30 000 ticks. Com o traço livre, ele desaba — porque **a agência
desaba**. Num ensaio de invasão, o **reflexo fixa contra o agente** em ~6000 ticks.

A bateria se chama "de desbotamento". Esta é a primeira vez que ela desbota de
verdade — e não somos nós que arrancamos a faculdade. É a seleção natural.

## 1. O defeito real da régua antiga

```c
Bloco faminto = blocos[i], saciado = blocos[i];
faminto.energia = 0.10f * SACIADO;   /* dois pontos, escolhidos a dedo */
saciado.energia = 1.00f * SACIADO;
```

`utilidade` é, para cada célula,

```
u(k) = comida_prev(k) · (1 + urgencia·fome)  +  peso_espaco · espaco(k) · (1 − fome)
```

Dividindo pelo fator `(1 + urgencia·fome)` — positivo e **igual para todas as
células**, logo inofensivo ao `argmax`:

```
nota(k) = comida_prev(k) + λ · espaco(k),     λ = peso_espaco·(1 − fome)/(1 + urgencia·fome)
```

Cada célula é uma **reta em λ**; a escolha é o **envelope superior** dessas retas.
E `λ` decresce estritamente com a fome, varrendo exatamente `[0, peso_espaco]`
quando a fome varre `[0, 1]`.

Isso expõe o defeito: os dois pontos de sonda visitavam
`λ ∈ [0,1·P/(1+0,9·u), P]` — com `u = urgencia`, um traço que **evolui**. O extremo
inferior da sonda coevoluía com a população medida, e a faixa
`λ ∈ [0, 0,034·P]` nunca era visitada.

## 2. O conserto

Varrer `λ` inteiro, em 33 amostras. Como no envelope superior cada reta vence no
máximo **um intervalo contíguo**, há no máximo `(opções − 1)` trocas de decisão, e
amostrar só pode **subestimar** as trocas — nunca inventar uma. A amostragem é
segura por construção.

A estatística continua a mesma de propósito — a fração dos blocos cuja decisão
muda em algum ponto do domínio. Trocar a sonda **e** a estatística no mesmo passo
confundiria as duas mudanças.

Verificação: só a coluna `agencia` do CSV muda; **a simulação é bit-a-bit
idêntica**. Leitura no controle: **0,388 → 0,435** — a sonda antiga perdia ~12%
dos blocos, cuja decisão só troca naquela faixa de `λ` que ela não visitava.

*(Um sobressalto pelo caminho: a primeira versão do patch trocou
`au * (1.0f/n)` por `au / n` e mudou a coluna `automodelo`. Mesma matemática,
arredondamento diferente. O teste "só a coluna alvo muda" pegou.)*

E o novo mostrador **não menciona `urgencia`**. Não por higiene: porque `urgencia`
não pode acrescentar nem remover nenhuma decisão do repertório do bloco. Ela só
desliza *onde*, no eixo da fome, a troca acontece. Quem decide *se* existe troca é
`peso_espaco`, sozinho.

## 3. A suspeita estava errada

Se a régua estivesse contaminada, congelar o traço não deveria estabilizá-la —
a leitura continuaria derivando. Congelamos `peso_espaco = 3,0` (sem mutação,
fluxo do RNG preservado). Média de 3 seeds:

| tick | 500 | 5 000 | 15 000 | 29 999 |
|---|---|---|---|---|
| `agencia`, `peso_espaco` **livre** | 0,430 | 0,360 | 0,059 | **0,049** |
| `esp_m`, livre | 2,760 | 1,677 | 0,131 | **0,079** |
| `agencia`, `peso_espaco` **congelado** | 0,464 | 0,486 | 0,447 | **0,440** |

Plana. A régua é estável; **o objeto é que muda**. `corr(esp_m, agencia)` =
+0,985 / +0,986 / +0,978 é a assinatura de um **mecanismo**: `peso_espaco` é o
único canal pelo qual o estado interno pode mudar uma decisão. Quando ele morre, a
política vira reflexo — `argmax(comida_prev)`, e nada mais.

## 4. E a agência não some por acaso: ela é derrotada

`esp_m` cai monotonicamente de 3,0 a 0,08. Um traço neutro num intervalo `[0, 8]`
derivaria para o meio, não para a borda. Então: seleção. O teste direto é uma
invasão — população 50/50 de `peso_espaco = 0` (**reflexo**) e `3,0` (**agente**),
sem mutação, herança exata. Com só dois valores na população, `esp_m` no CSV *é* a
frequência. Frequência do **reflexo**:

| tick | 0 | 500 | 1500 | 3000 | 6000 |
|---|---|---|---|---|---|
| seed 7 | 0,50 | 0,78 | 0,90 | 0,97 | **0,997** |
| seed 42 | 0,50 | 0,78 | 0,95 | 0,99 | **1,000** |
| seed 1234 | 0,47 | 0,87 | 0,98 | 0,99 | **1,000** |

O reflexo **fixa**. E `agencia`, na seed 7, acompanha o extermínio: 0,050 → 0,003.

Ao nível do grupo o custo de ser agente é pequeno (pop 288,2 × 290,8, ~0,9%) —
mas, como já sabemos por aqui, população de grupo não é aptidão individual, e é a
invasão que decide.

## 5. O que isso significa

O bloco **continua tendo valência**: a energia sobe, desce, e a zero ele morre. O
que a evolução apagou não foi o estado interno — foi o **uso** dele na decisão.
A política vencedora ignora a fome e vai sempre à célula de maior comida prevista.
É um reflexo elaborado: computa um modelo de mundo com horizonte, desconto e
partilha, e não pergunta uma única vez como está se sentindo.

Duas consequências que este projeto não pode mais evitar:

1. **A escada é reversível sob seleção.** A `FILOSOFIA.md` trata os degraus como
   aquisições — coisas que um bloco *ganha*. Aqui um degrau foi **perdido**, por
   pressão seletiva, num mundo onde tê-lo custava. Uma escada de senciência que
   desce sozinha não é uma escada de progresso.

2. **A bateria funcionou.** Ela existe para responder "esta faculdade carrega o
   comportamento?" — e respondeu "não, e cada vez menos". Nós é que estávamos
   olhando para o número e vendo um defeito de instrumento, porque o resultado era
   estranho demais. Vale registrar o viés: **a primeira reação a uma leitura
   incômoda foi acusar a régua.**

## 6. Ameaças à validade

- `agencia` tem um **piso de ruído de ponto flutuante**. No teste do eremita
  (`rivais_em ≡ 0`), todas as retas têm inclinação 1 e o `argmax` deveria ser
  constante em `λ`; medimos 0,0000 nas três seeds, com um **máximo de 0,0040** num
  único tick da seed 1234 — cancelamento em `float` quando dois `comida_prev`
  coincidem nos últimos bits. Não afeta nenhuma conclusão; afeta a leitura de "zero
  exato".
- 33 amostras de `λ` **subestimam** trocas em intervalos estreitos. Direção do erro
  conhecida; magnitude não medida. Uma versão exata (envelope superior analítico)
  é possível e daria o número certo.
- 3 seeds. A invasão é unânime e rápida, mas 3 é 3.
- A invasão fixa `peso_espaco` em `{0; 3,0}`. O ESS pode ser um valor pequeno e
  não-nulo; "0 invade 3" não é "0 é o ESS".

## 7. Em aberto

- A agência é sempre cara, ou só neste mundo? `peso_espaco` só paga quando a
  aglomeração machuca. Um mundo com predadores, ou com custo de disputa, deveria
  **restaurar** a agência. É um experimento, não uma opinião.
- Refazer o mostrador `agencia` na variante graduada `trocas/(opções − 1)`, que
  mede *quanta* estrutura o estado interno impõe à política, e não só se impõe
  alguma.
- Os mesmos dois defeitos (sonda arbitrária, unidade não ancorada) devem ser
  procurados em `automodelo` e `phi`.
