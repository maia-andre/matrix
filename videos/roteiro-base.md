# Roteiro-base: série de vídeos sobre a Matrix

Este documento serve de base para quem for escrever os roteiros finais, seja um
humano ou outro agente. Ele não é o roteiro final. É o mapa de **o que existe no
repo, o que cada vídeo conta e de onde vem cada número**.

Retrato do projeto em 2026-10-24. O último commit é `9598742` (nota 38), de 2026-08-15.

---

## 0. Regras para quem for escrever a partir daqui

1. **Todo número na tela ou na narração tem fonte no repo.** Abaixo, cada
   afirmação aponta para uma nota (`papers/notes/NN-*.md`), um paper ou um
   dataset. Se o número não está lá, ele não entra. Na dúvida, abra a nota e
   copie o número dela, não deste documento.
2. **Função, nunca experiência.** O projeto não afirma que os blocos sentem. Os
   mostradores medem se uma faculdade **carrega o comportamento** (ablação e
   calibração). Essa é a tese da `FILOSOFIA_v3.md` §6, e a narração não pode
   escorregar para "os blocos são conscientes". O gancho pode provocar ("será que
   sentem?"), mas a resposta do vídeo é sempre sobre a régua.
3. **A cronologia honesta é o diferencial.** O projeto registra hipóteses mortas,
   bugs na própria régua e previsões erradas (as notas existem para isso; ver
   `papers/notes/README.md`). Os vídeos devem mostrar o erro antes do conserto. É
   isso que os separa de um "olha que legal minha simulação".
4. **Sem atribuição a IA** em nada publicado: descrição, créditos, legendas. O
   autor é André Maia.
5. Idioma: pt-BR. Termos técnicos (ESS, ablação, seed) aparecem com uma frase de
   tradução na primeira vez.

---

## 1. Inventário: o que existe para usar

| Ativo | Onde | Uso em vídeo |
|---|---|---|
| Simulação ao vivo (ASCII, ANSI) | `main.c` → `gcc -std=c11 -Wall -Wextra -O2 -o matrix main.c` | B-roll principal; visão de deus e primeira pessoa |
| Chuva estilo Matrix | `assets/matrix-rain.gif` (gerada por `assets/gerar_rain.py`) | abertura, vinheta |
| Replay da bifurcação | `viz/replays/replay-bimodal.gif` | a população se divide em duas linhagens (nota 23) |
| Replay do colapso | `viz/replays/replay-colapso.gif` | detector de colapso disparando e desligando (nota 24) |
| 11 figuras (pt e en) | `papers/figs/pt/`, `papers/figs/en/` (geradas por `viz/gerar_figuras.py`) | gráficos explicativos (lista na §1.1) |
| Paper 1 (pt) | `papers/paper-1-quatro-reguas.md` | vídeo 2 |
| Paper 2 (pt) | `papers/paper-2-bem-posicional.md` | vídeo 3 |
| Preprints (en, PDF) | `papers/preprint/*.pdf` | "link na descrição" |
| 38 notas + scripts | `papers/notes/` (índice em `README.md`) | fonte de cada achado |
| Filosofia v1, v2, v3 | `FILOSOFIA.md`, `FILOSOFIA_v2.md`, `FILOSOFIA_v3.md` | arco narrativo, citações |
| ROADMAP | `ROADMAP.md` (o maior documento, ~25k palavras) | o que vem (v4, Fase 6) |
| 21 datasets congelados | `datasets/*.csv` + `datasets/README.md` (proveniência) | "tudo reproduzível" |

### 1.1 Figuras

| Arquivo | Mostra | Vídeo |
|---|---|---|
| `p1-fig1-modelo-ablacao` | `modelo` dá nota máxima a um agente sem modelo de mundo | 2 |
| `p1-fig2-agencia-regra4` | o conserto da `agencia` | 2 |
| `p1-fig3-modelo-do-outro-alpha` | o "automodelo" que media o outro | 2 |
| `p1-fig4-phi-ablacao` | `phi` infalseável | 2 |
| `p1-fig5-replicacao-50-seeds` | 50 seeds, zero violações | 2, 6 |
| `p2-fig1-bem-posicional` | população máxima em h=1; o fundo desloca o raso | 3 |
| `p2-fig2-torneio-heatmap` | torneio 12×12 do horizonte | 3 |
| `p2-fig3-inversao-escada` | em δ=0,95 a escada inverte | 3 |
| `p2-fig4-dose-resposta-colheita` | o planejador fundo colhe pior | 3 |
| `p2-fig5-imposto` | o imposto pigouviano sobre pensar | 3 |
| `p2-fig6-bimodalidade` | o ponto de ramificação vira polimorfismo | 3, 7 |

### 1.2 Takes da simulação ao vivo

```sh
gcc -std=c11 -Wall -Wextra -O2 -o matrix main.c
./matrix                      # seed padrão 20260628, infinito, 80 ms/tick, visão de deus
./matrix 7 0 80               # seed 7 (a seed "canônica" das notas)
./matrix 7 0 80 0             # 4º argumento = foco: já entra em 1ª pessoa no bloco 0
./matrix 7 0 200              # mais lento, bom para narração por cima
```

Teclas: `p`/`TAB` alterna para primeira pessoa (a "pílula vermelha", a vista de
dentro), `,` `.` trocam de bloco, `espaço` pausa, `q` sai. Precisa de terminal
real com ≥70 colunas. Para gravar, use asciinema ou captura de tela com fonte
grande. Por ser determinístico, **o take é refazível**: mesma seed, mesmo filme.
Esse fato é um ponto narrativo por si (ver vídeo 1, bloco 4).

---

## 2. A história do projeto (espinha da série)

Números gerais: **131 commits** entre 2026-06-28 e 2026-08-15 (13 em junho, 93
em julho, 25 em agosto). `main.c` tem 1 855 linhas, um arquivo, só libc, sem
`<math.h>`. São cerca de **136 mil palavras** de prosa: **38 notas**, **2
papers**, **2 preprints em inglês**, filosofia em três versões.

### Ato 1: a escada (junho; `FILOSOFIA.md`)
Blocos-agentes sobem uma **escada de senciência** com sete níveis: reatividade,
memória, valência, modelo de mundo, agência, auto-modelo e
aprendizado/seleção natural. No primeiro dia (2026-06-28) eles sobem do nível 2
ao 4. A pergunta da v1: *o bloco é consciente?*

### Ato 2: quebrar a régua (notas 01–11; `FILOSOFIA_v2.md`; Paper 1)
A pergunta muda para *até onde a palavra estica?* Para responder, constrói-se a
**bateria de desbotamento**, um conjunto de mostradores em [0,1]. Depois se
tenta quebrá-la, e os quatro mostradores originais falham, cada um de um jeito.
No meio disso aparece o self que já estava no código (nota 09).

### Ato 3: cognição como bem posicional (notas 12–28; Paper 2)
Pensar fundo é bom para o indivíduo e ruim para o grupo. O desconto do futuro
age como antídoto contra a "alucinação" do próprio plano. A nota 16 derruba a 14.

### Ato 4: quem calibra o calibrador (notas 24–38; `FILOSOFIA_v3.md` §7)
Detectores que observam a própria população, o arrependimento como traço, o
classificador com bug pego antes de publicar, o nulo que o desenho fabrica e,
no fim, a régua pareada dando **30/30** fora da amostra.

---

## 3. Os vídeos

Formato sugerido: vídeo longo (12–20 min) para 1, 2, 3 e 6; curto (5–8 min, ou
Short/Reel cortado) para 4, 5 e 7. A ordem recomendada de lançamento é
**1 → 3 → 2 → 4 → 5 → 6**, com o 7 como peça avulsa. O 1 funciona como piloto
e trailer da série, o 3 tem o tema mais compartilhável e o 6 fecha a série.

---

### Vídeo 1: "Construí uma Matrix de 56 KB e tentei medir se os bloquinhos sentem"

**Papel:** piloto da série, o arco completo.
**Duração:** 12–15 min.
**Fontes:** `FILOSOFIA.md`, `FILOSOFIA_v2.md`, `FILOSOFIA_v3.md` §0, §1, §6; `README.md`.

**Gancho (0:00–0:30).** Chuva da Matrix, depois corte para a simulação ASCII.
"Esse mundo inteiro cabe em um arquivo de C. Os bloquinhos comem, planejam,
herdam traços dos pais e evoluem. Eu queria saber se algum deles *sente*
alguma coisa. A resposta que eu encontrei não era sobre eles."

**Blocos**
1. **O mundo.** Mundo procedural `f(seed, x, y)`, manchas de comida, percepção
   estritamente local (3×3). Nenhum bloco lê estado global; o comportamento
   global *emerge*. Take: visão de deus.
2. **A escada.** Os sete níveis, um por vez, com o commit de cada degrau
   (`git log --reverse`). Take: primeira pessoa (`p`), a "pílula vermelha".
3. **A pergunta trocada.** De "é consciente?" (v1) para "até onde a palavra
   estica?" (v2). Apresentar a bateria de desbotamento: a ideia de **apagar uma
   faculdade e ver se o comportamento muda** (ablação).
4. **O determinismo.** Mesma seed, universo bit a bit idêntico. Mostrar dois
   terminais lado a lado rodando a mesma seed. Gancho filosófico: a "assimetria
   do determinismo" (`FILOSOFIA_v2.md` §6) e o "como sei que não sou um
   bloco?" (§2).
5. **O que aconteceu quando eu tentei quebrar a régua.** Trailer dos vídeos 2 e
   3: as réguas mentiam, e pensar demais é uma corrida armamentista.
6. **A escolha.** Função × experiência (`FILOSOFIA_v3.md` §6). O projeto mede o
   que uma faculdade *faz*, não como é *tê-la*. É aqui que a programação encosta
   no seu limite (`FILOSOFIA.md` §7).

**Fecho.** "Na próxima: como quatro réguas da mente mentiram para mim, cada uma
de um jeito diferente."

---

### Vídeo 2: "Quatro modos de uma régua mentir"

**Papel:** metrologia; o mais didático sobre ciência em geral.
**Duração:** 12–18 min.
**Fontes:** `papers/paper-1-quatro-reguas.md`; notas 01, 03, 04, 05, 10, 11.
**Figuras:** `p1-fig1` a `p1-fig5`.

**Gancho.** "Eu construí seis medidores de mente. Depois tentei quebrá-los. Os
quatro primeiros quebraram, cada um de um jeito diferente, e nenhuma das falhas
era visível sem tentar quebrar." (frase do resumo do Paper 1)

**Blocos, um por modo de erro.** Cada um segue a mesma estrutura: o que a régua
prometia, o teste que a derrubou, o mecanismo e o conserto.

1. **A régua que aplaudia a extinção** (nota 01). `modelo` dava nota **1,000** a
   um agente *sem* modelo de mundo, marchando para a extinção. Moral: *um mapa
   que não pode errar não é um mapa*, e a marca da representação é a
   possibilidade da desrepresentação. `p1-fig1`.
2. **A âncora que andava junto** (nota 03). A âncora da `agencia` coevoluía com o
   objeto medido. Reviravolta: depois do conserto a agência *continuou* caindo,
   e isso não era defeito de régua. O reflexo é fixado pela seleção *contra* o
   agente. `p1-fig2`.
3. **O nome que mentia** (nota 04). O `automodelo` era observação lida de graça,
   não intervenção, e media o **outro**: dava zero para um bloco sozinho. Foi
   renomeado para `modelo_do_outro`. Daí o **teste do eremita**: se uma métrica
   por-agente zera na solidão, ela mediu uma relação, não uma posse. `p1-fig3`.
4. **A régua infalseável** (nota 05). Nenhuma ablação zerava o `phi`. Ele foi
   redefinido, e a evolução **extingue a integração**. `p1-fig4`.
5. **Bônus: o quinto modo, a aritmética** (nota 10). `float32` tem um piso, e ele
   caiu exatamente sobre uma condição de falseamento. A conta em `double` mostra
   o mecanismo: float32 não inverte ordens, **cria empates**.
6. **A prova.** 50 seeds por condição, **zero violações em 500 corridas** (nota
   11). `p1-fig5`.

**Fecho.** Os dois resultados que não são sobre a simulação: (1) métricas de
calibração podem ser satisfeitas lendo o ambiente em vez da mente do agente;
(2) o teste do eremita como protocolo geral. Ponte para quem mede LLMs,
animais e pacientes, sem prometer além do que o paper diz.

---

### Vídeo 3: "Pensar demais é um bem posicional"

**Papel:** o tema com mais alcance fora do nicho.
**Duração:** 15–20 min.
**Fontes:** `papers/paper-2-bem-posicional.md`; notas 14, 15, 16, 17, 19, 20, 21, 23.
**Figuras:** `p2-fig1` a `p2-fig6`; `replay-bimodal.gif`.

**Gancho.** "Dei aos bloquinhos a capacidade de planejar `h` passos à frente e
deixei a evolução escolher quanto. Eles escolheram pensar o máximo possível, e
isso deixou todo mundo mais pobre."

**Blocos (três camadas, e cada uma derrubou a anterior: estrutura do resumo do Paper 2)**
1. **Corrida armamentista.** A população de equilíbrio é máxima em `h = 1` e cai
   com a profundidade, mas num ensaio de invasão o planejador fundo **desloca**
   o raso. É a Rainha Vermelha. `p2-fig1`. Torneio 12×12 em que o mais fundo
   vence (nota 14). `p2-fig2`.
2. **O horizonte não produz nada.** Numa população de tipo único, sem rival, com
   `h = 12` sobram +20 de comida em pé contra `h = 1` (`t = +12,5`). Tudo o que o
   plano compra é tomado de um vizinho. `p2-fig4`.
3. **A reviravolta: o desconto é um regularizador** (notas 16 e 17). A nota 14
   dizia que o ESS era o teto, mas era artefato do δ=0,80. Em δ=0,95 a escada
   **inverte** (h=9 vence h=12). A cauda do plano é alucinação, e `δᵏ` decide
   quanto peso ela recebe. Com tipo único em δ=0,95, `h = 12` sustenta 5,5
   blocos a menos que `h = 8` (`t = −4,3`), sem ninguém para tomar a comida.
   `p2-fig3`.
4. **O resultado mais contraintuitivo:** *mais paciência ⇒ horizonte ótimo mais
   raso* (nota 19). Quanto mais peso se dá ao futuro distante, menos longe se
   pode olhar sem ser envenenado pela própria previsão.
5. **O plano é um passo com uma cauda que nunca é vivida** (nota 18). A
   previsão morre no primeiro replanejamento (`k* = 0`, 8/8 seeds), mas o plano
   ainda **ordena** bem as opções (nota 22).
6. **Política pública de brinquedo** (notas 15 e 21). Um imposto pigouviano
   sobre a profundidade alinha o indivíduo ao ótimo do grupo, e o alinhamento
   sobrevive mesmo quando o imposto é devolvido como dividendo. `p2-fig5`.
7. **Epílogo: o ótimo é um ponto de ramificação** (notas 20, 23, 28). A
   população se divide em linhagens rasas e fundas. `replay-bimodal.gif`,
   `p2-fig6`. Honestidade: em δ=0,80 a resposta é mista (6/8 carga de
   mutação, 2/8 polimorfismo real; nota 28).

**Fecho.** "O horizonte é um bem posicional onde o desconto o protege. Acima
disso não é um bem caro, é um erro, e a seleção o corrige." Paralelos com a
corrida por modelos maiores ficam como *pergunta*, não como conclusão.

---

### Vídeo 4: "O self já estava no código"

**Papel:** curto e viral, uma linha de C.
**Duração:** 5–8 min (cortável em Short de 60 s).
**Fontes:** nota 09; nota 11 (replicação); nota 13 (fatorial).

**Gancho.** Mostrar a linha na tela:
```c
food  -= garfada;
```
"Eu fui construir um auto-modelo para os meus bloquinhos e descobri que ele já
existia, numa linha que ninguém tinha lido assim."

**Blocos**
1. A edição planejada: separar o próprio consumo do consumo dos rivais em
   `prever_valor` (pré-registrada no `ROADMAP.md` §5.0 antes de existir).
2. A descoberta. `food -= garfada` significa "a célula vai estar mais pobre
   porque **eu** vou comer". É o único ponto em que a ação futura do bloco
   realimenta a própria previsão: o self como *causa*.
3. O mostrador `autocausa` é o **único** que o eremita possui. Mas ele tem só
   ~1/5 do de um bloco acompanhado (razão 4,78 ± 0,67 em 50 seeds, nota 11). A
   bifurcação da escada vira uma *razão*, não um vencedor.
4. `horizonte = 1` zera o mostrador exatamente: o self existe no tempo.
5. O crescimento do self **é** a evolução desses traços (nota 13).

**Fecho.** "O self mais simples que eu achei é uma previsão de que eu vou mudar
o mundo."

---

### Vídeo 5: "O dedo do espectador: confabulação e Bandersnatch"

**Papel:** apelo pop (Black Mirror, cérebro dividido).
**Duração:** 8–12 min.
**Fontes:** notas 06, 07, 08; `FILOSOFIA_v3.md` §4, §5.

**Gancho.** "O que acontece quando alguém de fora mexe na decisão do bloco, e
depois pergunta a ele por que fez aquilo?"

**Blocos**
1. **O intérprete leigo** (nota 06). O mostrador `relato` foi pré-registrado
   antes do código. Há **confabulação espontânea** em ~21% das ações negadas. O
   eremita fica **mudo**: um self de um motivo só não tem o que relatar.
2. **Bandersnatch forçado** (nota 07). O espectador força a ação. A tabela de
   Gazzaniga vira uma linha por arquitetura: quem lê a ação confabula, quem lê o
   plano não percebe, o monitor detecta **sem autoria**. O dedo que não deixa
   rastro é indetectável por princípio.
3. **O sinal e a mentira** (nota 08). O relato vira sinal herdável. A
   **honestidade evolui sem multa**, e sobra ~10% de blefe. Na janela longa,
   `hon_f` = 0,898 ± 0,028 em 50 seeds de 30 000 ticks (nota 12).

**Fecho.** Gancho com o vídeo 6: a confabulação também mora em quem mede.

---

### Vídeo 6: "Como eu quase me enganei"

**Papel:** método científico honesto; fecha a série.
**Duração:** 12–18 min.
**Fontes:** notas 32–38; `ROADMAP.md` §4.5–§4.10; o protocolo de medição (as
regras listadas no fim das notas e no `CLAUDE.md`).

**Gancho.** "Depois de 2 horas e 14 minutos de simulação, meu script imprimiu
CONFIRMA. Estava errado, e eu quase publiquei."

**Blocos**
1. **O contexto.** O arrependimento como traço (nota 30): um bloco negado ganha
   um contrafactual verificável. A pergunta é se a seleção favorece arrepender-se.
2. **O efeito fundador** (nota 32). 5 de 6 corridas mostram que quem chegou
   primeiro domina. Três seeds não decidem.
3. **O bug** (nota 33). O classificador dizia T1 CONFIRMA (9/10). Conferido linha
   a linha, a fórmula de uma montagem estava invertida. Recalculado com os
   mesmos números brutos (sem rerodar, porque é determinístico), o veredito
   virou o **oposto**: 1/10, fundador puro.
4. **Uma seed do limiar** (nota 34). 20 seeds novas e pool de 20/30, a **uma**
   seed do corte pré-registrado. A direção nunca erra.
5. **O nulo que ninguém tinha medido** (nota 35). A álgebra, antes da máquina,
   mostra que o nulo intuitivo dá zero **por identidade**. O nulo certo diz que o
   desenho sozinho fabrica 30%, contra 66,7% medidos em T2.
6. **A ameaça fecha** (nota 37). A régua pareada, que estava lá desde o começo,
   dá 28/30 contra um nulo de 15/30.
7. **Fora da amostra** (nota 38). A régua pareada como primária, em 30 seeds que
   nenhuma nota tinha rodado, com potência calculada antes: **30/30**. A única
   coisa que falha é o nulo do classificador binário (30% → 53%), e isso também
   é publicado.

**Fecho.** A cultura do projeto em três frases: pré-registre antes de rodar,
meça o nulo antes de comemorar, e não reescreva a nota antiga, escreva uma
errata. As notas existem porque o conserto destrói a evidência
(`papers/notes/README.md`).

---

### Vídeo 7: replays como peça visual (sem narração ou com legenda mínima)

**Papel:** B-roll, clipe curto, teaser.
**Ativos:** `viz/replays/replay-bimodal.gif` (a população se dividindo em duas
linhagens de horizonte) e `viz/replays/replay-colapso.gif` (o detector de
colapso disparando e desligando, nota 24).
**Legenda sugerida:** uma frase por GIF, com link para o vídeo 3 (bimodal) ou 6
(colapso e eixo microscópio).
**Atenção:** os replays são corridas demonstrativas com o `main.c` atual. Os
números deles **não** reproduzem as tabelas das notas 23/24 (`viz/README.md`
explica o motivo). Não citar números a partir do GIF.

---

## 4. Frases-âncora (citáveis, com fonte)

- "Nenhuma das falhas era visível sem tentar quebrá-los." (Paper 1, resumo)
- "Um mapa que não pode errar não é um mapa." (Paper 1, resumo)
- "Se ela zerar, ela mediu uma relação, não uma posse." (Paper 1, teste do eremita)
- "O horizonte não produz nada. Tudo o que ele compra é tomado de um vizinho." (Paper 2, resumo)
- "Mais paciência ⇒ horizonte ótimo mais raso." (Paper 2, resumo)
- "A célula vai estar mais pobre no próximo tick porque **eu** vou ter comido dela." (nota 09)
- "O plano é um passo com uma cauda que nunca é vivida." (nota 18)

---

## 5. O que fica de fora (ou precisa de cuidado)

- **Não afirmar consciência**, nem em tom de brincadeira na thumbnail sem
  desmentir no vídeo.
- **Números do Paper 1 §4–§7** vêm de 3 seeds de versões antigas do `main.c` e
  não se reproduzem com o código de hoje sem o commit certo (`viz/README.md`).
  Citar como "na época, com 3 seeds", e citar a replicação de 50 seeds (nota 11)
  como o número robusto.
- **Trabalho em aberto** (não vender como resultado): pré-registro de T3, "por que
  −2,0 vence", v4 da filosofia (desenhada no `ROADMAP.md` Fase 6, sem rodar).
- **Venue dos preprints** ainda não foi decidido: dizer "preprint", não
  "publicado".
