# Papers

Escrita formal do projeto.

Convenção: commitar a **fonte** (`.md`/`.tex`) junto com o PDF gerado — o PDF
é artefato de build, a fonte é o que se revisa e diffa.

`figs/` guarda as figuras (`pt/` e `en/`, mesmos dados, rótulos traduzidos),
geradas por `../viz/gerar_figuras.py` — ver `../viz/README.md` para a
proveniência de cada uma. São artefato de build como o PDF: regenere com
`python3 viz/gerar_figuras.py` a partir da raiz do projeto.
