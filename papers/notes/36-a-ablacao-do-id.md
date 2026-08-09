# Nota 36 — A ablação do id: a palavra mais antiga não paga a entrada, e o controle de sanidade reencontrou o piso do `float32` um andar acima

**Data:** 2026-08-09
**Pré-registro:** `ROADMAP.md` §4.9, commit `4a86975` — antes de rodar. Com uma
**errata do próprio pré-registro** (commit `74350d3`, ainda antes do painel) e um
**adendo post-hoc** (D5, commit `6afc312`, depois de D4 falhar).
**Construído em:** `74350d3` / `6afc312` (script commitado antes de cada rodada).
**Serve ao:** `FILOSOFIA_v3` §3 — a última das cinco palavras emprestadas que
nunca pagou a entrada que a própria seção cobra. É o último item de pesquisa
antes de a v3 poder ser encerrada.
**Reproduzir:** `sh papers/notes/36-a-ablacao-do-id.sh` (~93 min, 7 condições ×
8 seeds × 30 000 ticks, sequencial por desenho)

---

## Resumo

A §3 estabelece a regra de admissão de toda palavra mental — *"que ablação a
zera? e ela carrega comportamento? sem resposta às duas, é decoração"* — e depois
admite por escrito que uma das cinco não a paga: *"o id existe, e é o único que
nunca foi posto à prova"*. Esta nota põe.

**O resultado principal veio da álgebra, antes da máquina, e não depende do que
as corridas deram.** A decisão é um `argmax` sobre células candidatas, e
`(1 + urgencia · fome)` é um fator **positivo e comum a todas elas** — `urgencia`
e `fome` são do bloco, não da célula. Logo `urgencia` **não tem canal próprio**:
ela não consegue empurrar o bloco *em direção* à comida, porque reescalar todas
as candidatas pelo mesmo fator não muda ordem nenhuma. Tudo o que ela faz é
**encolher os termos que não são comida**. Na língua da seção: **o id não é um
empurrão em direção à comida; é um botão que abaixa o volume de tudo o que não é
comida.**

**E o painel deu negativo no critério declarado.** Com o canal do id mantido
aberto à força (`peso_espaco` pregado no valor inicial), ablacionar o id
**não reduz a população**: 2/8 seeds, contra as ≥6/8 pré-registradas. A
diferença na janela cedo é cara-ou-coroa (4/8), e a comparação de magnitudes de
D2 ficou em 5/8, abaixo do corte. Pelo critério que a §3 cobra e que eu declarei
antes de rodar, **o id não carrega comportamento em população** — e a §3 tem de
dizer isso em voz alta em vez de fechar a v3 fingindo que a dívida foi paga.

**O controle de sanidade falhou e a investigação achou o suspeito de sempre.**
D4 previa que, num mundo onde os termos não-comida estão mortos, `urgencia` seria
exatamente inerte e as duas condições sairiam idênticas. Saíram idênticas em
4/8. A leitura do código descartou a hipótese preocupante — `urgencia` aparece em
**exatamente um** lugar do `main.c`, e `prever_valor_sigma` não a lê —, e o
adendo post-hoc D5 confirmou a alternativa: com o fator do id trocado por **2,0**
(multiplicação exata em `float32`, incapaz de criar empate), as duas condições
são idênticas em **8/8**. A divergência de D4 é **arredondamento**, não canal:
`float32` não inverte ordens, **cria empates** — o mecanismo que a nota 10
documentou para a `agencia`, reencontrado aqui um andar acima, agora afetando
a *decisão* e não só o mostrador.

## 1. A álgebra, e por que ela vem antes da máquina

A regra 9 do protocolo (paga pela nota 35) manda fazer a álgebra do controle
antes de gastar máquina. Feita aqui, ela entregou o resultado principal de graça.
A utilidade de uma célula `k` é

```
u(k) = comida_prev(k)·(1 + urgencia·fome)
     + peso_espaco·espaco(k)·(1 − fome)
     + peso_arrependimento·remorso·espaco(k)
```

Dividindo por `(1 + urgencia·fome)` — positivo, e **igual para todas as
candidatas**, porque depende só do bloco —, o ranking é idêntico ao de

```
nota(k) = comida_prev(k) + [ peso_espaco·espaco(k)·(1 − fome)
                           + peso_arrependimento·remorso·espaco(k) ] / (1 + urgencia·fome)
```

Três consequências, todas declaradas no §4.9 antes de rodar:

1. **O id não tem canal próprio.** Ele só existe como divisor dos outros motivos.
2. **Se os outros motivos morrem, o id é exatamente inerte** — o que dá um
   controle de sanidade bit a bit (D4), não uma estimativa.
