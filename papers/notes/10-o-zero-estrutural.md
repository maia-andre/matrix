# Nota 10 — O zero estrutural: a auditoria em `double` dos três mostradores restantes

**Data:** 2026-07-14
**`main.c` auditado:** o de `079a3ce` — nenhuma linha do canônico mudou; a auditoria
inteira são patches numa cópia temporária, como nas demais notas.
**Serve ao:** Paper 1 (metrologia da mente) — quita a dívida da nota 09 §5 e o
rodapé do Apêndice A da `FILOSOFIA_v3.md`.
**Reproduzir:** `sh papers/notes/10-auditoria-double.sh` (~10 min; expectativas
declaradas no cabeçalho do script, escritas **antes** de rodar)

---

## Resumo

A nota 09 §5 encontrou um piso de arredondamento (~0,003) num "0 exato" do
Apêndice A — a `agencia` do eremita — e deixou a dívida escrita: `modelo`, `phi`
e `relato` nunca tinham sido recomputados em `double`; os seus ✅ eram promessas.

Auditados. **Os três zeros são zeros — nas duas precisões, a nove casas, no
máximo e não só na média:**

| condição de falseamento (Apêndice A) | float32 | double |
|---|---|---|
| `modelo` sob `prever_valor ≡ 0` (nota 01) | **0, exato** | **0, exato** |
| `phi` sob eremita, `peso_espaco ≡ 0`, `prever_valor ≡ 0` (nota 05) | **0, exato** | **0, exato** |
| `relato` sob intérprete cego, k = 0..3 (nota 06) | **0, exato** | **0, exato** |

(3 seeds × 3000 ticks por condição; "exato" = `0.000000000e+00` no acumulador
de máximo, medido na fonte — não no CSV.)

E o resultado negativo que **não** veio é o achado: o piso da `agencia` não era
um aviso genérico sobre float32. Ele tem um alvo. **Float32 não inverte ordens —
cria e destrói empates.** Só vaza a sonda que dá *significado* a um empate (§3).

## 1. O aparato: três esconderijos abertos

As notas 01/05/06 verificaram os zeros no CSV, que tem três esconderijos:

1. **`%.3f`** — um piso menor que 0,0005 é invisível na coluna (o da `agencia`,
   0,003, passou raspando por cima do corte);
2. **a `phi` do CSV é média populacional** — um único bloco não-zero some numa
   média de ~300;
3. **o κ é clampado em `[0,1]`** — um κ *negativo* de arredondamento viraria 0
   sem deixar rastro.

A auditoria instrumenta cada medição **na fonte**, a nove casas, em stderr: o
máximo por **janela** (`modelo`), por **bloco** (`phi`) e o **|κ| antes do
clamp** (`relato`). O método da recomputação é o da nota 09: só a
**comparação** da sonda muda para `double` — a montagem da utilidade na `phi`,
o `1 − |pred−real|/(pred+real)` do `modelo`, o `(po−pe)/(1−pe)` do `relato`;
componentes (`prever_valor`, `espaco`, `comida[][]`) e simulação seguem em
float32.

Sanidade (regra 3 do protocolo): a variante instrumentada reproduz
`datasets/seed7.csv` **bit-a-bit**; a variante double só difere do float32 nas
colunas da própria sonda (14/17/18) — verificado por `cut` no script.

## 2. O placar

Todas as células abaixo leram `0.000000000e+00` nas três seeds (7, 42, 1234):

- **`modelo` / `prever_valor ≡ 0`** — média *e* pior janela do run, f32 e double.
  Bônus da instrumentação: o máximo em 0 prova que a borda de desenho *"previu
  0, colheu 0 ⇒ nota 1,0"* (declarada na expectativa E1 do script como única
  fuga possível) **nunca disparou** — em ~9000 ticks de lobotomia, nenhum bloco
  fechou janela com colheita exatamente zero.
- **`phi` / eremita, `peso_espaco ≡ 0`, `prever_valor ≡ 0`** — média *e* maior
  bloco individual do run, f32 e double. O zero da nota 05 não era média
  escondendo bloco: é zero bloco a bloco.
- **`relato` / intérprete cego (k = 0, 1, 2, 3)** — máximo da coluna *e* |κ|
  pré-clamp, f32 e double. O clamp nunca teve o que esconder: κ do cego é
  `+0`, não "negativo pequeno arredondado".

