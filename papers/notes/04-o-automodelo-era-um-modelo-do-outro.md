# Nota 04 — O `automodelo` era um modelo do outro

**Data:** 2026-07-10
**Mostrador `automodelo` antigo:** até o commit `52b2cac`. **Consertado em:** `9e96973`.
**Serve ao:** Paper 1 (metrologia da mente) — e à `FILOSOFIA_v3.md` (a costura da escada).
**Reproduzir:** `sh papers/notes/04-modelo-do-outro.sh`

---

## Resumo

O terceiro mostrador da bateria, `automodelo`, tinha **três defeitos de uma vez**,
e o conserto de todos foi a mesma edição. Ele era (1) uma **observação** lida de
graça — `intencao ≠ alvo`, subproduto do próprio tick — e não uma intervenção; (2)
uma sonda com um **parâmetro escondido**: a leitura escalava com a constante
`ANTECIPACAO`; e (3) **mal nomeado**: o *teste do eremita* mostra que ele é
identicamente zero sem rivais, logo mede um modelo do **outro**, nunca de si.

O conserto o torna uma intervenção **de propósito** e **ancorada** — pergunta se
antecipar os rivais *poderia* mudar a escolha, varrendo a força da antecipação por
todo o seu domínio, sem depender de `ANTECIPACAO`. E lhe dá o nome honesto:
`modelo_do_outro`. Diferente de `modelo` (§1.1), aqui **o número quase não muda**
(`~0,34 → ~0,35`). O achado desta nota não é um número errado — é um **método** e um
**nome** errados. Um mostrador pode acertar o valor e ainda assim não medir o que diz.

## 1. Os três defeitos

O código antigo, em `medir_decisao()`:

```c
/* AUTO-MODELO (nv5), de graca: antecipar os rivais mudou a escolha? */
if (intencao_x[i] != alvo_x[i] || intencao_y[i] != alvo_y[i]) au += 1.0f;
```

**(1) Observação, não intervenção.** `intencao` (de `declarar`, sem antecipação) e
`alvo` (de `decidir`, com antecipação) já existem porque o *tick* precisa deles. O
mostrador só os relia. `agencia`, ao lado, **varre** o domínio inteiro do estado
interno e conta trocas de decisão: uma intervenção construída de propósito. Somar os
dois no mesmo eixo `[0,1]` é somar uma medida a uma anedota.

**(2) Um parâmetro escondido.** A força da antecipação é `ANTECIPACAO = 0.5` — uma
lei da física, não um traço do bloco. `intencao ≠ alvo` pergunta "a escolha vira
*neste* ponto de força?". Varrendo a força `α` de `0` a `∞` (a simulação intacta, a
mesma corrida relida), a leitura desenha uma curva:

| `α` | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| 0 | 0,0000 | 0,0000 | 0,0000 |
| 0,25 | 0,2872 | 0,2942 | 0,2566 |
| **0,5** *(a sonda antiga)* | **0,3407** | **0,3481** | **0,3070** |
| 1 | 0,3528 | 0,3596 | 0,3200 |
| 4 → ∞ | 0,3540 | 0,3608 | 0,3220 |

`0,5` é só **um ponto no meio da subida**. Tivesse `ANTECIPACAO` valido `0,25`, o
mostrador leria `~0,29`; a `0,125`, `~0,19`. O valor absoluto não significava nada —
era uma função de uma constante escolhida por outro motivo (o comportamento dos
blocos), não uma propriedade do que se dizia medir.

**(3) O nome mente.** "Antecipar os rivais mudou minha escolha" é um modelo **do
outro**, não de si — o *self* entra só como "sou um dos pretendentes". E o *teste do
eremita* (§1.5) é definitivo: sem perceber rivais, todo `pret = 0`, nenhuma célula é
disputada, a leitura é **zero exato**. Uma faculdade que some quando o outro some não
é uma posse do bloco.

## 2. O conserto: uma intervenção ancorada

Cada célula alcançável `k` vale, com força de antecipação `α ≥ 0`,

```
nota_k(α) = u_k / (1 + α · pret_k)
```

onde `u_k` é a utilidade (nível 4) e `pret_k` quantos vizinhos declararam querer `k`
(ficar parado **nunca** é disputado: ninguém "entra" onde eu já estou, então
`pret = 0`). Em `α = 0` vence `W`, a escolha **pré-social** — a mesma de `declarar()`.
Varrer `α` por todo `[0, ∞)` em vez de espiar `α = ANTECIPACAO` tira a constante da
conta. E como cada `nota_k` só **decresce** em `α` (célula disputada) ou fica **plana**
(`pret = 0`), a escolha muda para algum `α > 0` **se, e só se**:

> `W` é disputada (`pret_W > 0`) **e** existe alternativa que a ultrapassa quando a
> disputa aperta — uma célula não disputada de valor positivo (inclui ficar parado;
> como `nota_W → 0`, em algum `α` ela vence), **ou** uma disputada com mais *valor por
> pretendente* (`u_k · pret_W > u_W · pret_k`, a de queda mais lenta passa a mais rápida).

