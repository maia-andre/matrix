# Nota 20 — O `h*` não é um ESS: é um ponto de ramificação. O invasor-raro achou o polimorfismo protegido que o 50/50 escondia

**Data:** 2026-07-20
**`main.c`:** o de `079a3ce` (canônico **intocado**; o patch é o da nota 16 com
**uma** mudança — a atribuição do horizonte usa `n_blocos % INVM` em vez de
`n_blocos & 1`, fração rara em vez de 50/50; o mundo segue idêntico, mesmo RNG).
**Pré-registro:** cabeçalho de `papers/notes/20-invasor-raro.sh`, commitado em
`20d1de5` — **antes** de rodar (I0/Idet/I1..I4).
**Serve ao:** Paper 2 — a distinção que o ROADMAP marcou como "passou a importar
agora que o ESS é interior". Agregados em `datasets/invasor-raro.csv`.
**Reproduzir:** `sh papers/notes/20-invasor-raro.sh` (~10 min com `NPROC=16`)

---

## Resumo

As notas 16 e 19 acharam e localizaram um ótimo de horizonte interior (`h*(δ)`
desce 12→7 conforme δ vai de 0,88 a 0,96). Mas **todo** aquele resultado veio de
duelos **50/50**: a média do traço partindo de 0,5, e o "vencedor" é quem passa de
0,5. Isso mede **dominância**, não **invasibilidade** — e um ótimo interior pode
vencer o 50/50 e ainda ser invadível por um mutante raro. Esta nota testa a
definição forte de Maynard Smith: um invasor a `p0 = 0,1` (6 de 60 blocos, linhagem
pura, mutação off), residente monomórfico no resto, e a pergunta "o raro cresce?".

**O `h*` não é um ESS.** A predição pré-registrada — "o residente `h*` resiste a
todo invasor raro" — foi **refutada**, no jeito exato que o pré-registro marcou
como falseador. Vários invasores crescem a partir de 0,1. Mas o `h*` **é** um
atrator (I3 confirmada: o `h*` raro invade residentes dos **dois** lados). As duas
coisas juntas — convergence-stable **e** invasível — são a assinatura de manual de
um **ponto de ramificação evolutiva**: o `h*` não é o fim da linha, é o centro de
um **polimorfismo protegido**, uma banda de horizontes que **coexistem**.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **I0** | `h_inv==h_res` ⇒ população pura | ✅ H=8/δ=0,95 e H=7/δ=0,96 |
| **Idet** | `f(seed)` reproduz | ✅ bit-a-bit |
| **I1** | residente `h*` **resiste** a todo invasor (nenhum `t>+2`) | ❌ **refutada** — j=4,6,7,12 (δ=0,95) e j=4,5,9,10,12 (δ=0,96) **crescem** (`t`=2,1–4,7). `h*` **não** é ESS estrito |
| **I2** | `h*` invade o teto (i=12) e o miope (i=1) | ✅ i=12→0,656; i=1→0,979 (δ=0,95) |
| **I3** | `h*` invade dos **dois** lados (atrator); falsearia se só de um | ✅ cresce contra i<H **e** i>H → **convergence-stable** |
| **I4** | direção raro × 50/50 concorda; divergência = freq-dependência | ✅ **diverge** onde importa: j=12/δ=0,96 cresce raro (0,200) mas **perde** no 50/50 (0,297) |

## 1. A invasibilidade mútua — a tabela que decide

Para cada par `{h*, j}`, a frequência do **raro** nas duas direções (média de 8
seeds; `>0,1` = o raro cresceu). Se **os dois** crescem, eles coexistem
(polimorfismo protegido); se só um, esse vence:

**δ=0,95, `h*`=8:**

