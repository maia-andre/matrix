# Nota 23 — O teste de bimodalidade: o ponto de ramificação vira polimorfismo de verdade, mas só no fundo em que foi medido

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/23-bimodalidade.sh`, commitado em
`b541040` — **antes** de rodar (B0a/B0b/B1/B2).
**Serve ao:** Paper 2 — fecha a "próxima sonda declarada" da nota 20 (a
evolução livre produz uma distribuição de horizontes bimodal?), ligando de
vez ao `hor_m` disperso da nota 15. Agregados em `datasets/bimodalidade.csv`.
**Reproduzir:** `sh papers/notes/23-bimodalidade.sh` (~12 min seriais, poucos
minutos com `NPROC=16`)

---

## Resumo

A nota 20 mediu o `h*` por **invasão pareada**: um residente e um invasor raro,
só dois valores de horizonte por corrida, mutação desligada. Achou que o `h*`
não é ESS (invasores dos dois lados crescem) mas é convergence-stable — a
assinatura teórica de um **ponto de ramificação**. Mas invasão pareada não é o
mesmo que ver a população **de fato se dividir**: o teste direto que sobrou é
deixar o horizonte mutar livremente por **todo** o domínio 1..12 e olhar a
forma da distribuição numa única população.

Dois pilotos (não commitados) decidiram o desenho. O primeiro pregou só o
desconto e deixou os outros três traços livres: o horizonte convergiu para
`~3`, nada a ver com o `h*=8` da nota 20 — porque o `h*` da nota 20 foi medido
com **todo o resto pregado**, e traços livres mudam a paisagem de aptidão por
completo (é o próprio achado da nota 15: profundidade evoluída livre = `3,31`,
bem abaixo do `h*` do torneio). Isso separou o desenho em duas condições:

- **`uni_h_livre`** — o **mesmo fundo** da nota 20 (desconto, urgência,
  peso_espaço e estratégia pregados), horizonte livre. Testa o ponto de
  ramificação no fundo em que foi medido.
- **`livre`** — a evolução de verdade (`main.c` vanilla + só a sonda do
  histograma), todos os traços livres. O teste **literal** do ROADMAP.

Um segundo piloto também derrubou o critério de bimodalidade original (contar
picos locais): o ruído de amostragem finita fragmentava um modo largo em
"3-4 picos" espúrios. Trocado por um critério mais grosso — massa em duas
regiões fixas flanqueando o `h*(δ)` das notas 19/20, com um buffer entre elas
— antes do pré-registro.

**O ponto de ramificação vira polimorfismo real — no fundo pregado, com
saturação total a partir de δ=0,90.** Mas na evolução de verdade, com os
outros traços livres, **nenhuma seed é bimodal** — cada corrida converge para
um pico só, e é o próprio pico que varia entre seeds (`sd=2,12`, a dispersão
que a nota 15 já via em `hor_m`).

| # | predição (escrita antes) | resultado |
|---|---|---|
| **B0a** | `livre` (só a sonda) reproduz `--log` bit a bit == vanilla | ✅ |
| **B0b** | `uni_h_livre` prega desc/urg/esp/estratégia (sd≈0), horizonte livre (sd>0) | ✅ desc_sd=0,0002; urg_sd=esp_sd=0; hor_sd=3,04 |
| **B1** | fração bimodal em `uni_h_livre` cresce com δ: ≤2/8 em 0,80; ≥6/8 em 0,90/0,95/0,96 | ⚠️ **parcial** — 0,80 deu **4/8** (previsto ≤2/8); 0,90/0,95/0,96 deram **8/8, saturação total** |
| **B2** | `livre`: fração bimodal baixa (≤2/8); dispersão da moda entre seeds > 2 | ✅ **0/8** bimodal; dispersão da moda = **2,12** |

## 1. `uni_h_livre` — a dose-resposta, com uma superfície mais ruidosa do que a teoria previu em δ=0,80

| δ | seeds bimodais | massa baixa (média) | massa alta (média) |
|---|---|---|---|
| 0,80 | **4/8** | 0,195 | 0,621 |
| 0,90 | **8/8** | 0,341 | 0,337 |
| 0,95 | **8/8** | 0,405 | 0,425 |
| 0,96 | **8/8** | 0,327 | 0,450 |

De 0,90 em diante, **toda seed** sustenta massa substancial nos dois lados do
`h*` — o ponto de ramificação da nota 20 produz, sem exceção, dois morfos
coexistindo quando o traço pode explorar o domínio inteiro. É a confirmação
direta que faltava: invasão pareada previu coexistência, e a evolução livre
(dentro deste fundo) entrega coexistência.

Em δ=0,80 o resultado é mais ambíguo do que a nota 14/16 sugeriam. A nota 14
mediu dominância transitiva do teto em δ=0,80 (h=12 vence todos os duelos), e
a nota 20 nunca testou invasão-rara **exatamente** nesse δ — a leitura "teto
quase-ESS em 0,80" vinha da dominância pareada, não do critério de
Maynard Smith que a nota 20 aplicou só em 0,95/0,96. O resultado aqui (metade
das seeds sustentando massa baixa substancial mesmo em 0,80) é consistente com
duas leituras que este desenho não separa: **(a)** existe algum grau de
ramificação já em 0,80, mais fraca e mais sensível a ruído que em δ maior; ou
**(b)** é carga de mutação — com a dominância do teto sendo forte mas não
absoluta, a introdução constante de mutantes de horizonte baixo (a uma taxa
fixa, `2×MUTACAO` por nascimento) sustenta uma nuvem de baixa frequência sem
que isso seja uma coexistência **evolutivamente estável**. Este desenho não
decide entre as duas — ver Ressalvas.

## 2. `livre` — nenhuma população bimodal, mas o pico varia mais que tudo

| seed | moda | massa baixa | massa alta |
|---|---|---|---|
| 1 | 8 | 0,002 | 0,393 |
| 2 | 9 | 0,000 | 0,862 |
| 3 | 3 | 0,978 | 0,000 |
| 4 | 6 | 0,247 | 0,010 |
| 5 | 6 | 0,144 | 0,245 |
| 6 | 9 | 0,000 | 0,928 |
| 7 | 8 | 0,026 | 0,490 |
| 8 | 9 | 0,013 | 0,656 |

**Moda:** média 7,25, desvio-padrão **2,12** — quase todo o domínio 1..12
visitado como "o pico da vez" entre as 8 seeds (de `h=3` a `h=9`). E **nenhuma**
seed é bimodal pelo critério pré-registrado. A leitura que os dois resultados
juntos sustentam: a evolução livre **não hesita entre dois morfos dentro de
uma corrida** — ela converge, e converge rápido o bastante para comprometer
com UM ponto, cedo. O ponto em que ela comete depende de onde o desconto (que
também evolui aqui) e os outros três traços pousaram naquela corrida
específica — e é exatamente essa dependência de trajetória que produz o
`hor_m` disperso entre seeds que a nota 15 mediu (`sd` até 15× o da profundidade
efetiva). A nota 15 media o sintoma; esta nota mostra o mecanismo agindo: não
é ruído de medição, é cada realização escolhendo um ponto diferente do mesmo
espaço de possibilidades, e nunca dividindo a aposta dentro da própria
corrida.

## 3. Ressalvas honestas

- **B1 não bateu o número em δ=0,80, e isso é o achado, não o ruído.** A
  predição pré-registrada (≤2/8) supunha que 0,80 fosse claramente "teto
  quase-ESS", herdando a leitura de dominância pareada das notas 14/16. O
  resultado (4/8) mostra que essa leitura não se sustenta quando o horizonte
  pode mutar livremente — e o desenho aqui não distingue ramificação fraca de
  carga de mutação. Resolver isso exigiria uma variante com mutação desligada
  no horizonte (equilíbrio sem introdução contínua de variantes) comparada à
  variante com mutação — não construída aqui.
- **`uni_h_livre` não é a evolução real.** É o fundo artificial da nota 20 —
  necessário para testar a ramificação no lugar exato em que foi medida, mas
  urgência/peso_espaço/estratégia pregados mudam a dinâmica que produziria em
  evolução livre. A comparação com `livre` é o que mostra que a coevolução
  dos outros três traços **apaga** a bimodalidade visível, não que ela não
  exista estruturalmente.
- **`livre` usa uma partição genérica (baixa≤5 / alta≥9), não um `h*` por
  seed.** Como o desconto também evolui aqui, não há um único `h*` de
  referência — uma seed com desconto baixo teria um `h*` diferente de uma com
  desconto alto. A ausência de bimodalidade sob a partição genérica é honesta
  como teste do "ROADMAP literal", mas não prova que uma partição
  seed-específica (por `h*(desc_m dessa seed)`) daria o mesmo resultado.
- **Janela de 5000 ticks, amostrada a cada 250 (20 leituras) — não 50 seeds.**
  8 seeds por condição, mesmo padrão de poder estatístico das notas 16/19/20;
  suficiente para a saturação 8/8 em δ≥0,90 (não há incerteza sobre "a maioria
  das seeds"), mas não para refinar a fronteira exata onde a mistura em 0,80
  se resolve.
- **Critério corrigido ANTES do pré-registro, não depois.** O primeiro
  desenho (picos locais) foi descartado num piloto não commitado — é a mesma
  disciplina da nota 16 (medir o instrumento antes de escrever a predição),
  não uma correção post-hoc do resultado.

## 4. Método

- **`uni_h_livre`:** reaproveita as substituições de `desconto`/`urgência`/
  `peso_espaço`/`estratégia` do patch `uni()` das notas 16/18 (mutação
  desligada nelas), mas **não toca** em `b->horizonte` nem em
  `cria->horizonte` — o traço semeia 1..12 e muta pela regra padrão
  (`muta_horizonte`, ~2×MUTACAO por nascimento).
- **Histograma:** acumulador novo `hist_soma[13]` (índice 1..12), somado a
  cada 250 ticks nos últimos 5000 de cada corrida (20 leituras), lendo só
  `blocos[i].horizonte` — pura leitura, sem RNG, sem escrita em estado da
  simulação (B0a confirma: CSV bit a bit idêntico ao vanilla quando não há
  pino).
- **Classificação:** ver "como se mede bimodalidade" no cabeçalho do script —
  massa em duas regiões fixas flanqueando `h*(δ)`, sem detecção de pico local.
- **Dataset** `bimodalidade.csv`: uma linha por variante × δ × seed:
  `variante,desconto,seed,h1,h2,...,h12` (as 12 somas cruas da janela, não
  normalizadas — a normalização e a classificação são feitas na análise).
