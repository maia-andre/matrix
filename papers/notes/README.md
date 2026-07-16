# notes/ — notas curtas, uma descoberta cada

Um paper é uma **síntese**. Uma nota é o **registro** de um achado, escrito
enquanto o código que o produziu ainda existe.

## Por que notas, e por que agora

O argumento não é de organização, é de **preservação de evidência**. A nota 01
nasceu no mesmo dia em que o mostrador `modelo` foi consertado — e o conserto
**destruiu a evidência**: o `main.c` mudou, o `datasets/seed7.csv` foi
regenerado, e o famoso `modelo = 1,000` para um bloco sem modelo de mundo deixou
de ser reproduzível a partir do estado atual do repositório. Sem a nota (e sem o
script que a acompanha), o achado sobreviveria só como anedota.

Daí as três regras:

1. **Uma descoberta por nota**, como é um degrau por commit.
2. **Toda nota é reproduzível.** Cada uma vem com um script que regenera seus
   números a partir do `main.c` — inclusive de uma *versão passada* dele, via
   `git show <commit>:main.c`. Nada de `experiment_001.c`: há **um `main.c`
   canônico** e as ablações são patches aplicados a uma cópia temporária (ver
   [`ROADMAP.md`](../../ROADMAP.md), seção "Engenharia").
3. **Toda nota diz a qual paper ela serve.** Notas que não sobem para lugar
   nenhum viram diário.

## O que uma nota pode ter e um paper não

**Hipóteses mortas.** Papers lavam a cronologia: apresentam a conclusão como se
ela tivesse sido óbvia. A nota registra que três explicações sucessivas para o
horizonte de planejamento foram falsificadas antes da quarta se sustentar. Num
projeto cuja tese é sobre o que uma medida *carrega*, hipótese morta é dado.

## Formato

Cabeçalho com **data**, **commit do `main.c`** a que os números se referem, e
**como reproduzir**. Depois: resumo, aparato, resultados, ameaças à validade, o
que ficou em aberto. Curto. Se passar de duas páginas, provavelmente são duas
notas.

## Índice

| nota | achado | serve ao paper |
|---|---|---|
| [01](./01-quatro-modos-de-errar.md) | os quatro mostradores da bateria falham de quatro maneiras independentes; `modelo` consertado | 1 — metrologia da mente |
| [02](./02-o-teto-de-nascimentos.md) | um teto de nascimentos congelava a evolução; havia uma regra de senioridade implícita; `hor_m` não é identificável sozinho | 2 — bem posicional (+ erratas do 1) |
| [03](./03-a-evolucao-extingue-a-agencia.md) | `agencia` consertada (varredura do domínio, não dois pontos); a queda dela não era defeito de régua — o **reflexo fixa contra o agente** | 1 — metrologia (+ `FILOSOFIA_v3`) |
| [04](./04-o-automodelo-era-um-modelo-do-outro.md) | `automodelo` era observação, não intervenção; escalava com `ANTECIPACAO`; e media o **outro** (zero para um eremita). Vira `modelo_do_outro`, intervenção ancorada | 1 — metrologia da mente |
| [05](./05-phi-media-o-segundo-motivo.md) | `phi` era **infalseável** (nenhuma ablação a zerava) e a suspeita "= profundidade" era artefato de janela; media o **segundo motivo**. Redefinida: menor distância aos módulos isolados; **a evolução extingue a integração** | 1 — metrologia (+ `FILOSOFIA_v3` §2) |
| [06](./06-o-interprete-leigo.md) | `relato` entregue com **pré-registro antes do código**; κ do intérprete leigo ≈ 0,67; **confabulação selvagem** em ~21% das ações negadas; P5 falhou — o eremita fica **mudo** (self de um motivo só não tem o que relatar) | 1 — metrologia (+ `FILOSOFIA_v3` §2 e §5) |
| [07](./07-o-dedo-do-espectador.md) | Bandersnatch forçado: a tabela de Gazzaniga vira **uma linha por arquitetura** (lê-ação confabula, lê-plano não percebe, monitor detecta **sem autoria**); dose-resposta do κ; o dedo sem rastro é **indetectável por princípio** | 1 — metrologia (+ `FILOSOFIA_v3` §4 e §5) |
| [08](./08-o-sinal-e-a-mentira.md) | o `relato` vira **causal**: sinal no lugar da telepatia do nv5, estratégia herdável; a **honestidade evolui** (ESS sem multa), sobra ~10% de blefe (polimorfismo); silêncio = eremita epistêmico. S2/S6 erraram a direção — achados | 1 — metrologia (+ Paper 3 futuro; `FILOSOFIA_v3` §3) |

