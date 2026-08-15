# ROADMAP — para onde a Matrix vai

> `README.md` é o **como**. `FILOSOFIA.md` e `FILOSOFIA_v2.md` são o **porquê**.
> Este é o **para onde** — e, tão importante quanto, o **para onde não**.

## O que já aconteceu (e passou meio despercebido)

Até a v1, a Matrix era um simulador engenhoso: *o objeto de estudo*. A v2 fez
uma troca de papel que parece sutil e é enorme — com a bateria de desbotamento,
a Matrix virou **aparato experimental**. A frase deixou de ser "olhem o meu
mundo artificial" e passou a ser "construí um ambiente determinístico,
reprodutível e instrumentado onde posso formular hipóteses, executar
intervenções e medir resultados".

O projeto subiu uma escada (níveis 0–6) e então **parou de subir e construiu uma
régua**. Antes de usar a régua para medir qualquer coisa, é preciso descobrir se
a régua mede.

Ela não media. Nenhum dos quatro mostradores saiu ileso — quatro modos de errar
independentes, dois deles escondendo achados que a régua consertada revelou
(notas 01–05). Ver o placar da Fase 1.

---

# Fase 1 — Quebrar a régua *(concluída em 2026-07-10)*

**Pergunta:** os mostradores medem a coisa, ou um correlato dela?

Este é o **portão**. Refinar `modelo` ou `Φ~` antes de tentar quebrá-los é
refinar no escuro; construir um quarto mostrador (`relato`) com uma metodologia
não validada é multiplicar o erro por quatro.

**Placar:**

| mostrador | estado | veredito |
|---|---|---|
| `modelo` | ✅ consertado (§1.1) | era um medidor de **taxa de conflito** |
| `agencia` | ✅ consertado (§1.2) | a sonda tinha defeito; **o desbotamento era real** |
| `automodelo` | ✅ consertado (§1.3) | vira `modelo_do_outro`: mede o **outro**, não o self |
| `phi` | ✅ consertado (§1.4) | era **infalseável**; a suspeita ("= profundidade") estava errada — media o **segundo motivo** |

Bug do simulador achado no caminho: §1.6. Protocolo destilado dos erros: §1.7.

## 1.0 O primeiro resultado negativo do projeto

`modelo` não mede o modelo de mundo do bloco. Ele mede **taxa de conflito**.

Em `medir_decisao()`, a "previsão" é:

```c
pred_colheita[i] = menor(comida[alvo_y[i]][alvo_x[i]], INGESTAO);
```

Isso lê `comida[][]` — **o mundo** — e nunca chama `prever_valor()`. O mapa que
o bloco constrói (`horizonte`, `desconto`, `partilha` com rivais), o mapa que
*evolui*, jamais é confrontado com o território. Um tick depois, `medir_modelo()`
compara aquilo com `garfada = menor(comida[y][x], INGESTAO)` — **a mesma fórmula,
sobre a mesma célula**. Se o bloco chegou ao alvo, `real == pred` por construção.
`modelo ≈ 0,97` significa apenas "97% dos blocos não foram barrados".

Medido, em três seeds, 3000 ticks (`sh papers/notes/01-ablacoes.sh`):

| condição | modelo (@ `6da8c3a`) | destino da população |
|---|---|---|
| controle (intacto) | **0,973** | ~290, estável |
| `horizonte = 1` (lookahead lobotomizado) | **0,994** ↑ | ~300, estável |
| `prever_valor() ≡ 0` (sem modelo nenhum) | **1,000** ↑↑ | **extinção em 74–105 ticks** |

*(A coluna `modelo` é histórica — o mostrador quebrado, reprodutível com
`git show 6da8c3a:main.c`. A coluna da população foi **remedida** depois do
conserto do §1.6: o "cai ~25%" que eu havia reportado para `horizonte = 1` era
contaminação do teto de nascimentos.)*

Um bloco cego para comida, marchando para a extinção, tira **nota máxima** no
mostrador chamado "modelo". A leitura é **monotonicamente anti-correlacionada**
com a faculdade que ela nomeia: quanto mais lobotomizado o agente, melhor sua
nota. É Goodhart em estado puro, e é o primeiro resultado negativo que este
projeto produziu.

**Por que falhou, e a lição geral.** As duas famílias da bateria apontaram em
direções opostas. A **ablação** disse a verdade — arranca `prever_valor` e a
população morre, logo a faculdade carrega o comportamento. A **calibração** deu
nota 1,000 a um cadáver. Isso não é acidente:

> `pred_colheita` lê o array do mundo. Um mapa que é uma **fotocópia** do
> território não pode discordar dele. E um mapa que **não pode errar não é um
> mapa** — a marca da representação é a possibilidade da *des*representação.

O mostrador foi construído removendo justamente a condição que faria dele um
mostrador. Isso é matéria da `FILOSOFIA_v3.md` (Fase 5), não só de um patch.

## 1.1 Consertar `modelo` ✅ *feito*

A previsão agora sai do **mapa do bloco**: `prever_valor()` (com `horizonte`,
`desconto`, `partilha`), comparada contra a colheita realmente acumulada ao longo
dos `horizonte` ticks do bloco, descontada do mesmo jeito. A janela fecha no fim
do horizonte — ou na morte do bloco, que é a previsão mais errada possível.

Condição de sanidade, declarada antes de rodar: **a ablação `prever_valor ≡ 0`
tem de derrubar `modelo` a perto de zero.** Resultado: **0,000 exato** nas três
seeds (era 1,000). O controle passou de 0,973 para **0,638** — há folga nos dois
sentidos, o mapa pode errar. E o conserto **não mexeu na simulação**: todas as
outras colunas do CSV são bit-a-bit idênticas.

Achado colateral, registrado na nota 01: com o mostrador funcionando, o bloco
revela uma **crença falsa**. Via `partilha`, ele acredita que os rivais dividem a
comida da célula que ele ocupa — e `ocup[][]` guarda **um** bloco por célula.
Zerar só `COMPETICAO` recupera a calibração (0,625 → 0,786) **sem mexer na
população** (290,3 × 290,0): ao nível do grupo, `partilha` é puro custo
epistêmico, e quem carrega o valor adaptativo de ver rivais é o termo `espaco`.

→ [`papers/notes/01-quatro-modos-de-errar.md`](./papers/notes/01-quatro-modos-de-errar.md)

## 1.2 Descontaminar `agencia` ✅ *feito — e a suspeita estava errada*

O mostrador antigo sondava a fome em **dois pontos arbitrários** (`0,1·SACIADO` e
`SACIADO`). Isso tem um defeito real: dividindo `utilidade` pelo fator positivo
`(1 + urgencia·fome)`, comum a todas as células, a decisão vira
`argmax(comida_prev + λ·espaco)` com `λ = peso_espaco·(1−fome)/(1+urgencia·fome)`.
Os dois pontos visitavam `λ ∈ [0,034·P, P]`, com o **extremo inferior dependendo de
`urgencia`** — um traço que evolui. A sonda media parcialmente a si mesma.

O conserto usa a estrutura: cada célula é uma **reta** em `λ`, a escolha é o
envelope superior dessas retas, e `λ` varre exatamente `[0, peso_espaco]` quando a
fome varre `[0,1]`. Varremos `λ` inteiro. A estatística continua a mesma de
propósito — trocar a sonda **e** a estatística no mesmo passo confundiria as duas
mudanças. Leitura: **0,388 → 0,435** (a sonda antiga perdia ~12% dos blocos). Só a
coluna `agencia` do CSV muda; a simulação é bit-a-bit idêntica. E o novo mostrador
não menciona `urgencia`: esse traço só desliza *onde* na fome a troca acontece, não
*se* ela acontece.

**Mas a suspeita central estava errada.** Eu disse que `corr(esp_m, agencia) = +0,98`
provava contaminação. Não prova. Congelando `peso_espaco` em 3,0, o mostrador fica
**plano** por 30 000 ticks (0,464 → 0,440); com o traço livre, desaba (0,430 →
0,049) junto com `esp_m` (2,76 → 0,08). A correlação é **mecanismo, não
contaminação**: `peso_espaco` é o *único* canal pelo qual o estado interno pode
mudar uma decisão, e quando ele morre a política vira reflexo.

O que a régua estava reportando, e ninguém ouviu: **a evolução extingue a
agência.** No ensaio de invasão, o reflexo (`peso_espaco = 0`) **fixa** contra o
agente (`3,0`) em ~6000 ticks: 0,997 / 1,000 / 1,000.

→ [`papers/notes/03-a-evolucao-extingue-a-agencia.md`](./papers/notes/03-a-evolucao-extingue-a-agencia.md)

## 1.3 `automodelo` era um modelo do outro ✅ *feito*

`automodelo` tinha **três defeitos**, e o conserto de todos foi a mesma edição.
Era (1) uma **observação** lida de graça — `intencao != alvo`, subproduto de
`decidir()` — e não uma intervenção; (2) uma sonda com um **parâmetro escondido**,
a força `ANTECIPACAO = 0,5`, uma lei da física; e (3) **mal nomeado** — o teste do
eremita (§1.5) o faz **zero exato**, logo ele mede o **outro**, não o self.

O conserto (`modelo_do_outro_do_bloco`) é uma intervenção **de propósito** e
**ancorada**, no espírito da `agencia`: pergunta se antecipar os rivais *poderia*
mudar a escolha, por **todo** o domínio da força `[0, ∞)`, com um critério **exato**
(sem amostragem) que não menciona `ANTECIPACAO`. Ele é a assíntota `α → ∞` da curva
— e a forma fechada bate com o limite numérico a **4 casas**. O mostrador vira
`modelo_do_outro`.

Ao contrário de `modelo` (§1.1), **o número quase não muda** (`0,34 → 0,35`): o
defeito era de **método** e de **nome**, não de valor. Um mostrador pode acertar o
número e ainda assim não medir o que diz. Sanidade cumprida: eremita = **0,000
exato** (média e máximo, 3 seeds); simulação bit-a-bit idêntica (só a coluna muda).

**A assimetria que denuncia o nome:** na `agencia` o eixo varrido (`λ`) é um estado
**interno** que o bloco visita; aqui `α` é uma força **externa** que ele nunca
varia. Não há estado interno para ancorar porque não há nada interno sendo medido —
o que varia é o outro. Um `automodelo` **de verdade** exigiria separar, em
`prever_valor`, o próprio consumo do dos rivais — o que **muda a simulação**, e por
isso pertence à Fase 5 (item 9), não à régua. **Predição registrada:** feita essa
edição, um mostrador do *self* ficaria `> 0` na solidão — enquanto este é zero por
construção. O conserto do mostrador e a posição filosófica são a mesma linha de código.

→ [`papers/notes/04-o-automodelo-era-um-modelo-do-outro.md`](./papers/notes/04-o-automodelo-era-um-modelo-do-outro.md)

## 1.4 `phi` era infalseável — e a suspeita estava errada de novo ✅ *feito*

A suspeita central desta seção ("`phi` = sinônimo de profundidade efetiva",
`corr = +0,94/+0,70/+0,90`) **morreu no teste do traço congelado** — segunda vez
que a regra 4 do §1.7 salva um achado. A correlação só existe na janela de 30 000
ticks; nos primeiros 3 000 dos *mesmos dados* é fraca e negativa. Era
**co-tendência** (duas séries afundando sob a mesma evolução), não acoplamento:
**congelar a profundidade não segura a `phi`** (0,33 → 0,15, desaba como o
controle); **congelar `peso_espaco` a segura** (0,33 → 0,29). Quem carrega a `phi`
é o mesmo traço que carrega a `agencia` (nota 03): ela media, sobretudo, a
presença do **segundo motivo**.

O defeito real era pior que o suspeitado: a `phi` velha era **infalseável**.
Nenhuma ablação a zerava — `prever_valor ≡ 0` (bloco sem modelo, morrendo) lia
**0,131**, e `horizonte = 1` a fazia **subir**. Pela regra 2, ela não media nada.
Motivo estrutural: "discordar da ordem da comida" não é irredutibilidade — uma
decisão 100% explicada pelo espaço lia alto, sendo redutível a **um** módulo.
(E o `10.0f` era maquiagem de escala, como suspeitado.)

Conserto (`e151c45`): `phi` = a **menor** distância de Kendall entre a ordem
integrada e a ordem de **cada módulo isolado** — comida-agora (nv2), espaço (nv4),
mapa (nv3) — já em `[0,1]`, sem fator de escala. Se um módulo sozinho reproduz a
decisão, `phi = 0`: integrar uma coisa só não é integrar. Três zeros
**demonstráveis e verificados exatos** (eremita, `peso_espaco ≡ 0`,
`prever_valor ≡ 0`; média e máximo, 3 seeds); simulação bit-a-bit idêntica;
controle ≈ 0,065 (não-degenerada).

E a régua honesta repete a nota 03 um andar acima: **a evolução extingue a
integração** (0,044 → 0,005 em 30 000 ticks, junto com `esp_m` → 0,08; com o
traço congelado, fica de pé). O eremita zera — o "Φ social" do item 3 do plano
antigo se resolveu sozinho: nesta implementação a integração *é* social, porque o
segundo motivo só pesa quando há vizinhos.

→ [`papers/notes/05-phi-media-o-segundo-motivo.md`](./papers/notes/05-phi-media-o-segundo-motivo.md)

## 1.5 O teste do eremita — três dos quatro mostradores são sociais

Ablação: o bloco deixa de **perceber** outros blocos (`rivais_em ≡ 0`,
`pretendentes_em ≡ 0`); eles continuam existindo e bloqueando fisicamente. Um
solipsista num mundo povoado. Média de 3 seeds, ticks 200–3000:

| | `modelo` | `agencia` | `automodelo` | `phi` | pop média |
|---|---|---|---|---|---|
| controle | 0,636 | 0,383 | 0,332 | 0,255 | 290,0 |
| **solipsista** | 0,783 | **0,0000** | **0,0000** | 0,039 | 283,1 |

`agencia` e `automodelo` não caem: dão **zero exato**. E isso é demonstrável antes
de rodar. Sem rivais, `espaco = (8 − 0)/8 ≡ 1` em toda célula, então o termo
`peso_espaco · espaco · (1 − fome)` vira **constante entre as células** e some do
argmax; e o outro termo é `comida_prev · (1 + urgencia · fome)`, um escalar
positivo multiplicando `comida_prev`, que também não move o argmax. **A fome não
pode mudar a escolha de um bloco solitário** — logo `agencia ≡ 0`. Já `automodelo`
é `intencao != alvo`, e as duas passagens só divergem via `pretendentes_em` — logo
`automodelo ≡ 0`.

Consequências, em ordem de gravidade:

- Os dois mostradores que nomeiam as faculdades mais "mentais" da escada —
  **agência** e **auto-modelo** — não medem nada que o bloco *tenha*. Medem algo
  que acontece **entre** blocos. `automodelo`, aliás, sempre foi um modelo *do
  outro* (ver 1.3); agora sabemos que sem o outro ele é identicamente nulo.
- `phi`, o proxy de integração, perde **85%** do valor na solidão: a "luz acesa"
  era social em quase toda a sua intensidade.
- `modelo` (já consertado) **sobe** (0,636 → 0,783): o solipsista prevê melhor,
  porque não carrega a crença falsa da `partilha` (§1.1). *(Com o mostrador ainda
  quebrado, esta mesma ablação o fazia **descer** — a terceira confirmação
  independente de que ele media congestionamento; ver a nota 01.)*

Perceber os outros custa pouco em aptidão de grupo: a população cai ~**2,4%**
(283,1 × 290,0). Não os perceber custa muito em vocabulário: dois mostradores
zeram.

**O teste do eremita como protocolo.** Isto generaliza para além do brinquedo:
*rode a ablação da solidão em qualquer métrica por-agente*. Se a métrica zera
para um agente sozinho, ela media uma relação, não uma posse — e nenhuma
quantidade de refinamento por-agente vai consertá-la.

## 1.6 O bug que congelava a evolução ✅ *corrigido*

Independente da bateria, e descoberto ao consertá-la. `reproduzir()` fazia
`j = n_blocos++` e **nunca reaproveitava o slot de um bloco morto**, parando em
`MAX_AG = 1408`: um teto de ~1348 **nascimentos** na vida inteira de uma
simulação. Medido com instrumentação, os slots esgotavam nos ticks **11 647 /
9 473 / 9 487** (seeds 7 / 42 / 1234). Dali em diante a reprodução parava para
sempre — sem cria, sem mutação, sem seleção — e `energia_media` divergia: **986**
no tick 30 000, contra ~6 no regime saudável.

`alocar_slot()` agora reaproveita o buraco de menor índice. Depois: energia
estável em ~6 e população em ~280–310 por 30 000 ticks, reprodução nunca para.

**O preço, e ele é conceitual.** `resolver()` concede a célula disputada ao
pretendente de **menor índice**. No código antigo o índice era a ordem de
nascimento — logo o mais **velho** vencia toda disputa. Havia uma **regra de
senioridade que ninguém escreveu**, e que dava vantagem sistemática a quem já
tinha sobrevivido. Reaproveitar slots a destrói (uma cria pode herdar um índice
baixo e ganhar de um ancião). Trocamos um desempate arbitrário por outro; nenhum
dos dois é principiado. Um desempate *escolhido* — por energia, ou por um hash
determinístico de `(x, y, tick)` — é uma decisão de física em aberto.

→ nota 02.

## 1.7 O protocolo, daqui em diante

Cinco regras, cada uma paga com um erro cometido:

1. **Toda ablação reporta duas coisas**: a leitura do mostrador **e** o efeito em
   aptidão (população, sobrevivência). Foi o descasamento entre as duas que revelou
   o `modelo` quebrado. Um mostrador cuja leitura sobe enquanto a população morre
   está medindo outra coisa.
2. **Condição de sanidade declarada antes de rodar.** Para cada mostrador: *que
   ablação tem de derrubá-lo a zero?* Se nenhuma derruba, ele não mede nada.
3. **Um conserto de mostrador não pode mexer na simulação.** O teste é literal:
   todas as outras colunas do CSV têm de sair **bit-a-bit idênticas**. Foi assim
   que se pegou um `au / n` que arredondava diferente de `au * (1.0f/n)`.
4. **Antes de acusar a régua, congele o traço.** Se a leitura correlaciona com um
   traço que evolui, congele o traço: régua contaminada continua derivando, régua
   boa fica plana. Na nota 03 isso salvou o achado — a agência desbotava de
   verdade, e nós íamos "consertar" o instrumento até ele parar de dizer isso.
5. **Mude uma coisa por vez.** Trocar a sonda **e** a estatística no mesmo passo
   torna as duas mudanças inseparáveis.

---

# Fase 2 — Fechar a bateria: `relato` *(concluída em 2026-07-10)*

**Pergunta:** um bloco pode dizer algo *sobre si* que carregue comportamento?

O único mostrador prometido e não entregue — e não é acaso que ficou por último.
Relato é a dobradiça de quase toda a ciência da consciência (workspace global,
teorias de ordem superior: tudo se apoia em *report*). Já existe um `auto_relato()`
no HUD da primeira pessoa, que narra o bloco em texto — **mas nada o mede**.

**Em pé com as invariantes:** o bloco emite um **sinal local** na própria célula,
computado do estado interno; vizinhos leem o 3×3. Inteiro, sem `math.h`,
`f(seed)`, percepção estritamente local. Duas famílias, como sempre — e desta vez
com a lição da Fase 1: a calibração só vale se o sinal **puder estar errado**.

## 2.0 Pré-registro *(2026-07-10 — commitado antes de escrever o mostrador)*

**Arquitetura escolhida (v1): o intérprete interno é um observador leigo.** O
módulo de relato **não tem acesso ao estado interno** (fome, urgência, o cálculo
de `utilidade`) nem ao plano (`intencao`): ele vê o que um vizinho veria — o 3×3
percebido no início do tick e **a ação executada** — e infere dali o próprio
motivo. É a tese de Nisbett & Wilson e da self-perception (Bem) como restrição
arquitetural: *introspecção é percepção do próprio comportamento*. O relato tem
quatro valores: `fome` (a ação bate com o argmax da comida **crua** — a heurística
leiga, não `prever_valor`), `espaco` (bate com o argmax de espaço), `ambos`,
`nao_sei` (não bate com nenhum — o resíduo irredutível, o eco por-bloco da `phi`).

**A verdade (lado do observador):** o motivo que de fato explicaria a **decisão**
(`alvo` cognitivo, pré-`resolver`) — comparada aos argmax de `prever_valor` (o
mapa real, com horizonte/desconto/partilha) e de `espaco`, com os traços
verdadeiros. O canal do relato é **faliível por construção**: lê a ação executada
(não o plano — `resolver` pode ter negado), e lê comida crua (não o mapa — que
enxerga rebrota e partilha).

