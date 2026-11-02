# Nota 40 — A decomposição: o `−2,0` ganha do zero, o `+2,0` perde, e um termo sem direção perde mais que os dois

**Data:** 2026-11-02
**Pré-registro:** `ROADMAP.md` §4.13, commit `f0c9a21`, antes de rodar.
**Construído em:** `b5aaa44` (script commitado antes de rodar).
**Serve ao:** item 2 da fila pós-nota 38 ("por que `−2,0` vence"), fase 1: antes do
*por que*, **contra quem**.
**Reproduzir:** `sh papers/notes/40-decomposicao-do-arrependimento.sh` (15 min 27 s de
relógio, 2 h 40 de CPU: 180 corridas de 5 000 ticks e a regressão de 30 000).

---

## Resumo

Q5 respondia um duelo (`−2,0 × +2,0`). Aplicada contra o `0,0`, a régua pareada
separa as duas histórias que o duelo misturava, e **as duas são verdadeiras, em
proporções desiguais**:

| braço | `ḡ_2000 > 0` | mediana `ḡ_2000` | veredito |
|---|---|---|---|
| **NEG** `−2,0 × 0,0` | **28/30** (`p = 4,3·10⁻⁷`) | **+0,0715** | P1 confirma: o negativo **paga** |
| **POS** `+2,0 × 0,0` | 6/30, ou seja, **24/30 negativas** (`p = 7,2·10⁻⁴`) | **−0,0234** | P2 confirma: o positivo **custa** |
| **NUL** termo sem direção × `0,0` | 1/30, ou seja, **29/30 negativas** (bilateral `p = 5,8·10⁻⁸`) | **−0,0790** | P3 detecta efeito: **custa** |

O negativo responde por cerca de **três quartos** da vantagem de Q5. A soma descritiva
`ḡ_NEG − ḡ_POS = +0,095` fica perto do `+0,101` que T2 mediu diretamente na nota 38,
com outras seeds. Isso é consistente com efeitos aditivos, mas não é um teste.

**O nulo errou a minha expectativa, e é o achado mais interessante.** Eu declarei
"não detectado". Um termo de arrependimento **sem direção** (a mesma dose, preferindo
espaço aberto em metade das células e lotação na outra) perde para o `0,0` em 29/30
seeds, e perde **mais** que o `+2,0`. A ordem fica:

> **`−2,0` > `0,0` > `+2,0` > sem direção**

Ter o termo não é neutro: uma política incoerente custa caro. O positivo recupera parte
desse custo, e o negativo recupera tudo e ainda ganha. A vantagem de `−2,0`, portanto,
é sobre **direção**, não sobre "mexer na decisão". Um ruído de mesma dose afunda.

## 1. Sanidade

- **S1 (regressão):** NEG/A da seed 1 a 30 000 ticks dá `arrep_m = −0,026` no tick
  29 999, exatamente o publicado na nota 33. O binário T1 é o mesmo.
- **S2 (paralelismo):** NEG/301/A repetida sozinha tem o mesmo md5 do painel.
- **S3 (a régua no tick 0):** `f_X = 0,5` exato nas duas montagens, nas 60
  corridas de cada braço. A régua parte do zero.

## 2. P1 e P2: os dois lados contribuem

| janela | NEG `ḡ > 0` (mediana) | POS `ḡ < 0` (mediana) |
|---|---|---|
| 500 | 29/30 (+0,0200) | 26/30 (−0,0118) |
| **2000** | **28/30 (+0,0715)** | **24/30 (−0,0234)** |
| 5000 | 26/30 (+0,1287) | 21/30 (−0,0354) |

As três janelas concordam no veredito. POS na janela de 5 000 fica exatamente no corte
(21/30), mais fraco que nas outras duas. O efeito do negativo **cresce** com o tempo
(a mediana vai de +0,020 a +0,129) e o do positivo cresce mais devagar. Pela tabela do
§4.13, P1 ✓ e P2 ✓ é "os dois contribuem, e as medianas dizem quanto": aqui
0,0715 × 0,0234, cerca de **3 : 1** a favor do negativo.

**O que isso faz com as notas 32/33.** O binário de T1 deu FUNDADOR em 9/10, e a única
seed REAL favorecia `0,0`. A régua pareada, nas mesmas condições e com seeds novas, dá
28/30 para `−2,0`. É a regra 10 de novo, num braço em que ela ainda não tinha sido
tentada: o viés de paridade vence no nível do rótulo e cancela na diferença. As notas
32/33 **não** recebem errata (o veredito binário é o que é). Recebem a mesma
qualificação que a nota 38 deu à nota 35: a régua delas não tinha poder para ver isto.