Controles (o análogo do "a autocausa não se move um dígito", nota 09 §5) —
média das 3 seeds, float32 × double, a quatro casas:

| seed | `modelo` f32 / dbl | `phi` f32 / dbl | `relato` f32 / dbl |
|---|---|---|---|
| 7 | 0,6401 / 0,6401 | 0,0606 / 0,0606 | 0,6226 / 0,6226 |
| 42 | 0,6288 / 0,6288 | 0,0687 / 0,0687 | 0,6159 / 0,6159 |
| 1234 | 0,6251 / 0,6251 | 0,0678 / 0,0678 | 0,6291 / 0,6291 |

## 3. Por que a agência vazou — e os três não

Os quatro zeros, por mecanismo:

- **`modelo`**: com `pred = 0`, a nota é `1 − real/real`, e `x/x = 1` é
  **identidade IEEE754** em qualquer precisão. Zero por identidade.
- **`phi`**: ou o módulo é constante entre células (diferenças exatamente 0 ⇒
  produto 0, e `0 < 0` é falso — **empate não é discordância**), ou a ordem
  integrada é herdada por **multiplicação por escalar positivo comum** — e o
  arredondamento é monotônico: pode criar empates, nunca inversões estritas; e
  empate só *reduz* a contagem. Zero por monotonia.
- **`relato`**: `po` e `pe` do intérprete cego são **o mesmo quociente real**
  (`col/n` e `n·col/n²`, somas inteiras exatas < 2²⁴), e a divisão IEEE
  arredonda o mesmo real para o mesmo float. Zero por igualdade de quociente.
- **`agencia`** (a que vazou): a mesma constante **somada** a todas as notas.
  A soma arredondada também não inverte ordem — mas **cria empates** onde ℝ não
  tem. E a agência conta **trocas de argmax sob desempate estrito `>`**: um
  empate fantasma entrega a vitória ao índice menor; no passo seguinte de λ o
  empate se desfaz e a vitória volta. Cada ida-e-volta conta como troca. Piso.

A lição, mais fina que a da nota 09: o quinto modo de errar não morde qualquer
sonda — morde a sonda que **conta mudanças de escolha**. Identidades, quocientes
iguais e contagens de discordância *estrita* têm **zero estrutural**: o
arredondamento não tem por onde entrar. Argmax com desempate dá significado ao
empate, e float32 fabrica empates. Da bateria, só `agencia` e `autocausa` contam
trocas — e a `autocausa` escapa porque a sua condição de falseamento
(`horizonte = 1`) produz **o mesmo float para todo σ** (nota 09 P2): não há par
quase-empatado a desempatar. Isso vira regra de desenho (§ em aberto).

## Ameaças à validade

- **3 seeds**, como sempre — a replicação de 50 segue sendo a dívida do Paper 1.
- A auditoria recomputa a **comparação**; a acumulação da janela do `modelo`
  (`real_acum`, `peso_janela`) segue float32 nas duas variantes. Para o zero
  auditado é irrelevante (`1 − x/x` não depende da precisão de `x`), mas o
  *valor* do controle (~0,63) carrega a precisão da acumulação, não auditada.
- O argumento de monotonia cobre o **zero das ablações** da `phi`; não diz nada
  sobre um eventual piso da `phi` numa população normal — a mesma pergunta que a
  nota 09 deixou aberta para a `agencia` fora do eremita.
- A borda *"previu 0, colheu 0 ⇒ 1,0"* não disparou aqui, mas segue no código: é
  **desenho**, não aritmética — se um dia disparar, dispara igual nas duas
  precisões.

## O que ficou em aberto

1. **O piso da `agencia` numa população normal** (nota 09) — onde não há verdade
   algébrica para comparar. Segue aberto, e segue desconfortável.
2. **A edição "honesta" da partilha** e a **varredura de densidade** (nota 09) —
   seguem herdadas à Fase 5; esta nota não as toca.
3. **(novo) Regra de desenho para mostradores futuros:** quem contar trocas de
   argmax deve desenhar a condição de falseamento para produzir **o mesmo float
   em todo o eixo varrido** (como a `autocausa` faz), e não "termos que se
   cancelam em ℝ" (como a `agencia` fazia). O zero tem que ser estrutural, não
   algébrico — senão a régua nasce com um piso onde menos se pode ter um.