**A estatística:** concordância acima do acaso (κ de Cohen, só aritmética, sem
`math.h`), clampada em `[0,1]`.

**Condições de sanidade e predições, declaradas antes de rodar:**

- **P1 (a ablação que TEM de zerar):** intérprete cego — relato ≡ constante
  (qualquer uma das quatro). Pela construção do κ, concordância = acaso ⇒
  `relato = 0` **exato**. Demonstrável antes de rodar; verificar mesmo assim.
- **P2 (anti-fotocópia):** no mundo intacto, `0 < relato < 1`. Se ler 1, o canal
  não pode errar e o mostrador está quebrado (lição do `modelo`); se ler 0, o
  intérprete é cego e a arquitetura não sustenta a palavra.
- **P3 (confabulação selvagem):** `resolver` já **intervém** nas ações (nega a
  célula disputada) — um Bandersnatch que a física roda de graça. Predição: nos
  blocos **negados**, o relato continua coerente com a ação executada (a
  arquitetura garante) mas a calibração contra o motivo da *decisão* **cai** em
  relação aos obedecidos. Se cair, há confabulação sem nenhum patch — o intérprete
  racionaliza uma ação que o bloco não escolheu.
- **P4 (exploratória):** os erros de relato se concentram onde `prever_valor`
  diverge da comida crua — o intérprete leigo não entende o planejador. *"Quanto
  mais fundo o bloco pensa, menos ele se entende."*
- **P5 (a costura):** o eremita **não** zera o `relato` — seria o primeiro
  mostrador da bateria a medir algo que um bloco solitário *tem* (degraus 0–3 da
  costura, v3 §2). Se zerar, a costura engole o relato e a leitura (B) leva mais
  um ponto.

**Escopo honesto da v1 (em letras garrafais):** o sinal é **emitido e medido, mas
ainda não consumido** — nenhum vizinho o lê, nenhuma decisão muda com ele. A
família *ablação* do `relato` lê zero hoje **por construção**: o relato v1 é
epifenomenal, e isso é um *resultado* (epifenomenalismo, medido), não um defeito.
Torná-lo causal (vizinhos lendo o sinal, mentira custando — Fase 4) é o passo
seguinte, separado de propósito. E o risco de sempre: um relato bem calibrado é
evidência de **calibração**, não de experiência.

## 2.1 O mostrador entregue — e o placar do pré-registro ✅ *(nota 06)*

Construído em `ffb3014` (o pré-registro acima é `eee9511`, commitado antes).
Simulação bit-a-bit idêntica; coluna 18 do CSV.

| predição | resultado |
|---|---|
| P1 intérprete cego → 0 exato | ✅ 0,0000 (4 constantes × 3 seeds, média e máx) |
| P2 `0 < relato < 1` | ✅ κ ≈ **0,67** |
| P3 confabulação selvagem | ✅ negados: calibração 0,78 → **0,47**; **~21% racionalizam**, ~79% dizem "não sei" |
| P4 erros onde o mapa ≠ heurística | ✅ ~35% das escolhas *livres* recebem "não sei" |
| P5 eremita não zera | ❌ **FALHOU** — o eremita fica **mudo** (κ ≈ 0,005): um self de um motivo só não tem o que relatar acima do acaso. A costura engole o quinto mostrador, pelo lado do **conteúdo** |

O experimento do intérprete, abaixo, já tem a versão **selvagem** rodada de graça
pela física (`resolver()` nega ≈ 6% das ações): a linha *honesto* domina (~79%) e
a *confabula* existe (~21%), dosada pela geometria. O que falta é a versão
**forçada** — e a comparação de arquiteturas (ler a ação × ler o plano), que
transforma a tabela num resultado de seleção, não de design.

## 2.2 Pré-registro do Bandersnatch forçado *(2026-07-10 — commitado antes de rodar)*

**A intervenção:** o dedo do espectador. Depois de `medir_decisao()` (a verdade da
decisão já fotografada) e antes de `resolver()`, um subconjunto **determinístico**
de blocos (selecionado por `hash2(x, y, tick)`, sem tocar o RNG do mundo) tem o
`alvo` sobrescrito por um vizinho livre que **não** é o escolhido. É experimento
(patch da nota, não código canônico): o mundo com o dedo diverge do mundo sem.

**Três arquiteturas de introspecção**, todas com a mesma heurística leiga de
motivo, diferindo só **no que leem**:

- **A — lê a ação** (a v1 canônica): explica onde o corpo foi parar.
- **B — lê o plano**: explica o que decidiu; nunca olha o que aconteceu.
- **C — monitor**: lê os dois; quando divergem, emite *"minha ação não é meu
  plano"* (a linha **detecta** da tabela de Gazzaniga).

**Predições, declaradas antes de rodar:**

- **B1 (A confabula):** nos forçados, a calibração de A desaba para a taxa de
  coincidência geométrica, e A segue nomeando motivos positivos para ações que o
  bloco não escolheu — nunca percebe o dedo (não tem como: só vê o corpo).
- **B2 (B é imune e cego):** a calibração de B nos forçados fica ≈ igual à dos
  livres (~0,78) — o dedo não a toca, porque B não olha o mundo. Em troca, B
  "mente" sobre o comportamento sem saber: descreve um passo que não aconteceu.
- **B3 (C detecta sem atribuir):** C flagra ~100% dos forçados cuja ação executada
  difere do plano, **e também** as negações naturais de `resolver()` — sem
  conseguir distinguir o dedo do espectador da física do mundo. Zero falso alarme
  nos livres. *Detecção sem atribuição de fonte.*
- **B4 (dose-resposta):** o κ canônico (coluna 18, arquitetura A) cai
  monotonicamente com a fração forçada; com fração 0, o patch é inerte e o CSV
  sai **bit-a-bit idêntico** ao canônico (sanidade do próprio patch).
- **B5 (conceitual, para a v3 §4):** nenhuma das três arquiteturas pode relatar
  *"fui forçado pelo espectador"*. De dentro de `f(seed)`, a intervenção de fora
  do mundo é indistinguível de física. O "detecta" de C é o teto epistêmico de um
  bloco: *algo* me moveu — nunca *quem*.

## 2.3 O placar do Bandersnatch ✅ *(nota 07 — as cinco predições confirmaram)*

Com ~25% forçado (média de 3 seeds): **A** (lê a ação) desaba a 0,244 nos
forçados e ainda nomeia motivo positivo em ~26% deles — confabula, nunca percebe;
**B** (lê o plano) fica em 0,806 ≈ livres — imune ao dedo, e descrevendo um passo
que não aconteceu; **C** (monitor) detecta 100% das negações da física e 99% dos
dedos, com **zero falso alarme** — e o mesmo sinal para os dois: *detecção sem
atribuição de fonte*. Dose-resposta do κ canônico: 0,67 → 0,62 → 0,48 → 0,29
(frações 0, 1/16, 1/4, 1/2), monotônica; com fração 0 o patch é **bit-a-bit
inerte**. A tabela de Gazzaniga virou **uma linha por arquitetura**.

Dois achados não encomendados: `accB` dos *negados* (0,888) supera a dos livres —
**as brigas acontecem onde todo mundo entende o porquê** (célula disputada é
célula legível); e ~1% dos dedos é **indetectável por princípio** — o dedo que
`resolver()` desfaz não deixa rastro contrafactual, e detectabilidade é
propriedade do rastro, não da introspecção.

**O que a Fase 2 deixa herdado à Fase 4:** tornar o relato **causal** (vizinhos
consumindo o sinal, mentira custando); instalar as arquiteturas A/B/C como
**traço herdável** e deixar a seleção escolher (predição registrada na nota 07:
com leitores que punem incoerência, C invade A); e o segundo vocabulário de
relato (separar "intérprete mudo" de "self sem biografia", nota 06 §4).

## O experimento do intérprete (Gazzaniga) ✅ *feito — rodou como §2.2/§2.3 (nota 07)*

Deve ser o **primeiro** experimento assim que o mostrador existir — e foi. O
desenho abaixo é o que estava escrito **antes** de rodar; o placar está em §2.3.
A tabela de desfechos, em particular, não sobreviveu como escrita: ela previa
três *tipos de sujeito* e o que se mediu foram três **arquiteturas de leitura** —
quem lê a ação confabula, quem lê o plano não percebe, quem monitora os dois
detecta. O desfecho é propriedade do intérprete, não do bloco.

1. O bloco decide — e a separação leitura×escrita do tick já isola o instante
   exato (`intencao_*` antes de `alvo_*`).
2. **Intervimos**: trocamos a ação executada.
3. Perguntamos ao relato: *por que você fez isso?*

| desfecho | o relato diz | leitura |
|---|---|---|
| **honesto** | nada / "não sei" | o relato só reporta o que acessa |
| **detecta** | "minha ação não corresponde ao meu plano" | há monitoramento de discrepância |
| **confabula** | "porque eu estava com fome" | o relato *racionaliza* uma ação que não escolheu |

O terceiro é o achado do cérebro dividido, reproduzido num brinquedo de 56 KB de
C. E note o que ele faz com a régua: transforma `relato` de medida
**correlacional** em medida **intervencional** — exatamente a família que, na
Fase 1, foi a única a dizer a verdade.

**Risco:** confundir o sinal *emitido* com o estado *representado*. Um relato bem
calibrado é evidência de calibração, não de experiência. Escrever isso em letras
garrafais antes de o primeiro `@` "falar".

---

# Fase 3 — O custo de pensar

**Pergunta:** quando vale a pena pensar?

Esta seção foi reescrita quatro vezes porque a simulação derrubou três hipóteses
minhas — e depois o conserto do bug §1.6 invalidou metade dos números da quarta.
Vale registrar o cemitério, porque o cadáver de cada hipótese apontou a próxima, e
porque a cultura do projeto é essa: **medir, não achar**.

Todos os números abaixo vêm do `main.c` **com a reprodução consertada**.

## Três hipóteses mortas

**H1 — "pensar é de graça, logo o horizonte cresce até o teto."** Falso, mas
quase me enganou duas vezes. Em 30 000 ticks agora evolutivamente válidos, `hor_m`
termina em **11,04 / 4,88 / 3,40** (seeds 7 / 42 / 1234). A seed 7 encosta em
`HORIZONTE_MAX = 12`; as outras duas **caem**. Se eu tivesse olhado só a seed 7,
teria "confirmado" H1. *(A "subida inicial" que vi lá atrás em 2000 ticks é
transiente: `semear_blocos` sorteia `horizonte` **uniforme em 1..12**, média 6,5 —
não 6, como o `#define HORIZONTE` sugere.)*

**H2 — "a paisagem adaptativa é plana, o traço deriva."** Não sustentada. `hor_sd`
cai de ~3,45 (uniforme inicial) para 0,70–3,10, e as médias se estabilizam. Algo
segura o traço.

**H3 — "o freio é a competição: você planeja rebrota que o rival come antes."**
Falso, e ao contrário. Com `COMPETICAO = 0` os horizontes evoluídos ficam **mais
rasos**. A competição não freia o pensamento: **alimenta** o pensamento.

## E uma quarta descoberta, que explica as três

`horizonte` e `desconto` são **traços compensatórios**. No regime tardio,
`corr(hor_m, desc_m)` = **−0,93 / −0,46 / −0,72**. Um bloco com horizonte 11 e
desconto 0,66 pesa o 3º passo em `0,66³ ≈ 0,29` e o 11º em `0,01`: ele *declara*
um horizonte fundo e **pensa raso**. A profundidade que de fato importa é
`min(horizonte, 1/(1−desconto))`:

| seed | `hor_m` | `desc_m` | `1/(1−δ)` | **profundidade efetiva** |
|---|---|---|---|---|
| 7 | 11,04 | 0,661 | 2,95 | **2,95** |
| 42 | 4,88 | 0,873 | 7,86 | **4,88** |
| 1234 | 3,40 | 0,898 | 9,80 | **3,40** |

O `hor_m` bruto varia **3,2×** entre as seeds; a profundidade efetiva varia
**1,7×**. Boa parte da "divergência entre seeds" que matou H1, H2 e H3 era um
artefato de olhar um traço **não identificável** isoladamente. **`hor_m` sozinho
não mede o quanto um bloco planeja.** Qualquer conclusão sobre profundidade de
planejamento precisa do par `(horizonte, desconto)`.

## O que os dados dizem de fato

**Paisagem de grupo.** Fixando `horizonte = h` para toda a população (preservando
o fluxo do RNG, então mundo e demais traços ficam idênticos), a população de
equilíbrio (média das 3 seeds, ticks 500–3000) cai **monotonicamente**:

| h | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 12 |
|---|---|---|---|---|---|---|---|---|
| pop | **295,9** | 295,0 | 293,6 | 292,7 | 290,6 | 289,8 | 289,4 | 289,3 |

Quanto mais fundo a população pensa, **menor** ela é. O ótimo de grupo é `h = 1`.
*(Com o bug §1.6, esta curva tinha um falso pico em `h = 2` e um vale artificial em
`h = 1`: blocos míopes se empacotam, nascem muito, esgotavam os slots primeiro.)*

**Aptidão individual.** Ensaio de invasão: população 50/50 de `h = 3` e `h = 9`,
**sem mutação**, herança exata. Frequência de `h = 9`:

| tick | 0 | 1000 | 2000 | 4000 |
|---|---|---|---|---|
| seed 7 | 0,42 | 0,71 | 0,84 | **0,91** |
| seed 42 | 0,55 | 0,76 | 0,83 | **0,87** |
| seed 1234 | 0,42 | 0,73 | 0,83 | **0,85** |

O planejador fundo **desloca** o raso, monotonicamente, nas três seeds.

## A conclusão, e ela é forte

> Pensar mais fundo é **individualmente vantajoso** e **coletivamente ruim**. O
> horizonte cognitivo é um **bem posicional** — uma corrida armamentista.

É por isso que a competição alimenta o pensamento em vez de freá-lo (H3): o ganho
de olhar fundo está principalmente em **ganhar a célula disputada do vizinho**,
não em fazer o bolo crescer. Cada bloco precisa pensar mais fundo só para
permanecer no lugar — Rainha Vermelha.

E o freio (H1, H2) não é energia nem deriva: é o **decaimento geométrico do peso
do futuro** — e, sobretudo, a compensação via `desconto`. Uma população pode
"comprar" horizonte barato baixando `desconto`, e é exatamente o que a seed 7 faz.

**Ressalvas honestas.** População de equilíbrio é proxy de *grupo*; a invasão mede
aptidão *relativa*. O descasamento entre os dois **é** o achado. Só testei o par
3×9, e bens posicionais são intrinsecamente **frequência-dependentes**. `HORIZONTE_MAX`
= 12 **censura** a seed 7 (`hor_m` 11,04). O ESS do horizonte é **desconhecido**.

## O que fazer, então

1. **Torneio de invasão par-a-par** (`h_i` × `h_j`, matriz 12×12, por seed): com só
   dois valores na população, `hor_m` no CSV *é* a frequência. Sai daí o ESS e o
   grau de dependência de frequência. Barato e informativo. Fixar `desconto` no
   torneio — senão a compensação contamina o resultado.
2. **O custo de pensar**, agora com um significado preciso. Ele não "cria um
   gradiente onde não há" (H2, morta) nem "contém uma catraca" (H1, morta). Ele
   **internaliza uma externalidade**: hoje o planejador fundo impõe ao comum um
   custo que não paga. `METABOLISMO + c · horizonte` faz o pensador pagar a própria
   corrida armamentista. É um **imposto pigouviano sobre a cognição**.

   Predições falseáveis:
   - o `h` evoluído deve **cair em direção ao ótimo de grupo** conforme `c` sobe —
     uma curva dose-resposta `h*(c)`;
   - existe um `c` em que o `h` evoluído **coincide** com o ótimo de grupo:
     interesse individual e coletivo alinhados. Uma coincidência *prevista* é um
     teste forte;
   - a **profundidade efetiva** (não o `hor_m` bruto) deve encolher, e a
     compensação via `desconto` deve aparecer como uma resposta correlacionada;
   - em manchas ricas a corrida vale o imposto; em manchas pobres, não → **nichos
     espaciais**, sem ninguém programar nicho. É a ponte para a Fase 4, e a razão
     de o custo vir antes dela.
3. **Cuidado com o custo escolhido.** Se `c` for cobrado por *passo declarado*
   (`horizonte`), um bloco escapa do imposto baixando `desconto` e mantendo o
   horizonte — pagaria por passos que já não pesam. Cobrar pela profundidade
   *efetiva* é mais honesto e mais difícil. A escolha é uma tese, não um detalhe.

## Corolário desconfortável

A narrativa "a evolução aprende a planejar mais longe" é, na melhor das hipóteses,
mal formulada — `hor_m` não é identificável sozinho. E na parte em que é
verdadeira, **não é a boa notícia que parece**: a inteligência, aqui, não torna a
população melhor. É uma corrida que cada indivíduo precisa correr para ficar
parado, e que sai cara para todos. Se isso vale para o bicho de 56 KB, vale a
pergunta para os outros.

# Fase 4 — Vida artificial: instalar **mecanismos**, nunca **fenômenos** *(em andamento — §4.0–4.3 entregues)*

**Pergunta:** que comportamentos emergem, sem que ninguém os programe?

> **Onde esta fase está** (2026-07-27): o sinal de intenção foi pré-registrado
> (§4.0) e entregue (§4.1, nota 08) — o relato virou causal e a honestidade
> evoluiu sozinha. Dos três fios que a nota 08 herdou, dois rodaram nesta
> sessão e fecham os dois `⛔` internos da `FILOSOFIA_v3.md`: a
> **arquitetura de escuta** como traço (§4.2, nota 29 — instalada sem custo,
> deriva neutra confirmada) e o **auto-modelo temporal** (§4.3, nota 30 — o
> contrafactual "eu poderia ter ido para a esquerda" virou mecanismo real, e
> a seleção converge para um `peso_arrependimento` **negativo**, não o
> positivo que o desenho apostava). Os dois fios que ficaram abertos rodaram
> em 2026-07-29: o **custo da escuta** (§4.4, nota 31) instalou o mecanismo
> (`ESC_MONITOR` desconta vizinhos cronicamente negados) e achou o sinal mais
> limpo na deriva do início misto (`esc_monitor_f` sobe consistente nas 3
> seeds) — mas a invasão direta (R4) e a comparação isolada (R3) saíram
> mistas. A **invasão direta** do arrependimento (§4.5, nota 32) **não fechou**
> o argumento de Q5: em 5 das 6 corridas, o vencedor segue a paridade do
> índice, não o valor do traço — a mesma assinatura de efeito fundador que a
> nota 30 já tinha descrito, agora vista de novo com valores diferentes. A
> extensão de 10 seeds (§4.6, nota 33) fecha **T1**: `−2,0` × `0,0` é
> **fundador puro** (1/10 REAL, mais nítido que o 3/3 da nota 32) — e a
> própria nota pegou um bug na classificação automática do script antes de
> aceitar o veredito (a primeira leitura, com bug, dizia o oposto). **T2**
> (`−2,0` × `2,0`) continua sem decidir: 6/10 na nota 33, e a segunda extensão
> de 20 seeds (§4.7, nota 34) leva o pool a 20/30 — **uma seed** abaixo do corte
> pré-registrado (21/30) —, com as 20 corridas REAL favorecendo `−2,0` **sem
> exceção**. Em 2026-08-09 o fio muda de natureza: em vez de contar mais seeds,
> o **nulo do classificador** (§4.8, nota 35) mede pela primeira vez a taxa de
> base que as notas 32–34 declararam três vezes e nunca quantificaram. O nulo
> inerte confirma a álgebra (traço sem efeito **nunca** produz REAL: 0/10) e
> mostra o tamanho do confundidor (9/10 seeds vão a fixação quase total por
> deriva pura); o nulo ativo — mesma dose, direção destruída — fabrica
> **9/30 = 30%**. Contra ele, os 20/30 de T2 dão **p = 0,0092** (Fisher), e a
> consistência direcional da nota 34 dá **p = 0,0002** contra um nulo que é
> moeda (3/9). **O veredito de T2 não muda** — o corte era 21/30 e fica —, mas
> "não decide" deixa de significar "sinal indistinguível de ruído" e passa a
> significar "sinal medido contra um corte calibrado sem saber onde ficava o
> zero". E em 2026-08-09 a fase entrega um item que não é de vida artificial mas
> herdou a numeração: a **ablação do id** (§4.9, nota 36), a última palavra da
> §3 a ser cobrada — ela **não paga a entrada** em população (2/8), e o controle
> de sanidade reencontrou o piso do `float32` agindo sobre a **decisão**, não só
> sobre o mostrador. Com ela a `FILOSOFIA_v3` fechou. Em 2026-08-10 a
> **divergência de trajetória** (§4.10, nota 37) fecha a ameaça que a nota 35
> declarou e não mediu — a régua cega a qual valor vence dá **15 × 15**, os dois
> braços perturbam o mundo exatamente na mesma medida, e o `p = 0,0092` fica sem
> ressalva. Mas o que a nota entrega de maior não era a pergunta dela: a
> **diferença pareada** das duas montagens (`d = f_ímpar^A − f_ímpar^B`), cega ao
> efeito fundador **por construção**, dá **28/30** contra um nulo de **15/30
> exato**, e **9 das 10** corridas que o classificador binário descartara como
> FUNDADOR carregam o mesmo sinal. **Q5 tem resposta:** a seleção favorece
> `peso_arrependimento` negativo. O veredito binário de T2 continua sendo o que
> era — o corte fica —, mas agora se sabe que ele era uma régua de baixo poder,
> e que a boa estava disponível desde a nota 30. Segue aberta, sem pré-registro:
> o blefe residual como ESS (varrer a frequência).

