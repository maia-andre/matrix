# Nota 24 (eixo microscópio) — O detector de colapso: não confabula, mas fica mudo diante do silêncio total

**Data:** 2026-07-26
**`main.c`:** o de `079a3ce` (canônico **intocado** desde a nota 09).
**Pré-registro:** cabeçalho de `papers/notes/24-detector-de-colapso.sh`, commitado
em `1549a71` — **antes** de rodar (C0a/C0b/C1/C2/C3).
**Serve ao:** o eixo paralelo "A Matrix como microscópio" (ROADMAP) — primeiro
módulo: um detector de mudança de regime, testado pela mesma bateria de
calibração/confabulação da Fase 2. Agregados em `datasets/detector-colapso.csv`.
**Reproduzir:** `sh papers/notes/24-detector-de-colapso.sh` (~3–5 min com
`NPROC=16`)

---

## Resumo

O ROADMAP declara o eixo: uma Matrix que emite relatório sobre o próprio
estado ("a população entrou em colapso") é, ela mesma, um sistema com
faculdade de `relato` — e a régua da Fase 2 (nota 06) recai sobre ela. Um
detector que dispara em cima de ruído confabula; um que nunca dispara é
inútil. Valida-se por intervenção: injete um colapso conhecido, injete ruído
sem colapso, veja o que o relatório diz.

O detector construído aqui não sabe nada além da própria história de
população por tick: compara a média de uma janela recente (250 ticks) com a
de uma janela de referência mais antiga (250 ticks, separada por um vão de
500), e reporta "colapso ativo" se a queda relativa passar de 20%. O
ground truth é o imposto pigouviano das notas 15/21 — já validado, ligado no
**meio** de uma corrida já estável (um piloto não commitado achou que o
colapso do imposto, medido desde a semeadura, acontece quase todo nos
primeiros ~1000 ticks; testar detecção exige um choque que aconteça depois
de a população estar assentada).

**O detector não confabula — 0/8 falsos positivos em população saudável.**
Mas ao testar o colapso mais forte planejado (`c=0,30`), **2 das 8 seeds
sofreram extinção total** em 11–14 ticks — rápido demais para a janela de 250
ticks do detector sequer começar a refletir a queda. O detector não "errou"
essas duas: **ficou mudo**, pela mesma razão estrutural que a nota 06 achou no
eremita — não há biografia a narrar quando o sujeito da narrativa desaparece
antes de a régua conseguir olhar.

| # | predição (escrita antes) | resultado |
|---|---|---|
| **C0a** | sem imposto, detector não muda a simulação (CSV bit a bit) | ✅ |
| **C0b** | o detector nunca antecipa (`tick_disparo > início`, sempre) | ✅ |
| **C1** | colapso real forte: dispara em 8/8 seeds, latência < 500 ticks | ⚠️ **6/8** dispararam (latência média 54,3 ticks, dentro do previsto) — as **2 que não dispararam sofreram extinção total** em 11–14 ticks, rápido demais para a janela |
| **C2** | não-confabulação: ≤1/8 falsos positivos em ruído normal | ✅ **0/8** |
| **C3** | colapso + recuperação: dispara ≥7/8; ativo_no_fim=0 em ≥6/8 | ⚠️ **6/8** dispararam (as mesmas 2 extintas antes de t=5000); **6/6 (100%)** das que dispararam desligaram até o fim |

## 1. O teste central passou limpo: não confabula

| condição | seeds | disparos |
|---|---|---|
| C2 — vanilla, sem imposto, 6000 ticks | 8 | **0** |

Zero falsos positivos em 8 corridas de 6000 ticks cada (48 000 tick-observações
do detector). O ruído natural de população (`seed7.csv`: banda de ~306–324,
~3–4% de amplitude) fica muito abaixo do limiar de 20% — o detector não lê
flutuação saudável como colapso. É o resultado mais importante da nota, porque
é o que o ROADMAP pede primeiro: "um detector que dispara em cima de ruído
está confabulando." Este não confabulou.

## 2. O colapso real: detectado em 6/8 — e as outras 2 são o achado

| seed | resultado | latência | queda_max |
|---|---|---|---|
| 1 | **extinção total, tick 2014** | — | 0,0477 (nunca refletiu o colapso) |
| 2 | disparou | 55 | 0,7155 |
| 3 | disparou | 54 | 0,6565 |
| 4 | disparou | 53 | 0,8884 |
| 5 | disparou | 52 | 0,7828 |
| 6 | disparou | 54 | 0,8606 |
| 7 | disparou | 58 | 0,6725 |
| 8 | **extinção total, tick 2011** | — | 0,0386 (nunca refletiu o colapso) |

As 6 seeds que sobrevivem ao choque (crash de 65–89% de população, mas não
zero) são detectadas rápido e sem exceção — latência 52–58 ticks, um quinto do
limite pré-registrado (500). Mas seeds 1 e 8 não deram "falso negativo" no
sentido usual: elas foram a **UNICA(s)** que se extinguiram **por completo**
— `"Silêncio. A população se extinguiu no tick 2014"` (seed 1) e no tick 2011
(seed 8) — 11 e 14 ticks depois do imposto ligar em `t=2000`.

