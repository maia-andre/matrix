# Nota 08 — O sinal e a mentira: o relato deixa de ser epifenomenal

**Data:** 2026-07-10
**Pré-registro:** `ROADMAP.md` §4.0, commit `372e827` — **antes** de rodar.
**Construído em:** `bde0946` (S1, o refactor inócuo) e `c924fbd` (a estratégia como traço).
**Serve ao:** Paper 1 (metrologia) e Paper 3 futuro (evolução da comunicação); `FILOSOFIA_v3` §3 (superego).
**Reproduzir:** `sh papers/notes/08-o-sinal-e-a-mentira.sh` (~4 min)

---

## Resumo

O `relato` da v1 (nota 06) era **epifenomenal por construção**: medido, nunca
consumido. Esta nota o torna **causal** — e o faz reaproveitando um leitor que já
existia. O nível 5 sempre teve telepatia embutida: `pretendentes_em()` lia a
`intencao` dos vizinhos, acesso perfeito à mente alheia. Trocamos a telepatia por
**comunicação**: cada bloco emite um sinal sobre a própria intenção, os vizinhos
leem o sinal, e a estratégia de fala (`honesto`/`mudo`/`blefe`) é um traço
herdável. Sem nenhuma multa artificial — o sinal só *repele*, e daí a mentira
custa por conta própria — a **honestidade evolui**: fixa contra o silêncio, resiste
ao blefe, e o cheap talk que a teoria teme **não** degenera o canal. Duas das seis
predições erraram a *direção* (não o fato), e os erros são achados.

## 1. De telepatia a comunicação

O único acesso de um bloco à mente do outro era `pretendentes_em`, lendo
`intencao_*`. Isso viola o espírito do projeto por baixo do pano: o auto-modelo do
nível 5 supunha telepatia. O relato causal insere uma passagem entre `declarar` e
`decidir` — `emitir()` — onde o bloco escreve em `sinal_*` **o que escolhe contar**,
e `pretendentes_em` passa a ler o sinal. Três estratégias:

- **honesto**: `sinal = intenção`;
- **mudo**: `sinal =` própria célula (ninguém pode mirar célula ocupada → silêncio);
- **blefe**: `sinal =` o melhor alvo que **não** é a intenção.

O custo é **endógeno**, não decretado. O sinal só desvaloriza (via `ANTECIPACAO`) a
célula sinalizada para quem a vê. Logo: o **mudo** abre mão da deterrência (não
afasta ninguém do que quer); o **blefe** gasta a deterrência numa célula que não vai
tomar **e deixa o alvo verdadeiro sem proteção**. Ninguém programou "mentir é ruim";
a geometria cobra.

## 2. O placar do pré-registro

| pred. | resultado |
|---|---|
| **S1** honesto ≡ telepatia bit-a-bit | ✅ idêntico, 18 colunas, 3 seeds (commit `bde0946`) |
| **S2** o canal carrega comportamento | ✅ **no fato**, ❌ na direção — ver §3 |
| **S3** todo-mudo → `modelo_do_outro` = 0 | ✅ **0,0000** exato, 3 seeds |
| **S4** honesto fixa contra mudo | ✅ 0,50 → **0,95 / 0,97 / 0,95** |
| **S5** honesto resiste ao blefe | ✅ 0,50 → **0,81 / 0,96 / 0,87** |
| **S6** dos terços, `hon_f → ~1` | ~ domina (**0,83 / 0,90 / 0,88**), mas **não fixa** — ver §4 |

## 3. S2 — o canal carrega comportamento, mas não onde eu apostei

Pré-registrei que abrir o canal honesto daria **população maior**. Errado. Média
de 3 seeds, ticks 500–3000:

| | população | energia média |
|---|---|---|
| todo-honesto (canal aberto) | 314,5 / 284,1 / 270,5 | **5,69 / 5,71 / 5,95** |
| todo-mudo (canal fechado) | 315,4 / 286,2 / 271,9 | **6,62 / 6,53 / 6,53** |

A população fica **praticamente igual** (o mudo até marginalmente maior). O que o
canal move é a **energia**: ~15% menor com o canal aberto, robusto nas três seeds.
A leitura mecânica: coordenar não faz caber mais gente no mesmo alimento finito
(o teto é a comida, não a colisão) — faz a mesma gente viver **mais apertada**,
com menos folga energética por indivíduo. O núcleo de S2 sobrevive intacto e é o
que importa: **silêncio muda o mundo**, logo o `relato` deixou de ser
epifenomenal. Mas a métrica que sente a mudança é a energia, não a demografia — e
eu teria "confirmado" S2 na direção errada se só olhasse população.

