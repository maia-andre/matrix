# Nota 29 — A escuta como traço: instalada, sem custo, e a deriva é mesmo neutra

**Data:** 2026-07-27
**Pré-registro:** `ROADMAP.md` §4.2, commit `4df4da4` — **antes** de rodar.
**Construído em:** `9b609ed` (o traço + a nota).
**Serve ao:** `FILOSOFIA_v3.md` §5 (fecha metade do `⛔` interno: a arquitetura
instalada, o custo ainda em aberto); Paper 1 (metrologia — o `relato` ganha
uma segunda dimensão).
**Reproduzir:** `sh papers/notes/29-escuta-evolutiva.sh` (~13 min)

---

## Resumo

A nota 07 mediu três arquiteturas de introspecção (ler a ação, ler o plano,
monitorar os dois) como um patch do observador — nunca instaladas em bloco
nenhum. Esta nota dá o primeiro passo do "passo evolutivo" que a própria
nota 07 deixou em aberto: `escuta` vira campo do `Bloco`, nível 6, herdado
com mutação — mas **sem nenhum custo ligado ao jogo**, de propósito (a
metade fácil e barata de confirmar antes de desenhar a metade difícil). As
quatro predições (P1–P4) confirmaram, incluindo um achado que o
pré-registro não antecipava na direção certa: `ESC_MONITOR` tira kappa
**mais alto** que `ESC_ACAO`, não mais baixo.

## 1. O mecanismo instalado

`relato_prepara()` já fotografava, antes de `resolver()`, os argmax leigos
usados tanto pela verdade da decisão quanto pelo relato. Passou a
fotografar também o próprio alvo cognitivo (`plano_x`/`plano_y`) — a posição
que se perdia quando `resolver()` sobrescrevia `alvo_*` dos negados. Com
isso, `relato_le(i)` (nova função) lê uma de três formas, segundo
`blocos[i].escuta`:

- **ESC_ACAO** — classifica a posição final (pós-`resolver()`). A leitura
  única de sempre, agora com nome.
- **ESC_PLANO** — classifica o alvo cognitivo (pré-`resolver()`). Imune à
  negação, do jeito que a nota 07 descreveu a arquitetura B.
- **ESC_MONITOR** — compara ação × plano; coincidem → mesma leitura de
  `ESC_ACAO`; divergem → `REL_NAOSEI`. Sem canal para nomear um motivo que
  só existe por causa da própria negação — a limitação da arquitetura C.

`escuta` não é lido em lugar nenhum além de `medir_relato()`: não alimenta
`utilidade()`, `pretendentes_em()` nem decisão alguma. É observação pura,
de propósito.

## 2. O placar do pré-registro

| pred. | resultado |
|---|---|
| **P1** instalação inócua (RNG preservado) | ✅ bit-a-bit, 17 colunas, 3 seeds |
| **P2** compatibilidade retroativa (traço removido) | ✅ bit-a-bit, 21 colunas, 3 seeds, contra `4df4da4` |
| **P3** ordem do kappa, populações homogêneas | ✅ **e mais** — ver §3 |
| **P4** deriva neutra (tercos + mutação, 30 000 ticks) | ✅ sem vencedor consistente |

**P1/P2 — a instalação não toca o mundo.** A comparação certa não é "traço
livre × traço ausente" (esses *devem* diferir: variar `escuta` livremente
consome `rng01()` a mais na semeadura e na mutação, o que desloca todo o
resto do fluxo do RNG — reprodução, tudo). A comparação certa preserva o
fluxo: um patch que ainda **consome** o mesmo `rng01()` mas descarta o
valor, fixando toda a população em `ESC_ACAO`. Contra a versão livre: as 17
colunas fora de `relato`/`esc_plano_f`/`esc_monitor_f` saem bit-a-bit
idênticas nas três seeds (P1). E removendo o traço por completo — sem
consumir RNG nenhum — as 21 colunas antigas batem exatas com o `main.c`
canônico do commit do pré-registro (P2). As duas juntas fecham o mesmo
argumento que a nota 08 usou para o S1 do sinal de intenção, só que mais
forte: lá "todos honestos" tinha que reproduzir a telepatia; aqui **qualquer
mistura** de arquiteturas tem que deixar o mundo intocado, porque nada no
tick lê `escuta`.

**P4 — a deriva é mesmo neutra.** Semeando em terços com mutação, 30 000
ticks, três seeds:

