# Nota 12 — A janela longa: 30 000 ticks × 50 seeds, e o motor do self era outro

**Data:** 2026-07-14
**`main.c`:** o de `079a3ce` (canônico intocado; variantes são patches temporários)
**Serve ao:** Paper 1 (metrologia — fecha a última janela não replicada) e à
`FILOSOFIA_v3.md` §2/§3. Agregados em `datasets/janela30k.csv`.
**Reproduzir:** `sh papers/notes/12-janela-longa.sh` (~35 min com `NPROC=12`;
~6 h de CPU)

---

## Resumo

A nota 11 replicou tudo em 3000 ticks e declarou a janela longa como ameaça: os
números de 30 000 ticks (o `hon_f` da nota 08, o traço congelado da nota 05, o
desbotamento da nota 03) seguiam com 3 seeds. Este lote fecha a ponta: **3
variantes (ctl, `fesp` = congela `peso_espaco`, `fdep` = congela
horizonte+desconto) × 50 seeds × 30 000 ticks.**

| alegação (3 seeds) | em 50 seeds | veredito |
|---|---|---|
| L1 (nota 08 S6): `hon_f` final 0,83–0,90, sem fixar | **0,898 ± 0,028** [0,83..0,94]; domina 50/50, fixa 0/50 | ✅ em cheio |
| L2 (nota 05): `fesp` segura a phi; ctl/`fdep` não | cai em 50/50 (ctl), 50/50 (`fdep`), **0/50 (`fesp`)** | ✅ sem uma exceção |
| L3 (nota 03): a agência desbota; o traço vai a ~0 | 0,464 → **0,052 ± 0,008** em 50/50; `esp_m` → 0,095 | ✅ e mais fundo que o intervalo da nota 01 |
| L4 (nota 05): corr(phi, profundidade) é artefato de janela | ctl: 0,964 (30k) × 0,528 (3k), 50/50 — e **`fesp` inverte**: 0,237 × 0,557, 0/50 | ✅ e ganhou um controle por intervenção |
| L5 (exploração declarada): o destino da `autocausa` | sobe até 30k em **150/150 corridas** — e sobe **mais com o horizonte pregado** | ⚠️ sobe, mas o **motor não era o horizonte** — errata de mecanismo na nota 09 P4 |

## 1. L1 — a nota 08 estava certa no horizonte certo

`hon_f` ao fim de 30 000 ticks: **0,898 ± 0,028** [0,829..0,942]; blefe
0,079 ± 0,029; a honestidade **domina em 50/50 e não fixa em nenhuma** (> 0,99
em 0/50). Os 0,83/0,90/0,88 da nota 08 eram amostras típicas, não sorte.

Isso fecha o arco aberto na nota 11 §5: lá, `hon_f` leu 0,76 ± 0,05 — mas aos
3000 ticks, e a comparação com a nota 08 foi registrada como inválida por
horizonte errado. No horizonte certo, o número da nota 08 replica em cheio. A
lição operacional (confira o horizonte antes de comparar) fica; a suspeita
sobre o número, morre.

## 2. L2/L3 — o traço congelado, sem uma exceção em 150 corridas

| variante | `phi` ini → fim | cai em | `agencia` ini → fim | `esp_m` fim |
|---|---|---|---|---|
| ctl | 0,0547 → **0,0083 ± 0,0016** | 50/50 | 0,464 → **0,052 ± 0,008** | 0,095 ± 0,018 |
| `fdep` | 0,0562 → 0,0177 ± 0,0032 | 50/50 | 0,473 → 0,093 ± 0,016 | 0,231 ± 0,055 |
| `fesp` | 0,0520 → **0,0664 ± 0,0035** | **0/50** | 0,484 → 0,472 ± 0,011 | 3,0 (pregado) |

Congelar a profundidade não salva nada; congelar `peso_espaco` salva **tudo** —
a phi até *sobe* de leve. Quem carrega a integração e a agência é o mesmo traço,
em 150 de 150 corridas. E o traço, solto, não para em "0,5–1,5" (o intervalo da
nota 01 §3, medido na era do teto de nascimentos): com a reprodução consertada,
30 000 ticks levam `esp_m` a **0,095 ± 0,018**. O "→ 0" da nota 03 era literal.