## 4. S6 — a honestidade domina, mas não fixa: um polimorfismo

Semeando em terços com mutação, 30 000 ticks, `hon_f / blef_f` no fim:

| seed | honesto | blefe | (mudo) |
|---|---|---|---|
| 7 | 0,83 | 0,14 | 0,03 |
| 42 | 0,90 | 0,08 | 0,02 |
| 1234 | 0,88 | 0,10 | 0,02 |

O **mudo é varrido** (só a mutação o repõe): o silêncio é a pior estratégia — abre
mão da deterrência sem ganhar nada. Mas o **blefe persiste em ~10%**, estável, nas
três seeds. É frequência-dependente: num mar de honestos, um blefe raro engana
barato (os vizinhos "acreditam" no sinal), então o blefe invade quando raro; comum,
ele se auto-estraga (todos blefam, ninguém deterra, o alvo verdadeiro fica exposto).
Não é fixação da honestidade — é um **equilíbrio misto**, exatamente a assinatura de
sinalização com honestidade custosa parcial. A predição "→ 1" era ingênua; o
resultado é mais interessante e mais realista.

## 5. S3 — silêncio é cegueira, para a régua

Todo-mudo → `pret ≡ 0` em toda célula → `modelo_do_outro` = **0,0000** exato (3
seeds, média e máximo). Demonstrável antes de rodar, e verificado. A consequência é
conceitual: o mostrador que a Fase 1 chamou de "modelo do outro" não distingue
*"não percebo os outros"* (eremita, nota 04) de *"os outros não falam"* (mundo
mudo). Para a régua, **cegueira e silêncio são o mesmo estado** — a informação
social não existe nem na origem (o sinal) nem no destino (a percepção). Fecha um
arco com o eremita: o outro só está "na cabeça" de um bloco se houver um canal, e o
canal tem duas pontas.

## 6. O que S4/S5 dizem, e a ponte para a v3 (superego)

Honesto **fixa** contra mudo (S4) e **vence** o blefe (S5) — sem ninguém decretar
que mentir é errado. Isto é a matéria da v3 §3: um **superego** funcional não
precisa ser instalado como `float culpa`; ele **emerge** como a norma "sinalize a
verdade" que a seleção fixa porque a mentira, aqui, custa a quem mente. A norma
internalizada é, neste brinquedo, um traço evoluído sob pressão de teoria dos jogos
— e o ~10% de blefe residual é o crime que nenhuma sociedade de sinais custosos
elimina de todo.

## Ameaças à validade

- **O custo do blefe é geométrico, não semântico.** O blefe erra porque desprotege
  o alvo real num mundo onde o sinal repele — não porque "ser pego mentindo" tenha
  consequência reputacional (não há memória de quem mentiu). É honestidade custosa
  à la Zahavi, não punição de trapaça à la reciprocidade. Um mundo com memória de
  sinais (Fase 4+) testaria a outra rota.
- **S2 mede entre mundos** (todo-honesto × todo-mudo são populações diferentes); a
  invasão (S4/S5) mede *dentro* do mesmo mundo e é o teste de aptidão relativa.
- **`ANTECIPACAO` fixo em 0,5.** A força do canal é uma lei da física; a intensidade
  da pressão (e talvez o nível do polimorfismo) escala com ela. Varrer fica para
  quando o custo de pensar (Fase 3) já estiver no lugar.
- **3 seeds**; as invasões concordam em direção nas três, com dispersão visível no
  ritmo (seed 7 é a mais lenta a expulsar o blefe).

## O que ficou em aberto

1. **Medir o blefe residual como ESS**: varrer a frequência inicial e confirmar o
   equilíbrio misto (o ponto onde o blefe raro não invade e o comum não resiste).
2. **Memória de sinais** (reputação) como a segunda rota anti-cheap-talk, ao lado do
   custo endógeno — e ver se ela empurra `hon_f` para 1.
3. O **Bandersnatch evolutivo** (nota 07): agora que a estratégia de *fala* é traço,
   a arquitetura de *escuta* (ler a ação × ler o plano) também pode ser — e as duas
   juntas fecham a co-evolução de emissor e receptor.
