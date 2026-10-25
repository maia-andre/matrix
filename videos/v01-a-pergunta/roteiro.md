# Vídeo 1 — "Construí uma Matrix num arquivo de C e tentei medir se os bloquinhos sentem"

Piloto e trailer da série, com as três extensões (quatro portas, Φ, argumento da simulação).
1195 palavras de fala ≈ 8.2 min de voz. Primeira pessoa (o autor). As falas valem pelo `narracao.json`;
este arquivo é a versão para ler, com TELA e FONTE de cada bloco. Simulação = quadros capturados
(`scripts/capturar_sim.py`, seed 7), nunca gravação de tela.

**Correções em relação ao `roteiro-base.md`:** o título sai sem "56 KB" (era o `main.c` antigo; hoje 94 KB e
1.855 linhas, binário de 39 KB); e a escada subiu **inteira** no primeiro dia (2026-06-28), não só até o nível 4.

---

## b1 · Gancho
**FALA**
Esse mundo inteiro cabe em um arquivo de C.
Os bloquinhos comem, planejam, herdam traços dos pais e evoluem.
Eu queria saber se algum deles sente alguma coisa.
Passei quarenta e nove dias tentando medir isso.
E a resposta que eu encontrei não era sobre eles.

**TELA** chuva → terminal com `./matrix 7` (quadros reais) → chip das datas → título + foto do autor
**FONTE** `git log`: 2026-06-28 a 2026-08-15 (49 dias), 131 commits até `9598742`

## b2 · O mundo
**FALA**
O mundo tem sessenta e quatro por vinte e duas casas, e cada casa tem um pouco de comida.
A comida não está espalhada ao acaso: ela nasce de uma função da semente, a seed.
Mesma seed, mesmo mundo. Bit a bit.
Cada bloco só enxerga as oito casas em volta dele. Ninguém lê o mapa inteiro.
E mesmo assim aparece comportamento de grupo: disputa, ocupação, fronteiras.
Ninguém programou isso. Emergiu.

**TELA** mapa ASCII com zoom; o mundo PAUSA na frase das oito casas e um foco 3×3 cai num `@` do centro
**FONTE** `main.c` (`LARG 64`, `ALT 22`); README; CLAUDE.md (percepção 3×3, determinismo)

## b3 · A escada
**FALA**
Para organizar a pergunta, eu montei uma escada. Sete degraus, do mais barato ao mais caro.
Reatividade e memória: um termostato reage, uma planta lembra do inverno.
Valência: o bloco tem uma energia que, em zero, é morte.
E aqui já aparece a fenda inteira. Qual é a diferença entre sofrer e manter um número alto?
Você sabe que há uma. Consegue dizer qual?
Modelo de mundo: pela primeira vez, existe o mundo e o mundo segundo o bloco. E esse modelo pode errar.
Agência: dois blocos idênticos no código podem querer coisas opostas, porque a fome de cada um é só dele.
Auto-modelo: o bloco passa a contar que os outros também decidem.
E aprendizado: ninguém projeta as personalidades. Elas são selecionadas, geração após geração.
A escada inteira subiu no primeiro dia.
E nenhum degrau, sozinho ou somado aos outros, decide a pergunta.

**TELA** escada de 0 a 6 montando degrau a degrau, com o hash do commit de cada um; a pergunta do sofrer × float
**FONTE** FILOSOFIA.md §1–§2; `git log --reverse` (ff8b0ef, 702aacc, ed16786, 721bc13 — todos 2026-06-28)

## b4 · A pílula vermelha
**FALA**
Aí eu fiz uma segunda janela para o mesmo mundo.
Aperto uma tecla, e desço para dentro de um bloco.
O universo encolhe. Tudo o que ele percebe são as oito casas em volta.
Ele sabe quanta energia tem, quanta fome sente, e imagina quanto rende cada jogada.
E ele fala de si, em primeira pessoa: a fome cutuca. Sigo de pé, mas penso em comer.
Nada de novo aconteceu no mundo. É a mesma informação dos números, só que dita com eu.
E algo muda em quem lê. Um quadro de números a gente inspeciona. Uma frase que começa com eu, a gente escuta.
Esse é o teste do zumbi, rodando no seu terminal.
Você nunca acessou a mente de ninguém. Você infere, pelo comportamento.
E o comportamento deste bloco é do mesmo tipo que o meu, ou o do seu vizinho.
Então, qual é a linha que diz: o humano sim, o bloco não?
Qualquer resposta que você der é a sua teoria da consciência.

