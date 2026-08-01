# Nota 34 — A segunda extensão de T2 chega a 20/30, uma seed abaixo do limiar — e a direção nunca erra, em 30 seeds

**Data:** 2026-08-01
**Pré-registro:** `ROADMAP.md` §4.7, commit `ce0d00b` — antes de rodar.
**Construído em:** `597a4a9` (script commitado antes de rodar).
**Serve ao:** estende a nota 33 (§4.6), que fechou T1 (fundador puro) mas deixou T2
(`−2,0` × `2,0`) em 6/10, sub-limiar. Nenhum mecanismo novo — mesmo `main.c` canônico,
mesmo harness `invasao` das notas 30/32/33, só T2 (T1 já está decidido).
**Reproduzir:** `sh papers/notes/34-invasao-arrependimento-t2-20-seeds.sh` (~50 min,
sequencial — sem paralelização por desenho, `CLAUDE.md`)

---

## Resumo

A nota 33 deixou T2 sem decidir: 6/10 REAL, abaixo do limiar de confirmação (7/10),
mas as seis corridas que escapavam do efeito fundador concordavam todas na direção
que a nota 30 (Q5) apostara. O pré-registro desta extensão (§4.7) prometeu 20 seeds
novas e sequenciais (`11..30`) e dois números, declarados antes de rodar: o
**standalone** (as 20 novas sozinhas) e o **pool** (as 20 somadas às 10 já publicadas),
com o pool decidindo se os dois discordassem.

Os dois números discordam. **Standalone: 14/20 REAL (70%) → CONFIRMA**, exatamente no
limiar. **Pool: 20/30 REAL (66,7%) → NÃO DECIDE**, a **uma seed** do limiar de
confirmação (21/30). Pelo critério pré-registrado, o pool decide: **T2 continua sem
decidir** — mas a distância ao limiar encolheu de 1/10 (nota 33) para 1/30 (esta nota).
T3 não roda: o critério (pool confirmar) não foi atendido. E um achado que o critério
de proporção não captura, mas que os dados mostram sem exceção: das 20 corridas
classificadas REAL nesta nota, **todas as 20** — somadas às 6 da nota 33, **as 20
corridas REAL em 30 seeds** — favorecem `−2,0`. Nenhuma, em nenhuma das duas notas,
favoreceu `2,0`.

## 1. As 20 seeds novas (11–30)

`arrep_m` (col. 24) em `t=30000`. Montagem A: `−2,0` par / `2,0` ímpar. Montagem B:
`2,0` par / `−2,0` ímpar (o mesmo desenho das notas 30/32/33; a fórmula de classificação
é a única — sem o bug de `wA`≠`wB` que a nota 33 pegou e corrigiu).

| seed | A → `arrep_m` | B → `arrep_m` | quem venceu as duas | classe |
|---|---|---|---|---|
| 11 | −2,000 | −2,000 | `−2,0` vence as duas | **REAL** |
| 12 | −2,000 | −1,987 | `−2,0` vence as duas | **REAL** |
| 13 | −2,000 | −2,000 | `−2,0` vence as duas | **REAL** |
| 14 | 2,000  | −2,000 | ÍMPAR | FUNDADOR |
| 15 | −1,927 | −2,000 | `−2,0` vence as duas | **REAL** |
| 16 | −1,950 | −2,000 | `−2,0` vence as duas | **REAL** |
| 17 | 2,000  | −2,000 | ÍMPAR | FUNDADOR |
| 18 | 1,785  | −2,000 | ÍMPAR | FUNDADOR |
| 19 | 1,657  | −1,986 | ÍMPAR | FUNDADOR |
| 20 | −2,000 | −1,975 | `−2,0` vence as duas | **REAL** |
| 21 | −1,323 | −1,166 | `−2,0` vence as duas | **REAL** |
| 22 | −2,000 | −2,000 | `−2,0` vence as duas | **REAL** |
| 23 | −1,663 | −2,000 | `−2,0` vence as duas | **REAL** |
| 24 | −1,851 | −2,000 | `−2,0` vence as duas | **REAL** |
| 25 | −0,720 | −2,000 | `−2,0` vence as duas | **REAL** |
| 26 | −2,000 | 1,502  | PAR | FUNDADOR |
| 27 | −2,000 | −2,000 | `−2,0` vence as duas | **REAL** |
| 28 | −2,000 | −2,000 | `−2,0` vence as duas | **REAL** |
| 29 | −1,989 | 1,535  | PAR | FUNDADOR |
| 30 | −1,971 | −1,926 | `−2,0` vence as duas | **REAL** |