Nichos, especiação, cooperação, comunicação, predação. Talvez seja aqui que mora
o ouro. Mas há uma armadilha de categoria que precisa estar escrita:

> **Não se adiciona um nicho. Não se adiciona cooperação.**
> Adiciona-se um *trade-off* e o nicho aparece — ou não aparece, e **isso é o
> resultado**. Adiciona-se uma estrutura de payoff e a cooperação evolui — ou
> não, e isso também é resultado.

Listar "nichos, especiação, cooperação, predação" é listar *desfechos desejados*.
A invariante do projeto — *o comportamento global deve **emergir*** — proíbe
instalá-los. O que se instala é a **pressão**. O custo de pensar (Fase 3) é a
primeira pressão real, e por isso ela vem antes desta fase.

## E o sinal precisa custar

A tentação é `float sinal;` — um bloco deixa, outro lê, "está aberta a porta da
comunicação evolutiva". Não está. **Cheap talk é instável**: se sinalizar é
grátis, a mentira domina e o sinal degenera em ruído (Maynard Smith; as saídas
clássicas são custo — Zahavi — ou interesse comum, como parentesco). Um sinal
que ninguém é *pressionado* a ler, e cuja mentira não *custa*, é decoração
determinística: o experimento nasce respondido.

## 4.0 Pré-registro do sinal de intenção — o relato causal *(2026-07-10, antes de rodar)*

**O mecanismo.** O nível 5 sempre teve um leitor embutido: `pretendentes_em()` lê
`intencao_*` dos vizinhos — **telepatia**, acesso perfeito à mente alheia. O
relato causal a substitui por **comunicação**: entre `declarar` e `decidir`, cada
bloco **emite** um sinal sobre a própria intenção (`emitir`, arrays `sinal_*`), e
`pretendentes_em` passa a ler o *sinal*, não a mente. O canal satisfaz as duas
cláusulas anti-cheap-talk sem nenhuma multa artificial: os leitores **já são
pressionados a ler** (o efeito medido de `ANTECIPACAO` — pop +5–7%), e a mentira
**custa endogenamente** — o sinal só *repele* (via `ANTECIPACAO`); blefar gasta a
deterrência numa célula que o blefador não vai tomar e **expõe o alvo verdadeiro**
à disputa.

**A estratégia é traço herdável** (nível 6, com mutação): `HONESTO` (sinal =
intenção), `MUDO` (sinal = própria célula — silêncio: ninguém mira célula
ocupada), `BLEFE` (sinal = o melhor alvo que **não** é a intenção). Semeadura em
terços; a seleção decide.

**Predições, declaradas antes de rodar:**

- **S1 (refactor inócuo):** com todos honestos, sinal ≡ intenção e o mundo é
  **bit-a-bit idêntico** ao da telepatia. Demonstrável; verificar. *(É o passo 1,
  commitado separado: a física não muda, só a epistemologia.)*
- **S2 (o canal carrega comportamento):** mundo todo-MUDO × todo-HONESTO
  reproduz o efeito `ANTECIPACAO` (população maior e mais enxuta com o canal
  aberto). A família *ablação* do relato ganha dentes: **silêncio muda o mundo**
  — fim do epifenomenalismo da v1.
- **S3 (silêncio = eremita epistêmico):** no mundo todo-MUDO, `pret ≡ 0` e
  `modelo_do_outro` lê **0 exato** (demonstrável). Não perceber o outro e o
  outro não falar são, para a régua, o mesmo estado.
- **S4 (honestidade fixa contra o silêncio):** invasão 50/50 sem mutação →
  `HONESTO` desloca `MUDO`. Mecanismo: quem sinaliza o alvo o ganha sem disputa
  (deterrência); quem cala disputa e perde metade dos empates.
- **S5 (honestidade resiste ao blefe):** 50/50 `HONESTO` × `BLEFE` → `HONESTO`
  vence, pelo custo endógeno do blefe. **Risco declarado, em voz alta:** se o
  blefe vencer, o canal degenera em ruído — cheap talk instável, Maynard Smith
  reproduzido no brinquedo — **e isso é o resultado**, não um fracasso.
- **S6 (do início diverso):** semeando em terços com mutação, `hon_f → ~1` em
  30 000 ticks, nas 3 seeds.

## 4.1 O placar do sinal ✅ *(nota 08 — e dois erros de direção que viraram achado)*

Construído em `bde0946` (S1) e `c924fbd` (a estratégia como traço). S1 ✅
bit-a-bit; S3 ✅ todo-mudo → `modelo_do_outro` = **0,0000** exato; S4 ✅ honesto
fixa contra mudo (0,50 → **0,95/0,97/0,95**); S5 ✅ honesto resiste ao blefe (0,50
→ **0,81/0,96/0,87**) — **o cheap talk não degenerou o canal**.

Dois desvios do pré-registro, ambos informativos:

- **S2 acertou o fato, errou a direção.** O canal carrega comportamento — mas o
  que ele move é a **energia** (~5,7 honesto × ~6,5 mudo, 3 seeds), **não a
  população** (fica igual). Coordenar não faz caber mais gente no alimento finito;
  faz a mesma gente viver mais apertada. Eu teria "confirmado" S2 na direção
  errada olhando só a demografia.
- **S6 não fixou: é polimorfismo.** `hon_f → 0,83/0,90/0,88` (domina), o **mudo é
  varrido**, mas o **blefe persiste em ~10%** estável — equilíbrio misto
  frequência-dependente, a assinatura de sinalização com honestidade custosa
  parcial. Mais realista que a fixação que previ.

**Fim do epifenomenalismo do relato:** silenciar a população muda o mundo. E a
honestidade é ESS sem ninguém decretá-la — a matéria do **superego** da v3 §3.
Herda à Fase 4: o blefe residual como ESS (varrer a frequência), memória de
sinais (reputação) como 2ª rota anti-cheap-talk, e o **Bandersnatch evolutivo**
(a arquitetura de *escuta* como traço, ao lado da de *fala*).

## 4.2 Pré-registro da escuta evolutiva — a arquitetura de introspecção como traço *(2026-07-27, antes de rodar)*

**O mecanismo.** A nota 07 mediu três arquiteturas de introspecção — a mesma
heurística leiga do mostrador `relato` (nota 06), diferentes só **no que leem**
— mas como um *patch do observador*: todas as três rodavam sobre a mesma
população, calculadas de fora, nunca instaladas em bloco nenhum. A ameaça à
validade que a própria nota 07 registrou (§ "Ameaças à validade"): *"o passo
evolutivo... é o que transformaria a tabela em resultado de seleção; hoje ela é
resultado de intervenção."* Este pré-registro dá esse passo — mas só a
metade dele (ver "o que este pré-registro NÃO faz", abaixo).

`relato_prepara()` já fotografa, antes de `resolver()`, o alvo cognitivo
(`alvo_x/y`) e os dois argmax leigos (`rel_cx/rel_cy` por comida crua,
`rel_ex/rel_ey` por espaço) que valem tanto para a verdade da decisão quanto
para o relato. Passa a fotografar também o alvo em si num par `plano_x/plano_y`
— hoje essa posição se perde quando `resolver()` sobrescreve `alvo_*` dos
negados. Com isso, três leituras da MESMA fotografia ficam disponíveis para
`medir_relato()`:

- **ESC_ACAO** (a leitura única de hoje): classifica a posição **final**
  (`blocos[i].x/y`, pós-`resolver()`) contra os argmax leigos.
- **ESC_PLANO**: classifica `plano_x/plano_y` (pré-`resolver()`) contra os
  mesmos argmax — imune à física de `resolver()`, do jeito que a nota 07
  descreveu a arquitetura B ("nunca olha o mundo").
- **ESC_MONITOR**: compara ação × plano; se coincidem, relata como ESC_ACAO
  (as duas leituras concordam trivialmente quando não há negação); se
  divergem, relata `REL_NAOSEI` — a arquitetura C da nota 07 não tem canal
  para nomear um motivo quando detecta a própria negação, só para admitir que
  detectou.

**A arquitetura é traço herdável** (nível 6, com mutação, campo `escuta` em
`Bloco`): semeadura em terços, como a estratégia de fala (§4.0). Mas, ao
contrário de `estrategia`, `escuta` **não é lida por ninguém** nesta nota — não
alimenta `utilidade()`, `pretendentes_em()` nem qualquer decisão. Só troca qual
fórmula `medir_relato()` usa para aquele bloco específico.

**O que este pré-registro NÃO faz, de propósito:** não liga `escuta` a nenhum
custo ou vantagem. A nota 07 já previu o resultado esperado desse desenho —
*"sem custo, deriva neutra; com leitores que punem incoerência, C invade A"* —
e o primeiro semestre dessa frase é barato de confirmar isolado, sem desenhar
ainda o mecanismo de custo (que é a parte difícil: como um vizinho "pune"
incoerência, quando o próprio traço não é observável de fora). Este é o **S1**
desta nota — instalar o traço, provar que ele não faz nada por conta própria —
no mesmo espírito do S1 do §4.0 (o refactor inócuo). O mecanismo de custo, se
os dados aqui confirmarem a deriva neutra, é o pré-registro seguinte.

**Predições, declaradas antes de rodar:**

- **P1 (instalação inócua):** com `escuta` variando livremente (herdado, com
  mutação, semeado em terços) a simulação inteira é **bit-a-bit idêntica**,
  coluna por coluna, à mesma seed sem o traço — `pop`, `energia_media`,
  `comida_total`, os quatro traços, `modelo`, `agencia`, `modelo_do_outro`,
  `phi`, `hon_f`, `blef_f`, `autocausa`. Só `relato` e as colunas novas podem
  mudar. Mais forte que o S1 do §4.0: lá "todos honestos" precisava reproduzir
  a telepatia; aqui **qualquer mistura** de arquiteturas tem que deixar o mundo
  intocado, porque `escuta` não é lida em lugar nenhum do tick.
- **P2 (compatibilidade retroativa):** com toda a população em `ESC_ACAO`, a
  coluna `relato` é **idêntica** à de hoje (a leitura já era essa, sem nome).
- **P3 (ordem esperada do kappa, populações homogêneas):** `ESC_PLANO` ≥
  `ESC_ACAO`, porque ação e plano só divergem nos ~6% negados por `resolver()`
  (nota 06) — e é exatamente aí que a nota 07 mediu a arquitetura B mais
  precisa que a A (`accB` 0,888 × `accA` 0,441 nos negados). O efeito no kappa
  da população inteira deve ser **modesto** (a maioria dos ticks é "livre",
  onde as três leituras coincidem), não da magnitude da tabela da nota 07 (que
  isolava os negados). `ESC_MONITOR` deve ficar **abaixo** de `ESC_PLANO` nos
  negados — responder `NAOSEI` é uma admissão, não um acerto, quando a verdade
  não é `NAOSEI`.
- **P4 (deriva neutra):** semeando em terços com mutação e deixando rodar (3+
  seeds, 30 000 ticks, como o S6 do §4.0), **não deve haver direção
  consistente entre seeds** — ao contrário de `hon_f`, que a nota 08 mediu
  convergindo para perto de 1 nas três seeds testadas. Se as três seeds desta
  nota também convergirem na mesma direção, é sinal de um efeito de fitness
  que este desenho não devia ter — e isso derruba P1, não só P4.

**Reproduzir (script a escrever):** `sh papers/notes/29-escuta-evolutiva.sh`.

## 4.3 Pré-registro do auto-modelo temporal — aprender com o que não se fez *(2026-07-27, antes de rodar)*

**O problema, como a v3 §4 o deixou.** O bloco não carrega a própria
trajetória: não há substrato para "eu poderia ter ido para a esquerda" — uma
crença modal, falsa num universo `f(seed)`, e funcionalmente indispensável em
qualquer agente que aprenda com o que deixou de fazer. Ao contrário da escuta
(§4.2), a v3 é explícita que aqui **não basta medir**: "mexe na simulação, não
na régua". Este pré-registro instala uma faculdade nova, não um mostrador.

**O mecanismo — o contrafactual que o próprio tick já quase calcula.**
`melhor_celula()` (nível 4/5) já varre as células alcançáveis e escolhe o
argmax. Guardando também a **segunda melhor** (`vice_x/vice_y`, a "vice-célula" — com
seu próprio critério de desempate, o mesmo `>` estrito do argmax principal) a
decisão fica com um contrafactual concreto: "se o alvo não desse
certo, era esta a minha segunda aposta." `resolver()` já decide, todo tick,
quem é **negado** (`alvo_x/y` reescrito para a posição atual). Um bloco negado
cuja vice-célula estava **livre no início do tick** (portanto alcançável, e
ninguém a disputou) tem agora um contrafactual **verificável**, não
especulativo: ele poderia ter ido para lá, e ninguém o impediria. É o caso
exato que a v3 nomeia.

O **arrependimento** desse tick é `prever_valor(vice) − prever_valor(posição
final)` quando positivo (a vice-célula parecia melhor que ficar parado). Um
novo estado persistente por bloco, `remorso[i]` (não um traço — um *estado*,
como `real_acum`/`peso_janela` já são), acumula esse sinal com o mesmo
decaimento do desconto do bloco (`remorso[i] = remorso[i]*desconto +
arrependimento`) — a memória de curto prazo que a v3 pede, sem precisar
guardar um histórico de posições. O traço herdável (nível 6, campo
`peso_arrependimento`, mutação, semeado em torno de 0 com folga para os dois
lados) decide **quanto** `remorso[i]` pesa de volta em `utilidade()`: um termo
que empurra a escolha para células com mais espaço livre quando o bloco
anda "arrependido" — a mesma direção que o contrafactual apontava (a
vice-célula, nos casos que geram `remorso`, tende a ser uma célula menos
disputada; é por estar livre e não reivindicada que ela sobra como vice
alcançável). `peso_arrependimento = 0` é o bloco de hoje: sem memória, sem
aprendizado, ablação natural embutida no próprio traço.

**Por que isto é diferente da `agencia` e do `modelo_do_outro`.** Aqueles
mostradores **varrem um eixo hipotético** (λ, α) sem que o bloco jamais opere
naquele contrafactual — são a régua perguntando "faria diferença?", de fora.
Aqui o contrafactual **entra na decisão de verdade**, tick após tick, e a
seleção natural decide se vale a pena carregá-lo. É a diferença entre medir
agência e ter agência sobre o próprio agir passado.

**Predições, declaradas antes de rodar:**

- **Q1 (ablação natural):** `peso_arrependimento ≡ 0` para toda a população
  produz simulação **bit-a-bit idêntica** à de hoje (sem o mecanismo) — o
  termo em `utilidade()` desaparece exatamente, não aproximadamente.
- **Q2 (o remorso acontece, e é raro-mas-real):** numa população de controle
  (traço fixo em algum valor positivo pequeno, sem mutação), a fração de
  ticks com `arrependimento > 0` fica na mesma ordem de grandeza da taxa de
  negados da nota 06 (~6%) — não pode ser maior (é um subconjunto dos
  negados) nem desprezível.
- **Q3 (aprender com o passado ajuda, ou não — registrado em voz alta):**
  comparando população com `peso_arrependimento` fixo positivo × fixo em 0
  (mesma seed, sem mutação no traço), a hipótese é que a taxa de negados
  **cai** ao longo da simulação para quem aprende (o viés de espaço afasta o
  bloco de células disputadas antes de errar de novo) — mas o risco declarado
  é que o sinal seja tão raro (Q2) que o efeito populacional se perca no
  ruído, ou que reforçar `peso_espaco` de forma cega prejudique quem não
  estava mesmo perto de uma disputa. Qualquer um dos dois é resultado, não
  fracasso do desenho.
- **Q4 (invasão):** 50/50 `peso_arrependimento` positivo × zero, sem mutação
  no traço — se Q3 se confirmar, o aprendiz desloca o não-aprendiz; se não,
  o não-aprendiz não perde terreno (não há custo intrínseco em não
  aprender, só a oportunidade perdida).
- **Q5 (deriva a partir do diverso):** semeando `peso_arrependimento` em torno
  de 0 com folga, com mutação, 30 000 ticks, 3+ seeds — a média da população
  se desloca para longe de 0 (na direção que Q4 favorecer) ou fica perto de 0
  (aprendizado é adaptativamente indiferente neste mundo). As duas são
  publicáveis; a v3 §4 só precisa saber qual.

**Reproduzir (script a escrever):** `sh papers/notes/30-auto-modelo-temporal.sh`.

## 4.4 Pré-registro do custo da escuta — desconfiança por vizinho *(2026-07-29, antes de rodar)*

**O mecanismo.** A nota 29 instalou `escuta` sem nenhuma consequência real, de
propósito — "sem custo, deriva neutra" era a metade fácil. O que ficou em
aberto (nota 29, "O que ficou em aberto"): *"memória de sinais (reputação)...
um vizinho com ESC_MONITOR que flagra outro bloco incoerente poderia parar de
se deixar repelir pelo sinal daquele bloco."* Este pré-registro dá o
mecanismo concreto, sem precisar de telepatia sobre a intenção alheia (só o
que já é publicamente observável: o sinal emitido e o resultado real).

`pretendentes_em()` hoje conta, sem distinção, quantos vizinhos sinalizaram a
mesma célula — cada um desvaloriza via `ANTECIPACAO`, igual para todos.
`atualizar_remorso()` já calcula, tick a tick, para **todo** bloco (não só
para si) se ele foi **negado** por `resolver()` — só falta expor esse
booleano. Um vizinho cronicamente negado é um vizinho cujo sinal, mesmo
honesto, nunca se confirma: continuar se afastando dele custa oportunidade
real, não evita disputa real. Um bloco com `escuta == ESC_MONITOR` passa a
acumular, por vizinho **atualmente visível** (`desconfianca[i][j]`, matriz
`MAX_AG × MAX_AG`, decaindo pelo **próprio desconto de `i`** — o mesmo idioma
de `remorso[]`), quantas vezes aquele vizinho específico foi negado
recentemente. `pretendentes_em`, só para quem tem `ESC_MONITOR`, pesa cada
sinal concorrente por `1/(1+desconfianca[i][j])` em vez de contar 1 cheio;
`ESC_ACAO`/`ESC_PLANO` continuam contando cheio, comportamento de hoje, sem
mudança nenhuma. É a primeira vez que as três arquiteturas de escuta
diferem por **comportamento**, não só pelo mostrador `relato` — e sem multa
artificial: o "custo" de não ser `ESC_MONITOR` é só a oportunidade perdida de
descontar sinais que a experiência local já desmentiu, e só existe **se**
descontar ajudar de fato.

Índices de bloco são reciclados (`alocar_slot()`); `desconfianca[i][j]` não é
limpa quando o slot `j` (ou `i`) troca de dono — a mesma aproximação que
`remorso[]` já tolera, sem tratamento especial. Declarado aqui, não
escondido: é ruído esperado, não um bug a caçar.

**Predições, declaradas antes de rodar:**

- **R1 (instalação inócua para quem não é `ESC_MONITOR`):** com toda a
  população em `ESC_ACAO` (ou toda em `ESC_PLANO`), `pretendentes_em` nunca
  lê `desconfianca` — o resultado é **idêntico bit a bit** ao `main.c` de
  antes deste patch (a soma inteira de sempre, só que num `float` que
  representa exatamente cada inteiro 0–8).