| j | j raro (res=8) | 8 raro (res=j) | leitura |
|---|---|---|---|
| 1 | 0,019 | 0,979 | **8 vence** (domina o miope) |
| 4 | 0,160 | 0,483 | **coexistem** |
| 6 | 0,196 | 0,258 | **coexistem** |
| 7 | 0,130 | 0,116 | **coexistem** (quase neutro) |
| 9 | 0,100 | 0,210 | 8 favorecido |
| 10 | 0,117 | 0,449 | **coexistem** (marginal) |
| 12 | 0,153 | 0,656 | **coexistem** |

**δ=0,96, `h*`=7:**

| j | j raro (res=7) | 7 raro (res=j) | leitura |
|---|---|---|---|
| 1 | 0,005 | 0,994 | **7 vence** |
| 4 | 0,130 | 0,499 | **coexistem** |
| 5 | 0,125 | 0,304 | **coexistem** |
| 6 | 0,094 | 0,163 | 7 favorecido |
| 8 | 0,111 | 0,145 | 7 favorecido (quase neutro) |
| 9 | 0,188 | 0,363 | **coexistem** |
| 10 | 0,202 | 0,512 | **coexistem** |
| 12 | 0,200 | 0,664 | **coexistem** |

Leia a coluna do meio: um `h=12` **raro** cresce contra um residente `h*` (0,153 em
δ=0,95; 0,200 em δ=0,96). Se `h*` fosse ESS, o `12` raro **decairia** abaixo de 0,1,
não subiria. E leia a coluna da direita: o `h*` raro cresce contra o `12` residente
(0,656; 0,664). **Os dois invadem um ao outro** ⇒ nenhum exclui o outro ⇒ eles
**coexistem** num equilíbrio interior. O `h*` só **exclui** limpo o extremo miope
(`h=1`); com a banda de horizontes médios e fundos, ele **divide o mundo**.

## 2. O que o `h*` é, então: um ponto de ramificação

Junte as duas metades:

- **I3 — o `h*` é convergence-stable.** O `h*` raro cresce contra residentes de
  **ambos** os lados (contra `h=1,4,6` rasos e `h=9,10,12` fundos, δ=0,95). A
  dinâmica adaptativa **flui para** o `h*`: uma população longe dele é invadida na
  direção dele. É o que a nota 16 chamou de "ESS interior" e o que faz o `h*` ser
  o alvo da evolução.
- **I1 — o `h*` não é evolutionarily stable.** Chegando lá, mutantes raros dos dois
  lados **se estabelecem** (não fixam — persistem a baixa frequência). O `h*` é um
  **mínimo** de aptidão no sentido de invasão, não um máximo.

Convergence-stable **mais** invasível dos dois lados é, na teoria da dinâmica
adaptativa (Geritz et al.), a definição de **ponto de ramificação evolutiva**: um
ponto que atrai a evolução e, ao ser atingido, *deixa de repelir* — a população se
parte em morfos que coexistem. O `h*` das notas 16/19 não é o topo de uma colina de
aptidão; é uma **sela** que a evolução alcança e onde então se **espalha**.

## 3. Isto explica o "`hor_m` é ruído" da nota 15

A nota 15 achou que a profundidade efetiva evoluída é limpa (sd 0,2–0,7) mas o
**horizonte declarado** `hor_m` é **ruído** — sd até **15×** maior, uma seed
pousando em `hor_m=11` e outra em `hor_m=1`. Lá isso foi lido como não-
identificabilidade do par `(horizonte, desconto)`. A nota 20 acrescenta uma segunda
causa, estrutural: **o `h*` é um ponto de ramificação, então a população de
horizontes não colapsa num valor — ela mantém um espalhamento protegido em torno do
`h*`.** Parte da "dispersão entre seeds" de `hor_m` não é a evolução falhando em
convergir; é ela convergindo para um ponto que **seleciona a favor da variância**.
A nota 15 mediu o sintoma; a nota 20 nomeia uma das doenças.

## 4. A δ-dependência do caráter do ponto singular

A nota 14 (δ=0,80) viu dominância **transitiva** e leu "o ESS é o teto". A nota 16
mostrou que isso era do δ=0,80. A nota 20 fecha a mudança de **caráter** do ponto
singular com a paciência:

- **δ baixo (0,80):** o teto `h=12` é um vencedor quase-estrito (nota 14) — perto de
  um ESS de canto, censurado pela parede `HORIZONTE_MAX`.
- **δ alto (0,95–0,96):** o ponto singular é **interior** e é um **ponto de
  ramificação** — atrai a evolução e mantém um polimorfismo protegido em volta.

Mais paciência não só **baixa** o ótimo (nota 19); ela **muda o tipo** de equilíbrio,
de exclusão para coexistência. É o resultado que só o invasor-raro podia ver: o
50/50 da nota 16/19 achava o centro do polimorfismo e o chamava de vencedor.

## 5. I4 — por que o raro e o 50/50 discordam, e por que isso confirma

O `h=12` contra o `h*`=7 (δ=0,96): **raro**, cresce (0,200 > 0,1); **50/50**, perde
(0,297 < 0,5). A discordância não é erro — é a definição de **dependência de
frequência**: o tipo fundo é protegido quando raro e derrotado quando comum, que é
*exatamente* o que produz um equilíbrio interior estável. O I4 divergir onde o par
coexiste é a terceira testemunha do polimorfismo protegido, independente de I1 e I3.

## 6. Ressalvas honestas

- **Efeitos modestos.** Os invasores que "crescem" vão de 0,1 a 0,13–0,20 (`t`
  2–4,7), não fixam. O sinal robusto é a **mútua** invasibilidade e a **direção**
  (crescer, não decair), não a magnitude. A estrutura fina — qual vizinho exato
  coexiste e qual perde — mora **dentro do ruído** do platô mole que a nota 19
  mediu perto do `h*`, e não deve ser lida degrau a degrau.
- **Ramificação medida por invasão, não por bimodalidade.** "Ponto de ramificação"
  é a leitura teórica de (convergence-stable + invasível). O teste direto —
  **a evolução livre produz uma distribuição de horizontes bimodal?** — não foi
  feito aqui. É a próxima sonda (e ligaria de vez ao `hor_m` disperso da nota 15).
- **`p0 = 0,1`, não `ε → 0`.** Seis blocos iniciais têm ruído demográfico; 8 seeds e
  o `se` (0,01–0,04) o domam, mas um `p0` menor seria o limite estrito de Maynard
  Smith. A direção (mútua invasibilidade) é robusta ao valor de `p0`.
- **Janela de 6000 ticks.** O 50/50 da nota 16 resolve nesse horizonte; a invasão a
  partir de 0,1 tem menos distância a andar, mas o equilíbrio final pode não estar
  completo. O sinal de decair-vs-crescer (o que decide ESS-vs-coexistência) já está
  claro em 6000.
- **Dois δ, dois `h*`.** δ=0,95 (H=8) e δ=0,96 (H=7); a leitura "ponto de
  ramificação" vale onde o ESS é interior (δ alto), não no regime de teto (δ baixo).

## 7. Método

- **`p0` determinístico:** invasor se `n_blocos % INVM == 0`; com `INVM=10` e
  `N_INICIAL=60`, exatamente 6/60 = 0,1 no plantio. `(rng01(), …)` preserva o
  consumo de RNG ⇒ mundo idêntico ao das notas 16/17/19.
- **`freq_inv = (hor_m − h_res)/(h_inv − h_res)`** (a média do traço *é* a
  frequência, com dois tipos puros — o corolário do protocolo).
- **Bidirecional** por construção: cada par `{h*, j}` roda como `(res=h*, inv=j)`
  **e** `(res=j, inv=h*)` — a invasibilidade mútua exige as duas.
- **Pareado por seed**, `t` contra `p0=0,1` com o `se` entre as 8 seeds.
- **Dataset** `invasor-raro.csv`: `desconto,seed,h_res,h_inv,freq_inv,hor_m,pop_fim,status`.
