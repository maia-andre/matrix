# Nota 35 — O nulo do classificador: o desenho fabrica 30%, T2 mede 66,7%, e a aposta do pré-registro estava errada

**Data:** 2026-08-09
**Pré-registro:** `ROADMAP.md` §4.8, commit `c2bf422` — antes de rodar.
**Construído em:** `153da52` (script commitado antes de rodar).
**Serve ao:** mede, pela primeira vez, a **taxa de base** que as notas 32, 33 e 34
declararam três vezes como ameaça à validade e nunca mediram. Não é um painel do
mundo — é um painel da **régua**. Nenhum mecanismo novo entra no `main.c` do repo:
os dois braços são patch temporário compilado em tmpdir (técnica das notas 23/24/25).
**Reproduzir:** `sh papers/notes/35-nulo-do-classificador.sh` (~2h20 de máquina
acordada, 80 corridas de 30 000 ticks, sequencial por desenho)

---

## Resumo

As notas 32–34 mediram T2 (`peso_arrependimento` `−2,0` × `2,0`) três vezes e
sempre esbarraram na mesma frase, declarada mas nunca quantificada: se o efeito
fundador for estrutural ao harness, nenhum n de seeds separa um sinal pequeno de
"uma taxa de base nunca medida num traço comprovadamente neutro". Esta nota mede
essa taxa.

O primeiro resultado veio **antes de rodar qualquer coisa**, da álgebra: o nulo
intuitivo — ablar o mecanismo e contar quantas seeds ainda saem REAL — é
**degenerado**. Com `remorso ≡ 0` o traço deixa de entrar em `utilidade_sigma`, as
duas montagens espelhadas viram a mesma simulação bit a bit, e o classificador
**nunca** pode dizer REAL. Zero por identidade, não por medição. Disso saiu a
correção que reorganizou o teste: **REAL exige que o traço seja causalmente ativo,
não que ele seja vantajoso** — e um traço ativo mas empatado decorrelaciona as
montagens, fazendo cada uma sortear um vencedor. Duas moedas honestas concordam
metade das vezes: a taxa de base a temer não era ≈0%, era ≈50%.

Os dois braços pré-registrados a partir daí:

- **N1 (nulo inerte, 10 seeds):** confirma a álgebra nas três predições, exatas —
  P1 10/10, P2 10/10, P3 **0/10 REAL**. E entrega de brinde a primeira medida do
  confundidor: com o traço **provadamente inerte**, 9 das 10 seeds terminam com uma
  classe de paridade tomando a população quase inteira, por deriva pura.
- **N2 (nulo ativo, as mesmas 30 seeds de T2):** mesma dose, direção destruída.
  **REAL = 9/30 = 30%** — **abaixo** da banda pré-registrada (10–20/30). P4 falhou.

E o número que a nota existe para produzir: **T2 66,7% × nulo 30,0%, Fisher exato
bilateral p = 0,0092**. Ou seja, **a aposta que eu declarei no §4.8 estava errada**.
Eu escrevi, antes de rodar, que esperava T2 indistinguível do nulo, "o achado mais
forte contra Q5 deste fio". É o contrário: T2 está significativamente acima do que
este desenho fabrica sozinho. E a direção — os 20/20 da nota 34 — **sobrevive**: no
nulo ela é uma moeda (3/9 para `−2,0`, p = 0,51), e T2 contra o nulo dá p = 0,0002.

**O veredito de T2 não muda.** O corte era 21/30, o pool deu 20/30, e mover critério
depois de ver o placar é exatamente o que a §7 da `FILOSOFIA_v3` proíbe. O que muda
é o que "não decide" **significa**: já não é "sinal fraco demais para distinguir de
ruído" — é "sinal real medido contra um corte que foi escolhido sem saber onde
ficava o zero".

## 1. N1 — a álgebra vale, e o confundidor é fixação quase total

Ablação natural do remorso (`remorso[i] = 0` **depois** do cálculo, que fica de pé;
`prever_valor` não consome RNG, então a ablação é inócua ao fluxo). 10 seeds, os
valores de T2, 30 000 ticks, as duas montagens espelhadas.