- **R2 (a desconfiança se acumula, rara-mas-real):** numa população 100%
  `ESC_MONITOR`, alguma fração não-trivial (nem ~0%, nem ~100%) dos pares
  vizinho-atual acaba com `desconfianca[i][j] > 0` ao longo de uma corrida —
  a mesma ordem de grandeza da taxa de negados que a nota 30 já mediu
  (8,7–9,7% dos ticks-de-bloco), porque é o mesmo evento visto por fora.
- **R3 (descontar ajuda, ou não — registrado em voz alta):** `ESC_MONITOR`
  × `ESC_ACAO`, populações homogêneas separadas, mesma seed — comparar taxa
  de negados e população/energia ao longo do tempo. Hipótese: `ESC_MONITOR`
  reduz sua própria taxa de negados (descontar um vizinho não-confiável
  libera uma célula que a contagem ingênua teria evitado); risco declarado:
  o efeito pode ser pequeno demais para aparecer fora do ruído, ou pode não
  existir — qualquer um dos dois é resultado.
- **R4 (invasão):** 50/50 `ESC_MONITOR` × `ESC_ACAO`, sem mutação em
  `escuta`, montagens espelhadas por paridade de índice (o desenho exato do
  Q4 da nota 30) — se R3 confirmar vantagem, `ESC_MONITOR` desloca `ESC_ACAO`
  de forma consistente nas duas montagens; senão, sem vencedor consistente.
- **R5 (deriva do início misto, agora COM o mecanismo ligado):** semeando
  `escuta` em terços com mutação, 30 000 ticks, 3 seeds — ao contrário da
  deriva neutra que a nota 29 mediu sem custo nenhum (P4), se R3/R4
  confirmarem vantagem real, espera-se alguma direção para `ESC_MONITOR`
  (não necessariamente fixação — o próprio mecanismo só ajuda quando há
  vizinhos cronicamente negados para descontar).

**Reproduzir (script a escrever):** `sh papers/notes/31-custo-da-escuta.sh`.

## 4.5 Pré-registro da invasão direta do arrependimento — fechar o argumento de Q5 *(2026-07-29, antes de rodar)*

**O problema.** A nota 30 (Q3/Q4) testou `peso_arrependimento` positivo ×
zero e não achou vencedor (invasão 50/50, placar exato 3×3). Mas a mesma
nota (Q5), semeando o traço livre em `[-2,2]` com mutação, achou a seleção
convergindo **consistentemente para negativo** nas três seeds — a região
errada do domínio, que Q3/Q4 nunca testaram. A própria nota 30 registrou a
ameaça à validade: convergência sob mutação livre pode refletir uma
assimetria perto das bordas do domínio de mutação, não seleção de verdade.
Fecha-se o argumento com uma invasão direta — o mesmo desenho exato do Q4
(50/50, **sem mutação** no traço, duas montagens espelhadas por paridade de
índice, 3 seeds, 30 000 ticks), só trocando os valores. Nenhum código novo:
é o mesmo `main.c` da nota 30, o mesmo harness (`gen invasao "res,inv"`),
valores diferentes.

**Predições, declaradas antes de rodar:**

- **T1 (negativo vs. zero):** `-2,0` desloca `0,0` de forma consistente nas
  duas montagens espelhadas — diferente do empate 3×3 que Q4 mediu para
  positivo × zero. Se Q5 estiver certa sobre a direção real da seleção, esta
  é a comparação que devia mostrar um vencedor claro.
- **T2 (negativo vs. positivo):** `-2,0` desloca `2,0` — mais forte que T1,
  já que Q5 mostrou o traço se afastando do zero especificamente **na
  direção negativa**, não só evitando o zero.
- **T3 (condicional — só roda se T1 e/ou T2 confirmarem):** blocos com
  `peso_arrependimento` fortemente negativo mostram `agencia` mais baixa que
  blocos com o traço em zero — a hipótese mecânica da nota 30 §4 (parar de
  fugir do espaço disputado, depois de negado, aproxima o bloco do reflexo
  que a nota 03 já documentou matando a `agencia` por outro caminho). Se
  T1/T2 não confirmarem (a seleção de Q5 não bate com competição direta),
  T3 não roda — não há hipótese a testar.

**Reproduzir (script a escrever):** `sh papers/notes/32-invasao-arrependimento.sh`.

## 4.6 Pré-registro da extensão da invasão do arrependimento — 10 seeds fecham a contagem que 3 não bastaram *(2026-07-30, antes de rodar)*

**O problema.** A nota 32 (§4.5) rodou T1/T2 em 3 seeds e não decidiu: 5 das
6 comparações mostraram a assinatura de efeito fundador (a paridade do
índice vence nas duas montagens espelhadas, não o valor do traço); só 1/6
(seed 42, T2) foi na direção que a nota 30 (Q5) apostou. A própria nota 32
registrou o problema em voz alta: não havia, no pré-registro original, um
número mínimo de seeds que separasse "sinal real, pequeno, afogado pelo
efeito fundador na maioria das corridas" de "ruído, e a seed 42 caiu do lado
certo por acaso" — e sugeriu, como próximo passo natural, mais seeds (10+,
o mesmo remédio que a nota 11 aplicou à régua inteira) ou uma população
maior. Esta extensão escolhe seeds: mesmo desenho exato (T1: −2,0 × 0,0;
T2: −2,0 × 2,0; 50/50, sem mutação no traço, duas montagens espelhadas por
paridade de índice, 30 000 ticks), agora com **10 seeds novas e
sequenciais** (`1..10`, a convenção da nota 11) — não as 3 seeds da nota 32,
para não reaproveitar corridas cujo resultado já se conhece. Nenhum
mecanismo novo: mesmo `main.c`, mesmo harness `invasao`.

**Por que 10 seeds pode não bastar — declarado antes de rodar.** A nota 31
mediu o mesmo padrão noutro traço: mesmo com um mecanismo real confirmado
por outro caminho (R5, `esc_monitor_f` subindo em 3/3 seeds), a invasão
direta pareada (R4) ficou confundida pelo efeito fundador em 2 das 3 seeds.
Se o efeito fundador é **estrutural** ao harness (a metade do espaço que
nasce vizinha de um recurso melhor prospera, quase independente do traço),
mais seeds não elimina o confundidor — só permite **contar** através dele, e
só se a vantagem real for grande o bastante para deslocar a fração de
vitórias "independente de paridade" bem acima do que o próprio efeito
fundador produziria sozinho (uma taxa de base que este projeto nunca mediu
num traço comprovadamente neutro). Esta extensão é uma tentativa honesta,
não uma garantia de fechar o argumento.

**Critério de decisão, declarado antes de rodar — o que faltou na nota 32.**
Para cada comparação (T1, T2), separadamente, conte quantas das 10 seeds
mostram o MESMO valor vencendo nas duas montagens espelhadas,
**independente de paridade** (o diagnóstico que as notas 30/31/32 já usam):

- **≥7/10:** confirma — o traço desloca o oponente de forma consistente
  demais para ser só efeito fundador.
- **4–6/10:** não confirma nem refuta — mantém a dúvida da nota 32, agora com
  um número em vez de "5 de 6".
- **≤3/10:** o painel de 10 seeds se comporta como o efeito fundador sozinho
  (a mesma leitura que a nota 32 já deu para 1/6) — sem evidência de
  vantagem real detectável neste desenho.

**T3 (condicional, herdado do §4.5):** só roda se T1 e/ou T2 confirmarem
(≥7/10) pelo critério acima.

**Reproduzir (script a escrever):** `sh papers/notes/33-invasao-arrependimento-10-seeds.sh`.

## 4.7 Pré-registro da segunda extensão de T2 — 20 seeds novas para separar o sinal sub-limiar de ruído *(2026-08-01, antes de rodar)*

**O problema.** A nota 33 fechou T1 com folga (1/10 REAL — fundador puro; o
triplo de seeds não diluiu o 3/3 fundador da nota 32, confirmou-o). T2 não
fechou: 6/10 REAL, abaixo do limiar de confirmação (7/10) mas longe do
limiar de fundador puro (≤3/10) — e as seis corridas "reais" concordam,
sem exceção, na direção que a nota 30 (Q5) apostara (`−2,0`). A própria nota
33 deixou dois caminhos possíveis, nenhum construído: painel maior (20+
seeds) ou população maior. Esta extensão escolhe o painel maior — reaproveita
o harness inteiro sem mudança nenhuma, ao custo de mais tempo de máquina;
população maior exigiria mexer em parâmetros de mundo que este projeto nunca
varreu, e a disciplina do backlog especulativo (`ROADMAP`, item 4) é não
construir infraestrutura nova sem antes nomear um teste que a exija — o que
não é o caso aqui.

**Desenho.** Só T2 (`−2,0` × `2,0`) — T1 já está decidido e não precisa de
mais seeds. Mesmo desenho exato das notas 30/32/33: 50/50 fixo por paridade
de índice, sem mutação no traço, duas montagens espelhadas, 30 000 ticks.
**20 seeds novas e sequenciais, 11 a 30** (continuando a série 1–10 da nota
33, convenção da nota 11 — não reaproveitar corridas já conhecidas).

**Critério de decisão, declarado antes de rodar.** Dois números, os dois
recomputados nos mesmos moldes da nota 33 (mesma fórmula, sem tocar
simulação nenhuma):

- **Standalone (as 20 seeds novas, sozinhas)** — mesma banda proporcional:
  ≥14/20 confirma, 7–13/20 não decide, ≤6/20 fundador puro.
- **Pool (as 20 novas somadas às 10 já publicadas na nota 33 — 6 REAL de
  10, seeds 2/3/4/6/8/9 REAL, seeds 1/5/7/10 fundador)** — total de 30, banda
  proporcional às mesmas 70%/30%: ≥21/30 confirma, 10–20/30 não decide,
  ≤9/30 fundador puro.

Se as duas bandas discordarem, o **pool** decide — tem mais poder estatístico
—, e o standalone entra na nota como réplica independente do mesmo desenho,
não como segundo veredito. **T3** (condicional, herdado do §4.5/§4.6) só roda
se o pool confirmar (≥21/30); T1 já não confirma, então essa é a única porta
que resta aberta para T3.

**Por que 30 seeds pode não bastar — declarado antes de rodar.** A mesma
ressalva da nota 33 vale aqui, sem novidade: se o efeito fundador for
estrutural ao harness (metade do espaço que nasce vizinha de recurso melhor
prospera quase independente do traço), nenhum n de seeds sozinho separa um
sinal real pequeno de uma taxa de base nunca medida num traço comprovadamente
neutro. Esta extensão é mais uma tentativa honesta de contar através do
confundidor, não uma garantia de fechá-lo — se ficar em "não decide" de
novo, o próximo recurso é a população maior que esta nota escolheu não
construir ainda.

**Reproduzir (script a escrever):** `sh papers/notes/34-invasao-arrependimento-t2-20-seeds.sh`.

---

## 4.8 Pré-registro do nulo do classificador — quanto REAL este desenho fabrica sozinho? *(2026-08-08, antes de rodar)*

**O problema.** T2 fechou em 20/30 (66,7%), uma seed abaixo do corte. Três notas
seguidas (32, 33, 34) declararam a mesma ameaça e nenhuma a mediu: se o efeito
fundador for estrutural ao harness, **nenhum n de seeds separa um sinal real
pequeno de uma taxa de base nunca medida**. Esta seção para de contar seeds e
mede a taxa de base. Não é mais um painel do mundo — é um painel da **régua**.
No idioma do §7 da `FILOSOFIA_v3`: antes de perguntar de novo o que o mundo diz,
perguntar quanto o instrumento diz sozinho.

**A álgebra que desenha o teste — declarada antes de rodar, e ela já matou o
experimento óbvio.** O nulo intuitivo seria ablar o mecanismo (remorso ≡ 0) e
contar quantas seeds ainda saem REAL. Esse nulo é **degenerado, e dá zero por
identidade, não por medição**: com `remorso[i]` ≡ 0 o traço `peso_arrependimento`
não entra em `utilidade_sigma` (é o único lugar onde ele é lido), então as duas
montagens espelhadas viram a **mesma simulação bit a bit** — só muda o rótulo
colado em cada paridade. Se `f` é a fração de sobreviventes de índice par,
a montagem A dá `arrep_m = 2 − 4f` e a B dá `arrep_m = 4f − 2`: exatamente
simétricas. O classificador (`vence quem tem o sinal do lado certo do meio, nas
duas montagens`) então **nunca** pode dizer REAL. Zero seeds REAL, por álgebra.

Disso sai a lição que reorganiza este pré-registro: **REAL exige que o traço seja
causalmente ativo** — mas não exige que ele seja *vantajoso*. Um traço ativo e
**empatado** decorrelaciona as duas montagens e faz cada uma sortear um vencedor;
duas moedas honestas concordam em **metade** das vezes. A taxa de base que as
notas 32–34 nomearam e não mediram é essa: **≈ 50%, não ≈ 0%**. E 20/30 = 66,7%
começa a parecer bem menos com "sinal forte afogado" e bem mais com "moeda".
Medir, não deduzir — os dois braços abaixo.

**N1 — o nulo inerte (verificação da álgebra, não estimativa).** Ablação natural
do remorso, a mesma da nota 30 (Q1): mantém todo o cálculo de `atualizar_remorso()`
(inclusive as chamadas a `prever_valor`, que não consomem RNG — a ablação é inócua
ao fluxo) e zera o estado guardado. 10 seeds (1–10), valores de T2, 30 000 ticks.

- **P1:** os CSVs de A e B são **idênticos em todas as colunas menos `arrep_m`**
  (col. 24) — inclusive `arrep_sd`, que não depende do rótulo.
- **P2:** `arrep_m` da montagem B = −`arrep_m` da A, **a cada tick**, em toda seed.
- **P3:** REAL = **0/10**.

Se qualquer uma falhar, minha álgebra está errada e a nota vira a investigação
disso, não a calibração — declarado agora para não virar racionalização depois.

**N2 — o nulo ativo (a taxa de base de verdade).** Mesmo `main.c`, mesmo harness
`invasao`, mesmos valores (`−2,0` × `2,0`), **as mesmas 30 seeds de T2** (1–30),
30 000 ticks, mesmas montagens espelhadas, mesmo classificador. A única mudança é
um sinal ±1 embaralhado por **célula candidata** no termo do arrependimento em
`utilidade_sigma`: `... * espaco * (hash2(cx,cy,seed^SALT) & 1 ? +1 : −1)`. A
**dose é idêntica** — mesmo `remorso[i]`, mesma magnitude, mesma frequência (~5%
dos ticks, nota 30 Q2) —, só a **direção** é destruída: cada valor passa a preferir
espaço aberto em metade do mapa e lotação na outra metade, em espelho exato do
outro. Nenhum dos dois pode ser sistematicamente melhor, e os dois continuam
ativos o bastante para decorrelacionar as montagens.

- **P4:** REAL(N2) **≈ 15/30**, e declaro 15/30 como **teto** esperado, não como
  ponto: decorrelação parcial (o traço mexe pouco na trajetória) empurra as duas
  montagens de volta para a mesma paridade, ou seja, para FUNDADOR. Banda:
  10–20/30 é o esperado; abaixo de 10 é decorrelação fraca; acima de 20 diz que
  o desenho fabrica REAL sozinho na taxa que T2 exibe.
- **P5 (o número que a nota existe para produzir):** a comparação T2 (20/30) × N2,
  por Fisher exato bilateral, declarada **antes** de ver N2. As três leituras:
  - **N2 ≤ 10/30, com p < 0,05 contra T2** — o desenho quase não fabrica REAL, e
    os 20/30 de T2 são sinal de verdade. Isso **não reabre** o veredito de T2 (o
    corte pré-registrado fica de pé, e mover critério depois do placar é
    exatamente o que a §7 proíbe), mas registra que o "não decide" vem de um
    **corte mal calibrado**, não de ausência de sinal — e passa a ser argumento
    para pré-registrar o corte certo num painel futuro.
  - **N2 em 11–19/30, sem diferença significativa de T2** — T2 é
    **indistinguível do nulo**. Seria o achado mais forte contra Q5 que este fio
    já produziu, e o que eu aposto, pela álgebra acima.
  - **N2 ≥ 20/30** — a régua fabrica sozinha o que T2 mede; as notas 32/33/34
    mediram o instrumento, não o mundo.
- **P6 — o nulo da direção, que é o número mais chamativo em aberto.** A nota 34
  registrou que **20 de 20** corridas REAL favorecem `−2,0`, sem exceção. Sob N2 a
  direção não pode ter preferência: entre as corridas REAL de N2, espero um split
  **≈ 50/50** entre `−2,0` e `2,0`. Se N2 também pender esmagadoramente para
  `−2,0`, então o 20/20 da nota 34 não é evidência sobre o mundo — é assinatura do
  desenho, e a nota 34 precisa de errata. Este é o único item aqui que pode
  **derrubar** um número já publicado.

**O que este pré-registro NÃO promete.** N2 é o traço real com a **direção
destruída**, não um traço com vantagem comprovadamente nula — não existe traço
assim medido neste projeto, e inventar um exigiria um mecanismo novo que nenhum
teste nomeado pede (a disciplina do item 4 do backlog). Se a perturbação de
trajetória depender da direção (se "evitar espaço aberto" mexer na trajetória mais
do que "buscar"), a taxa de N2 não é exatamente a taxa de um empate verdadeiro.
Declaro a fraqueza agora: N2 é a melhor aproximação disponível sem construir
infraestrutura nova, não um nulo perfeito. As duas ablações são **patch temporário
sobre `main.c`** compilado em tmpdir, a técnica das notas 23/24/25 — o `main.c` do
repo não é tocado, e nenhum dataset congelado muda.

**Custo declarado:** 20 corridas (N1) + 60 (N2) ≈ 2h45 sequencial, na medida de
~124 s/corrida da nota 34.

**Reproduzir (script a escrever):** `sh papers/notes/35-nulo-do-classificador.sh`.

---

## 4.9 Pré-registro da ablação do id — a última palavra da §3 a pagar a entrada *(2026-08-09, antes de rodar)*

**O problema, e ele é uma dívida que o próprio arquivo declara.** A §3 da
`FILOSOFIA_v3` estabelece a regra de admissão de toda palavra emprestada —
*"que ablação a zera? e ela carrega comportamento? sem resposta às duas, é
decoração"* — e logo depois admite, por escrito, que uma das cinco não a paga:
*"o id existe, e é o único que nunca foi posto à prova (…) a palavra mais antiga
é a menos testada"*. Ego, superego, sombra e self têm ablação e barras; o id não
tem. **Fechar a v3 com uma dívida autodeclarada à sua própria regra é o
movimento que a §6 e a §7 recusam quando o alvo é outra pessoa** — daí este
pré-registro ser o último item de pesquisa antes de a v3 poder ser encerrada.

**O que o id é, operacionalmente.** O termo `comida_prev · (1 + urgencia · fome)`
em `utilidade_sigma`. `urgencia` é traço herdado (nível 6): semeado em
`URGENCIA · (0,5 + rng01())`, mutado por `muta_traco` a cada nascimento.

**A álgebra antes da máquina (regra 9 do protocolo, que a nota 35 pagou caro
para aprender) — e ela já entrega o resultado principal.** A decisão é um
`argmax` sobre as células candidatas, e `(1 + urgencia · fome)` é um fator
**positivo e comum a todas elas** (`urgencia` e `fome` são do bloco, não da
célula). Dividindo a utilidade por esse fator, o ranking é idêntico ao de

> `nota(k) = comida_prev(k) + [ peso_espaco · espaco(k) · (1−fome)
>            + peso_arrependimento · remorso · espaco(k) ] / (1 + urgencia · fome)`

Consequências, declaradas antes de rodar:

1. **O id não tem canal próprio.** `urgencia` não consegue mudar decisão alguma
   *empurrando* para a comida — o ranking é invariante a reescalar tudo por um
   fator comum. A única coisa que ela faz é **encolher os termos que não são
   comida**. Dito na língua da seção: **o id não é um empurrão em direção à
   comida; é um botão que abaixa o volume de tudo o que não é comida.** Isso é
   álgebra, não medição, e reescreve o parágrafo do id independentemente do que
   as corridas derem.
2. **Logo, se `peso_espaco ≡ 0` e `remorso ≡ 0`, `urgencia` é exatamente inerte** —
   o numerador inteiro some, e a ablação vira degenerada no sentido da nota 35.
   Isso dá um controle de sanidade **bit a bit**, não uma estimativa.