## 3. L4 — o artefato de janela ganha um controle por intervenção

No ctl, corr(phi, profundidade efetiva) = **+0,964** na janela de 30 000 e
**+0,528** nos primeiros 3000 dos *mesmos dados* — maior na janela longa em
50/50 seeds. Até aqui, é a nota 05 fase 3 com barras: co-tendência.

O novo é o `fesp`: com o traço congelado, a correlação **desce** com a janela
(0,557 → 0,237, em 50/50). Se a correlação alta do ctl fosse acoplamento
phi↔profundidade, congelar um *terceiro* traço não a destruiria. Destruiu. As
duas séries só sobem juntas porque a **mesma seleção** move as duas — retire o
motor (a evolução de `peso_espaco`) e a "correlação" não sobrevive à própria
janela que a criava. Co-tendência, agora demonstrada por intervenção, não só
por particionamento.

## 4. L5 — a autocausa sobe até 30 000… e o motor não era o horizonte

A exploração declarada no script ("satura, segue ou reverte?"): **segue**. Em
150/150 corridas, a `autocausa` termina acima de onde começou.

| variante | `autocausa` ini → fim | `hor_m` ini → fim |
|---|---|---|
| ctl | 0,093 → 0,204 ± 0,007 | 7,0 → 7,6 ± 2,8 |
| `fesp` (motivo pregado em 3,0) | 0,088 → **0,148** ± 0,011 | 7,0 → **9,7** ± 0,6 |
| `fdep` (**horizonte pregado em 6,00**) | 0,100 → **0,226** ± 0,007 | 6,0 → 6,0 exato |

A nota 09 P4 atribuiu o crescimento ao horizonte ("o que o sustenta é o
horizonte, e o horizonte sobe"). A tabela desmente a atribuição duas vezes:
com o horizonte **pregado**, a autocausa sobe **mais que em qualquer variante**
(`fdep`); com o horizonte **subindo mais que nunca** mas o motivo pregado
largo, sobe **menos** (`fesp`). O motor dominante do crescimento é o
**estreitamento do motivo** — o mesmo `peso_espaco → 0` que mata a agência
concentra a decisão no termo da comida, que é exatamente onde o σ morde.

Separe as duas coisas que a nota 09 juntou: a dependência **estrutural** do
horizonte fica intacta (`horizonte = 1` zera a autocausa — P2, replicada na
nota 11; sem futuro não há self). Mas o **crescimento** sob seleção não é o
futuro alargando: é o motivo estreitando. O achado-manchete da nota 09 ("a
mesma seleção que apaga a agência constrói o self") sai *mais* forte, não
menos: não são dois processos paralelos — é **um** processo. O colapso de
`peso_espaco` apaga a agência e constrói o self **no mesmo movimento**, porque
agência (aqui) é sensibilidade ao segundo motivo e self (aqui) é presença no
primeiro. Errata de mecanismo registrada na nota 09 §4.

## Ameaças à validade

- **Janelas fixas** (início 20–300, fim 29700–30000); não variadas.
- A corr do `fdep` é **degenerada** (profundidade efetiva constante ⇒ variância
  zero) e foi reportada como 0 por convenção do script — não entra em L4.
- L5 era exploração declarada, não predição: a decomposição de motores
  (fesp/fdep) foi lida *depois* dos dados. O desenho fatorial que a confirmaria
  de frente (congelar os dois; varrer o congelamento) fica em aberto.
- A soma dos "motores" não fecha aditivamente (ctl +0,111 < fdep +0,126) — há
  interação que este lote não decompõe.

## O que ficou em aberto

1. ~~O **fatorial** de L5: pregar motivo *e* horizonte juntos; a predição da
   explicação por estreitamento é autocausa subindo pouco ou nada.~~ ✅ **feito
   (nota 13)**: `fambos` dá Δac +0,022 ± 0,009 (F1 confirmada, 0/50 acima do bar
   do terceiro motor). E a não-aditividade desta nota ganhou número: interação
   = −0,053, do tamanho dos efeitos principais. Ver
   [`13-o-fatorial.md`](./13-o-fatorial.md).
2. O torneio 12×12 e a dose-resposta `h*(c)` (Paper 2) — intocados.
3. Varredura de densidade; edição honesta da partilha (pré-registro §5.0).