## 3. P3: o termo sem direção custa, e custa mais que o positivo

| janela | NUL `ḡ < 0` (mediana) |
|---|---|
| 500 | 30/30 (−0,0369) |
| **2000** | **29/30 (−0,0790)** |
| 5000 | 30/30 (−0,1149) |

O pré-registro mandava dizer uma coisa caso P3 detectasse efeito no mesmo sentido de
um braço confirmado. Aqui é o caso do POS: **parte do custo do `+2,0` pode ser só
presença do termo**, e não a direção positiva. Mas a comparação entre braços aponta o
contrário do que "só presença" preveria. Se o custo do `+2,0` fosse todo presença,
`ḡ_POS` deveria ficar perto de `ḡ_NUL`, e fica a um terço dele. A direção positiva
**ajuda** em relação ao termo incoerente, só não o bastante para empatar com o zero.

O nulo, assim, muda a pergunta do item 2. "Por que `−2,0` vence?" agora tem três
partes, todas medidas:

1. ter o termo, sem direção, custa (`−0,079`);
2. a direção positiva recupera parte disso e ainda perde para o zero (`−0,023`);
3. a direção negativa recupera tudo e ganha (`+0,072`).

O mecanismo que o item 2 procura tem de explicar a **escada inteira**, e não só o topo.

**A álgebra do §4.13 previa um nulo assimétrico, e ele saiu assimétrico.** Sob NUL o
outro tipo é o `0,0`, e a involução não força simetria. O pré-registro disse isso e
por isso declarou o teste bilateral. A expectativa de "não detectado" é que estava
errada, não a álgebra.

## 4. O que isso diz, e o que não diz, sobre o mecanismo

Nada aqui é mecanismo, e a nota não finge que é. O que a decomposição muda para a fase
2 do item 2:

- **A hipótese da nota 30 §4 sobrevive e fica mais específica.** "Depois de perder uma
  disputa, continuar competindo pelo recurso que valia a disputa." Ela previa que o
  negativo **paga**, e P1 confirma. Mas ela não previa que um termo incoerente custasse
  tanto. A fase 2 precisa medir **onde** cada tipo come depois de perder uma disputa
  (riqueza e lotação da célula), nos três braços, para ver se a escada
  `−2 > 0 > +2 > NUL` se repete nesse observável.
- **A nota 39 entra aqui.** Lá, os blocos `−2,0` leem menos `agencia` (régua do
  `main.c`) por ecologia: estão em posições com menos escolha. Ficar onde há disputa é
  exatamente o que deixa menos células livres em volta. A fase 2 pode medir as duas
  coisas no mesmo fluxo.
- **O termo sem direção custar caro é um resultado por si.** Ele diz que a decisão
  deste mundo é **sensível** a perturbações do motivo de espaço, e que perturbá-la sem
  coerência é pior que não ter memória nenhuma. Num projeto que mede faculdades por
  ablação, isso é um aviso: "ligar um termo com o sinal errado" e "ligar um termo
  aleatório" não são a mesma ablação, e nenhuma das duas equivale a desligá-lo.

## Ameaças à validade

- **`ḡ` é vantagem de crescimento cedo** (composição média em `[0, W)`), não aptidão
  e não fixação. Os valores finais de `f_X` (tabela por seed no script) variam muito,
  e 5 000 ticks não são fixação.
- **A comparação com T2 é entre painéis** (seeds 101–130 × 301–330). A aditividade é
  descritiva.
- **O NUL usa um campo de sinal por seed.** A involução garante que `+2` e `−2` sob o
  campo têm a mesma distribuição, mas um campo é **uma** realização por seed. A
  variação entre campos está misturada à variação entre seeds, como nas notas 35–38.
- **POS no corte em W = 5000 (21/30).** O veredito primário é o de W = 2000 (24/30), e
  as três janelas concordam, mas o efeito do positivo é o mais frágil dos três.
- **Seed 31 vista antes.** No teste do encanamento (200 ticks, fora da amostra) os três
  braços já se moviam no sentido que o painel mostrou. O pré-registro estava commitado.

## O que ficou em aberto

1. **Fase 2 do item 2, o mecanismo:** depois de uma disputa perdida, onde cada tipo
   come (riqueza e lotação da célula) e quanto, nos três braços. Com pré-registro
   próprio, e predizendo a escada `−2 > 0 > +2 > NUL`.
2. **Por que o termo sem direção custa tanto** (pós-hoc, sem teste): um bloco que, em
   metade das células, é atraído pela lotação depois de perder uma disputa entra em
   mais disputas. O número de negados por bloco nos três braços responderia isso
   barato.
