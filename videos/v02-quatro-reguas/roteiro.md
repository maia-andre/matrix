# Vídeo 2 — "Quatro modos de uma régua mentir"

Metrologia: os quatro mostradores originais da bateria falharam, cada um de um jeito, e o quinto modo foi de aritmética.
1077 palavras de fala. Primeira pessoa (o autor). As falas valem pelo `narracao.json`; este arquivo é a versão para ler.

**Regras aplicadas:** números da fala arredondados e por extenso, valores exatos na tela; tudo o que vem do Paper 1 §4–§7 aparece como "na época, com três seeds" (roteiro-base §5), e o número robusto é o da replicação de 50 seeds (nota 11). Sem "56 KB" (o `main.c` de hoje é maior). "Ticks" vira "passos" na fala.

---

## b1 · Gancho
**FALA**
Eu construí seis medidores de mente.
Depois, tentei quebrá-los.
Os quatro primeiros quebraram. Cada um de um jeito diferente.
E nenhuma das falhas era visível sem tentar quebrar.

**FONTE** Paper 1, resumo

## b2 · O problema
**FALA**
Suponha que você queira saber se um agente tem um modelo de mundo.
Você cria um número de zero a um, que sobe quando o agente prevê bem. Pronto?
Não. Falta a pergunta que quase ninguém faz: o que esse número lê quando o agente não tem modelo nenhum?
Se ele não despenca, ele nunca leu o modelo. Leu outra coisa, que por acaso andava junto.
No mundo real, quase nunca dá para responder. Ninguém arranca uma faculdade de um cérebro e roda o mesmo dia de novo.
Aqui dá. O universo dos bloquinhos é função da seed: mesmo ruído, mesma comida, mesma ordem de eventos.
Então eu tenho dois jeitos de testar uma régua.
A calibração pergunta: isto acerta?
A ablação arranca a faculdade e pergunta: isto carrega o comportamento?
Parecem a mesma pergunta. Não são. E elas podem apontar para lados opostos.

**FONTE** Paper 1 §1–§3

## b3 · Modo 1
**FALA**
Primeiro modo: a régua que aplaudia a extinção.
O mostrador de modelo de mundo dava zero vírgula noventa e sete. Parecia ótimo.
Aí eu fiz as ablações. Na época, com três seeds.
Encurtei o plano do bloco para um passo só. A nota subiu.
Arranquei o modelo de mundo inteiro. A nota foi a um. Perfeita.
E a população que ganhou essa nota perfeita estava extinta.
A ablação disse a verdade: sem modelo, a população morre. A calibração deu nota máxima a um cadáver.
O defeito estava numa linha. A previsão lia o mapa do mundo, e não o mapa do bloco.
E uma fotocópia do território não pode discordar dele.
Um mapa que não pode errar não é um mapa.
No conserto, a previsão passa a sair da cabeça do bloco. Sem modelo, a nota cai a zero exato.
E o controle passa a ler zero vírgula sessenta e três. Agora o mapa pode errar. E erra.

**FONTE** Paper 1 §4; nota 01 (3 seeds, main.c da época; extinção 51–121 ticks pela replicação, nota 11)

## b4 · Modo 2
**FALA**
Segundo modo: a âncora que andava junto.
O mostrador de agência pergunta se a fome do bloco muda a decisão dele.
Para medir, ele clonava o bloco em dois pontos de fome. Só que um desses pontos dependia de um traço que evolui.
A régua se movia junto com o que ela media.
Isso eu consertei: a sonda passou a varrer o eixo inteiro.
Mas a agência continuava despencando ao longo da evolução. E eu pensei: a régua está contaminada.
Antes de acusar a régua, eu congelei o traço.
Com o traço livre, a agência cai de zero vírgula quarenta e três para zero vírgula zero cinco.
Com o traço congelado, ela fica plana.
A régua estava certa. Quem desaparecia era o objeto.
Num duelo entre reflexo e agente, o reflexo toma a população inteira em uns seis mil passos.
Os blocos continuam sentindo fome. O que a evolução apagou foi o uso da fome na decisão.
E o registro mais desconfortável é este: minha primeira reação a uma leitura incômoda foi acusar a régua.

**FONTE** Paper 1 §5; nota 03 (3 seeds; tabela de 30 000 ticks; invasão 0,997/1,000/1,000)