| seed | A → `arrep_m` | B → `arrep_m` | P1 | P2 (desvio máx.) | classe |
|---|---|---|---|---|---|
| 1 | 2,000 | −2,000 | OK | 0,000000 | FUNDADOR |
| 2 | 1,941 | −1,941 | OK | 0,000000 | FUNDADOR |
| 3 | 2,000 | −2,000 | OK | 0,000000 | FUNDADOR |
| 4 | −1,983 | 1,983 | OK | 0,000000 | FUNDADOR |
| 5 | 1,986 | −1,986 | OK | 0,000000 | FUNDADOR |
| 6 | −1,976 | 1,976 | OK | 0,000000 | FUNDADOR |
| 7 | 1,987 | −1,987 | OK | 0,000000 | FUNDADOR |
| 8 | −2,000 | 2,000 | OK | 0,000000 | FUNDADOR |
| 9 | −0,621 | 0,621 | OK | 0,000000 | FUNDADOR |
| 10 | 2,000 | −2,000 | OK | 0,000000 | FUNDADOR |

**P1 ✅ 10/10** — os CSVs de A e B são idênticos em **todas** as 24 colunas restantes
(inclusive `arrep_sd`, que não depende do rótulo), verificado por `cmp` byte a byte
depois de cortar a coluna 24. **P2 ✅ 10/10** — `arrep_m(B) = −arrep_m(A)` em todos
os 30 000 ticks de todas as seeds, desvio máximo **0,000000**. **P3 ✅ 0/10 REAL.**

O braço existia só para verificar a álgebra, e verificou. Mas a coluna do meio diz
uma coisa que nenhuma nota anterior tinha medido: **com o traço provadamente inerte,
`|arrep_m|` termina acima de 1,94 em nove das dez seeds** — só a seed 9 fica
misturada (0,62). Traduzindo: numa corrida onde as duas metades da população são,
por construção, causalmente idênticas, **uma delas toma quase tudo mesmo assim**. O
"efeito fundador" que as notas 32–34 vinham tratando como confundidor não é um viés
modesto sobre uma competição justa; neste harness, a deriva sozinha leva o sistema à
fixação quase completa. É a medida mais concreta já feita de por que este desenho
tem tão pouca potência — e ela veio do braço que eu esperava que fosse só burocracia.

## 2. N2 — o nulo ativo: 30%, não 50%

Mesmo `main.c`, mesmo harness, mesmos valores, as **mesmas 30 seeds de T2**, mesmas
montagens, mesmo classificador. A única mudança: o termo do arrependimento em
`utilidade_sigma` ganha um sinal ±1 por célula candidata, de um `hash2` com salt
próprio (um campo arbitrário por seed, sem relação com o campo de comida). Mesma
magnitude, mesma frequência, **direção destruída** — cada valor prefere espaço
aberto em metade das células e lotação na outra metade, em espelho exato do outro.

REAL nas seeds **2, 12, 13, 15, 16, 19, 24, 25, 29** — **9 de 30 = 30,0%**.

**P4 falhou.** Eu havia declarado 15/30 como teto esperado e 10–20/30 como banda;
9/30 fica **fora, abaixo**. Registro a falha em vez de arredondar para dentro: o
raciocínio das "duas moedas" superestimou a decorrelação. O motivo é visível agora
que N1 existe — as duas montagens partilham mundo, seed e posições iniciais, então a
paridade que a deriva favorece tende a vencer nas duas mesmo quando o traço está
ativo, e isso empurra para FUNDADOR. A intuição estava na direção certa (declarei
que decorrelação parcial puxaria para baixo); a magnitude estava errada, de novo, do
mesmo jeito que a nota 31 errou a magnitude da desconfiança por 5–6×.

## 3. P5 — T2 está acima do nulo, e a aposta do pré-registro estava errada

|  | REAL | FUNDADOR | taxa |
|---|---|---|---|
| **T2** (notas 33+34) | 20 | 10 | 66,7% |
| **N2** (nulo ativo) | 9 | 21 | 30,0% |

