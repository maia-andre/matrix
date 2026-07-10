# Nota 01 — Quatro réguas da mente, quatro modos de errar

**Data:** 2026-07-09
**Mostrador `modelo` quebrado:** até o commit `6da8c3a`. **Consertado em:** `48ecbcb`.
**Serve ao:** Paper 1 (metrologia da mente).

**Reproduzir:**

```sh
sh papers/notes/01-ablacoes.sh                       # main.c atual (consertado)

git show 6da8c3a:main.c > /tmp/main_quebrado.c       # a evidencia historica
sh papers/notes/01-ablacoes.sh /tmp/main_quebrado.c  # o mostrador quebrado
```

---

## Resumo

A bateria de desbotamento tem quatro mostradores. Submetidos a ablação, os quatro
falham — cada um de um jeito diferente, e nenhuma das falhas era visível sem
tentar quebrá-los. `modelo` dava nota **1,000** a um agente sem modelo de mundo
nenhum, marchando para a extinção. `agencia` e `automodelo` são **identicamente
zero** para um agente que não percebe outros agentes. `phi` não está normalizado
e não é independente dos demais. Este documento registra as quatro falhas, o
conserto de `modelo`, e dois morais que sobrevivem ao brinquedo.

## 1. O aparato

Todos os números abaixo: média de 3 seeds (7, 42, 1234), 3000 ticks, ticks > 20,
população viva. As ablações são patches aplicados a uma cópia temporária do
`main.c` — não há fork do núcleo da física. As colunas `agencia`, `automodelo`,
`phi` e `pop` são **idênticas** entre o `main.c` quebrado e o consertado, o que
prova que o conserto tocou o medidor e não a simulação.

| condição | `modelo` (quebrado) | `modelo` (consertado) | `agencia` | `automodelo` | `phi` | pop |
|---|---|---|---|---|---|---|
| controle | 0,973 | 0,636 | 0,383 | 0,332 | 0,255 | 312 |
| **A.** `horizonte = 1` | **0,994** ↑ | 0,505 | 0,296 | 0,170 | 0,263 | 321 |
| **B.** `prever_valor ≡ 0` | **1,000** ↑↑ | **0,000** | 0,000 | 0,000 | 0,131 | **extinta** |
| **C.** solipsista | 0,789 | 0,783 | **0,0000** | **0,0000** | 0,039 | 314 |
| **D.** `COMPETICAO = 0` | 0,955 | 0,790 | 0,570 | 0,441 | 0,192 | 315 |

> **Errata (nota 02).** A primeira versão desta tabela trazia populações de
> 199–307 e falava em quedas de 25–35%. Eram contaminação do teto de nascimentos
> (`reproduzir()` não reciclava slots), corrigido depois. As leituras dos
> **mostradores** praticamente não mudaram; as de **população** mudaram muito.
> Nada nas conclusões abaixo dependia delas, exceto onde marcado.

> **Errata (nota 03).** A coluna `agencia` acima vem do mostrador **antigo** (dois
> pontos de sonda). Com a sonda varrendo o domínio inteiro, o controle lê **0,435**
> em vez de 0,383. O `0,0000` do solipsista **sobrevive** (e agora tem prova: sem
> rivais todas as retas têm a mesma inclinação). E a seção 3 abaixo diagnostica
> `agencia` como "unidade que coevolui com o objeto" — **diagnóstico errado**. A
> correlação `+0,98` com `esp_m` é mecanismo, não contaminação: a agência
> **realmente desbota**, e a régua estava certa. Ver a nota 03.

## 2. Modo 1 — `modelo`: um mapa que não podia errar

A "previsão" era

```c
pred_colheita[i] = menor(comida[alvo_y[i]][alvo_x[i]], INGESTAO);
```

Isto lê `comida[][]` — **o array do mundo** — e nunca chama `prever_valor()`. O
mapa que o bloco constrói e que *evolui* (horizonte, desconto, partilha) jamais
era confrontado com o território. Um tick depois, comparava-se com
`garfada = menor(comida[y][x], INGESTAO)`: a mesma fórmula, sobre a mesma célula.
Se o bloco chegasse ao alvo, `real == pred` **por construção**. `modelo ≈ 0,97`
significava apenas *"97% dos blocos não foram barrados"* — um medidor de
**taxa de conflito** com nome de medidor de calibração.

Três confirmações independentes, cada uma isolada, todas apontando para o mesmo
lugar:

