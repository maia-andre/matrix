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