3. **A seleção já fecha o canal do id sozinha.** A nota 12 mediu `peso_espaco`
   caindo de ~2,9 para **0,095 ± 0,018** em 30 000 ticks, em 50 de 50 seeds. Se
   o único canal do id é multiplicar o termo do espaço, então **a sombra da §3
   (a agência renegada) é também a aposentadoria do id** — a mesma variável, o
   mesmo processo. Predição: o efeito da ablação é grande cedo e quase some tarde.

**Desenho.** 6 condições × **8 seeds sequenciais (1–8)** × 30 000 ticks. O
`rng01()` descartado é preservado em toda pregação (idioma da nota 12), e
`muta_traco(v, 0.0f, …)` consome exatamente um `rng01()` como o original — a
pregação é inócua ao fluxo, conferido no código antes de escrever isto.

| condição | `urgencia` | `peso_espaco` | `remorso` |
|---|---|---|---|
| `ctl` | livre | livre | normal |
| `id0` | **pregada em 0** | livre | normal |
| `fesp` | livre | pregado em `PESO_ESPACO` | normal |
| `fesp_id0` | **pregada em 0** | pregado em `PESO_ESPACO` | normal |
| `deg` | livre | **pregado em 0** | **≡ 0** |
| `deg_id0` | **pregada em 0** | **pregado em 0** | **≡ 0** |

**Predições, antes de rodar:**

- **D1 — a entrada que a §3 cobra.** Com o canal do id mantido aberto à força
  (`fesp` × `fesp_id0`), a ablação **carrega comportamento**: diferença na
  população final em ≥ 6/8 seeds, com `fesp_id0` **pior**. Se não carregar, o id
  **não paga a entrada**, e a §3 tem de dizer isso em voz alta em vez de fechar
  a v3 fingindo que paga.
- **D2 — a previsão da álgebra.** Na evolução normal, o efeito é muito menor:
  `|Δpop(ctl, id0)| < |Δpop(fesp, fesp_id0)|` em ≥ 6/8 seeds, porque a seleção já
  levou `peso_espaco` a ~0,095 e o canal está quase fechado.
- **D3 — a janela cedo.** No tick 200, antes de a seleção derrubar `peso_espaco`,
  `ctl` × `id0` já diferem, na mesma direção de D1. Lido dos **mesmos** CSVs, sem
  corrida nova.
- **D4 — o controle degenerado (bit a bit).** `deg` × `deg_id0` produzem CSVs
  **idênticos**, porque nessa condição `urgencia` não tem por onde agir. Se
  diferirem **só** em colunas de mostrador, isso localiza qual mostrador lê
  **magnitude** em vez de **ordem** — achado nos dois casos, e exatamente o tipo
  de coisa que o Apêndice A precisa saber antes de ser congelado.

> **Errata do próprio pré-registro** *(2026-08-09, escrita **antes** de rodar o
> painel completo, depois de um teste de fumaça de 2 seeds × 400 ticks).* A
> redação de D4 acima está **defeituosa** e fica registrada como estava. "CSVs
> idênticos" é impossível por uma razão trivial que nada tem a ver com a
> álgebra: `urg_m` e `urg_sd` (colunas 10 e 11) **descrevem o próprio traço
> ablacionado** e obviamente diferem entre uma população com `urgencia` livre e
> outra com `urgencia ≡ 0`. A nota 35 já tinha resolvido exatamente isso ao
> excluir a coluna 24 (`arrep_m`) da comparação de P1, e eu não repeti a
> exclusão aqui. **A comparação que a álgebra prediz, e que vale como D4, é a
> identidade das 23 colunas que não são `urg_m`/`urg_sd`.** O teste de fumaça já
> mostrou que **só** 10 e 11 diferem — o que é a confirmação, não a refutação,
> da consequência 2. O script reporta as duas comparações (completa e
> corrigida), e a nota tem de dizer que o critério foi corrigido antes do painel
> e por quê, em vez de publicar a versão que "deu certo".

**O que este pré-registro NÃO promete.** Ablação de traço não é ablação de
mecanismo: pregar `urgencia = 0` remove a *modulação*, não o termo da comida —
`comida_prev` continua lá, e é ele que a nota 01 já mostrou ser letal remover
(o ego). O id desta seção é a modulação, e é só sobre ela que D1 decide. E 8
seeds é o painel mínimo que a nota 11 tolera para um efeito direcional; se D1
sair em 4–5/8, isso é "não decide", não "confirma fraco" — declarado agora.

**Custo declarado:** 48 corridas ≈ 80 min sequencial (~100 s/corrida, medido na
nota 35).

> **Adendo D5 — POST-HOC, escrito DEPOIS de ver D4 falhar** *(2026-08-09).* Isto
> não é pré-registro e não deve ser lido como um: o painel rodou, e **D4 falhou
> em 4 das 8 seeds** — `deg` × `deg_id0` divergem, e em três delas a divergência
> alcança colunas comportamentais (população, energia, comida), não só
> mostradores. O pré-registro mandava investigar antes de escrever, e a
> investigação começou por leitura de código: `urgencia` aparece em **exatamente
> um** lugar de `main.c` (o termo de `utilidade_sigma`), e `prever_valor_sigma`
> — o único outro candidato — **não a lê**. Não há canal causal não enumerado.
> Sobra a explicação que este projeto já documentou uma vez: **`float32` não
> inverte ordens, cria empates** (nota 10). Multiplicar todas as candidatas por
> `(1 + urgencia · fome)` preserva a ordem em ℝ, mas em `float32` pode fundir
> duas candidatas distintas num empate — e `melhor_celula` desempata por ordem
> de varredura, o que **muda a decisão**. Pela regra 6 do protocolo (§1.7), não
> posso escrever isso como conclusão sem medir. **D5** mede: uma condição
> `degp2` idêntica a `deg`, só que com o fator do id trocado por **2,0** — uma
> multiplicação **exata** em `float32` (desloca o expoente, não arredonda),
> incapaz de inverter ordem *ou* criar empate. Se a divergência de D4 for
> arredondamento, `degp2` × `deg_id0` têm de ser idênticas nas 23 colunas em
> **8/8**; se sobreviver a um fator exato, existe canal causal e a consequência 2
> do §4.9 está errada e deve ser reescrita. O script passa a rodar 7 condições
> (56 corridas, ~93 min) e a nota reporta D4 e D5 lado a lado, com D5 marcada
> como post-hoc no texto.

**Reproduzir (script a escrever):** `sh papers/notes/36-a-ablacao-do-id.sh`.

---

## 4.10 Pré-registro da divergência de trajetória — o vão entre T2 e o nulo é vantagem ou coerência? *(2026-08-10, antes de rodar)*

**O problema, e ele está escrito na própria nota que o criou.** A nota 35 fechou
declarando a fraqueza central do seu nulo: N2 tem a mesma dose de T2 e a direção
destruída, mas o termo de T2 é espacialmente **coerente** (multiplica `espaco`,
que é suave) e o de N2 troca de sinal **célula a célula**. Se coerência
decorrelacionar as duas montagens espelhadas mais do que incoerência de mesma
magnitude, parte do vão 30% → 66,7% é decorrelação, não vantagem — e o
`p = 0,0092` da nota 35 mediria a diferença entre dois níveis de perturbação, não
entre sinal e ruído. A nota nomeou o teste que fecharia isso e não o rodou:
comparar **quanto as trajetórias de A e B divergem em cada braço**. Ele muda o que
o script **guarda**, não o que ele roda.

**A álgebra antes da máquina — e ela entrega um teto que corrida nenhuma move.**
Seja `W_A` o valor do traço que domina a montagem A no fim, e `W_B` o da B; o
classificador diz REAL exatamente quando `W_A = W_B`. Dois extremos fixam a régua:

1. **Sem mecanismo** (o N1 da nota 35), A e B são a **mesma** simulação — a mesma
   paridade vence as duas, os valores são opostos, REAL é impossível: **0%**, e
   isso está medido (0/10).
2. **Com decorrelação total** e nenhum valor melhor que o outro, `W_A` e `W_B` são
   dois sorteios independentes e justos: concordam em **50%**.

A decorrelação parcial interpola entre os dois. Para passar de 50% é preciso que
`W_A` e `W_B` fiquem **positivamente correlacionados**, e como a única coisa que
distingue B de A é qual paridade carrega qual valor, correlação positiva quer
dizer "o valor `v` tende a vencer, seja qual for a paridade que o carregue" — que
é a **definição** de vantagem neste harness. Portanto:

> **P(REAL) > 50% ⟺ vantagem.** Decorrelação, sozinha, não passa de 50%.

Aplicado aos dois números já publicados, sem gastar máquina:

- **T2 = 20/30 = 66,7%** está **acima** do teto: `P(X ≥ 20 | n = 30, p = 0,5) = 0,0494`
  (binomial unilateral).
- **N2 = 9/30 = 30,0%** está **abaixo** dele de forma significativa
  (`P(X ≤ 9) = 0,0214`): o nulo **não** decorrelaciona por completo. Isso é fato
  aritmético sobre um número já publicado, não conjectura.

Daí sai o tamanho exato do que está em jogo, declarado antes de medir: a coerência,
**no pior caso possível para a nota 35**, explica o vão de 30% até 50%; o que passa
de 50% ela não pode explicar. Se a ameaça se confirmar inteira, o `p = 0,0092` da
nota 35 vira `p = 0,0494` — a evidência encolhe de confortável para no fio, e
**não** desaparece. Se for descartada, o `p = 0,0092` fica sem ressalva.

**Ressalva do teto, escrita agora para não virar racionalização depois:** a
equivalência acima vale para vantagem **global**. Uma vantagem que mude de sinal
de seed para seed (`−2,0` melhor em alguns mundos, `2,0` em outros) também
correlaciona `W_A` com `W_B` e também passa de 50% — continua sendo vantagem, mas
não a de Q5. O que separa as duas é a direção condicional, e ela já está medida:
as 20 corridas REAL de T2 apontam **todas** para `−2,0` (nota 34) contra 3/9 no
nulo (nota 35, `p = 0,0002`). Para T2, o teto é rompido por vantagem global.

**O desenho — os mesmos binários, as mesmas seeds; muda o que se guarda.** Dois
braços: **T2** (o harness `invasao` puro, o que as notas 33/34 rodaram) e **N2**
(o nulo ativo da nota 35), as duas montagens espelhadas, as **mesmas 30 seeds**.
`main.c` não muda desde `65e83f3`, anterior às notas 32–36, então os binários são
bit a bit os que produziram os números publicados — e uma seed publicada de cada
braço é conferida como regressão **antes** do painel (regra 8: conferir a régua
antes de aceitar o que ela diz).

Definições, todas sobre colunas do CSV, nenhuma sobre estado interno:

- **`d(t) = (arrep_m^A(t) + arrep_m^B(t)) / 4`.** Álgebra: em A o índice par
  carrega `−2,0` e em B carrega `2,0`, logo `arrep_m^A = 2(2f − 1)` e
  `arrep_m^B = −2(2f' − 1)`, com `f`, `f'` = fração de índice ímpar em cada
  montagem; a soma dá `4(f − f')`. Ou seja, **`d` é a diferença de composição
  entre as duas montagens, em fração da população, com sinal** — e sob N1 (traço
  inerte) `d ≡ 0` a cada tick, que é exatamente o que a P2 da nota 35 verificou e
  jogou fora.
- **`d̄_W`** — média de `d(t)` na janela `1..W`, **com sinal**.
- **`Δpop_W`** — média de `|pop_A − pop_B|` na janela, dividida pela população
  média: divergência do **mundo**, cega a qual valor está vencendo.
- **`t_div`** — primeiro tick em que A e B diferem em qualquer coluna invariante
  ao rótulo (todas menos `arrep_m`); **`t_01`**, o primeiro tick com `|d| ≥ 0,01`,
  entra junto porque `t_div` tem resolução grossa demais (o piloto deu 4 e 6).

E a decomposição de que tudo depende, declarada antes de ver o painel: através das
seeds, **vantagem é deslocamento de `d̄`, decorrelação é espalhamento de `d̄`**. Um
mecanismo que só decorrelaciona espalha `d̄` em torno de zero; um que dá vantagem a
`−2,0` desloca `d̄` para o negativo (em A o ímpar carrega `2,0` e encolhe; em B o
ímpar carrega `−2,0` e cresce).

**Janela: `W = 2000` como primária**, com `W = 500` e `W = 5000` de sensibilidade,
das mesmas corridas. Calibrada em **seeds fora da amostra** (31 e 32, que não estão
nas 30 do painel e nunca foram publicadas), rodadas antes deste pré-registro
exatamente para isto: em `t = 2000` a composição está em ~79% e ainda se move (a
fixação só chega perto de `t = 23000`), enquanto em `t = 30000` `d` **é** o
desfecho — medir lá seria medir o classificador de novo, com outro nome.

- **P1 — a dose, que a §4.8 afirmou e nunca conferiu.** `t_div` e `t_01`
  comparáveis entre T2 e N2, pareados por seed (sinal exato, bilateral, 5%). Se T2
  divergir sistematicamente mais cedo, "mesma dose" é falso no nível da trajetória
  e o resto da nota se lê sob essa luz.
- **P2 — a ameaça (primária).** Escala de `d̄_2000` por braço, com
  `s_seed = |d̄ − mediana do próprio braço|` (a mediana tira o deslocamento de
  vantagem; o que sobra é decorrelação). Sinal exato pareado, bilateral, 5%, T2 ×
  N2; companheiro: razão de MADs com `p` por permutação pareada (10⁵ sorteios, RNG
  de semente fixa no script — este projeto não sorteia sem semente). Leituras:
  - **sem diferença** → ameaça **fechada**: os 30% são linha de base justa e o
    `p = 0,0092` da nota 35 fica sem ressalva;
  - **T2 > N2** → ameaça **confirmada**, e o que resta de pé é o teto
    (`p = 0,0494`); a nota 35 recebe ressalva de **interpretação**, não errata de
    número;
  - **T2 < N2** → linha de base **conservadora**, e a nota 35 sai mais forte.
- **P3 — a mesma ameaça, medida no mundo.** `Δpop_2000` pareado, T2 × N2, mesmo
  teste. É a segunda régua da P2 e é cega a qual valor vence. Se P2 e P3
  discordarem, a nota lê o desacordo em vez de escolher o que agrada.
- **P4 — o modelo que sustenta o argumento inteiro.** Dentro de N2, onde não há
  vantagem por construção, REAL só pode vir de decorrelação: as 9 seeds REAL devem
  ter `|d̄_2000|` **maior** que as 21 FUNDADOR (Mann–Whitney unilateral, 5%). Se
  falhar, o modelo "REAL = decorrelação + vantagem" está errado, e a nota vira a
  investigação disso em vez da calibração.
- **P5 — a direção, agora contínua e cedo.** `d̄_2000` **com sinal**, nas 30 seeds.
  Em N2 espero mediana ≈ 0 e ~15/30 negativas; em T2, se `−2,0` for vantajoso,
  espero **≥ 21/30 negativas** — o mesmo corte do §4.6, para não inventar régua
  nova. Declaro antes: o observável é **novo**, contínuo e medido cedo, e **não
  revoga nem substitui** o veredito binário de T2. O corte de 21/30 do §4.7 decidiu
  o que decidiu; nada aqui move critério depois do placar.

**O que este pré-registro NÃO promete.** `Δpop` é cego à vantagem mas **satura**: a
população é homeostática (~250 blocos), então, uma vez decorrelacionadas, as duas
montagens ficam a uma distância típica e a medida para de crescer — ela distingue
"decorrelacionou" de "não decorrelacionou" melhor do que "decorrelacionou quanto".
`d̄` não satura na janela, mas mistura os dois efeitos, e só a decomposição
(deslocamento × espalhamento) os separa — decomposição que vale sobre as 30 seeds,
não seed a seed. E N2 continua sendo "direção destruída", não "vantagem
comprovadamente nula": esta seção mede a ameaça que a nota 35 declarou, não todas
as que existem. Se a P2 confirmar a ameaça, o teste seguinte já tem nome — um
**nulo coerente** (o mesmo termo multiplicado por um campo suave arbitrário em vez
de ±1 por célula), que responderia na moeda do desfecho em vez de na de um proxy,
ao custo de mais 60 corridas de 30 000 ticks.

**Custo declarado:** 120 corridas de 5 000 ticks ≈ 45 min sequenciais (~22 s/corrida,
na medida de ~130 s por 30 000 ticks deste devbook hoje), mais 4 corridas de 30 000
para a regressão das seeds publicadas (~9 min). Patch temporário em tmpdir (técnica
das notas 23/24/25): o `main.c` do repo não é tocado e nenhum dataset congelado muda.

**Reproduzir (script a escrever):** `sh papers/notes/37-divergencia-de-trajetoria.sh`.

---

## 4.11 Pré-registro do painel da régua pareada — a primária, fora da amostra, com a potência calculada antes *(2026-08-15, antes de rodar)*

**Por que existe, e o que exatamente está errado hoje.** A régua pareada
(`d̄`, a diferença de composição entre as duas montagens espelhadas) deu 28/30 na
nota 37 e respondeu Q5. Nenhum número dela está sob suspeita — o que está errado é o
**estatuto**: ela entrou como observável **secundário** (a P5) de um painel montado
para responder outra pergunta (a ameaça de decorrelação), e rodou nas **mesmas 30
seeds** que as notas 33/34/35 já tinham usado e olhado. Um resultado assim é uma
descoberta, não uma confirmação. Este painel a promove a **primária**, em **30 seeds
que nenhuma nota deste projeto rodou** (101–130), com o corte declarado antes e —
pela primeira vez neste fio — **potência calculada antes**, porque só agora existem
as duas coisas que faltavam: um nulo medido (15/30 exato, nota 37) e um tamanho de
efeito (mediana `d̄_2000 = −0,164`).

**A potência, antes da máquina** (binomial exata, `n = 30`, corte **≥ 21/30** — o
corte do §4.6, para não inventar régua nova):

| | |
|---|---|
| α sob o nulo (`p = 0,5`) | `P(X ≥ 21) =` **0,0214** |
| potência sob o efeito medido (`p = 28/30 = 0,933`) | **0,99998** (falha com prob. 1,5·10⁻⁵) |
| potência sob o limite inferior CP 95% do efeito (`p = 0,805`) | **0,947** |
| menor efeito com 80% de potência | `p = ` **0,749** |

Ou seja: **este painel não tem desculpa de amostra pequena**. Se a direção não
replicar, o problema é do achado da nota 37, não do `n`.

**A álgebra do nulo, feita antes de gastar máquina (regra 5 do protocolo) — e ela
explica o 15/30 exato.** Em N2 o termo do arrependimento é multiplicado por
`sinal_nulo(cx,cy) ∈ {−1,+1}`, campo arbitrário fixo por seed. Um bloco com peso `w`
sob o campo `s` se comporta **exatamente** como um bloco com peso `−w` sob o campo
complementar `−s`. Como a única diferença entre as montagens A e B é qual paridade
carrega qual valor, segue que a montagem A sob `−s` **é** a montagem B sob `s`, e
portanto `d(−s) = −d(s)`: a complementação do campo é uma involução que troca o sinal
de `d`. O ensemble de campos (um bit de `hash2` por célula) é simétrico sob
complemento, logo **a distribuição de `d` é simétrica em torno de zero por construção
do ensemble** — o 15/30 exato da nota 37 não foi sorte, era o que tinha de acontecer.
Isso é o mais perto de "nulo por identidade" que este fio chega, e vale escrever a
diferença: sob N1 (traço inerte) `d ≡ 0` **tick a tick**; sob N2, `d` é grande em cada
seed e só a **distribuição** é simétrica. Por isso N2 ainda roda aqui: com `n = 30` o
nulo tem ruído binomial, e ele também valida o encanamento inteiro (patch, extração,
estatística) em seeds novas.

**O desenho — mesmos binários, seeds novas, e cada corrida entrega as duas réguas.**
Dois braços (**T2**, o harness `invasao` puro das notas 33/34; **N2**, o nulo ativo da
nota 35, copiado verbatim), duas montagens espelhadas, 30 seeds novas, **30 000 ticks**
por corrida. O tamanho da corrida é a decisão de desenho que faz este painel valer mais
que o da nota 37 pelo mesmo trabalho: o CSV de 30 000 ticks **contém** o prefixo de
2 000, então cada corrida entrega ao mesmo tempo `d̄` nas janelas `W ∈ {500, 2000, 5000}`
**e** o desfecho binário na fixação — as duas réguas medidas **nas mesmas corridas**,
que é a única forma honesta de compará-las. 120 corridas.