- **A.** lobotomizar o horizonte faz a nota **subir** (0,973 → 0,994);
- **B.** remover o modelo de mundo por inteiro dá **1,000** — nota perfeita para
  uma população que se extingue em 74–105 ticks;
- **C.** cegar o bloco para os rivais faz a nota **descer** (0,973 → 0,789),
  porque sem aversão a multidão os blocos se amontoam e a congestão sobe.

Nenhuma das três tem a ver com a qualidade de um modelo de mundo.

**As duas famílias apontaram para lados opostos.** A *ablação* disse a verdade
(arranca `prever_valor`, a população morre: a faculdade carrega o comportamento).
A *calibração* deu nota máxima a um cadáver. Isso não é acidente:

> A sonda lia o array do mundo. Um mapa que é **fotocópia** do território não pode
> discordar dele. E um mapa que **não pode errar não é um mapa** — a marca da
> representação é a possibilidade da *des*representação.

O mostrador fora construído removendo exatamente a condição que faria dele um
mostrador.

### O conserto

A previsão passa a sair de `prever_valor(alvo, bloco)` — o mapa do bloco, com o
horizonte, o desconto e a partilha *dele*. A janela dura os `horizonte` ticks do
próprio bloco, acumulando a colheita real descontada pelo mesmo `desconto`. A
janela fecha quando o horizonte se esgota — ou quando o bloco morre, que é a
previsão mais errada possível.

**Condição de sanidade, declarada antes de rodar:** se `prever_valor ≡ 0` não
derrubar `modelo` a ~0, o conserto não consertou. Resultado: **0,000 exato**,
nas três seeds. E o controle passa a ler **0,638** — há folga nos dois sentidos.
O mapa agora pode errar. E erra.

## 3. Modos 2 e 3 — `agencia` e `automodelo` medem uma relação, não uma posse

**O teste do eremita.** O bloco deixa de *perceber* outros blocos (`rivais_em ≡ 0`,
`pretendentes_em ≡ 0`); eles continuam existindo e bloqueando fisicamente. Um
solipsista num mundo povoado. Os dois mostradores não caem: dão **zero exato**.

E isso é demonstrável antes de rodar. Em `utilidade()`:

```
u(célula) = comida_prev · (1 + urgencia · fome)  +  peso_espaco · espaco · (1 − fome)
```

Sem rivais, `espaco = (8 − 0)/8 ≡ 1` em toda célula: o segundo termo vira
**constante entre as células** e some do argmax. O primeiro é `comida_prev`
multiplicado por um escalar positivo, que também não move o argmax. Logo **a fome
não pode mudar a escolha de um bloco solitário**, e `agencia ≡ 0`. Já `automodelo`
é `intencao != alvo`, e as duas passagens só divergem via `pretendentes_em`; logo
`automodelo ≡ 0`.

Os dois mostradores que nomeiam as faculdades mais "mentais" da escada — **agência**
e **auto-modelo** — não medem nada que o bloco *tenha*. Medem algo que acontece
**entre** blocos.

Há ainda um segundo defeito em `agencia`: sua escala **deriva com a população que
ela mede**. A fome só troca o peso entre comida e `peso_espaco`, e `peso_espaco`
evolui (cai de ~3,1 para 0,5–1,5 em 30 000 ticks); a correlação entre `esp_m` e
`agencia` é **+0,93 / +0,94 / +0,38**. Comparar `agencia` no tick 100 e no tick
20 000 é comparar réguas diferentes. A ablação **D** mostra o mesmo por outro
lado: mexer em `COMPETICAO`, que nada tem a ver com agência, move `agencia` de
0,385 para 0,578.

E `automodelo` sequer é uma ablação: é `intencao != alvo`, lido de graça do estado
que já existe — uma **observação**. `agencia`, ao lado, roda um contrafactual de
verdade (dois clones, faminto × saciado). Plotar os dois no mesmo eixo `[0,1]` é
somar laranjas com maçãs.

## 4. Modo 4 — `phi`: escala inventada, e não independente

`phi_proxy()` devolve `10.0f * disc/tot`, sem clamp, enquanto a documentação
afirma `[0,1]`. Se a discordância passar de 10%, `phi > 1`. Nas corridas feitas o
máximo observado foi 0,372 — **fragilidade latente**, não um bug que disparou. Mas
o fator `10.0f` foi escolhido para o número *parecer* morar em `[0,1]`, o que
esvazia o valor absoluto. Além disso `corr(hor_m, phi)` fica entre **+0,56 e
+0,80**: `phi` acompanha a profundidade de planejamento. E perde **88%** do valor
na solidão (0,256 → 0,031): a "luz acesa" era quase toda social.

