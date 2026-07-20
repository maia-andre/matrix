# Nota 18 — O plano é um passo com uma cauda fictícia: o horizonte de informação deste mundo é k* = 0

**Data:** 2026-07-20
**`main.c`:** o de `079a3ce` (canônico **intocado**; a sonda é patch de medição —
E0a prova que ela não muda uma vírgula da simulação).
**Pré-registro:** cabeçalho de `papers/notes/18-sonda-erro.sh`, commitado em
`1c85169` — **antes** de rodar (E0a/E0b/E1..E5).
**Serve ao:** Paper 2 — fecha **o elo que falta** declarado no §8 dele e no
ROADMAP; Paper 1 — esta é a sonda que ele exigiria do próprio autor. Agregados em
`datasets/sonda-erro.csv`.
**Reproduzir:** `sh papers/notes/18-sonda-erro.sh` (~12 min com `NPROC=16`,
MEDIDO — a estimativa do cabeçalho, 35–60 min, errou para **cima** desta vez; fica
registrado que a moeda das erratas de custo tem dois lados)

---

## Resumo

O §5 do Paper 2 era *inferência à melhor explicação*: o tipo fundo colhe pior
(nota 17) e o dano escala com δ, **logo** a cauda da previsão devia ser ruído. O
erro do plano nunca tinha sido medido. Esta nota mede: para cada decisão, guarda o
fluxo de garfadas que `prever_valor` projetou para a célula escolhida
(`ĝ_0..ĝ_{h−1}`) e compara com o que o bloco **de fato colheu** k ticks depois
(`r_{t+k}`), mais a trajetória de comida prevista da célula contra a real.
~700 000 amostras por corrida, 83 corridas, tudo em `double`.

**O elo fecha — e é mais curto do que o pré-registro previa.** A previsão só
carrega informação no **primeiro passo**: `corr(ĝ_0, r_0) ≈ 0,60–0,73`, e já em
k=1 despenca para ≤ 0,19 (na evolução livre, 0,05). Pelo critério pré-registrado
(último k com corr ≥ 0,5), **k\* = 0 em todas as 10 condições povoadas, 8/8 seeds,
por unanimidade** — e o veredito não muda se o limiar descer a 0,25. O rmse dobra
de k=0 (~0,13) para k=1 (~0,27) e não volta.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **E0a** | a sonda não muda a simulação (CSV bit a bit) | ✅ idêntico ao vanilla |
| **E0b** | eremita, premissa cumprida ⇒ erro **0 exato** em double, todo k | ✅ 36/36 linhas com cobertura, `maxabsP == 0`, até k=11 (nP de 425 201 a 130) |
| **E1** | corr decai, rmse cresce; k\* ≤ 3 nas povoadas | ✅ **com folga**: k\* = 0 em todas, 8/8 seeds |
| **E2** | livre: k\* ∈ {2, 3}, casando com pico de colheita h≈2 e profundidade evoluída 3,31 | ❌ **na direção não prevista**: k\* = 0 — o horizonte de informação é *ainda mais curto* que o pico de colheita. A tese do regularizador sai **fortalecida**, e fica um enigma novo (§4) |
| **E3** | premissa < 0,5 até k=3; viesP(0) < 0; rmseP ≪ rmse | ✅ **mais forte**: fprem(1) = 0,03–0,08 (morre no *primeiro* replanejamento); viesP(0) ∈ [−0,10; −0,08] em 10/10; rmseP(3) = 0,01–0,03 contra rmse(3) ≈ 0,28 (10–20×) |
| **E4** | h=12: corr(k) quase igual entre δ=0,80 e 0,95 (\|Δ\| < 0,1) | ❌ → **achado**: Δcorr = **−0,134 ± 0,005** (`t = −25,9`, 8/8 seeds) — em δ=0,95 a cauda fica **anticorrelacionada** (−0,04..−0,06). O erro não é estático: o próprio comportamento fundo o fabrica (§3) |
| **E5** | W(δ) cresce na direção da dose-resposta da 17 | ✅ direção (0,785 → 0,861 → 0,891), ❌ magnitude (×1,13 enquanto o dano triplica) — o peso sozinho não explica o dano; falta o canal do E4 |