O critério é **exato** — nenhuma amostragem — e não menciona `ANTECIPACAO`. Ele é,
por construção, a **assíntota** `α → ∞` da curva do §1: a linha `4 → ∞` da tabela e a
leitura ancorada batem a **4 casas** (`0,3540 / 0,3608 / 0,3220`). Isso valida a
forma fechada contra o limite numérico.

Bloco **encurralado** (uma só opção) não tem escolha a modelar: sai da média, como na
`agencia`. Foi a única mudança de estatística — e ela é parte da sonda (a intervenção
é *indefinida* sem alternativas), não uma segunda mudança independente.

## 3. O que se mediu

- **Teste do eremita:** `0,0000` exato — média **e máximo** — nas 3 seeds. A condição
  de sanidade declarada antes de rodar (regra 2 do §1.7): *que ablação tem de derrubar
  o mostrador a zero?* Resposta: a solidão. Cumprida ao pé da letra.
- **Simulação bit-a-bit idêntica:** todas as outras 16 colunas do CSV saem iguais nas
  3 seeds (regra 3). O mostrador relê a mesma corrida; não a perturba. Logo a
  **aptidão é idêntica por construção** (pop 314,8 / 285,2 / 272,5, antes = depois) —
  o descasamento leitura×aptidão da regra 1 aqui é trivial: mesma corrida, régua nova.
- **A/B:** a leitura ancorada fica um fio acima da antiga (`0,341/0,348/0,307 →
  0,354/0,361/0,322`), pelos dois motivos que empurram no mesmo sentido — a captura da
  *capacidade* (troca em algum `α`, não só em `0,5`) e o denominador sem encurralados.

## 4. A assimetria que denuncia o nome

`agencia` e `modelo_do_outro` parecem irmãs — as duas varrem um eixo e perguntam "a
decisão muda em algum ponto?". Mas os eixos são de espécies diferentes:

- na `agencia`, o eixo varrido (`λ`, a fome) é um **estado interno** que o bloco de
  fato **visita** ao longo da vida. A varredura pergunta algo que acontece *dentro*.
- aqui, `α` é uma **força externa** que o bloco **nunca varia** — a força da disputa é
  lei do mundo. Varrer `α` é rodar um contrafactual que não ocorre.

Essa assimetria **é a digital do defeito 3**. A razão de não haver um estado interno
para ancorar é que não há nada interno sendo medido: o que varia, e o que a leitura
lê, é o **outro**. O conserto que a torna honesta e o nome honesto são a mesma coisa.

## 5. Um `automodelo` de verdade seria outra edição — e é uma tese

O mostrador honesto mede o outro. Um **auto-modelo** de verdade — o *self* na própria
simulação — exige o item pendente do `README.md`: em `prever_valor`, separar o
**próprio** consumo do consumo dos rivais (hoje ambos entram juntos via `partilha`),
modelando que a célula escolhida fica deprimida *pelo próprio bloco*. Isso **muda a
simulação** (a decisão muda), então **não é conserto de régua** — é a bifurcação da
Fase 5 (ROADMAP, item 9: a escada é aquisição de faculdades, ou escalada de um
conflito?).

**Predição falseável, registrada aqui:** feita essa edição, um mostrador do *self*
ficaria **`> 0` na solidão** — ao contrário deste, que é zero por construção. Se
ficar, a leitura internalista (A) da escada ganha um degrau que o eremita possui; se
não houver como fazê-lo sem rival, a leitura relacional (B) vence. O conserto do
mostrador e a posição filosófica continuam sendo **a mesma linha de código**.

## Ameaças à validade

- **A leitura é de *capacidade*, não de *ocorrência*.** "Antecipar poderia mudar a
  escolha em algum `α`" não é "mudou na força operante `0,5`". É a mesma escolha que
  a `agencia` faz (capacidade sobre o domínio), de propósito — mas é uma escolha, e um
  revisor pode preferir reportar a força operante. A curva do §1 deixa as duas à vista.
- **`pret` vem das intenções já declaradas**, que dependem de `ANTECIPACAO` via
  `decidir()`. A *trajetória* (quem está onde, quem mira o quê) ainda carrega a
  constante; só a **régua** não. Removi o parâmetro da medida, não do mundo — e é o
  correto: o mundo tem a sua física, o instrumento não deve herdá-la.
- **3 seeds.** Como sempre: uma seed não é um resultado. A curva é monotônica e satura
  em `α ≈ 2–4` nas três, o que dá alguma confiança na forma, não no terceiro decimal.

## O que ficou em aberto

1. O **auto-modelo de verdade** (§5) e sua predição do eremita `> 0`. É a próxima
   coisa que **mexe na simulação**, não só na régua — entra pela Fase 5, não pela 1.
2. Falta um mostrador da bateria: **`phi`** (§1.4) — não normalizado, e talvez
   sinônimo de profundidade efetiva de planejamento. É o último portão da Fase 1.
3. Com `modelo` (nota 01), `agencia` (nota 03) e `modelo_do_outro` (aqui) de pé,
   **três dos quatro** modos de errar do Paper 1 estão documentados com mecanismo,
   ablação e conserto. O quarto é o `phi`.
