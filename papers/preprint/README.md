# Preprint (English)

English translations of the two papers, prepared for an arXiv-style
preprint. The Portuguese originals in `papers/` remain the source of
record — these are derived artifacts, kept in sync by hand when the
source changes.

- `paper-1-four-gauges.md` / `.pdf` — translation of
  `../paper-1-quatro-reguas.md`.
- `paper-2-positional-good.md` / `.pdf` — translation of
  `../paper-2-bem-posicional.md`, including all inline addenda.

Both add a formal bibliography and a handful of citations the Portuguese
originals only gestured at in prose (see each file's References section).

PDF build: `pandoc <file>.md -o <file>.pdf --pdf-engine=typst -V
mainfont="DejaVu Serif" -V monofont="DejaVu Sans Mono"` (typst installed
as a standalone binary in `~/.local/bin`, not via apt — see the project
memory for how).
