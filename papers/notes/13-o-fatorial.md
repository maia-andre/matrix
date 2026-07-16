# Nota 13 — O fatorial de L5: um motor, e uma interação que a nota 12 não fechava

**Data:** 2026-07-15
**`main.c`:** o de `079a3ce` (canônico intocado; a variante `fambos` é patch
temporário — os dois patches da nota 12 combinados, mesmas âncoras).
**Pré-registro:** cabeçalho de `papers/notes/13-fatorial.sh`, commit `c965787`
— **antes** de rodar (F1/F2/F3).
**Serve ao:** Paper 1 (metrologia — fecha a decomposição de motores da
autocausa) e à `FILOSOFIA_v3.md` §2. Agregados em `datasets/fatorial30k.csv`.
**Reproduzir:** `sh papers/notes/13-fatorial.sh` (~12 min com `NPROC=12`;
~2 h de CPU)

---

## Resumo

A nota 12 §4 mediu três células de um desenho fatorial e leu a quarta *de
relance*: com o horizonte pregado a autocausa cresce **mais** (fdep), com o
motivo pregado cresce **menos** (fesp), logo o motor do crescimento é o
**estreitamento do motivo** (`peso_espaco → 0`), não o horizonte — a errata da
nota 09 P4. Mas a nota 12 registrou duas dívidas: a decomposição foi lida
*depois* dos dados (não era predição), e "a soma dos motores não fecha
aditivamente — há interação que este lote não decompõe".

Esta nota preenche a quarta célula com predição escrita antes: `fambos`, os
dois motores pregados juntos. O placar:

| # | predição (escrita antes) | resultado |
|---|---|---|
| **F1** | com os dois motores desligados, a autocausa quase não sobe: **Δac < +0,03** | ✅ **+0,0220 ± 0,0088** [−0,001..+0,038]; 38/50 seeds < 0,03 |
| **F2** | Δac ≥ +0,06 ⇒ **existe um terceiro motor** que fesp/fdep não isolam | ✅ **não disparou** — 0/50 seeds; máximo +0,0377 |
| **F3** | sanidade: `esp_fim` = 3,0 e `hor_fim` = 6,0 exatos; a phi **não cai** | ✅ 3,0000 / 6,0000; phi 0,053 → **0,061** (sobe) |

E, de brinde, a interação que a nota 12 não conseguiu decompor **agora tem
número** — e é do tamanho dos efeitos principais. Ver §2.

## 1. F1/F2 — um motor, confirmado por construção

O desenho, agora completo (Δac = `ac_fim` − `ac_ini`, média ± sd de 50 seeds,
janelas 20–300 e 29 700–30 000):

| variante | motivo | horizonte | **Δac** |
|---|---|---|---|
| `ctl`    | livre   | livre   | **+0,1115 ± 0,0089** |
| `fdep`   | livre   | pregado (6) | **+0,1266 ± 0,0072** |
| `fesp`   | pregado (3,0) | livre | **+0,0601 ± 0,0113** |
| `fambos` | pregado (3,0) | pregado (6) | **+0,0220 ± 0,0088** |

Desligados os dois motores, o que sobra do crescimento da autocausa é **um
quinto** do controle (+0,022 contra +0,112). A predição F1 pedia < +0,03; a
média está lá, e — o que é mais forte que a média — **a distribuição inteira
está abaixo do bar do refutador**: a seed que mais subiu fez +0,0377, e F2
(+0,06, o "terceiro motor") não disparou em nenhuma das 50. O crescimento do
self sob seleção não sobrevive quando se prega o motivo e o horizonte: ele
**é** a evolução desses traços, não um processo terceiro que corre ao lado.

Isso confirma a errata da nota 09 §4 pela via mais limpa possível — não mais
por contraste indireto (fesp sobe menos, fdep sobe mais), mas por **ablação
conjunta**: retire os dois candidatos a motor e o fenômeno desaparece até o
resíduo. O achado-manchete "a mesma seleção que apaga a agência constrói o
self" fica: é **um** processo (o colapso de `peso_espaco`), com dois sinais.

**O resíduo não é zero, e a honestidade manda dizer.** +0,022 ± 0,009 está a
~2,5 sd de zero — pequeno, abaixo do bar do terceiro motor, mas real. Em
`fambos` sobram dois traços livres (`urgencia`, `estrategia`) e a estrutura
espacial da população, que segue se adensando por 30 000 ticks; a autocausa
morde mais onde a `partilha` varia de célula para célula (nota 09 §3), e essa
variação depende da densidade, que não foi pregada. O resíduo é o candidato
natural a "quarto efeito, minúsculo" — não um motor, um sedimento.

