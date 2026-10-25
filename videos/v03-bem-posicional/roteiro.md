# Vídeo 3 — "Pensar demais é um bem posicional"

O tema com mais alcance fora do nicho: as três camadas do Paper 2, cada uma derrubando a anterior, mais os adendos (sonda do plano, imposto reciclado, ramificação).
956 palavras de fala. Primeira pessoa (o autor). As falas valem pelo `narracao.json`; este arquivo é a versão para ler.

**Regras aplicadas:** números da fala arredondados e por extenso, valores exatos na tela; o erro aparece antes do conserto (o "ESS = teto" do δ = 0,80, e o "alinhar ≠ restaurar o bem-estar" corrigido pela nota 21); o histograma de duas linhagens é marcado como esquema (o replay não é citado com números); a comparação com modelos maiores fica como pergunta.

---

## b1 · Gancho
**FALA**
Dei aos bloquinhos a capacidade de planejar alguns passos à frente.
E deixei a evolução escolher quantos.
Eles escolheram pensar o máximo que podiam.
E isso deixou todo mundo mais pobre.

**FONTE** Paper 2, resumo

## b2 · Os dois traços
**FALA**
Cada bloco herda dos pais dois traços, com mutação.
O horizonte: quantos passos à frente ele planeja. De um a doze.
E o desconto: quanto vale, para ele, uma comida que só vem daqui a alguns passos.
Desconto alto é paciência. Desconto baixo quer tudo agora.
E os dois se compensam. Um bloco pode declarar um plano longo e, com desconto baixo, pensar raso.
Então qualquer frase sobre pensar fundo precisa do par: horizonte e desconto.

**FONTE** Paper 2 §1–§2 (não identificabilidade do par h, δ; corr até −0,93)

## b3 · A corrida
**FALA**
Primeira medida: pregar o horizonte na população inteira, e ver quantos blocos o mundo sustenta.
A cada passo a mais de plano, a população encolhe. Pouco, mas sempre.
O ótimo do grupo é pensar o mínimo: um passo.
Segunda medida: um duelo. Metade da população planeja três passos. A outra metade, nove.
O planejador fundo vence. Nas três seeds, em quatro mil passos, ele chega a oitenta e cinco por cento da população ou mais.
Bom para o indivíduo, ruim para o grupo. Isso tem nome: bem posicional.
É a Rainha Vermelha. Correr cada vez mais, só para ficar no mesmo lugar.
E desligar a competição deixa os horizontes mais rasos. A competição não freia o pensamento. Ela alimenta.
Depois, o torneio inteiro: todos os horizontes contra todos. Sessenta e seis duelos, oito seeds cada.
Cada horizonte maior vence todos os menores. O doze vence os onze.
Uma corrida sem freio.

**FONTE** Paper 2 §3 (população 295,9 → 289,3; duelo 3×9: 0,91/0,87/0,85 em 4000 ticks, 3 seeds) e §4 (torneio 66 pares × 8 seeds × 6000 ticks); notas 14, 15

## b4 · Não produz nada
**FALA**
Mas quanto desse pensamento é produção, e quanto é só tomar do vizinho?
Para separar, eu rodei mundos de um tipo só. Todo mundo com o mesmo horizonte. Ninguém de outro tipo para disputar.
Se pensar fundo produz comida, esses mundos deviam colher mais.
Colhem menos. Com doze passos de plano, sobram vinte unidades a mais de comida em pé do que com um passo só. Comida que ninguém colheu.
Só um passo de plano paga: o segundo. Do terceiro em diante, cada passo a mais piora a colheita.
O horizonte não produz nada. Tudo o que ele compra é tomado de um vizinho.

**FONTE** Paper 2 §5; nota 17 (comida em pé contra h = 1 em δ = 0,80: −2,3 / +11,0 / +20,3, t = +12,5)