## 1. A âncora: o zero é estrutural

A garfada real de `aplicar_e_comer` é `menor(comida, INGESTAO)` **inteira** — a
`partilha` do `prever_valor` é um desconto heurístico de risco, não uma previsão
da dinâmica (só um bloco ocupa cada célula; ninguém come da célula alheia). No
eremita (`rivais_em == 0`), `partilha = 1.0f`, e aí previsão e realidade executam
**as mesmas operações de float**: comer inteiro, rebrotar `REGROW·(cap−food)`.
Medido: enquanto o bloco ocupa a célula planejada, o erro é **0 exato em
`double`**, nas 3 seeds, em todo k com cobertura — até k=11, onde restam 130
amostras por seed. O modelo do bloco **é** a regra do mundo. Todo erro medido
nas outras condições vem, portanto, de duas fontes apenas: a **premissa** (ele não
fica onde planejou) e a **partilha** (o pessimismo heurístico) — nunca de
aritmética da sonda (regras 2 e 6 do protocolo).

## 2. O achado central: k\* = 0

`corr(ĝ_k, r_k)` por condição (média de 8 seeds; colunas k=0..11):

| condição | k=0 | k=1 | k=2 | k=3 | k=4 | … | k=11 |
|---|---|---|---|---|---|---|---|
| livre (evol.) | **0,599** | 0,053 | 0,065 | 0,067 | 0,069 | … | 0,051 |
| uni δ=0,80 h=4 | **0,699** | 0,189 | 0,233 | 0,211 | — | | |
| uni δ=0,80 h=8 | **0,685** | 0,101 | 0,142 | 0,129 | 0,140 | … | |
| uni δ=0,80 h=12 | **0,692** | 0,079 | 0,118 | 0,107 | 0,119 | … | 0,089 |
| uni δ=0,90 h=12 | **0,717** | 0,005 | 0,027 | 0,024 | 0,037 | … | 0,032 |
| uni δ=0,95 h=12 | **0,726** | **−0,051** | **−0,064** | −0,059 | −0,051 | … | −0,037 |

O primeiro passo é meio previsível; o segundo já é quase ruído; e no fundo com δ
alto é *anti*-sinal. O pequeno **repique** de k=1 para k=2 (0,079 → 0,118 em
δ=0,80 h=12) é real e não estava previsto — candidato: em k=1 concentra-se a
quebra *recém-ocorrida* da premissa (o bloco acabou de trocar de célula), o pior
subconjunto; fica como observação, sem tese.

Duas leituras de tamanho: o rmse **dobra** no primeiro passo cego (0,13 → 0,27,
todas as condições) e estaciona — o erro da cauda não *explode*, ele satura no
nível "não sei nada"; e a variância explicada cai de ~40% (k=0) para <4% (k≥1).
A profundidade que a evolução carrega — 3,31 ± 0,24 pela régua da nota 15 (30 000
ticks), `hor_m` ≈ 7–10 no transiente de 3000 ticks medido aqui — está **inteira
além do horizonte de informação**.

## 3. A decomposição: quem fabrica o erro

**A premissa morre no primeiro replanejamento.** fprem(k) — fração dos planos cujo
dono ainda ocupava a célula planejada k ticks depois:

| condição | k=0 | k=1 | k=2 | k=3 |
|---|---|---|---|---|
| todas | 0,92–0,97 | **0,03–0,08** | 0,01–0,04 | ≤ 0,03 |

O bloco ganha a célula que declarou (k=0 ≈ 0,95), e no tick seguinte **já não
está nela** — o próprio replanejamento abandona o plano que acabou de avaliar. O
plano de h passos é, empiricamente, **um plano de 1 passo com uma cauda que nunca
é vivida**. E o pouco erro que sobra *dentro* da premissa é o pessimismo da
partilha: viesP(0) < 0 em 10/10 condições (ĝ_0 = partilha·garfada < garfada
real), com rmseP 10–20× menor que o incondicional. Dentro da própria premissa, o
modelo só erra pelo desconto de risco que ele mesmo escolheu aplicar.