## 2. A interação que a nota 12 não fechava

A nota 12 viu que os efeitos não somavam: `ctl` +0,111 e `fdep` +0,127 dizem
que pregar o horizonte **aumenta** o crescimento (+0,015), enquanto `fesp`
+0,060 diz que pregar o motivo o **corta** (−0,051). Somados ingenuamente,
`fambos` deveria dar ~0,111 − 0,015 − 0,051 = +0,045. Deu **+0,022** — metade.
A diferença é interação, e o fatorial a mede:

| operação | com o outro fator **livre** | com o outro fator **pregado** |
|---|---|---|
| pregar o **motivo** | −0,051 (fesp − ctl) | **−0,104** (fambos − fdep) |
| pregar o **horizonte** | +0,015 (fdep − ctl) | **−0,038** (fambos − fesp) |

**Interação = −0,0525** — tão grande quanto os efeitos principais. Leia a
segunda linha: pregar o horizonte **sobe** a autocausa quando o motivo está
livre (+0,015) e a **derruba** quando o motivo está pregado (−0,038). O sinal
do efeito do horizonte **inverte** conforme o motivo. Por isso a nota 12 não
fechava aditivamente: não há dois motores independentes para somar.

A leitura mecânica: o horizonte não é um motor da autocausa **por si** — é um
amplificador do motor real. Enquanto o motivo evolui (`peso_espaco → 0`, a
decisão concentrando no termo da comida, que é onde o σ morde), um horizonte
mais fundo dá mais passos futuros para o self se descontar, e o efeito do
estreitamento aparece maior. Congele o motivo e não há o que amplificar: o
horizonte fundo vira custo sem retorno para a autocausa, e pregá-lo até ajuda
de leve (menos ruído na previsão). O horizonte é **estrutural** para a
existência do self (`horizonte = 1` zera — nota 09 P2, que segue de pé) e
**interativo** para o seu crescimento — nunca um motor autônomo.

## 3. F3 — a sanidade, e a phi de brinde

`esp_fim` = 3,0000 e `hor_fim` = 6,0000 exatos: os dois congelamentos pegaram.
E a `phi` **não cai** — sobe de 0,0531 para 0,0605, exatamente como no `fesp`
da nota 12 (L2: pregar o motivo segura a integração; aqui, com motivo *e*
profundidade pregados, ela segura igual). Confirma, de lado, que quem carrega
a phi é o `peso_espaco`, e mais nada dos três traços mexidos. `pop_fim` = 291,2,
dentro do regime normal.

## Ameaças à validade

- **`fambos` não prega tudo.** `urgencia` e `estrategia` seguem evoluindo (só
  `peso_espaco`, `horizonte` e `desconto` foram congelados — os mesmos da
  nota 12). O resíduo +0,022 pode ter contribuição de `urgencia`; um fatorial
  de 3+ fatores decidiria, e não foi rodado. A afirmação segura é a negativa
  que F2 pedia: **não há um motor do tamanho dos dois primeiros** escondido no
  resíduo.
- **A interação é de médias entre variantes**, não um termo estimado dentro de
  uma corrida; as quatro células vêm de mundos com dinâmicas populacionais
  diferentes (pregar traços muda quem sobrevive). A direção (inversão de sinal)
  é robusta às barras; a magnitude exata do −0,0525 herda a soma das
  variâncias.
- **Janelas fixas** (as mesmas da nota 12: início 20–300, fim 29 700–30 000).
- **`fambos` é 50 seeds numa variante**; as três outras células vêm do
  `datasets/janela30k.csv` (nota 12), mesmas seeds 1..50, mesmo `main.c`
  `079a3ce` — comparáveis linha a linha por construção.

## O que ficou em aberto

1. O **resíduo +0,022**: um fatorial que também pregue `urgencia` (e/ou fixe a
   densidade) diria se ele é traço ou estrutura espacial. Barato, não urgente.
2. O torneio 12×12 e a dose-resposta `h*(c)` (Paper 2) — a próxima frente.
3. Varredura de densidade; edição honesta da partilha (pré-registro §5.0).
