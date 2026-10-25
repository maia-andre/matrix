"""Captura a simulação (main.c) como quadros de texto para os vídeos.

  python capturar_sim.py <saida.js> --seed 7 --ticks 300 [--foco 0] [--nome deus] [--colunas 116]

Compila o main.c do repositório numa pasta temporária, roda `./matrix <seed> <ticks> 0 [foco]` com a
saída num pipe (sem atraso entre ticks) e corta o fluxo ANSI em quadros (cada tick começa com ESC[H).
Cada quadro vira uma lista de linhas; cada linha é [texto, cores], com um caractere de cor por
caractere de texto. O .js grava `window.SIM[nome] = {seed, foco, quadros, colunas}` e o HTML desenha o
quadro floor(t · ticks_por_segundo): o filme é f(seed), igual em toda máquina.

Também roda a mesma seed duas vezes e compara os bytes: o determinismo é conferido, não suposto.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]  # matrix/
SGR = re.compile(r"\x1b\[([0-9;?]*)([A-Za-z])")
# códigos de cor do main.c → classe de um caractere (o HTML mapeia cada uma para a paleta da marca)
CORES = {"0": ".", "2;32": "c", "91": "r", "92": "g", "93": "y", "96": "a", "3": "i"}


def rodar(binario: Path, seed: int, ticks: int, foco: int | None) -> bytes:
    args = [str(binario), str(seed), str(ticks), "0"] + ([str(foco)] if foco is not None else [])
    return subprocess.run(args, check=True, capture_output=True, timeout=600).stdout


def quadros(bruto: bytes, colunas: int) -> list[list[list[str]]]:
    texto = bruto.decode("utf-8", errors="replace")
    saida = []
    for q in texto.split("\x1b[H")[1:]:
        linhas, txt, cor, atual = [], [], [], "."
        pos = 0
        for m in SGR.finditer(q + "\x1b[0m"):
            for ch in q[pos:m.start()]:
                if ch == "\n":
                    linhas.append(["".join(txt)[:colunas], "".join(cor)[:colunas]])
                    txt, cor = [], []
                else:
                    txt.append(ch)
                    cor.append(atual)
            pos = m.end()
            if m.group(2) == "m":
                atual = CORES.get(m.group(1), ".")
        if txt:
            linhas.append(["".join(txt)[:colunas], "".join(cor)[:colunas]])
        while linhas and not linhas[-1][0].strip():
            linhas.pop()
        saida.append(linhas)
    return saida


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("saida", type=Path)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--ticks", type=int, default=300)
    ap.add_argument("--foco", type=int, help="bloco em primeira pessoa (a 'pílula vermelha')")
    ap.add_argument("--nome", default="deus")
    ap.add_argument("--colunas", type=int, default=116, help="corta linhas longas do HUD")
    a = ap.parse_args()

    with tempfile.TemporaryDirectory() as d:
        binario = Path(d) / "matrix"
        subprocess.run(["gcc", "-std=c11", "-Wall", "-Wextra", "-O2", "-o", str(binario), str(RAIZ / "main.c")], check=True)
        b1 = rodar(binario, a.seed, a.ticks, a.foco)
        b2 = rodar(binario, a.seed, a.ticks, a.foco)
    if b1 != b2:
        raise SystemExit("! duas rodadas da mesma seed deram saídas diferentes: o determinismo quebrou")
    commit = subprocess.run(["git", "-C", str(RAIZ), "log", "-1", "--format=%h", "--", "main.c"],
                            capture_output=True, text=True).stdout.strip()
    qs = quadros(b1, a.colunas)
    dados = {"seed": a.seed, "foco": a.foco, "ticks": a.ticks, "colunas": a.colunas, "main_c": commit, "quadros": qs}
    a.saida.parent.mkdir(parents=True, exist_ok=True)
    a.saida.write_text(f"window.SIM = window.SIM || {{}};\nwindow.SIM[{json.dumps(a.nome)}] = "
                       + json.dumps(dados, ensure_ascii=False, separators=(",", ":")) + ";\n", encoding="utf-8")
    print(f"{a.saida} · {len(qs)} quadros · seed {a.seed} · foco {a.foco} · main.c {commit} · "
          f"{a.saida.stat().st_size // 1024} KB · duas rodadas idênticas ({len(b1)} bytes)")


if __name__ == "__main__":
    main()