## b5 · Modo 3
**FALA**
Terceiro modo: o nome que mentia.
Eu tinha um mostrador chamado automodelo. Ele contava quando antecipar os rivais mudava a escolha do bloco.
Primeiro problema: ele não intervinha em nada. Só relia o que a simulação já tinha calculado.
Segundo: dependia de uma constante escondida.
Variando essa força, a leitura desenha uma curva. E o valor de sempre era só um ponto no meio da subida.
O terceiro é o que importa. Tire os rivais. Deixe o bloco sozinho.
A leitura dá zero. Exato.
Uma faculdade que some quando o outro some não é uma posse do bloco.
O conserto foi trocar o nome: modelo do outro.
E daí sai um protocolo que serve para qualquer métrica: o teste do eremita.
Rode a medida num agente sozinho. Se ela zerar, ela mediu uma relação, não uma posse.

**FONTE** Paper 1 §6; nota 04 (curva em α da seed 7; eremita 0,0000 média e máximo)

## b6 · Modo 4
**FALA**
Quarto modo: a régua que nunca dizia não.
O fi, minha caricatura de integração, devia dizer o quanto a decisão é mais que a soma dos motivos.
Eu fiz quatro ablações. Encurtei o plano, apaguei o modelo, ceguei o bloco para os rivais, desliguei a competição.
Nenhuma ablação levou o fi a zero. Uma até fez ele subir.
Uma régua que nenhum teste obriga a dizer não, não está medindo nada.
Na redefinição, eu comparo a decisão com cada motivo isolado: a comida de agora, o espaço, o mapa.
Se um motivo sozinho reproduz a escolha, fi é zero. Integrar uma coisa só não é integrar.
Agora há três ablações que zeram o fi, e dá para demonstrar isso antes de rodar.
E a régua nova conta uma história: ao longo da evolução, o fi cai quase a zero.
A seleção não apaga só a agência. Apaga a irredutibilidade da decisão.

**FONTE** Paper 1 §7; nota 05 (tabela de ablações da phi velha; 0,044 → 0,005 em 30 000 ticks)

## b7 · O quinto modo
**FALA**
E teve um quinto modo, que eu só descobri tarde. Não era de desenho. Era de aritmética.
No eremita, a agência tinha que dar zero. A prova algébrica estava certa.
Mas a régua rodava em ponto flutuante de trinta e dois bits, e ali apareceu um piso.
Recalculei a comparação em precisão dupla. Zero exato.
Um visto da minha tabela era falso. Não por erro de conceito, mas de arredondamento.
E o piso tinha alvo. O arredondamento não inverte ordens. Ele cria empates.
E só vaza na régua que dá significado a um empate.

**FONTE** Paper 1 §8; nota 10 (piso 0,003–0,005 em float32; 0 exato em double)

## b8 · A prova
**FALA**
Até aqui, todos os números nasceram de três seeds. E uma seed não é um resultado.
Então eu publiquei esses valores como pré-registro. E rodei tudo de novo, com cinquenta seeds em cada condição.
Dez condições que tinham de dar zero. Quinhentas corridas.
Zero violações.
A replicação também mexeu nos números. E é para isso que ela serve.
A extinção sem mapa, que eu tinha medido entre setenta e quatro e cento e cinco passos, foi de cinquenta e um a cento e vinte e um.
E as minhas seeds favoritas, a sete e a quarenta e dois, eram sorteios altos em mais de um mostrador.

**FONTE** Paper 1 §9; nota 11 (10 zeros × 50 seeds = 500 corridas, 0 violações; 74–105 → 51–121)

## b9 · Fecho
**FALA**
Nada disso depende de o mundo ser pequeno.
Primeiro: uma métrica de calibração pode ser satisfeita lendo o ambiente, em vez da mente do agente.
Pergunte sempre: o que esta régua lê quando não há nada para ler?
Segundo: o teste do eremita. A medida que zera na solidão mediu uma relação.
E terceiro: quando a calibração e a ablação discordam, a ablação ganha.
Isso vale para quem mede modelos de linguagem, animais ou pacientes. Não como resposta. Como a pergunta a fazer antes.
Na próxima: por que pensar demais deixou todo mundo mais pobre.

**FONTE** Paper 1 §10