**Fisher exato bilateral: p = 0,0092.** Pelo pré-registro (§4.8), a leitura que
dispara é a primeira das três: *o desenho quase não fabrica REAL; os 20/30 de T2 são
sinal; o "não decide" vem do corte, não de ausência de sinal.*

E eu tinha apostado no contrário. O §4.8 diz, textualmente, que a leitura do meio
(T2 indistinguível do nulo) era "o que eu aposto, pela álgebra acima". A álgebra que
me levou até lá estava certa em tudo que era dedutível — o nulo degenerado é mesmo
zero, o nulo ativo é mesmo maior que zero — e errada exatamente na parte que só a
medição resolvia: **onde** o nulo ativo cai. Deduzi 50%, medi 30%, e 66,7% contra
30% é outra história que 66,7% contra 50%. É o terceiro pré-registro seguido deste
fio em que a direção que eu aposto não é a que sai (notas 30, 31, e agora 35) — e o
padrão já é informativo por si: minhas intuições sobre este harness erram
sistematicamente para o lado de "o efeito vai ser menor do que é".

Dois companheiros **descritivos, não pré-registrados**, calculados fora do script
que produziu o dado (segunda régua, regra 8 do protocolo):

- **Pareado.** T2 e N2 rodaram nas mesmas 30 seeds, então dá para olhar par a par:
  REAL nos dois = 7 (seeds 2, 12, 13, 15, 16, 24, 25); REAL só em T2 = **13**; REAL
  só em N2 = **2** (seeds 19, 29); FUNDADOR nos dois = 8. McNemar exato sobre os 15
  discordantes: **p = 0,0074** — o teste pareado concorda com o Fisher
  pré-registrado, então nada depende de qual eu tivesse escolhido.
- **T2 contra a base medida.** Binomial unilateral, `P(X ≥ 20 | n=30, p=0,30) =
  3,7·10⁻⁵`. E o corte que uma taxa de base de 30% pediria, a 5% unilateral, seria
  **14/30** — não os 21/30 que o §4.6 pré-registrou a partir de uma proporção
  escolhida por intuição (70%).

## 4. P6 — a direção do nulo é uma moeda, e o 20/20 da nota 34 sobrevive

Este era o único item do pré-registro capaz de **derrubar um número já publicado**:
a nota 34 registrou que as 20 corridas REAL de T2 favorecem `−2,0` sem uma única
exceção, e eu declarei que, se o nulo também pendesse inteiro para `−2,0`, aquilo
seria assinatura do desenho e a nota 34 precisaria de errata.

Não pendeu. Das 9 corridas REAL de N2, **3 favorecem `−2,0` e 6 favorecem `2,0`** —
binomial bilateral contra 50/50 dá **p = 0,51**, ou seja, indistinguível de uma
moeda, exatamente como previsto. E T2 (20/20) contra o nulo (3/9): **Fisher exato
bilateral p = 0,0002**.

**A nota 34 não precisa de errata.** A consistência direcional que ela registrou
como "achado que o critério não pergunta" agora tem um nulo medido embaixo, e é o
número mais forte que este fio inteiro produziu — mais forte que a própria taxa
REAL, porque o desenho **não** tem preferência de direção quando a vantagem é
removida, e tem 20/20 quando ela não é.

## 5. O que isso faz — e o que não faz — com o veredito de T2

**Não muda o veredito.** O corte de T2 foi pré-registrado em 21/30 (§4.7), o pool deu
20/30, e T2 segue **sem decidir**. A tentação de dizer "mas agora sabemos que o corte
estava errado, então T2 confirma" é precisamente o movimento que a §7 da
`FILOSOFIA_v3` chama de mover a régua depois de ver o placar. O corte fica.