3. **A seleção fecha o canal do id sozinha.** A nota 12 mediu `peso_espaco`
   caindo de ~2,9 para 0,095 ± 0,018 em 50 seeds; medido aqui nas 8 seeds de
   controle, ele fecha em **0,255** (mín. 0,144, máx. 0,429) partindo de ~2,9.
   Isto é: **a sombra da §3 — a agência renegada — é também a aposentadoria do
   id.** A mesma variável, o mesmo processo, dois parágrafos que a seção
   escrevia como se fossem independentes.

## 2. D1 — o id não carrega comportamento em população

`fesp` (`peso_espaco` pregado, canal aberto à força) × `fesp_id0` (o mesmo, com
`urgencia ≡ 0`). População e energia média em `t = 29999`:

| seed | `fesp` pop | `fesp_id0` pop | id0 pior? | `fesp` E | `fesp_id0` E | Δ E |
|---|---|---|---|---|---|---|
| 1 | 222 | 218 | **sim** | 7,135 | 7,384 | +0,249 |
| 2 | 263 | 270 | não | 7,501 | 6,255 | −1,246 |
| 3 | 318 | 327 | não | 6,362 | 6,208 | −0,154 |
| 4 | 249 | 249 | não | 7,324 | 6,050 | −1,274 |
| 5 | 292 | 294 | não | 7,050 | 6,793 | −0,257 |
| 6 | 325 | 329 | não | 7,149 | 6,323 | −0,826 |
| 7 | 316 | 300 | **sim** | 7,077 | 6,691 | −0,386 |
| 8 | 265 | 271 | não | 6,777 | 6,579 | −0,198 |

**D1 = 2/8 → falha.** O pré-registro pedia ≥6/8 e declarou que 4–5/8 seria "não
decide"; 2/8 não é nem isso. A população não sente a falta do id.

**D2 = 5/8** (predito ≥6/8): a diferença que o id faz na evolução normal não é
confiavelmente menor que a que faz com o canal aberto — **não confirma**, embora
a premissa da consequência 3 (o canal fecha: `esp_m` final ≈ 0,25) esteja
medida e de pé. **D3 = 4/8**: na janela cedo (`t = 200`), com `peso_espaco` ainda
em ~2,9, a direção é cara-ou-coroa. Nenhuma das três janelas salva o id.

### O companheiro descritivo, e por que ele NÃO vira o veredito

A tabela acima carrega uma segunda coluna que o script imprime e que eu **não**
pré-registrei: a energia média. Ela vai na direção oposta, e com força — o id
intacto dá blocos **mais bem alimentados em 7 das 8 seeds** (binomial bilateral
`p = 0,070`), com diferenças de até −1,27. A leitura mecânica é limpa: sem
urgência, um bloco faminto não prioriza comida o bastante, mas a **população**
é regulada pela oferta de comida do mundo, não pela eficiência de cada bloco —
então o custo aparece em quanto cada um come, não em quantos existem.

**Isso não muda o veredito, e registro por quê.** Eu declarei população antes de
rodar. Trocar de observável depois de ver o dado é exatamente o movimento que a
§7 da `FILOSOFIA_v3` proíbe, e não vou fazê-lo por ele ser conveniente — nem
mesmo com `p = 0,070`, que aliás nem cruza 0,05. O que este número é: um
**candidato a pré-registro futuro**, e uma pista de que o mecanismo é real mas se
expressa em outro lugar que não o que eu apostei.

## 3. D4 falhou, D5 explicou: o piso do `float32`, um andar acima

D4 previa identidade bit a bit entre `deg` e `deg_id0` (ambas com `peso_espaco ≡
0` e `remorso ≡ 0` — os dois termos que o id divide). Resultado: **4/8**. Em três
das quatro seeds divergentes, a diferença alcança colunas **comportamentais**
(população, energia, comida), não só mostradores.

A investigação que o próprio pré-registro exigia começou por leitura de código, e
descartou o cenário ruim: `urgencia` aparece em **exatamente um** lugar do
`main.c` (o termo de `utilidade_sigma`), e `prever_valor_sigma` — o único outro
candidato plausível — **não a lê**. Não existe canal causal não enumerado.

Sobrou a explicação que este projeto já pagou uma vez. Multiplicar todas as
candidatas por `(1 + urgencia·fome)` preserva a ordem em ℝ, mas em `float32` pode
**fundir duas candidatas distintas num empate** — e `melhor_celula` desempata
por ordem de varredura, o que muda a decisão. Pela regra 6 do protocolo, isso não
podia ser escrito como conclusão sem ser medido. **D5** mede: a condição `degp2`
troca o fator do id por **2,0**, uma multiplicação exata em `float32` (desloca o
expoente, não arredonda), que não pode inverter ordem *nem* criar empate.