## b5 · O erro e o freio
**FALA**
E aqui eu errei. O erro precisa aparecer.
Eu tinha escrito que o doze era o fim da corrida: o equilíbrio era pensar o máximo possível.
Só que eu tinha medido isso num único desconto: zero vírgula oitenta.
Varri outros descontos. Em zero vírgula noventa e cinco, a escada inverte.
O nove vence o doze. O seis vence o doze. O raso vence.
A pergunta passou a ser: o fundo perde porque prevê pior, ou só porque alguém chega antes na comida dele?
O mundo de um tipo só decide.
Com desconto alto, um mundo inteiro de blocos com doze passos sustenta cinco blocos e meio a menos que um mundo com oito.
E ali não tem ninguém de fora para tomar a comida. O déficit é contra o mundo.
A ponta do plano é uma alucinação. E o desconto decide quanto peso ela recebe.
Com desconto zero vírgula oitenta, o último passo entra com nove por cento do peso. Com zero vírgula noventa e cinco, com mais da metade.
O desconto não é impaciência. É o bloco se recusando a confiar numa previsão que ele não consegue fazer.

**FONTE** Paper 2 §4(c) e §5; notas 16, 17 (inversão em δ = 0,95: 0,344/0,240/0,202; pop(h12) − pop(h8) = −5,51, t = −4,3; 0,8¹¹ ≈ 0,09 e 0,95¹¹ ≈ 0,57)

## b6 · Mais paciência
**FALA**
Daí sai o resultado mais estranho do trabalho.
Mais paciência, horizonte ótimo mais raso.
Com desconto zero vírgula noventa, o melhor é planejar uns dez passos. Com zero vírgula noventa e cinco, uns sete ou oito.
Quanto mais peso você dá ao futuro distante, menos longe pode olhar sem ser envenenado pela própria previsão.

**FONTE** Paper 2, resumo e §4(c); nota 19

## b7 · O plano
**FALA**
Depois eu medi a previsão passo a passo, contra o que de fato aconteceu.
Só o primeiro passo do plano carrega informação. Do segundo em diante, a previsão já não acerta. Em oito de oito seeds.
O plano é um passo, com uma cauda que nunca é vivida.
Mas tem uma virada. Como previsão, o plano falha. Como ordem, ele funciona.
Ele ainda põe as opções na ordem certa, e acerta a melhor cerca de quatro vezes mais que o acaso.

**FONTE** notas 18 e 22 (k* = 0 em 8/8 seeds; argmax 3,8–4,5× o acaso)

## b8 · O imposto
**FALA**
Se pensar fundo impõe um custo ao grupo, a receita clássica é cobrar por ele. Um imposto sobre pensar.
Cobrei pela profundidade efetiva, e não pelo horizonte declarado. Senão o bloco escapava baixando o desconto.
Funciona. Com o imposto certo, a profundidade evoluída cai de três vírgula três para um. Encosta no ótimo do grupo.
Mas, queimando a arrecadação, o imposto custou um terço da população.
Eu escrevi que alinhar a escolha não é restaurar o bem-estar. E isso também estava errado.
Devolvendo a arrecadação como dividendo, igual para todos, o alinhamento continua. E a população vai a cento e dois por cento do original.
O problema não era o imposto. Era queimar o dinheiro.

**FONTE** Paper 2 §7 e adendo; notas 15 e 21 (3,31 → 1,04 em c = 0,15; queimado 66%, reciclado 102%)

## b9 · Duas linhagens
**FALA**
Agora, o último andar.
O horizonte ótimo não é um equilíbrio estável. É um ponto de ramificação: a população pode se dividir ali.
Com desconto alto e os outros traços pregados, ela se divide de fato, em duas linhagens: uma rasa, outra funda.
Na evolução livre, cada mundo escolhe um pico só. E cada mundo escolhe um diferente.
E onde o desconto é zero vírgula oitenta, a resposta é mista. Em seis de oito seeds era ruído de mutação. Em duas, eram duas linhagens de verdade.

**FONTE** notas 20, 23 e 28

## b10 · Fecho
**FALA**
Então, pensar demais é um bem posicional.
Onde o desconto protege, é um bem que não produz nada. E mesmo assim você precisa dele, para não ser deslocado.
Acima disso, não é um bem caro. É um erro. E a seleção corrige.
Dá vontade de comparar com a corrida por modelos cada vez maiores. Eu deixo isso como pergunta, não como conclusão.
Na próxima: o self que já estava no código.

**FONTE** Paper 2 §6