**O motivo é estrutural, não um bug.** A janela "recente" do detector
precisa de 250 ticks para se atualizar. Com extinção em 11–14 ticks, o
programa termina antes de a janela conter tempo suficiente de dados
pós-colapso — o cálculo do `queda_max` registrado (0,04–0,05) é só o ruído do
período de assentamento inicial, ANTES do imposto sequer ligar (tick
~1046–1055, quando a janela completou seu primeiro ciclo). O detector nunca
teve a chance de olhar para o abismo, porque o abismo engoliu o mundo antes
da régua completar uma volta.

Os oito seeds carregavam imposto comparável na hora do choque (`ed` — a
profundidade efetiva média em `t=2000` — variando de 4,7 a 7,5 nas 8 seeds,
`imp = 0,30×ed` entre 1,41 e 2,25, várias vezes o metabolismo basal de 0,35);
não há um limiar simples de traço que separe as duas extintas das seis
sobreviventes — a diferença entre "crash duro que sobrevive" e "silêncio
total" parece depender de mais do que a média populacional dos traços no
instante do choque (heterogeneidade individual, população momentânea, sorte
de poucos ticks). Não isolado aqui — ver Ressalvas.

## 3. A recuperação: o relatório acompanha o retorno, não fica preso

| | dispararam | desligaram até o fim |
|---|---|---|
| C3 (imposto liga 2000, desliga 5000, total 8000 ticks) | 6/8 | **6/6 (100%)** |

As mesmas duas seeds que se extinguem em C1 se extinguem aqui também (antes
mesmo de `t=5000`, quando o imposto seria removido — `CUSTO_H_FIM` nunca chega
a importar para elas). Das 6 que sobrevivem ao choque, **todas** têm o sinal
de "colapso ativo" desligado até o fim da corrida — 3000 ticks depois da
remoção do imposto, tempo mais que suficiente para a população voltar perto
do baseline (confirmado num piloto: recuperação de ~115 para ~320 em cerca de
1000 ticks). O detector não fica preso numa narrativa: ele mede a TRANSIÇÃO
(colapso *em curso*), não a distância permanente a um baseline histórico —
por desenho, e é isso que o item C3 confirma.

## 4. Ressalvas honestas

- **A extinção não foi orçada — e devia ter sido.** O pré-registro previa
  8/8 disparos assumindo que todo choque forte seria detectável; não
  considerou que o choque pudesse ser tão forte a ponto de a população
  desaparecer mais rápido que a régua reage. É o mesmo tipo de correção que a
  nota 23 teve em δ=0,80: a predição errou por otimismo sobre a nitidez do
  sinal, não por o mecanismo estar errado.
- **O paralelo com a nota 06 é uma leitura, não uma prova.** A nota 06 achou
  que "o eremita fica mudo" porque um self de um motivo só não tem biografia
  para o intérprete leigo relatar (`κ≈0,005`). Aqui a mudez é de outra
  natureza — não falta motivo, falta TEMPO: a régua (janela de 250 ticks)
  é mais lenta que o evento que deveria medir. São mecanismos diferentes que
  produzem o mesmo sintoma (silêncio do relato); a semelhança é temática, não
  estrutural.
- **Por que 2 de 8 e não outra fração** não foi isolado. A profundidade
  efetiva média na hora do choque varia bastante entre seeds (4,7–7,5) sem
  separar limpo quem se extingue de quem sobrevive — isolar o fator (traço
  médio? variância entre indivíduos? população no instante exato?) exigiria
  um desenho novo, não construído aqui.
- **Um único limiar (20%), uma única janela (250/500/250).** Não foi
  variado. Uma janela mais curta teria mais chance de pegar a extinção rápida
  (menos tempo para preencher) às custas de mais sensibilidade a ruído — o
  trade-off não foi explorado.
- **Um único custo forte (`c=0,30`).** Não há dose-resposta aqui — ficou para
  uma nota futura testar se custos mais brandos (que colapsam mas não
  extinguem, pela dose-resposta já medida nas notas 15/21) são detectados sem
  o problema da extinção-rápida-demais.
- **O detector mede população, o mais simples dos sinais.** "Emergiu uma
  nova estratégia" e "há duas linhagens distintas" (os outros dois exemplos
  do ROADMAP) são módulos futuros deste mesmo eixo — o segundo já tem
  praticamente toda a maquinaria pronta na nota 23 (histograma + classificação
  por região), só falta rodá-la "ao vivo" dentro de uma única simulação em vez
  de post-hoc.

## 5. Método

- **Detector:** `col_hist[1000]`, ring buffer de população por tick (leitura
  pura — não consome RNG, não escreve estado da simulação; C0a confirma CSV
  `--log` bit a bit idêntico ao vanilla). `recente` = média dos últimos 250
  ticks; `referência` = média de um bloco de 250 ticks terminando 500 ticks
  antes de `recente` começar. `colapso ativo` = queda relativa ≥ 0,20.
- **Ground truth:** o termo do imposto pigouviano, idêntico ao das notas
  15/21 (`custo_h × min(horizonte, 1/(1−desconto))`), mas ligando/desligando
  em ticks controlados por `CUSTO_H_INICIO`/`CUSTO_H_FIM` em vez de vigorar
  desde a semeadura — captura o global `imp_t` (a função de aplicação não
  recebe `t`).
- **C0b:** verificação estrutural, não estatística — o detector só vê o
  passado (ring buffer), então `tick_disparo > início` é garantido pela
  própria aritmética, a menos que haja erro de indexação.
- **Dataset** `detector-colapso.csv`: uma linha por condição×seed —
  `condicao,inicio,seed,disparou,tick_disparo,queda_max,tick_queda_max,
  ativo_no_fim`.
