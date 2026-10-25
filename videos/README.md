# Vídeos da Matrix

Produção da série de vídeos do projeto (mapa e fontes em `roteiro-base.md`). Cada vídeo é uma pasta
com `narracao.json` (falas), `episodio.html` (cenas) e `audio/` (narração gerada).

**O motor é emprestado do repositório `Treinamentos`** (tipografia cinética em HTML, narração sintética,
render determinístico). Os dois repositórios precisam estar lado a lado:

```
Documentos/Projetos/
├── Treinamentos/   lib/ (motor.js, GSAP), tts/, render/, .venv/
└── matrix/videos/  marca/, scripts/, vNN-*/
```

O `episodio.html` carrega `../../../Treinamentos/lib/...`. Os comandos rodam a partir do Treinamentos:

```sh
cd ../../Treinamentos
.venv/bin/python -m tts.narrar ../matrix/videos/v04-o-self                 # narração (Fish, voz "Morpheus")
.venv/bin/python -I ../matrix/videos/scripts/gerar_trilha.py \
    ../matrix/videos/v04-o-self/audio/trilha-fundo.ogg <duracao_s>          # trilha original (duração do out/plano.json)
.venv/bin/python render/render.py ../matrix/videos/v04-o-self \
    --fundo ../matrix/videos/v04-o-self/audio/trilha-fundo.ogg              # MP4 em out/
.venv/bin/python render/conferir.py ../matrix/videos/v04-o-self             # sincronia, frames, pronúncia
```

## Simulação ao vivo (`scripts/capturar_sim.py`)
A simulação entra no vídeo como **texto**, não como gravação de tela: o script compila o `main.c`, roda
`./matrix <seed> <ticks> 0 [foco]` num pipe, roda **duas vezes e compara os bytes** (para se divergir) e
grava `sim/<nome>.js` com um quadro por tick (texto + uma cor por caractere), a seed, o foco e o commit do
`main.c`. O HTML desenha o quadro `floor(t · ticks_por_segundo)` na fonte da marca, com zoom livre.

```sh
.venv/bin/python -I ../matrix/videos/scripts/capturar_sim.py ../matrix/videos/v01-x/sim/deus.js --seed 7 --ticks 300
.venv/bin/python -I ../matrix/videos/scripts/capturar_sim.py ../matrix/videos/v01-x/sim/eu.js --seed 7 --ticks 140 --foco 0 --nome eu
```

## Identidade (`marca/`)
- Preto, verde fósforo `#00FF41`, JetBrains Mono embutida (`marca/fontes/`, licença OFL).
- Chuva de caracteres e mundo ASCII desenhados em canvas como função pura de `t` (nada de animação CSS).
- `marca/autor.jpg`: ilustração do autor (abertura e cartão final).
- Música: **só trilha original** (`scripts/gerar_trilha.py`, sintetizada e determinística). Nada de faixas
  com direitos (ex.: a trilha do filme): no YouTube o Content ID identifica em segundos, e no Brasil não
  há "fair use" para música de fundo.

## Regras de conteúdo (do `roteiro-base.md`)
Todo número tem fonte no repo (a tela mostra a nota no rodapé); função, nunca experiência; o erro
aparece antes do conserto; nenhuma atribuição a IA em nada publicado. Autor: André Maia.