**Muda o que "não decide" significa, e isso não é pouco.** Até esta nota, T2 em
20/30 era compatível com duas histórias: sinal real pequeno, ou artefato de um
desenho que fabrica REAL sozinho. A segunda história agora está medida e vale 30% —
e 20/30 contra 30% tem `p = 3,7·10⁻⁵`. O que sobra é a primeira história, com o
veredito formal preservado como registro histórico de um corte mal calibrado.

**O que isso faz com Q5 (nota 30).** A convergência para `peso_arrependimento`
negativo, que a nota 30 mediu sob deriva livre e a nota 32 pôs em dúvida, sai desta
nota mais forte do que entrou: a competição pareada produz REAL acima do nulo
(p = 0,0092) e uma direção que o nulo não produz (p = 0,0002). A hipótese mecânica
da nota 30 — persistir onde a disputa valia a pena paga mais do que fugir para uma
célula vazia só por estar vazia — continua **não provada**, mas já não é uma leitura
apoiada só na média sob mutação livre.

**T3 continua sem rodar.** O gate pré-registrado é o pool de T2 confirmar, e ele não
confirmou. Esta nota não abre o gate — ela documenta que o gate estava calibrado
contra um zero imaginário.

## Ameaças à validade

- **N2 não é um empate comprovado — é a direção destruída.** Declarado no §4.8 antes
  de rodar, e continua sendo a fraqueza central: não existe neste projeto um traço
  com vantagem medida como nula, e inventar um exigiria mecanismo novo que nenhum
  teste nomeado pede. O que N2 garante é que **nenhum dos dois valores pode ser
  sistematicamente melhor** (a preferência de cada um é o espelho exato da do outro
  sobre um campo arbitrário); o que ele não garante é que a **perturbação de
  trajetória** tenha o mesmo tamanho que a de T2. O termo de T2 é espacialmente
  **coerente** (multiplica `espaco`, que é suave), o de N2 troca de sinal célula a
  célula. Se coerência decorrelacionar as montagens mais que incoerência de mesma
  magnitude, parte do vão 30% → 66,7% é isso, não vantagem. **Não medido aqui** — o
  teste que fecharia isso é comparar quanto as trajetórias de A e B divergem em cada
  braço, e ele exige guardar as séries que este script descarta.
- **9 corridas REAL é uma base pequena para P6.** O `p = 0,51` de N2 contra 50/50 não
  prova equilíbrio — só diz que 3/9 não é distinguível de moeda. O número que carrega
  peso é a comparação T2 × N2 (p = 0,0002), que não depende de N2 ser exatamente
  50/50, apenas de não ser 100% para `−2,0`.
- **P4 falhou, e falhas de banda são dado.** 9/30 fora da banda 10–20/30 diz que meu
  modelo da decorrelação é grosseiro. Ele não invalida P5 (que compara duas taxas
  medidas, sem depender do valor previsto), mas invalida qualquer uso futuro do "50%
  teórico" como referência: a referência é **30% medido**, neste harness, neste
  desenho, com estas 30 seeds.
- **As mesmas ameaças estruturais das notas 30–34** seguem de pé: `n_blocos % 2` não
  é sorteio espacialmente independente, e agora sabemos o tamanho do estrago (§1).

## O que ficou em aberto

O fio do arrependimento tem, pela primeira vez, um zero medido embaixo dele. Isso
reorganiza os dois caminhos que as notas 33/34 deixaram abertos e que esta nota
continua não escolhendo:

1. **Um painel novo com o corte pré-registrado contra o nulo medido** (14/30 a 5%
   unilateral, não 21/30 escolhido por intuição). Seria a primeira vez que este fio
   pergunta a T2 com um critério calibrado — e o cálculo de potência agora é possível,
   coisa que nenhuma nota anterior podia fazer.
2. **População maior**, que ataca a causa em vez do sintoma: o §1 mostra que o
   problema é fixação por deriva quase total, e é isso que uma população maior
   diluiria.

E um item novo, que esta nota criou: **medir a divergência de trajetória entre as
montagens** nos dois braços, para saber se o vão medido é vantagem ou coerência.
É o único jeito de fechar a ameaça central acima, e é barato — muda o que o script
guarda, não o que ele roda.