## 5. Achado colateral — o bloco tem uma crença falsa

Com o mostrador consertado, o controle lê 0,638 e o **solipsista lê 0,783**: um
bloco que *ignora* os rivais prevê **melhor**. A ablação **D** isola a causa —
zerar só `COMPETICAO` (mantendo a percepção dos rivais para o termo `espaco`)
recupera a calibração para 0,795.

A causa é uma **crença falsa**. Via `partilha = 1/(1 + COMPETICAO · rivais)`, o
bloco acredita que os rivais dividem a comida da célula que ele ocupa. Mas
`ocup[][]` guarda **um** bloco por célula: ninguém divide nada, nunca. O bloco
subestima sistematicamente a própria colheita.

Duas observações, e uma delas eu quis fazer e os dados não deixaram:

- **`partilha` é puro custo epistêmico ao nível do grupo.** Removê-la (D) recupera
  0,16 de calibração e **não muda a população** (290,3 × 290,0). Quem carrega o
  valor adaptativo de enxergar rivais é o outro termo, `espaco`: o solipsista, que
  perde os dois, paga só **2,4%** de população (283,1 × 290,0).
- **Não é (ainda) uma "crença falsa adaptativa".** Ela não paga, ao nível do grupo.
  Se é *individualmente* vantajosa é outra pergunta — e uma que exige `COMPETICAO`
  como traço por bloco e um ensaio de invasão. É a pergunta de McKay & Dennett
  (*The evolution of misbelief*, 2009), executável.

> **Errata (nota 02).** Aqui eu havia escrito que "o solipsista modela melhor e
> **morre 35% mais** — acurácia e aptidão dissociam". Era artefato do teto de
> nascimentos: o solipsista se amontoa, nasce muito, esgotava os slots antes. Com
> a reprodução consertada o custo é de 2,4%, e a frase perde a força. **Retirada.**
> O que sobrevive é mais modesto: `partilha` custa calibração e não paga nada.

## 6. Dois morais que sobrevivem ao brinquedo

1. **Qualquer métrica da família *calibração* pode ser satisfeita por uma sonda
   que lê o ambiente em vez da representação do agente.** O teste é perguntar: *o
   que esta sonda lê quando o agente não tem representação nenhuma?* Se ela não
   despenca, ela nunca leu a representação.

2. **Qualquer métrica *por-agente* de uma faculdade *relacional* lê zero num
   agente sozinho** — e nenhum refinamento por-agente conserta isso. Daí o **teste
   do eremita** como protocolo geral: rode a ablação da solidão em qualquer
   métrica por-agente; se ela zerar, ela media uma relação, não uma posse.

## 7. Ameaças à validade

- **3 seeds.** A infraestrutura torna 50 baratas; o Paper 1 deve reportar média ±
  dispersão. Aqui as três concordam em direção e ordem de grandeza, não mais.
- **A ablação A é confundida.** Com `horizonte = 1` o mapa enxerga 1 passo, mas a
  janela de comparação continua durando `blocos[i].horizonte` ticks. A queda de
  `modelo` (0,638 → 0,508) mistura "mapa raso" com "janela mais longa que o mapa".
  As conclusões desta nota não dependem de A: dependem de **B** e **C**.
- **Bug no simulador, descoberto ao consertar a bateria — hoje corrigido.**
  `reproduzir()` fazia `j = n_blocos++` e nunca reaproveitava o slot de um morto,
  impondo um teto de ~1348 **nascimentos** por simulação. Ele **contaminou todas as
  comparações de população** desta nota (ver as erratas acima); as leituras dos
  mostradores sobreviveram quase intactas. Ver [nota 02](./02-o-teto-de-nascimentos.md).

## 8. Em aberto

- Consertar `agencia` (unidade que não coevolua com o objeto), `automodelo`
  (virar intervenção; e renomear — é um modelo *do outro*) e `phi` (normalizar,
  desacoplar de `hor_m`).
- `partilha` como traço por bloco + ensaio de invasão: a crença falsa é
  individualmente adaptativa?
- Consertar o teto de nascimentos, e refazer os resultados evolutivos de longo
  prazo que hoje não existem.