Nenhuma linha fica perto de um empate (`mid = 0,0`): a mais próxima é a seed 25 (montagem
A, `−0,720`), ainda inequivocamente do lado negativo. Diferente da seed 8 de T1 na nota
33 (48,9%, quase cara-ou-coroa), este painel não tem nenhuma classificação de margem
fina.

## 2. Standalone confirma; pool não — o pré-registro decide pelo pool

**Standalone (20 novas): REAL = 14/20 = 70% → CONFIRMA** (≥14/20, a banda declarada em
§4.7).

**Pool (20 novas + 6/10 já publicadas na nota 33): REAL = 20/30 = 66,7% → NÃO DECIDE**
(10–20/30; o limiar de confirmação era 21/30 — **uma seed** a mais teria confirmado).

O §4.7 declarou, antes de rodar, que o pool decidiria se os dois discordassem, porque
tem mais poder estatístico. Aplicando a regra sem exceção: **T2 não decide** — pela
segunda vez, mas agora a uma seed do limiar, não a quatro (nota 33: 6/10 faltava 1/10
para a banda de confirmação também, mas numa amostra três vezes menor). Não movo o
critério depois de ver o número: o pré-registro pedia o pool, e o pool diz não decide.

**T3 não roda** (condicional a T1 e/ou T2 confirmarem pelo critério do pool; nenhum dos
dois confirma).

## 3. O achado que o critério de proporção não pergunta: a direção nunca erra

O critério REAL/FUNDADOR é cego a *qual* valor vence quando vence — só pergunta se é o
valor (independente de paridade) ou a paridade que decide. Uma pergunta adjacente, mais
simples, é: **das corridas em que o valor vence (REAL), qual valor vence?** Juntando as
duas notas: 6 REAL na nota 33, todas `−2,0`; 14 REAL nesta nota, todas `−2,0`. **20 de
20 corridas REAL, nas duas notas, favorecem `−2,0` — nenhuma exceção, em 30 seeds.**

Isso não estava no critério pré-registrado e não muda o veredito de T2 (que é sobre a
*proporção* REAL, não sobre a *direção* condicional a REAL) — mas é um sinal muito mais
forte, na direção que Q5 apostou, do que "não decide" sozinho comunica. A leitura mais
honesta: este desenho não separa com confiança "há vantagem competitiva real" de "é só
efeito fundador" (a pergunta que T2 pré-registrou) — mas **toda vez que o desenho
consegue enxergar através do confundidor, o que ele vê aponta para o mesmo lado**, sem
uma única corrida na direção oposta em 30 tentativas.

## Ameaças à validade

- **O pool ficou a uma seed do limiar** — um resultado assim sensível ao corte convida a
  perguntar se `70%`/`30%` são os números certos, e não há resposta melhor que a mesma
  disciplina da nota 33 (§7 de `FILOSOFIA_v3`): o corte foi escolhido antes de rodar, e
  não se move depois de ver o placar. Se se mover, é preciso dizer, em voz alta, que
  moveu.
- **A ausência de exceções em 20/20 não é o mesmo que magnitude grande.** Metade das
  corridas REAL nesta nota fixou a quase 100% (`−2,000` exato ou próximo); a outra
  metade converge de forma menos completa (seed 21: `−1,32`/`−1,17`; seed 25: `−0,72` em
  A). A direção é consistente; o tamanho do efeito, quando existe, varia.
- **As mesmas ameaças estruturais das notas 30/32/33**: `n_blocos % 2` não é um sorteio
  espacialmente independente; 30 seeds continua sendo pouco se o efeito fundador for
  estrutural ao harness e a vantagem real, pequena. Esta nota não resolve essa dúvida —
  só reduz a distância ao corte de 4/10 para 1/30.

## O que ficou em aberto

T2 segue sem decidir pelo critério pré-registrado, mas mais perto de confirmar do que
em qualquer rodada anterior, e com uma consistência direcional (20/20) que nenhuma nota
anterior deste fio tinha alcançado. Os dois caminhos que a nota 33 já apontava —
painel ainda maior ou população maior — continuam abertos; esta nota não escolhe entre
eles. Se um painel futuro repetir uma proporção REAL parecida (≈66–70%) e a direção
seguir sem exceção, o argumento a favor de "há uma vantagem real, pequena, quase sempre
afogada pelo efeito fundador" fica mais forte do que o critério binário por si só
comunica — mas isso é uma leitura para a próxima nota, não para esta.