**E o erro cresce com δ — o segundo canal (E4).** O pré-registro esperava a curva
de erro invariante ("o dano é o *peso* δᵏ dado ao mesmo erro"). Falhou, pareado
por seed: −0,134 ± 0,005, `t = −25,9`, e em δ=0,95 h=12 a cauda anticorrelaciona.
Não é só que o mundo seja imprevisível: **o comportamento do planejador fundo com
paciência alta torna o mundo mais imprevisível para ele mesmo** (fprem(1) piora de
0,04 para 0,07–0,08; todos perseguem as mesmas caudas). Hipótese, marcada como
tal: a anticorrelação é a assinatura de uma população inteira correndo atrás da
mesma previsão — a célula que o plano diz que renderá em k é exatamente a que
estará raspada. A dose-resposta do dano da nota 17 (+20 → +74) precisa dos dois
canais: o peso (E5, ×1,13) **e** a degradação (E4).

## 4. O que k\* = 0 **não** diz — e o enigma que ele abre

A sonda mede o plano como **previsão** (valor absoluto da colheita própria). A
decisão usa o plano como **ranking** entre ≤9 células candidatas. As duas coisas
podem divergir: a nota 17 mediu que h=2 colhe *melhor* que h=1 — o termo ĝ_1
**ajuda a decidir** apesar de não prever (corr ≤ 0,19). Candidato a mecanismo: o
termo de rebrota dentro de `prever_valor` injeta a **capacidade** da célula — que
é estática e perfeitamente conhecida — no valor; como previsão da garfada de
amanhã isso erra (o bloco não estará lá), mas como critério de ordenação
("prefira manchas férteis") acerta. Erros fortemente correlacionados **entre as
células candidatas** cancelam no argmax.

Fica declarado (e **não** construído) o desenho da sonda sucessora: correlação
**ordinal** — por decisão, o rank do valor previsto das células candidatas contra
o rank do retorno realizado contrafactual. É outra régua, para outra pergunta
("o plano ordena?", não "o plano prevê?"), e é a fronteira honesta desta nota: o
k\* = 0 fecha o elo do Paper 2 (a *cauda como previsão* é ruído desde o primeiro
passo, e o desconto que a suprime é um regularizador), mas não mede o valor
ordinal residual que faz h=2 > h=1.

O enigma novo: se até k=1 é ruído como previsão, por que o pico de colheita da 17
é h=2 e não h=1 — e por que a evolução carrega h≈9 com δ≈0,85? A resposta
posicional do Paper 2 §6 continua de pé para o *excesso*; o degrau h=1→h=2 agora
tem um candidato mecânico (o ranking pela capacidade); e a nota 16 já mostrou que
em δ≈0,80 a cauda é *inofensiva e inútil* — barata de carregar. As três peças são
consistentes, mas a segunda é hipótese até a sonda ordinal rodar.

## 5. Método

- **Censura:** morte censura o plano do tick da morte em diante (contada);
  slot reusado por cria nunca herda plano do morto. Burn-in: planos do tick 500
  em diante. Janela de 2500 ticks × pop ≈ 280 ⇒ ~7·10⁵ planos por corrida.
- **A premissa como flag pegajosa:** sair da célula planejada quebra a premissa
  para sempre (voltar não a restaura) — é a premissa que `prever_valor` de fato
  assume ("ocupo por h ticks"), não "estar lá no tick k".
- **Estatística entre seeds, pareada** quando compara condições (lição da nota
  17 §4); dentro de uma corrida as amostras são autocorrelacionadas (planos
  sobrepostos) e nunca entram num teste como se fossem independentes.
- **Sentinela −9** no dataset marca estatística indefinida (corr sem variância,
  condicionais sem amostra).
- O `n ≥ 1000` do critério de k\* nunca mordeu nas condições povoadas (o menor
  n de célula usada foi ≥ 10⁴).