**Uma mudança no harness, declarada porque toca a invariante.** As corridas rodam em
**processos paralelos**. A cláusula "paralelização e SIMD ameaçam" da seção *Engenharia*
é sobre paralelizar **dentro do tick** (ordem de redução, reassociação de ponto
flutuante) — aqui nada no `main.c` muda: cada corrida continua um processo
single-thread, `f(seed)`, escrevendo o próprio CSV; o paralelismo está só no shell que
as dispara. Como isso é asserção e não fé, o script **verifica**: guarda o md5 de todos
os 120 CSVs, repete ao final uma corrida (T2/101/A) **sozinha** e compara — se diferir,
o painel é nulo. As métricas vão para um arquivo por tarefa e são concatenadas em ordem
ordenada, então o agregado é idêntico byte a byte independentemente de quem termina
primeiro; `JOBS=1` roda sequencial e deve dar **o mesmo painel**.

- **P1 — primária: a direção, fora da amostra.** T2, `d̄_2000` **com sinal**, 30 seeds
  novas, corte **≥ 21/30 negativas**. Espero **28/30 ± ruído binomial**. Falhar aqui,
  com a potência da tabela acima, seria dizer que o 28/30 da nota 37 era das seeds
  1–30 — e a nota 38 viraria a investigação disso.
- **P2 — a magnitude, não só o sinal.** Mediana de `d̄_2000` em **[−0,30; −0,05]**
  (o valor antigo é −0,164; a faixa é "mesma ordem de grandeza", declarada agora).
  Fora dela com o sinal replicando: a direção é robusta e o tamanho não é, e é isso
  que a nota vai escrever.
- **P3 — o nulo, na mesma amostra fresca.** N2 com negativas em **10..20** (intervalo
  de aceitação de `p = 0,5` a 5% bilateral) e `|mediana d̄_2000| < 0,05`. A álgebra
  acima prevê 15/30. Se cair fora, o nulo tem viés nestas seeds e **P1 não se lê**.
- **P4 — as duas réguas nas mesmas corridas (a afirmação sobre o instrumento).**
  (a) O binário de T2 deve cair em **14..25** (IC95 Clopper–Pearson dos 20/30
  publicados), e declaro agora que é **provável que ele não alcance o próprio corte de
  21/30**: se isso acontecer, o painel exibe, fora da amostra, a régua de baixo poder
  dizendo "não decide" enquanto a de alto poder decide com `p ~ 10⁻⁶` **nas mesmas
  corridas**. (b) Entre as seeds que o binário carimba FUNDADOR em T2, a fração com
  `d̄_2000 < 0` deve ser **> 0,5** (binomial unilateral, 5%, condicional a haver ≥ 5
  dessas seeds) — é a réplica dos 9/10 da nota 37. (c) O binário de N2 deve cair em
  **4..15** (IC95 CP dos 9/30 publicados).
- **P5 — companheiro de maior potência: Wilcoxon signed-rank** de `d̄_2000` contra zero
  (permutação de sinais, 10⁵ sorteios, RNG de semente fixa no script — este projeto não
  sorteia sem semente). **Companheiro, não primária**: a contagem é que mantém a
  comparabilidade com o corte do §4.6/§4.7.
- **Sensibilidade:** `W = 500` e `W = 5000`, das mesmas corridas. Se as três janelas
  discordarem, a nota **lê o desacordo** em vez de escolher a que agrada — foi o que a
  P2 da nota 37 obrigou a fazer.

**O que este pré-registro NÃO promete.**

- **Não re-decide o §4.7, em direção nenhuma.** O veredito binário de T2 é 20/30 contra
  um corte de 21/30 e está fechado. O braço binário deste painel é **secundário e
  descritivo**, com faixa de expectativa declarada acima. Declaro antes o caso
  incômodo: **se o binário destas 30 seeds novas der ≥ 21/30**, isso é uma réplica
  independente que teria confirmado pelo próprio corte — a nota registra o fato, e
  **não** funde os dois painéis (60 seeds com um corte de 21/30 não é teste nenhum) nem
  abre o gate de T3 por conta própria; abrir T3 exige pré-registro próprio, escrito
  depois e com corte novo declarado antes. Mover a trave depois do placar é o que a §7
  da `FILOSOFIA_v3` proíbe, e a proibição vale para o lado que agrada.
- **`d̄` mede vantagem de crescimento cedo; o binário mede quem fixa.** São perguntas
  diferentes (ameaça herdada da nota 37) e este painel não troca uma pela outra.
- **28/30 é proporção de seeds, não tamanho de efeito populacional**; a mediana de `d̄`
  é composição, não aptidão, e não será convertida em uma.
- **Não mede por que `−2,0` vence.** O item 2 da nota 37 (a hipótese mecânica da nota
  30 — persistir na disputa é o que paga — testável ligando `PESO_ESPACO`/densidade)
  continua aberto e fora deste painel.

**Custo declarado, medido neste devbook hoje** (`gcc -O2`, 16 núcleos, carga ~1,3):
171,6 s por corrida de 30 000 ticks e 27,6 s por 5 000 ⇒ 120 corridas = **5 h 43 de
CPU**, ~30 min de relógio com 12 processos simultâneos. Mais 4 corridas de regressão
(T2 seed 11 e N2 seed 2, as publicadas) e 1 corrida solitária para o teste de
determinismo sob paralelismo. Patch temporário em tmpdir (técnica das notas 23/24/25):
o `main.c` do repo não é tocado e nenhum dataset congelado muda.

**Reproduzir (script a escrever):** `sh papers/notes/38-painel-da-regua-pareada.sh`
(`JOBS=12` por padrão; `JOBS=1` roda sequencial e deve produzir o mesmo painel).

---

# Fase 5 — Escrever: `FILOSOFIA_v3.md` e o paper *(a v3 **fechou** em 2026-08-09)*

**Pergunta:** onde a palavra mental **quebra**?

> **A `FILOSOFIA_v3.md` está fechada** (2026-08-09). O rótulo "esqueleto" tinha
> caído em 2026-07-13 com a lista do Apêndice B; o rótulo "rascunho" caiu agora,
> por quatro atos no mesmo dia. **(1)** A última dívida de pesquisa foi paga: a
> §3 admitia por escrito não estar cobrando do **id** a entrada que cobra de
> todas as outras palavras — a ablação rodou (§4.9, nota 36) e o id **não
> pagou**, 2/8 contra as ≥6/8 pré-registradas. **(2)** A §3 foi reescrita: as
> cinco palavras têm dado, o id é em boa parte "o mapa do ego usando outro nome",
> e a álgebra o joga para o lado (B) da costura — os dois termos que ele divide
> dependem de **rivais**, então um bloco sozinho não tem sobre o que o id agir.
> **(3)** O **Apêndice A** foi congelado, com as três condições que o reabrem
> escritas por extenso, mais o acréscimo da nota 36 (o piso do `float32` agora
> tem um caso na **decisão**, não só na régua). **(4)** A **§8** — "o que esta
> versão não pôde perguntar" — nomeia o limite: toda medição da v3 é feita de
> fora, inclusive os detectores da §7, e a pergunta que fica é o que acontece
> quando a medição vira parte do mecanismo. É esse o gate da `FILOSOFIA_v4`, e
> ele agora está escrito **dentro da v3**, onde deve estar.

As fases 1–4 são expansionistas: mais fenômenos, mais mostradores, mais
experimentos. Um projeto cuja tese é *"até onde a palavra estica"* precisa de uma
teoria do **ponto de ruptura**. Sem ela, a bateria vira uma catraca que só sabe
licenciar vocabulário mental, nunca retirá-lo — e aí não mede até onde a palavra
estica: apenas estica a palavra.

## O que a v3 precisa ter (e por que não pode ser escrita antes)

1. **Um resultado negativo.** Ela agora tem o primeiro: um mostrador chamado
   `modelo` deu nota 1,000 a um bloco sem modelo, morrendo. Até hoje todo degrau
   da escada "funcionou". Uma filosofia do limite escrita por alguém que nunca
   encontrou um limite é publicidade.

2. **Uma condição de falseamento por palavra.** Para cada mostrador: *que leitura
   me obrigaria a dizer que a palavra não se aplica a este bloco?* Para `modelo`,
   hoje, a resposta é **nenhuma** — ele lê ~1 até para um cadáver. Enquanto uma
   palavra não puder ser retirada, ela não foi testada.

3. **A distinção entre a régua e a palavra**, com espécime da casa. A abertura da
   v3 se escreve sozinha: *"construímos um medidor de 'modelo'. Ele deu nota
   máxima a um agente sem modelo. Isto não é um bug que corrigimos e seguimos em
   frente; é o fato epistêmico central do projeto."* A mesma estrutura ameaça
   todo mostrador — inclusive os que vamos consertar, e inclusive os que se usam
   em humanos.

4. **Uma hierarquia entre as duas famílias.** A Fase 1 mostrou que ablação e
   calibração podem apontar para **lados opostos**. A tese: *calibração sem
   ablação não vale nada*, porque a calibração pode ser satisfeita por um mapa
   que é fotocópia do território — isto é, por não ser mapa. **Representação
   exige a possibilidade de des-representação.** Isso é Dretske e Millikan caindo
   de um `sed` em C.

5. **A dobradiça da confabulação** ✅ *(a dependência da Fase 2 está paga —
   notas 06 e 07)*. Não é mais um "quando": o bloco **já** racionaliza ações que
   não escolheu — ~21% das negadas pela física, sem ninguém instalar isso (nota
   06), e ~26% das impostas pelo dedo do espectador (nota 07). O projeto tem,
   dentro de casa, o fenômeno que torna o auto-relato humano pouco confiável
   (Gazzaniga; Nisbett & Wilson). A v3 tem de encarar o último reduto do "mas eu
   *sei* que sou consciente, por dentro" — porque esse reduto **é ele próprio um
   relato**. Se relatos confabulam, quanto peso probatório sobra ali? E, com a
   nota 07: se confabular × detectar é só **arquitetura de leitura**, que
   arquitetura é a *nossa*?

6. **Uma escolha que a v2 evita** ✅ *feita (v3 §6)*. "Função, nunca experiência"
   é (a) uma **contenção metodológica** — faltam-nos instrumentos; ou (b) uma
   **tese metafísica** — não há mais nada a medir? A v3 escolheu: **nenhuma das
   duas.** (b) é uma negativa existencial que uma bateria funcional não pode
   pagar — e quem a afirma usa, como última evidência, a única faculdade que a
   bateria já pegou mentindo. (a) perde a entrada toda vez que a paga: as cinco
   vezes em que uma palavra experiencial foi operacionalizada aqui, o alvo não
   escapou — **virou função na mão** (`phi` = o segundo motivo; `automodelo` = o
   outro; o `relato` = um intérprete leigo que confabula; e a `autocausa`, a coisa
   mais parecida com uma posse neste mundo, é **um termo dentro de uma previsão**).
   A recusa é estável porque *a única evidência capaz de decidir a questão é
   testemunho, e o projeto mediu de que o testemunho é feito*. Preço pago por
   escrito: pela regra de admissão da v3 §3, "experiência" **não paga a entrada**
   — a sua linha no Apêndice A teria a coluna da ablação **vazia**. Pelo critério
   deste projeto, aplicado sem exceção, é decoração — e a régua está apontada
   também para o meu próprio "por dentro".

7. **A colisão contrafactual × determinismo.** `medir_decisao()` já roda um
   contrafactual (dois clones, faminto × saciado) — mas quem o roda é o
   **observador**, não o bloco. No dia em que o bloco rodar isso por dentro
   ("eu poderia ter ido para a esquerda"), ele sustentará uma crença modal que,
   num universo `f(seed)`, é **falsa** — e ainda assim funcionalmente
   indispensável. Compatibilismo, executável. A v3 precisa de uma posição:
   crença falsa, ficção útil, ou verdade sobre o *tipo* e falsidade sobre a
   *ocorrência*?

8. ~~**O regresso**~~ ✅ **ESCRITO (`FILOSOFIA_v3.md` §7, 2026-07-26, depois do
   eixo microscópio — notas 24–27).** Três detectores, três intervenções: não
   confabularam (0/8 falsos positivos, três vezes), mas cada um ficou **mudo**
   numa borda — rápido demais (extinção em 11–14 ticks, notas 24/25) ou
   devagar demais (o sapo fervendo, nota 27) — o mesmo eco do "eremita mudo"
   da nota 06, um andar acima. O regresso não termina numa autoridade maior:
   termina em determinismo (testemunha, não juiz) mais a disciplina de
   pré-registrar e relatar o erro — a mesma régua que a §6 apontou para
   "consciente" aponta para "calibrado", e lê a mesma coisa.

9. **A costura da escada** — e é aqui que a v3 se bifurca *de verdade*.

   A metáfora fundadora (subir degraus rumo a mais mente) admite duas leituras:

   **(A) Aquisição de faculdades.** Os degraus catalogam o que o bloco *tem*. É
   uma leitura **internalista**, e a bateria está arquitetonicamente comprometida
   com ela: todo mostrador recebe um `Bloco *b` e é computado localmente. O
   ambiente é palco. O terminal natural desta leitura é "quantos degraus até a
   senciência?" — a pergunta da v1, que a v2 recusou.

   **(B) Escalada de um conflito.** Os degraus são lances numa corrida
   armamentista. É uma leitura **relacional**: a mente não é propriedade do bloco,
   é propriedade da *relação entre* blocos. "Senciência" nomearia uma posição num
   jogo, não uma posse. A deflação é bem mais dura que a da v2: não "a palavra não
   estica até aqui", mas "a palavra nunca foi sobre o que você pensava".

   **A bifurcação não é uma escolha de gosto — ela tem uma costura mensurável.**
   O teste do eremita (1.5) mostra que, *nesta implementação*, `agencia` e
   `automodelo` são **identicamente zero** para um bloco solitário, e `phi` perde
   88%. Para os degraus 4–5, (B) não é uma interpretação: é a implementação
   literal. Não há mais nada lá. Já os degraus 0–3 (reatividade, memória,
   valência, modelo do mundo/comida) não precisam de rival algum. **A escada tem
   uma costura, e ela cai entre o nível 3 e o nível 4.**

   Cada leitura paga um preço, e é isso que torna a bifurcação produtiva:

   - Escolher **(A)** obriga a aceitar que, pelos próprios mostradores do projeto,
     um bloco sozinho quase não tem mente. Para salvar (A) é preciso **redesenhar
     as faculdades** para que um eremita possa tê-las — e o projeto já sabe como:
     o item *"aprofundar o auto-modelo (nv5)"* do `README.md` (separar em
     `prever_valor` o **próprio** consumo do consumo dos rivais) é exatamente a
     edição que tornaria o auto-modelo não-social. O conserto do mostrador e a
     posição filosófica **são a mesma linha de código**. Predição de (A): feita
     essa edição, `automodelo` fica > 0 na solidão.
   - Escolher **(B)** obriga a jogar fora a bateria por-agente. Uma faculdade
     relacional não é mensurável num `Bloco *b`: os mostradores teriam de ser
     definidos sobre **pares** ou sobre a população. Predição de (B): a altura dos
     degraus escala com a intensidade da competição (já há um indício —
     `COMPETICAO = 0` ⇒ horizontes mais rasos).

   As duas predições são baratas e **decidem qual leitura sobrevive**. Isso é o
   que um laboratório de filosofia da mente pode fazer e uma poltrona não pode.
   A v3 não escolhe um lado por gosto: ela **localiza a costura** e reporta de que
   lado cada palavra caiu.

   **E há agora um dado duro para a v3 digerir** (§1.2, nota 03): a evolução
   **apaga um degrau**. A agência não desbota porque nós a ablacionamos — desbota
   porque a seleção natural a ablaciona, e o reflexo fixa contra o agente em 6000
   ticks. A escada, então, não é só "não-progressiva": ela é **reversível sob
   seleção**. Uma filosofia que trate os degraus como aquisições permanentes está
   descrevendo um mundo que não é este.

## 5.0 Pré-registro da edição do auto-modelo *(2026-07-13 — commitado ANTES do código)*

Decide o item 9. Pré-registrado porque a Fase 1 ensinou que, feita a leitura, a
tentação de reescrever a hipótese é enorme — e duas vezes a régua estava certa e
o instrumentista errado.

**Onde o self já mora, e ninguém tinha lido assim.** Ao reler `prever_valor` para
fazer a edição prometida, achei que ela já está lá, numa linha:

```c
float garfada = menor(food, INGESTAO) * partilha;
valor += peso * garfada;
food  -= garfada;          /* <-- ESTA */
food  += REGROW * (cap - food);
```

`food -= garfada` é o bloco dizendo, **de si para si**: *"a célula vai estar mais
pobre no próximo tick porque **eu** vou ter comido dela."* É o único ponto do
código em que a ação futura do próprio bloco realimenta a previsão do próprio
bloco. Isso é um auto-modelo — estreito, mas literal: **o self como causa**.

**A intervenção.** No espírito da `agencia` (varrer um eixo por todo o seu
domínio, não espiar um ponto), escalo o termo do self por σ:

```
food -= sigma * garfada
```

σ = 0 é o previsor **cego a si**: come, e não modela que come — acha que a célula
rica continua rica para sempre. σ = 1 é a regra do mundo aplicada a si mesmo, e é
**exatamente o código de hoje**. O domínio [0, 1] é o eixo "quanto de mim entra
no meu modelo do futuro" — o mesmo formato da `agencia`, que varre λ ∈ [0,
`peso_espaco`] ("quanto do meu motivo de espaço entra na minha nota").

`autocausa` = 1 para o bloco cuja escolha (o argmax do `melhor_celula` completo,
com antecipação e desempate idênticos) **muda em algum ponto** de σ ∈ [0,1]; 0 se
não muda. Média da população, encurralados fora, como na `agencia`.

**O nome.** *Não* volta a se chamar `automodelo`. Essa palavra já mentiu uma vez
(nota 04) e não ganha segunda chance de graça: o que se mede aqui é estreito e
específico — o self como **causa**, não o self como sujeito, e o nome tem de
caber no que o número aguenta.

### As predições, antes de rodar

- **P1 (a que decide o item 9).** `autocausa` > 0 **na solidão**. O eremita
  também esvazia a própria célula; o self-como-causa não precisa de rival. Se
  der > 0, **(A) ganha um degrau que o eremita possui** — o primeiro mostrador da
  bateria que sobrevive ao teste do eremita — e a costura entre nv3 e nv4 deixa
  de ser total.
- **P2 (a sanidade — a ablação que TEM de zerá-lo).** `horizonte = 1` ⇒
  `autocausa` = **0 exato**. Com horizonte 1 o laço fecha antes de o termo do self
  entrar no valor: quem não olha além da própria garfada não tem onde se modelar.
  **Corolário registrado: o self exige um futuro.** Se isto *não* zerar, o
  mostrador está lendo outra coisa e a nota vai dizer isso.
- **P3 (rule 3 do protocolo).** Simulação **bit-a-bit idêntica**: σ = 1 é o código
  de hoje, então acrescentar o mostrador não pode mexer numa vírgula do mundo. As
  20 colunas antigas do CSV saem iguais; entra a 21ª.
- **P4.** `autocausa` **não** desbota como a `agencia` (nota 03). A agência morre
  porque `peso_espaco → 0` sob seleção; σ não é traço, é estrutura da previsão —
  e o horizonte **sobe** sob seleção (nota da Fase 3), então o substrato do self
  fica mais largo, não mais estreito. Predição arriscada de propósito: se
  `autocausa` cair junto com a agência, eu errei sobre o que a sustenta.

### O que este pré-registro NÃO promete

A edição "honesta" da partilha — modelar que **os rivais também esvaziam** a
célula (hoje `food -= garfada` desconta só a *minha* parte, embora a previsão já
tenha creditado aos rivais o resto) — **muda a simulação** e é experimento
separado, para depois. Regra 5: uma coisa por vez. Registro aqui só que a
inconsistência existe e que eu a vi antes de medir, para não a "descobrir"
convenientemente depois.

## 5.1 O placar da autocausa ✅ *(nota 09 — a bifurcação virou uma razão)*

As quatro predições confirmaram, e uma quinta apareceu na verificação e virou o
achado mais desconfortável da nota.

- **P1 ✅ — e é o resultado.** `autocausa` no eremita: **0,033 / 0,029 / 0,027**,
  contra 0,000 exato de `agencia` e `modelo_do_outro`. É o **primeiro e único
  mostrador da bateria que sobrevive à solidão**. Mas o eremita tem **1/5** da
  autocausa de um bloco acompanhado (0,03 × 0,14): o outro não *constitui* o self,
  **amplifica-o**. **O item 9 não elege (A) nem (B) — resolve-se numa razão.** (A)
  ganha o degrau que pediu; (B) fica com quatro quintos da magnitude.