**D5 = 8/8 idênticas nas 23 colunas.** A divergência de D4 é arredondamento.

O eco com a nota 09 é exato, e o degrau é novo: lá, `float32` vazava sobre um
**mostrador** (a `agencia` do eremita, "0 exato" em ℝ com piso de ~0,003); aqui
ele vaza sobre a **decisão** — o mundo em si toma um caminho diferente porque um
empate apareceu onde a álgebra não previa nenhum. A frase da nota 10 continua
valendo e ganha alcance: `float32` não inverte ordens, cria empates; o que muda é
que agora sabemos que um empate criado pode custar uma trajetória inteira, não só
uma casa decimal num CSV.

### Errata do meu próprio pré-registro (registrada antes do painel)

D4 foi escrito pedindo "CSVs idênticos", o que é impossível por razão trivial:
`urg_m` e `urg_sd` (colunas 10 e 11) **descrevem o traço ablacionado**. A nota 35
já tinha resolvido isso excluindo a coluna do traço (`arrep_m`) e eu não repeti a
exclusão. Peguei no teste de fumaça, corrigi no §4.9 **antes** de rodar o painel,
e o script reporta as duas comparações — a literal (0/8, trivialmente) e a
corrigida (4/8, a que a álgebra prediz). Fica registrado porque a alternativa
seria publicar a versão que "deu certo" sem dizer que o critério mudou.

## 4. O que isto faz com a §3

A seção precisa de duas correções, e nenhuma é cosmética.

**Primeira: o id, como a §3 o define, é duas coisas, e só uma delas paga a
entrada.** O parágrafo trata `comida_prev · (1 + urgencia · fome)` como um bloco
só. Mas `comida_prev` é o mapa — é o **ego**, cuja ablação a nota 01 mostrou ser
letal em 51–121 ticks, em 50 de 50 seeds. O que sobra de próprio ao id é a
**modulação**, e é ela que não carrega comportamento em população. Dito sem
diplomacia: **o id desta seção é, em boa parte, o mapa do ego usando outro
nome**, mais um modulador que a régua declarada não consegue distinguir de zero.

**Segunda: o id e a sombra são a mesma variável.** A seção escreve a sombra
(`peso_espaco → 0,095`) e o id em parágrafos independentes. A álgebra mostra que
o id só age dividindo o termo do espaço — então a seleção que renega a agência
**aposenta o id junto**, e a nota 12 já tinha medido a data do enterro sem saber
que era dupla.

Pelo critério da própria §3, aplicado sem exceção: a palavra "id" fica com uma
ablação identificada (✅ existe) e um "carrega comportamento" que **falhou no
observável declarado** (❌ em população; sugestivo em energia, não pré-registrado).
É a única das cinco nessa situação — e a v3 fecha dizendo isso, não escondendo.

## Ameaças à validade

- **8 seeds é o painel mínimo**, e foi declarado como tal. Um efeito real e
  pequeno em população pode não aparecer aqui — mas 2/8 não é um efeito pequeno
  na direção prevista, é ausência de direção.
- **Ablação de traço não é ablação de mecanismo**, declarado no §4.9: pregar
  `urgencia = 0` remove a modulação, não o termo da comida. O id "grande" (a
  pulsão inteira) não foi testado, e não podia ser sem virar o teste do ego.
- **A energia média é confundida por densidade** — o erro que a nota 17 registrou
  em si mesma. Como população e energia andaram em direções opostas aqui, essa
  ameaça é *especialmente* viva para o companheiro descritivo, e é mais uma razão
  para ele ser pré-registro futuro e não veredito.
- **D5 é post-hoc.** Ele testa a explicação que sobrou depois de a leitura de
  código descartar a outra; não foi declarado antes. Sua força vem de ser uma
  predição bit a bit exata (8/8, sem margem), não de ter sido escolhido a frio.

## O que ficou em aberto

O pré-registro que esta nota deixa pronto para a próxima: **o custo do id em
energia, com energia declarada antes e a densidade controlada** — o companheiro
descritivo do §2 diz 7/8 e `p = 0,070`, o que é exatamente o tamanho de coisa que
merece um teste próprio em vez de uma frase. E, do lado da régua, uma pergunta
nova que o D4/D5 abriu e que nenhum mostrador deste projeto respondeu: **com que
frequência um empate criado por `float32` muda uma decisão numa corrida normal?**
Aqui foi 4 em 8 seeds numa condição artificial; na simulação canônica, ninguém
mediu.