| seed | `esc_plano_f` (0→fim) | `esc_monitor_f` (0→fim) |
|---|---|---|
| 7 | 0,300 → 0,397 | 0,417 → 0,494 |
| 42 | 0,250 → 0,350 | 0,467 → 0,422 |
| 1234 | 0,250 → 0,616 | 0,367 → 0,205 |

Nenhuma direção comum: a seed 1234 quase dobra `esc_plano_f` enquanto
`esc_monitor_f` cai à metade; a seed 42 faz o oposto em menor escala; a
seed 7 sobe as duas moderadamente (às custas de `ESC_ACAO`, que não tem
coluna própria — é o resto). Contraste direto com `hon_f` na nota 08, que
convergiu para perto de 1 nas três seeds testadas: ali havia seleção
direcional real (o custo endógeno do blefe); aqui não há nenhuma, e os
dados **parecem** exatamente isso — passeios aleatórios de amostragem
finita, não convergência. O pré-registro declarou que uma direção comum
entre as três seeds derrubaria P1, não só P4; não houve.

## 3. P3 — a ordem certa, por um motivo que o pré-registro não previu

Média do `relato` (kappa), populações homogêneas, tick > 500:

| arquitetura | seed 7 | seed 42 | seed 1234 |
|---|---|---|---|
| `ESC_ACAO` | 0,627 | 0,623 | 0,627 |
| `ESC_PLANO` | 0,678 | 0,690 | 0,692 |
| `ESC_MONITOR` | 0,643 | 0,641 | 0,644 |

`ESC_PLANO ≥ ESC_ACAO` confirmou, como previsto — imunidade à negação de
`resolver()` compensa, mesmo com a maioria dos ticks sendo "livre" (ação =
plano), onde as três leituras coincidem trivialmente. Mas o pré-registro
também apostou que `ESC_MONITOR` ficaria **abaixo** de `ESC_PLANO` "nos
negados", tratando `NAOSEI` como uma admissão, não um acerto. Os dados
confirmam essa parte (0,64 < 0,68–0,69) — só que `ESC_MONITOR` também ficou
**acima** de `ESC_ACAO` (0,64 > 0,63), o que o pré-registro não comprometeu
em nenhuma direção.

A explicação é a própria construção do kappa: `rel_verdade` inclui
`REL_NAOSEI` como categoria legítima (o plano do bloco não bate com nenhum
argmax leigo — a decisão do planejador fundo, idiossincrática). Nesses
casos, `ESC_ACAO` tenta nomear um motivo pela posição final e frequentemente
erra por coincidência geométrica — a mesma confabulação que a nota 07 mediu
para a arquitetura A. `ESC_MONITOR` só cai em `NAOSEI` quando **detecta**
uma negação — nos ticks livres (a maioria, e onde a maior parte da massa de
`NAOSEI` verdadeiro mora, por não envolver disputa) ele lê exatamente como
`ESC_ACAO`. Admitir "não sei" **acerta** contra uma verdade que também é
"não sei" com mais frequência do que confabular um motivo positivo erra
menos — o kappa recompensa a honestidade sobre a própria ignorância mais do
que pune a admissão em si.

## Ameaças à validade

- **3 seeds**, como sempre — mas as três concordam no sinal de P1–P3 a duas
  casas, e a ausência de direção comum em P4 é justamente o que se mede com
  poucas seeds discordando entre si.
- **P4 não prova ausência de seleção fraca** — só que, se existe, é fraca
  demais para dominar a deriva em 30 000 ticks e ~300 blocos. Um efeito de
  primeira ordem (como o de `hon_f`) foi excluído; um de segunda ordem, não.
  Está declarado explicitamente no pré-registro (Q4/§4.2): "se as três
  seeds também convergirem na mesma direção, é sinal de um efeito que este
  desenho não devia ter" — não convergiram.
- **O achado do §3 é post-hoc**, não pré-registrado na direção certa — está
  marcado como tal, não maquiado de acerto total.

## O que ficou em aberto

O mecanismo de custo — ligar `escuta` a alguma consequência real, para que
"leitores que punem incoerência" (a predição da nota 07) tenha o que testar
— continua fora desta nota, por escolha explícita do pré-registro (§4.2).
Candidato natural: a **memória de sinais (reputação)**, o outro fio que a
nota 08 deixou aberto — um vizinho com `ESC_MONITOR` que flagra outro bloco
incoerente poderia parar de se deixar repelir pelo sinal *daquele* bloco.
Precisa de memória por vizinho, que ainda não existe no código.