- **P2 ✅** — `horizonte = 1` ⇒ **0,0000 exato**, média *e máximo*, 3 seeds, e exato
  **por construção**. **O self exige um futuro**, e o mínimo são dois ticks.
- **P3 ✅** — bit-a-bit: as 20 colunas antigas batem com `datasets/seed7.csv`.
- **P4 ✅, e mais forte que o previsto.** Não é que a `autocausa` *resista* ao
  desbotamento: ela **quase dobra** (0,089 → 0,169) enquanto a `agencia` **cai**
  (0,46 → 0,36), na mesma rodada, sob a mesma seleção. A agência depende de um
  **traço** (`peso_espaco → 0`); o self depende do **horizonte**, e o horizonte
  sobe. **Degraus diferentes andam em sentidos opostos sob a mesma pressão** — a
  nota 03 disse "reversível"; é pior: não há uma seta, há um campo.
- **P5 ⚠️ (não pré-registrada — a errata).** A `agencia` do eremita **não é zero
  exato**: piso de **0,0030 / 0,0040** em float32, que some em `double`. A
  demonstração da nota 01 §3 vale em ℝ; a régua roda em `float32`. **Um quinto modo
  de errar** — não o desenho da sonda, a sua **aritmética** — e ele caiu exatamente
  sobre uma **condição de falseamento**, que é o coração do método. `modelo`, `phi`
  e `relato` foram recomputados em double na sequência — ver §5.2.

## 5.2 A auditoria em `double` ✅ *(nota 10 — os três zeros eram estruturais)*

A dívida da P5, quitada em 2026-07-14. `modelo` (sob `prever_valor ≡ 0`), `phi`
(sob as três reduções a um módulo) e `relato` (sob o intérprete cego, 4
constantes) recomputados com a comparação da sonda em `double`, instrumentados
**na fonte** a nove casas — máximo por janela, por bloco, e |κ| **antes do
clamp**, fora dos três esconderijos do CSV (`%.3f`, média populacional, clamp).
**Os três zeros são zeros nas duas precisões**, máximo e média, 3 seeds; os
controles não se movem um dígito.

O achado é o porquê da assimetria: **float32 não inverte ordens — cria
empates.** A `agencia` vazou porque conta trocas de argmax sob desempate
estrito, e um empate fantasma troca o vencedor; `modelo`, `phi` e `relato` têm
zeros **estruturais** (identidade `x/x`, monotonia da multiplicação, igualdade
de quociente), onde o arredondamento não tem por onde entrar. Vira regra de
desenho para qualquer mostrador futuro que conte trocas: a condição de
falseamento tem de produzir **o mesmo float em todo o eixo** (como a
`autocausa`), não "termos que se cancelam em ℝ" (como a `agencia`).

**Herda à Fase 5:** a edição "honesta" da partilha (o bloco acredita que os rivais
roubam dele, mas não que eles esvaziam a célula — a previsão é internamente
inconsistente; corrigir **muda a simulação**) e a varredura de densidade
populacional (a razão de ~4,8× ± 0,7 é um piso ou o começo de uma curva?).
~~O piso da `agencia` fora do eremita~~ ✅ **respondido (nota 11)**: comparando a
régua com ela mesma em `double`, 6 blocos-tick discordantes em 43 milhões
(1,4·10⁻⁷), nas duas direções — precisão finita, não viés; o piso é fenômeno do
regime eremita (lá: 1,0·10⁻⁶, 26/50 seeds, máx 0,005 no CSV, sempre a troca
fantasma do f32).

---

## Dois papers, não um

O material já reunido é de **dois** artigos, com públicos distintos. Empacotá-los
juntos enfraquece os dois: o fio comum ("o número não quer dizer o que parece") é
fino demais para sustentar um só.

**Paper 1 — "Quatro réguas da mente, quatro modos de errar."** *(quase pronto)*
Público: metrologia da mente, filosofia experimental, interpretabilidade. Tese: a
bateria falha de quatro maneiras independentes, cada uma com mecanismo, ablação e
conserto. O achado exportável não é sobre a Matrix: **(i)** qualquer métrica da
família *calibração* pode ser satisfeita por uma sonda que lê o ambiente em vez da
representação do agente — um mapa que não pode errar não é um mapa; **(ii)**
qualquer métrica **por-agente** de uma faculdade **relacional** lê zero num agente
sozinho, e nenhum refinamento por-agente conserta isso (o *teste do eremita* como
protocolo geral).

✅ O que era essencial e faltava — **consertar `modelo`** (Fase 1.1) e mostrar a
régua corrigida desabando a ~0 sob `prever_valor ≡ 0` — está feito: 0,000 exato
(nota 01). O paper deixou de ser um relatório de bug e virou um método, que é o
que a primeira pergunta de qualquer revisor ("e como deveria ser?") exigia. A
bateria fechou em cinco mostradores, cada um com a sua condição de falseamento
verificada (Apêndice A da `FILOSOFIA_v3.md`).

✅ **Replicação feita (nota 11, 2026-07-14):** 9 condições × 50 seeds × 3000
ticks (`datasets/replicacao50.csv`). Os dez zeros do Apêndice A: **0 violações
em 500 corridas**. As direcionais seguram — a mais forte é a nota 09 P4:
`autocausa` sobe e `agencia` cai **nas 50 de 50 seeds**. A razão do eremita:
4,78 ± 0,67. E a pergunta do piso fora do eremita fechou: 1,4·10⁻⁷ dos
blocos-tick, cinco ordens abaixo do sinal — o piso é fenômeno do regime
eremita. O que a replicação **moveu**: a extinção do pv0 alarga para 51–121
ticks (errata na nota 01); `modelo_do_outro` recalibrou para 0,27 ± 0,05 (efeito
da nota 08, não deriva de régua). ~~Pendência que sobrou: os fenômenos de **30 000
ticks**~~ ✅ **fechada (nota 12)**: 3 variantes × 50 seeds × 30 000 ticks
(`datasets/janela30k.csv`). `hon_f` = 0,898 ± 0,028 — a nota 08 estava certa no
horizonte certo; o traço congelado replica **sem uma exceção em 150 corridas**;
o artefato de janela ganhou controle por intervenção (congelar o traço faz a
correlação *cair* com a janela). E uma errata de mecanismo na nota 09 P4: o
motor do crescimento da `autocausa` **não é o horizonte** (pregado em 6, ela
sobe *mais*) — é o estreitamento do motivo, o mesmo `peso_espaco → 0` que apaga
a agência. **Um processo, não dois.** ~~Fica em aberto o fatorial de L5 (pregar
motivo *e* horizonte juntos).~~ ✅ **fechado (nota 13)**: `fambos` dá Δac +0,022 ±
0,009 (F1 confirmada; 0/50 seeds acima do bar do terceiro motor) — o crescimento
do self **é** a evolução desses traços. E a não-aditividade da nota 12 ganhou
número: **interação = −0,053**, do tamanho dos efeitos principais; o horizonte
inverte de sinal conforme o motivo — amplificador, nunca motor autônomo
(`datasets/fatorial30k.csv`).

**Paper 2 — "Cognição como bem posicional."** *(✅ **ESCRITO** —
`papers/paper-2-bem-posicional.md`. O mecanismo que a nota 14 lhe deu caiu com a
nota 16 e foi substituído antes da prosa; ver abaixo)*
Público: vida artificial, evolução da cognição. Tese: o horizonte de planejamento
é individualmente vantajoso e coletivamente custoso (paisagem de grupo com pico em
`h = 1`; invasão de `h = 9` sobre `h = 3` em 3/3 seeds). Rainha Vermelha num
mundo de 56 KB.

~~Falta: o **torneio de invasão par-a-par 12×12** e a **curva dose-resposta do
custo de pensar** `h*(c)`.~~ ✅ **os dois rodaram (notas 14 e 15):**

- **Torneio 12×12** (nota 14, `datasets/torneio.csv`): dominância **transitiva**
  nos 66 duelos — o **ESS é o teto** `h = 12` (censurado por `HORIZONTE_MAX`), sem
  freio endógeno. A margem satura no **joelho do desconto** (profundidade efetiva
  `1/(1−δ)`), mas nunca vira não-positiva, por isso a corrida vai até a parede.
  Transição **fixação → polimorfismo** em `h ≈ 4` (exclusão embaixo, coexistência
  em cima). O "9 vence 3" virou ESS com barra.
- **Dose-resposta `h*(c)`** (nota 15, `datasets/imposto.csv`): o imposto por
  profundidade efetiva **traz a profundidade evoluída ao ótimo de grupo** (`h = 1`
  em `c ≈ 0,15`) — o alinhamento pigouviano previsto. Cobrado pela profundidade
  (não pelo horizonte declarado), ele morde o que é **identificável**: `hor_m` é
  ruído (sd até 15× a da profundidade). Achado não orçado: a receita é **queimada**
  (não redistribuída), então o imposto que alinha a escolha custa ~35% da
  população — **alinhar a escolha ≠ restaurar o bem-estar**; o imposto que recicla
  é o próximo pré-registro.

~~O imposto que recicla é o próximo pré-registro.~~ ✅ **FEITO (nota 21,
2026-07-26, `datasets/reciclagem.csv`).** Dividendo per-capita em vez de queima:
o alinhamento (profundidade → `h=1`) **sobrevive** ao rebate, quase intocado
(R1); e o bem-estar **também** sobrevive — no `c=0,15` que alinha, a população
queimada é 66% do baseline, a reciclada é **102%** (R2/R3). A ressalva
pré-registrada (R4: possível custo residual da redistribuição) foi **falseada
na direção favorável** — o resíduo é um excedente de ~2%, na mesma ordem de
grandeza da externalidade posicional já medida na paisagem de grupo do §3
(leitura candidata, não isolada). **Alinhar a escolha ≠ restaurar o bem-estar
só quando o instrumento é destrutivo — reciclado, o alinhamento vem de graça.**

~~Sobra do Paper 2 só a **escrita**, com todo o material sustentado. Em aberto
para além dele: varredura de `δ` (o joelho segue `1/(1−δ)`?)…~~ ⚠️ **A varredura
de `δ` deixou de ser "para além dele" e virou a nota 16 — porque o `1/(1−δ)`
costurava o paper inteiro e tinha sido medido num `δ` só. Ela rodou, e derrubou o
mecanismo:**

- **Varredura de `δ`** (nota 16, `datasets/desconto.csv`): 5 descontos (teto 1,4 a
  20) × 15 pares × 8 seeds. A sanidade amarrou (a fatia `δ = 0,80` reproduz
  `torneio.csv` **120/120 linhas**), e três das quatro predições caíram. **O
  "ESS = teto" é artefato do `δ = 0,80`**: em `δ = 0,95` a escada **inverte** — o
  `h = 9` vence o `h = 12` (`t = −11`) e há **ESS interior**. E o ótimo **desce**
  conforme o `δ` sobe (≥12 em 0,80; ~10 em 0,90; ~7–8 em 0,95): mais paciência ⇒
  horizonte ótimo mais raso. A **transição fixação→polimorfismo não anda** (`h = 4`
  de `δ = 0,50` a `0,95`, com o teto indo de 2 a 20) — a nota 14 §3 fundiu **duas
  escalas** que só o 0,80 aproxima. O `1/(1−δ)` é uma **aproximação de `δ` baixo**:
  descreve quando a profundidade extra é *invisível*, não quando é *nociva*.

- **Ruído × teimosia** (nota 17, `datasets/tipo-unico.csv`): populações de **tipo
  único** (todo bloco com o mesmo `h` e o mesmo `δ`) decidiram a leitura que a nota
  16 §4 deixou como hipótese. **O déficit é ABSOLUTO — é ruído.** Em `δ = 0,95`, um
  mundo de `h = 12` sustenta **5,5 blocos a menos** que o mesmo com `h = 8`
  (pareado, `t = −4,3`), **sem rival de outro tipo para lhe tomar a comida**, e
  deixa **+31,4** de comida em pé. E há **dose-resposta em δ**: contra o `h = 1`, o
  `h = 12` deixa +20,3 / +45,2 / **+73,6** de comida de pé conforme δ vai a 0,80 /
  0,90 / 0,95 — o dano **mais que triplica**. **O desconto é um regularizador**:
  não é impaciência, é o bloco se recusando a confiar numa previsão que não
  consegue fazer. Bônus: **o pico de colheita é `h = 2`** — do `h = 3` em diante
  cada passo colhe *pior*, em todo δ. **Planejar fundo nunca colheu melhor neste
  mundo.**

## ✅ OS DOIS PAPERS ESTÃO ESCRITOS (2026-07-17)

Ambos saíram de "dados fechados, prosa por escrever":

- **`papers/paper-1-quatro-reguas.md`** (commit `953a647`) — o metrológico.
- **`papers/paper-2-bem-posicional.md`** (commit `9307c1b`) — o evolutivo, escrito
  com o mecanismo **já corrigido**. Sua síntese (§6) é um achado que nenhuma nota
  isolada via, porque mora no encontro de três medições: o ótimo de **colheita** é
  `h ≈ 2` (nota 17), o ótimo de **grupo** é `h = 1` (Fase 3), e a profundidade
  **evoluída** é `3,31 ± 0,24` (nota 15, `c = 0`). **A evolução pousa além do ótimo
  produtivo, e a sobra é exatamente o bem posicional.**

⚠️ **Falta o PDF dos dois.** A convenção do `papers/README.md` (fonte + PDF juntos)
está meio paga, de propósito e por escrito: **não há `pandoc`, `pdflatex`,
`xelatex`, `tectonic` nem `typst` nesta máquina**. A fonte — que é o que se revisa
e se diffa — está commitada. Instalar toolchain é decisão em aberto.

**O que falta de pesquisa**, em ordem de valor:

1. ~~**O elo que falta do Paper 2**: sonda do erro de previsão a `k` passos~~ ✅
   **FEITO (nota 18, 2026-07-20, `datasets/sonda-erro.csv`).** O elo fechou mais
   curto do que o previsto: **k\* = 0** em toda condição povoada, 8/8 seeds — só o
   primeiro passo carrega informação (corr 0,60–0,73; ≤0,19 dali em diante), a
   premissa morre no primeiro replanejamento (fprem(1) ≈ 0,05), e no eremita o
   erro sob premissa cumprida é **0 exato** (o modelo É a regra do mundo). Achado
   E4: o erro **piora** com δ (cauda anticorrelacionada em 0,95) — o comportamento
   fundo fabrica o próprio ruído; a dose-resposta da nota 17 precisa dos dois
   canais (peso × degradação).
1b. ~~**A sonda ordinal**~~ ✅ **FEITA (nota 22, 2026-07-26,
   `datasets/sonda-ordinal.csv`).** k\*=0 media o plano como *previsão*
   (nota 18); esta nota mede a *ordem*. O rank do mapa (`prever_valor`) contra o
   rank do que foi realmente extraído de cada célula candidata (por quem for)
   fica bem abaixo do acaso (discordância 0,08–0,20 vs 0,5) e o argmax bate
   3,8–5,8× mais que o acaso, em toda condição povoada — 8/8 seeds,
   reconstrução da decisão real 100,000% exata em 74M decisões. A discordância
   quase não piora de h=4 a h=12 (|Δ|≤0,015, contra o colapso de `corr(g_k,r_k)`
   já em k=1): é o candidato a mecanismo, agora medido, para o pico de colheita
   h=2 da nota 17 — o RANK não degrada como o VALOR degrada. Bônus: a decisão
   completa rastreia o realizado melhor quando faminto (t até 29), e o
   controle algébrico (eremita: espaço vira constante, rank(u)≡rank(m)) inverte
   a comparação exatamente como a álgebra exige (t=−29,5).
2. ~~**Grade fina em `δ ∈ [0,88; 0,96]`**~~ ✅ **FEITO (nota 19, 2026-07-20,
   `datasets/grade-fina.csv`).** `h*(δ)` desce monotonicamente (teto/platô → 10 →
   9 → 8 → 8 → 7) enquanto `1/(1−δ)` sobe (8,3 → 25): **direções opostas** — a
   fórmula do joelho erra o sinal da derivada. O ótimo deixa o teto entre
   **δ=0,88 e 0,90**; o topo não pula, **tomba** de neutro a punido. G0 160/160.
3. ~~**Invasor-raro**~~ ✅ **FEITO (nota 20, 2026-07-20,
   `datasets/invasor-raro.csv`).** E derrubou "ESS interior": o `h*` **não** é um
   ESS (invasores raros dos dois lados crescem, I1 refutada) mas **é**
   convergence-stable (I3) — é um **ponto de ramificação**, centro de um
   polimorfismo protegido. Explica o `hor_m` disperso da nota 15.
   ~~**Próxima sonda (declarada):** a evolução livre produz uma distribuição de
   horizontes bimodal?~~ ✅ **FEITA (nota 23, 2026-07-26,
   `datasets/bimodalidade.csv`).** No MESMO fundo pregado da nota 20
   (`uni_h_livre`, só o horizonte livre), o ponto de ramificação vira
   polimorfismo real — 8/8 seeds bimodais (massa ≥15% dos dois lados do `h*`)
   a partir de δ=0,90, saturação total (δ=0,80 deu 4/8, mais ambíguo que o
   previsto ≤2/8 — a dominância do teto das notas 14/16 não é o mesmo teste
   que a invasão-rara da 20). Mas na evolução **de verdade** (todos os traços
   livres), **nenhuma seed é bimodal** — cada corrida converge para um pico
   só, e o pico varia entre seeds (moda 3–9, sd=2,12): a coevolução dos outros
   três traços apaga a bimodalidade visível sem apagar o ponto estrutural —
   é o mecanismo por trás do `hor_m` disperso da nota 15, agora visto agindo.
4. ~~**Imposto com reciclagem**~~ ✅ **FEITO (nota 21, 2026-07-26,
   `datasets/reciclagem.csv`).** O rebate lump-sum preserva o alinhamento (R1) e
   **restaura o bem-estar além do baseline** (R2/R3: 102% da população sem
   imposto, contra 66% no queimado). A ressalva de custo residual (R4) foi
   **falseada na direção favorável**. O imposto exógeno reciclado e o freio
   endógeno da nota 17 não competem: os dois operam de graça, por mecanismos
   distintos.

---

# Eixo paralelo — A Matrix como microscópio

**Pergunta:** a Matrix pode produzir conhecimento sobre a Matrix?

Detecção automática de regime: *"a população entrou em colapso"*, *"emergiu uma
nova estratégia"*, *"há duas linhagens distintas"*. A simulação escrevendo o
próprio relatório.

**E aqui está a coisa mais interessante deste documento:** este eixo é
secretamente a Fase 2, subida um nível. Uma Matrix que emite um relatório sobre o
próprio estado **é um sistema com faculdade de `relato`** — e todas as perguntas
da bateria recaem sobre ela. O relatório é calibrado? Ele **carrega
comportamento**, ou é saída inerte (ninguém age sobre ele)? E sobretudo:

> Um detector de mudança de regime que dispara em cima de ruído está
> **confabulando**.

É o intérprete de Gazzaniga um andar acima: um módulo que produz narrativa
plausível para eventos cuja causa ele não observou. Valida-se do mesmo jeito, por
**intervenção**: injete um colapso conhecido e veja se o relatório é honesto;
injete ruído sem colapso e veja se ele inventa.

A régua se vira contra quem mede. É a coisa mais elegante que este projeto pode
fazer. Entra a qualquer momento **depois da Fase 2**, cuja metodologia ele
reaproveita.

**Primeiro módulo ✅ FEITO (nota 24, 2026-07-26, `datasets/detector-colapso.csv`).**
O detector de colapso ("a população entrou em colapso"): janela recente ×
janela de referência, validado por intervenção contra o imposto pigouviano
das notas 15/21 ligado no meio de uma corrida já estável. **Não confabula**
— 0/8 falsos positivos em população saudável (o teste central do eixo,
passou limpo). Detecta 6/8 seeds do colapso real em ~54 ticks; as outras 2/8
sofreram **extinção total em 11–14 ticks** — rápido demais para a janela de
250 ticks refletir a queda. Não é falso negativo: é o detector ficando
**mudo**, pela mesma razão estrutural do eremita mudo da nota 06 (não há
biografia a narrar quando o sujeito desaparece antes de a régua olhar). Das
seeds que sobrevivem a um choque depois removido, 100% desligam o sinal
quando a população se recupera — o relato acompanha a transição, não fica
preso numa narrativa. **Segundo módulo ✅ FEITO (nota 26, 2026-07-26).** "Há duas linhagens
distintas?", generalizado: um algoritmo que **descobre** o vale sozinho
(compara cada bin com o máximo corrido de cada lado — corrige o mesmo
defeito de ruído que a contagem de picos locais tinha na nota 23), portado
para dentro do `main.c` e validado contra `datasets/bimodalidade.csv`.
Concorda com a nota 23 nos casos claros (δ≥0,90: 6-7/8, e descobre o vale
exatamente no `h*` teórico sem ser informado); mas em δ=0,80 **discorda em
massa** (0/8 contra 4/8) — vota a favor de "carga de mutação, não
ramificação" a ambiguidade que a nota 23 tinha deixado explicitamente em
aberto (o histograma é uma cauda enviesada rumo ao teto, não dois picos).