| [09](./09-o-self-ja-estava-la.md) | o auto-modelo **já estava no código** (`food -= garfada`: "a célula empobrece porque EU vou comer"). `autocausa` é o **único mostrador que o eremita possui** — mas ele tem só **1/5** do de um bloco acompanhado: a bifurcação da escada vira uma **razão**, não um vencedor. `horizonte=1` o zera exato (**o self exige um futuro**); e a mesma seleção que **apaga a agência constrói o self**. Errata: a `agencia` do eremita não era "0 exato" — tinha um **piso de arredondamento** em float32 | 1 — metrologia (+ `FILOSOFIA_v3` §2, §3 e Apêndice A) |
| [10](./10-o-zero-estrutural.md) | a dívida da nota 09 §5 quitada: `modelo`, `phi` e `relato` recomputados em `double` — **os três zeros são zeros nas duas precisões**, a nove casas, no máximo e fora do clamp. E o piso ganha mecanismo: **float32 não inverte ordens, cria empates** — só vaza a sonda que conta trocas de argmax sob desempate (`agencia`); zeros por identidade, monotonia ou quociente igual são **estruturais**. Regra de desenho para mostradores futuros | 1 — metrologia (+ Apêndice A da `FILOSOFIA_v3`) |
| [11](./11-a-replicacao.md) | **50 seeds para tudo que foi afirmado com 3**: os dez zeros do Apêndice A com **0 violações em 500 corridas**; `autocausa` sobe × `agencia` cai em **50/50**; razão do eremita 4,78 ± 0,67; eremita mudo 0,0046 ± 0,0005. O piso fora do eremita fecha: 1,4·10⁻⁷, sem direção — é fenômeno do regime eremita. Moveu: extinção pv0 51–121 (errata na 01); `modelo_do_outro` recalibra a 0,27 ± 0,05 (efeito da nota 08); e um erro do próprio pré-registro fica registrado (comparei `hon_f` de 3000 ticks com número de 30 000). Agregados em `datasets/replicacao50.csv` | 1 — metrologia (a tabela média ± dispersão) |
| [12](./12-a-janela-longa.md) | **a janela longa, 30 000 × 50**: `hon_f` = 0,898 ± 0,028 (a nota 08 estava certa no horizonte certo); o traço congelado sem uma exceção em 150 corridas (`fesp` segura phi e agência; ctl/`fdep` desabam); o artefato de janela ganha **controle por intervenção** (congelar o traço faz a corr *cair* com a janela). E a errata de mecanismo da nota 09 P4: com horizonte **pregado**, a `autocausa` sobe *mais* — o motor do self é o **estreitamento do motivo**, o mesmo `peso_espaco → 0` que apaga a agência. **Um processo, não dois.** Agregados em `datasets/janela30k.csv` | 1 — metrologia (+ `FILOSOFIA_v3` §2/§3) |
| [13](./13-o-fatorial.md) | **o fatorial de L5 fechado**: `fambos` (motivo *e* horizonte pregados) é a quarta célula. Com os dois motores desligados a `autocausa` quase não sobe — Δac +0,022 ± 0,009, 0/50 seeds acima do bar do "terceiro motor" (F1 ✅, F2 não disparou): o crescimento do self **é** a evolução desses traços. E a não-aditividade da nota 12 ganha número: **interação = −0,053**, do tamanho dos efeitos principais — o horizonte **inverte de sinal** conforme o motivo, é amplificador do motor, nunca motor autônomo. Agregados em `datasets/fatorial30k.csv` | 1 — metrologia (+ `FILOSOFIA_v3` §2) |

## Erratas

Notas são datadas, não sagradas. Quando um achado posterior derruba um número de
uma nota anterior, a nota antiga recebe um bloco **Errata** apontando para a nova —
o texto original **não é reescrito para parecer que sempre esteve certo**. A nota 02
corrigiu as comparações de população da nota 01; a nota 01 diz isso, em voz alta,
no lugar onde errou.