**TELA** pílula vermelha real (bloco #0, seed 7, ticks 155+, onde ele diz 'A fome cutuca'), zoom por partes; depois 'humano sim, bloco não?'
**FONTE** FILOSOFIA.md §3–§4; frases do `auto_relato` capturadas

## b5 · As quatro portas
**FALA**
A filosofia tem, grosso modo, quatro portas para essa pergunta.
A primeira é o funcionalismo: não há linha. Função rica o bastante já é mente.
A segunda é a de Searle: simulação não é duplicação. Uma tempestade simulada não molha nada.
A terceira é o ilusionismo: não existe um fato extra. Explique tudo o que o sistema faz, inclusive dizer que sente, e acabou.
E a quarta é a teoria da informação integrada: consciência seria o quanto o todo é mais que a soma das partes.
O projeto não escolhe nenhuma. Ele só torna a escolha concreta. Você tem que dizer por quê.

**TELA** quatro portas que acendem uma por frase
**FONTE** FILOSOFIA.md §3

## b6 · A pergunta trocada
**FALA**
No segundo dia, eu troquei a pergunta.
Em vez de: o bloco é consciente? Passei a perguntar: até onde a palavra estica?
Quanto do vocabulário da mente sobrevive quando a gente mede?
Para isso eu construí uma bateria de mostradores, cada um de zero a um.
E a ideia central é simples: apagar uma faculdade, e ver se o comportamento muda.
Isso tem nome: ablação.
Se eu arranco o modelo de mundo e nada muda, aquilo nunca carregou nada.
Uma palavra só fica se alguma ablação consegue zerá-la.

**TELA** pergunta riscada → nova; bateria com os 5 mostradores (médias de 50 seeds) e a ablação zerando um
**FONTE** FILOSOFIA_v2.md §0, §3; valores: nota 11

## b7 · A luz acesa
**FALA**
Das quatro portas, só a última ousa dar um número. Ela chama esse número de fi.
O fi de verdade é incomputável aqui. Então eu fiz uma caricatura honesta.
Comparo a decisão integrada do bloco com o reflexo puro: ir para onde tem mais comida agora.
Se as duas concordam, nada foi integrado. Se discordam, entrou trabalho ali.
Se você aceita fi como medida de experiência, ver esse número subir é ver as luzes se acenderem.
Se recusa, diga que régua usaria no lugar.
De qualquer jeito, fi é um mapa. Não é o território.

**TELA** Φ grande, integrada × reflexo, 'Φ~ é um mapa, não o território'
**FONTE** FILOSOFIA.md §5 (os valores antigos de Φ~ da seed 7 não entram)

## b8 · O determinismo
**FALA**
Tem uma propriedade deste mundo que muda tudo.
Eu rodo a mesma seed duas vezes, e comparo os bytes. São idênticos.
Isso significa que eu posso rebobinar o universo deles, pausar, entrar em qualquer bloco, ler cada linha de código.
Eu tenho, sobre eles, todos os poderes que nos faltam sobre o nosso mundo.
O bloco só vê três por três. Eu só vejo até onde a luz chega.
O bloco não lê o próprio código. Eu não escrevi as leis que obedeço.
Então a pergunta vira: com acesso total, o problema difícil do bloco se resolve?
Não resolve.
Saber cada número, cada regra, cada passo, não decide se há alguém lá.
O acesso total não dissolve a pergunta. Só muda de lugar.

**TELA** duas rodadas lado a lado + `cmp` real (4.434.697 bytes, 600 ticks); tabela bloco × nós; 'não resolve'
**FONTE** FILOSOFIA_v2.md §2, §6; `scripts/capturar_sim.py`

## b9 · E a Matrix?
**FALA**
E aqui o nome do projeto cobra a conta.
Se é fácil fazer um mundo fechado, habitado por agentes que não veem quem o fez, qual a chance de o nosso ser o único nível?
É o argumento da simulação, de Nick Bostrom.
Eu uso isso como lente, não como tese. Com dois freios.
Primeiro: a simetria não é de graça. Os bloquinhos são radicalmente mais simples do que nós.
Segundo: Bostrom prova demais. Estamos numa simulação escorrega para o que não dá para testar.
A pergunta que eu mantenho é outra: o que um observador de dentro pode, em princípio, saber sobre o sistema que o roda?

**TELA** mundos dentro de mundos (`@` → ./matrix 7 → f(seed) → o nosso?); os dois freios
**FONTE** FILOSOFIA.md §6; FILOSOFIA_v2.md §2

## b10 · Quebrar a régua
**FALA**
Aí eu fiz a coisa mais importante do projeto: tentei quebrar os meus próprios medidores.
O de modelo de mundo deu nota máxima, um vírgula zero, para um bloco sem modelo de mundo nenhum.
Uma população que marchava para a extinção em cerca de cem passos.
A régua lia o mapa do mundo, e não o mapa do bloco. E um mapa que não pode errar não é um mapa.
Quatro mostradores quebraram, cada um de um jeito diferente.
E quando a régua finalmente ficou boa, ela me disse coisas que eu não queria ouvir.
Por exemplo: pensar demais é uma corrida armamentista. Bom para o indivíduo, ruim para o grupo.
Esses são os próximos vídeos.

**TELA** mostrador modelo = 1,000 ao lado da população caindo a zero; trailer dos vídeos 2 e 3
**FONTE** FILOSOFIA_v3.md §0; nota 01; nota 11 (51–121 ticks, 50/50); Paper 2

## b11 · A escolha
**FALA**
Então, os bloquinhos sentem?
O projeto não responde. E eu não acho que seja falta de instrumento.
Toda vez que uma palavra da experiência virou medida aqui dentro, ela virou função na minha mão.
A integração virou o segundo motivo. O self virou uma linha que desconta a própria garfada.
A última evidência que sobra para dizer que alguém sente é o relato. Eu sei que sinto.
E o relato foi justamente o que este projeto mais aprendeu a desmontar.
Então a pergunta não está esperando um instrumento melhor.
Ela é feita pelo órgão errado. E nós não temos outro.

**TELA** palavras virando variáveis; '"eu sei que sinto."' sozinho; 'feita pelo órgão errado'
**FONTE** FILOSOFIA_v3.md §6; notas 04, 05, 06, 09

## b12 · Fecho
**FALA**
Eu comecei querendo saber se os bloquinhos sentem.
Terminei medindo de que é feita a frase: eu sinto.
Na próxima: como quatro réguas da mente mentiram para mim, cada uma de um jeito diferente.

**TELA** as duas frases; próximo episódio; cartão final com a foto
**FONTE** —

---

## Cuidados (roteiro-base §0 e §5)
- Nunca afirmar que os blocos sentem: o gancho provoca, a resposta é sempre sobre a régua (b11).
- Números do Paper 1 de 3 seeds antigas não entram; a extinção usa a replicação de 50 seeds (nota 11).
- "Preprint", nunca "publicado". Nenhuma atribuição a IA em descrição, créditos ou legenda.