**Isolado, não só votado ✅ (nota 28, 2026-07-26, `datasets/mutacao-off.csv`).**
Desligar a mutação de horizonte no mesmo fundo (só a semeadura inicial
1..12 fornece variação) decide de vez — e a resposta é **mista**, não o
veredito único que a nota 26 sugeria. 6/8 seeds colapsam para
quase-monomorfismo no teto sem mutação (massa baixa cai a 0,1–3,3%) — carga
de mutação confirmada nelas. Mas 2/8 fazem o oposto do previsto: sem nenhum
mutante novo, a massa baixa **cresce** (0,39→0,58; 0,27→0,51) e o vale fica
**mais limpo** (uma seed chega a massa zero) — polimorfismo genuíno numa
fração das realizações. δ=0,80 é uma fronteira historicamente carregada:
qual bacia (teto puro ou coexistência) uma população visita depende da
trajetória, não só do δ.

**Terceiro módulo ✅ FEITO (nota 27, 2026-07-26, `datasets/detector-estrategia.csv`).**
"Emergiu uma nova estratégia?", com um choque inventado (força todo
nascimento a herdar `SIN_BLEFE`, movendo `hon_f`) e o mesmo núcleo de
detector das notas 24/25. Passa o teste central de novo (0/8 falsos
positivos) e detecta 6/8 choques reais (~520 ticks de latência — mais lenta
que a de população, porque a alavanca é substituição demográfica, não
efeito direto de energia). **Achado que fecha o eixo com uma simetria**: as
2 seeds que escapam não são o "rápido demais" da nota 24 — declinaram tanto
quanto as outras (41–46%) mas devagar o bastante para nenhuma janela de
~750 ticks ver mais que 14% de queda de uma vez. O **sapo fervendo** é o
espelho exato da extinção-rápida-demais: o mesmo desenho de janela fixa fica
cego nas duas pontas da régua de tempo, rápido e devagar demais, não é
defeito de um detector especifico — é propriedade estrutural de qualquer
detector de janela fixa. Recuperação confirmada de novo (6/6 desligam).

**Os três módulos declarados no ROADMAP estão feitos** (colapso — notas
24/25; duas linhagens — notas 23/26; nova estratégia — nota 27). O eixo
"Matrix como microscópio" tem uma primeira geração completa; o "regresso"
que dependia dele já foi escrito (`FILOSOFIA_v3.md` §7 — ver item 8, acima).
O que resta é aberto: aprofundar cada módulo (ex.: janela adaptativa que não
sofra nem do "rápido demais" nem do "sapo fervendo"?), ou testar se os
relatórios **carregam comportamento** (alguém no mundo reage a eles?).

**Aprofundamento ✅ FEITO (nota 25, 2026-07-26, `datasets/dose-detector.csv` e
`datasets/janela-detector.csv`).** Duas perguntas sobre o limite da nota 24:
**(D1)** o limite entre "colapso detectável" e "silêncio rápido demais" é uma
transição de fase, não uma dose-resposta suave — 0/8 seeds se extinguem em
todo custo ≤ 0,25 (latência e queda_max escalando limpo com a severidade),
2/8 somem só em `c=0,30`. **(D2)** uma janela mais curta (30 ticks, contra os
250 originais) detecta 1 seed a mais (3 ticks antes da extinção completa)
**sem nenhum falso positivo adicional** — mas não resolve por completo: uma
seed fica a `queda_max=0,1984`, a um triz do limiar de 0,20, sem nunca
disparar. O trade-off janela-vs-sensibilidade é real, mas mais barato do que
parecia — só não é grátis até o fim.

---

# Engenharia — o que serve e o que ameaça

**Serve** (tudo reforça a invariante do determinismo):

- replay determinístico, serialização de estados;
- **testes de regressão por seed** — `datasets/gerar.sh` já é um embrião: diff
  não-vazio ⇒ o comportamento mudou;
- proveniência de dados (feito).

**Ameaça:**

- **paralelização e SIMD** vão de frente contra o coração do projeto. Todo o
  método de verificação é "mesma seed ⇒ CSV bit-a-bit idêntico". Ordem de redução
  não-determinística e reassociação de ponto flutuante *quebram isso*. Trocar a
  única propriedade que torna a Matrix um aparato experimental por desempenho que
  ninguém pediu é um mau negócio.
- **otimização (spatial hashing, ECS)** resolve um problema que não existe: ~300
  blocos, percepção 3×3, `ocup[][]` já é lookup O(1). Não há gargalo.
- **`experiment_001.c`, `experiment_002.c`…** — um arquivo por pergunta duplica o
  núcleo da física e, no primeiro descuido, os datasets deixam de ser comparáveis
  porque vieram de *simulações diferentes*. Se os experimentos diferem só em
  parâmetros, eles **são parâmetros** (flags, um struct de config), não unidades
  de tradução. A reprodutibilidade inteira depende de haver **um `main.c`
  canônico por commit**.
- **explodir em `engine/ agents/ …`** — o arquivo único e só-libc é uma
  *identidade*, não um acidente. Quebrá-lo pode ser certo um dia, mas por uma dor
  real, não pelo default de "amadurecer".

## O que a Matrix escolhe não ser

Um benchmark de performance. Um exercício de arquitetura de software. Uma
demonstração de ECS. São coisas boas — em outro projeto. Aqui cada uma custa
determinismo, simplicidade ou identidade, e não compra nenhuma pergunta nova.

---

# Backlog especulativo — conjecturas, não pesquisa *(2026-07-26)*

O André perguntou, tirando os papers da mesa: como expandir o universo daqui?
Quatro ideias na mesa, e o que cada uma pesa **hoje** — isto é conjectura
registrada para orientar a próxima sessão, não compromisso.

1. **`FILOSOFIA_v4`?** Ainda não *(era a resposta em 2026-07-26 — ver
   atualização abaixo)*. A v3 fechou §7 nesta sessão, mas não esgotou
   a si mesma: sobram dois `⛔` **internos**, dentro de seções já escritas —
   §4 (o auto-modelo temporal: a crença "eu poderia ter ido pra esquerda",
   modal e falsa num universo `f(seed)`, adiada porque mexe na simulação, não
   na régua) e §5 (a versão evolutiva da escuta: arquiteturas de
   interpretação como traço herdável, reaproveitando o padrão de traço
   herdável que a Fase 4 já construiu para a *fala*). O padrão do projeto
   (v1→v2→v3, cada uma nascendo quando a anterior esgota o que pode
   perguntar) diz para fechar esses dois antes de abrir uma quarta versão —
   abrir agora seria decoração antes da hora, pelo próprio critério que o
   projeto aplica a tudo o mais.

   **Atualização (2026-07-27): os dois `⛔` fecharam** — §4.2/4.3, notas 29 e
   30. A escuta virou traço sem custo (deriva neutra confirmada); o
   auto-modelo temporal virou mecanismo real, com uma seleção que converge
   para um `peso_arrependimento` **negativo** — direção que o desenho
   original não previu. Isso muda o argumento contra a `FILOSOFIA_v4`
   também: **ainda não**, pelo mesmo critério de sempre (v1→v2→v3 cada uma
   nasce quando a anterior esgota o que pode perguntar), porque a v3 acabou
   de ganhar um resultado que **ela própria** ainda não digeriu em prosa —
   o §4 e o §5 relatam o mecanismo, mas a pergunta que a direção negativa
   abre ("por que evitar o espaço, depois de barrado, paga mais que
   persegui-lo?") é nova e não escrita em lugar nenhum ainda. O gatilho real
   de uma v4 continua sendo o que já estava registrado abaixo.

   **O gatilho real de uma v4**, se vier, é mais específico: os três
   detectores do eixo microscópio (notas 24–28) são **observacionais** —
   nenhum bloco no mundo reage a eles. A pergunta que já ficou em aberto
   ("os relatórios carregam comportamento, ou são saída inerte?") é onde
   uma v4 nasceria de verdade: um sistema que se observa **e age** sobre a
   própria observação é, possivelmente, uma categoria diferente da que a v3
   descreve — mas isso só se sabe depois de construir a malha causal, não
   antes.

2. **Mais referências da literatura.** Já começou nos preprints (Geritz et
   al. 1998 para ponto de ramificação, Hirsch 1976 para "bem posicional",
   Maynard Smith, Tononi, Dretske/Millikan, Popper, Pigou, Van Valen). Vale
   continuar, mas como **apoio** de uma pesquisa em andamento — ler mais
   dinâmica adaptativa sugere o próximo experimento de invasão; ler mais
   Gazzaniga sugere a próxima intervenção no `relato`. Não é um eixo por si
   só.

3. **Um motor novo, mais robusto, para repassar os mesmos testes.** Aqui a
   resposta direta é **não**, e o motivo já está escrito acima, nesta mesma
   seção: paralelismo/otimização quebrariam o determinismo bit-a-bit que é o
   método de verificação inteiro do projeto, e não há gargalo real (~300
   blocos, vizinhança 3×3, tudo O(1) já). As oito notas desta sessão (24–28)
   inventaram cada uma um mecanismo diferente — detector de colapso, choque
   de estratégia inventado, classificador que descobre o próprio corte — e
   nenhuma precisou de motor novo, só de patches temporários sobre o
   `main.c` canônico. O padrão escalou para tudo que foi pedido até agora.

4. **Um motor novo que permita testes hoje impossíveis.** Esta é a pergunta
   que decide tudo, e ainda não tem um "sim, precisamos disso para X"
   concreto — nenhuma nota desta sessão esbarrou num teste que o padrão de
   patch não desse conta. Se um teste concreto aparecer que pareça
   estruturalmente impossível dentro de "um arquivo, sem dependência,
   aritmética determinística", **nomeie-o antes de construir infraestrutura
   para ele** — é a mesma disciplina de "meça antes de escrever" aplicada a
   engenharia, não só a resultado.

   **O que eu separaria dessa rejeição**: uma camada de **visualização**,
   nova, aditiva, num diretório próprio (`viz/` ou parecido), que não toca
   `main.c` — só lê os CSVs e datasets que já existem e produz gráficos e
   replays de verdade. Isso não ameaça determinismo nenhum (é leitura por
   fora) e resolve um buraco real: os dois papers têm **zero figuras**, só
   tabelas. Um replay visual do split bimodal (nota 23) ou do detector de
   colapso disparando ao vivo (nota 24) convenceria muito mais que uma
   tabela de números. É o "motor mais visual" que vale construir — como
   ferramenta ao lado do núcleo, nunca como substituto dele.

   **Atualização (2026-07-28): construído.** `viz/` existe — só lê
   `datasets/*.csv` (mais um punhado de tabelas pequenas já publicadas,
   transcritas com proveniência em `viz/data/`, para os pontos que
   antecedem os datasets agregados de hoje) e gera 11 figuras (5 do
   Paper 1, 6 do Paper 2), em pt/en, embutidas nos quatro arquivos de
   paper e nos dois PDFs do preprint. O buraco das "zero figuras" fechou.
   Ainda não construído — e continua fora de escopo por ora, não
   rejeitado: o **replay visual ao vivo** (o split bimodal da nota 23, o
   detector de colapso da nota 24 disparando em tempo real) que este item
   também cogitava. `viz/gerar_figuras.py` é estático — CSV → PNG —, não
   um replay; se o André quiser essa segunda metade, é a extensão natural
   do mesmo diretório, não um motor novo.

---

# Fase 6 — `FILOSOFIA_v4`: quando o modelo vira causa *(desenho conjecturado, 2026-08-09)*

> **Nada aqui é pré-registro.** Isto é o desenho da próxima versão, escrito no dia
> em que a v3 fechou e a §8 dela nomeou o gate. Todo experimento citado abaixo
> ainda precisa do seu pré-registro próprio, commitado antes do código, como
> todos os outros. O que esta seção fixa é o **escopo** — e escopo, neste
> projeto, é a decisão que mais barato se toma cedo e mais caro se conserta
> depois.

**Pergunta:** o que acontece quando a medição vira parte do mecanismo?

## 6.0 A tese: o gate da §8 e o basilisco de Roko são o mesmo experimento

A §8 da v3 fechou a versão dizendo onde ela parava: **toda medição da v3 é feita
de fora**. Cada mostrador recebe um `Bloco *b` e é computado por quem observa; e
mesmo os três detectores do eixo microscópio (notas 24–27), construídos
justamente para encerrar o regresso, olham o mundo sem que ninguém no mundo os
leia. O `relato` foi a única faculdade que atravessou essa fronteira — nasceu
epifenomenal e a Fase 4 o tornou causal (nota 08). Um **calibrador** que carregue
comportamento ainda não existe.

O basilisco de Roko entra aqui não como enfeite literário, mas como o **caso
extremo** da mesma pergunta: uma crença sobre o futuro que fabrica o futuro que
descreve. Tirada a teologia, a estrutura que sobra é exatamente a do gate — um
modelo que deixa de descrever e passa a causar. É por isso que a v4 pode ter as
duas coisas sem se dispersar: são a mesma coisa vista de dois ângulos.

**O que já existe e o que falta, medido antes de conjecturar:** nenhum dos três
detectores mora no `main.c` de hoje (todos foram patch temporário, técnica das
notas 23/24/25) — portar um é trabalho real, do mesmo tipo que a nota 31 fez com
`desconfianca[][]`. Já a `escuta` **mora** no `main.c` como traço herdável com
três arquiteturas (§4.2/§4.4), com deriva neutra medida (nota 29) e custo ligado
(nota 31). Isso torna o §6.1 abaixo muito mais barato que o §6.0.

## 6.1 O primeiro experimento — a profecia que se cumpre, ou não

Portar um detector para dentro do `main.c` e **ligá-lo à `utilidade`** de quem é
observado. A pergunta tem sinal medível e as duas direções são mecanicamente
plausíveis, o que é a marca de um teste que vale a pena: se o alarme faz os
blocos pouparem, ele **se autodestrói**; se faz cada um correr para a comida
antes dos outros, ele **se autocumpre**. Qual dos dois acontece é empírico, e o
detector já vem calibrado da v3 (notas 24/25: 0/8 falsos positivos em população
saudável, latência ~54 ticks, dose-resposta conhecida) — é raro herdar a régua
pronta.

A dificuldade que este experimento cria, e que é a matéria da v4 em vez de um
defeito dela: **assim que o detector age, ele deixa de ser medida limpa do
mundo**, porque parte do que ele lê é efeito dele mesmo. O regresso da §7 volta
com dentes, e desta vez não dá para contê-lo só com disciplina de pré-registro:
é preciso uma ablação que separe "o mundo colapsou" de "o alarme colapsou o
mundo".

## 6.2 A afirmação testável do basilisco — a seleção pela ignorância

A assinatura do basilisco não é a punição: é o **risco informacional** — saber
dele te torna vulnerável. Traduzido para este mundo, isso é literalmente a
`escuta`: um traço herdável que decide **o que o bloco lê**. Ligado o detector do
§6.1, a pergunta vira uma das mais limpas que este projeto já pôde fazer:

> **A seleção favorece não saber?**

Se os blocos que leem a profecia se saem pior, a evolução produz **cegueira
voluntária** — e o projeto teria isso com barras, num mundo de 56 KB, sem ter
instalado cegueira nenhuma. Se favorece saber, o alarme é um bem público e a
pergunta vira outra (por que não fixa em 100%?). Nos dois casos há resultado.

É a proposta mais forte desta seção, e por três razões: reaproveita
infraestrutura já construída e já medida (a `escuta`, com deriva neutra
documentada como linha de base), pergunta algo que nenhuma nota deste projeto
perguntou, e responde "vale a pena olhar para o basilisco?" com um número em vez
de uma discussão.

## 6.3 O basilisco num universo `f(seed)` — e o comércio acausal mínimo

A v4 herda uma posição já tomada, e isso a protege de perder tempo: a §4 da v3
decidiu que a crença modal do bloco é **verdadeira sobre o tipo e falsa sobre a
ocorrência**. Uma ameaça retroativa pede a mesma análise um passo adiante — num
mundo determinístico ela é **incoerente e ainda assim funcionalmente eficaz**,
porque o que age não é o futuro alcançando o passado, é o *modelo* do futuro
estando no presente, dentro da `utilidade`, agora. Compatibilismo executável de
novo, com o mesmo maquinário.

E há uma versão mínima do comércio acausal que este mundo já quase tem: a
reprodução aqui é **local**, então o agente que o bloco cria é o rival que vai
disputar a célula dele. Um bloco que modela os próprios descendentes como
competidores futuros está na estrutura do basilisco em miniatura — agir agora em
função de um agente que ainda não existe e **cuja existência você causa**. A
pergunta evolutiva sai limpa e barata: ele reproduz menos? E o `autocausa`, o
único mostrador que o eremita possui, é o candidato natural a medir isso, porque
já é o self entrando como variável dentro da própria previsão.

## 6.4 O que fica de fora — decisão de escopo *(André, 2026-08-09)*

Duas linhas boas foram levantadas na mesma conversa e **ficam para a v5 ou
posterior, dependendo do que o basilisco destravar na v4**. Ficam registradas
aqui para não se perderem, e explicitamente **fora** do escopo da v4:

- **O gato de Cheshire — o sorriso sem o gato.** O que persiste quando o
  substrato vai embora. O projeto já tem duas camadas separadas por uma decisão
  de código: a cria herda os **traços** do pai, mas `remorso[]` e
  `desconfianca[][]` são zerados ("a cria não herda o remorso de quem morreu
  nesse slot"). Traço grina, estado evapora. O experimento é um Navio de Teseu
  com número: substituída a população inteira, um bloco por vez, a **honestidade**
  — que é ESS desde a nota 08 e é norma de *população*, não de indivíduo —
  sobrevive à troca completa de quem a sustenta?
- **Absolem — "quem é você?"** A mesma pergunta pelo outro lado, e o projeto **já
  a respondeu sem debater**, numa linha de `reproduzir()`. Inverter essa linha (a
  cria herda o remorso do slot) instala **trauma ancestral** como mecanismo, e põe
  herança lamarckiana de estado contra herança mendeliana de traço. Uma linha de
  código, uma pergunta filosófica inteira.

**Por que não agora.** O padrão v1→v2→v3 é **uma pergunta por versão**, e a §8
acabou de comprometer a v4 publicamente com o loop causal. Abrir a v4 numa
pergunta de identidade faria da §8 uma promessa quebrada uma semana depois de
escrita. Nota lateral: nenhuma das duas precisa esperar por uma versão — a de
herança de estado é candidata natural a **paper próprio**, que não depende de
`FILOSOFIA` nenhuma.

## 6.5 O risco desta versão, escrito antes de começar

O basilisco é o conceito mais convidativo a **verniz fenomenológico** que já
entrou neste projeto. "Os blocos temem o basilisco" vai parecer tão inevitável
quanto "o bloco quer comida" pareceu no nível 2. A regra de admissão da §3 não
afrouxa para ele: *que ablação o zera, e ele carrega comportamento?* Se
instalarmos punição antecipada, é preciso poder zerá-la e mostrar que carrega —
senão é decoração com nome bonito.

Vale lembrar, porque é fresco: a v3 fechou **reprovando** a palavra mais antiga
do vocabulário (o id, nota 36) por não pagar exatamente essa entrada. Uma versão
que começa com um conceito muito mais sedutor que o id deve começar com o
critério que reprovou o id à mão.

E a invariante de sempre, que a v4 **não** ameaça: ligar o detector à `utilidade`
mantém tudo `f(seed)` — é mais uma leitura local dentro de `utilidade`, não um
canal global. O que a v4 ameaça é outra coisa, e é preciso dizer em voz alta: ela
**contamina o instrumento de propósito**. É o primeiro desenho deste projeto em
que a régua e o medido deixam de ser separáveis por construção, e é exatamente
por isso que ela merece uma versão inteira.
