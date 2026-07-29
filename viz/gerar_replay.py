#!/usr/bin/env python3
"""Replay visual ao vivo (fio 4 do backlog especulativo, ROADMAP).

So le viz/data/replay_bimodal.csv e viz/data/replay_colapso.csv -- nao toca
main.c, nao roda a simulacao (quem roda a simulacao sao os dois geradores em
viz/data/gerar_replay_*.sh, que produzem esses CSVs a partir de uma corrida
fresca e ja documentam a propria proveniencia no cabecalho).

Ao contrario das figuras estaticas de gerar_figuras.py, isto e uma segunda
metade que viz/README.md ja previa: nao um "CSV -> PNG" mas um "CSV -> GIF",
porque o que ha para ver aqui e a MUDANCA ao longo do tempo -- a bifurcacao
do histograma de horizonte (nota 23) e o detector de colapso disparando e
desligando (nota 24), nao um estado final.

    python3 viz/gerar_replay.py

Requer pandas + matplotlib + pillow (o mesmo ambiente de gerar_figuras.py;
pillow escreve o GIF).
"""
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter
import pandas as pd

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DADOS = os.path.join(RAIZ, "viz", "data")
SAIDA = os.path.join(RAIZ, "viz", "replays")

# paleta (references/palette.md do skill dataviz -- a mesma de gerar_figuras.py)
AZUL, VERMELHO_CRITICO = "#2a78d6", "#d03b3b"
TINTA, TINTA_SEC, MUDO = "#0b0b0b", "#52514e", "#898781"
GRADE, EIXO = "#e1e0d9", "#c3c2b7"
SUPERFICIE = "#fcfcfb"

plt.rcParams.update({
    "figure.facecolor": SUPERFICIE,
    "axes.facecolor": SUPERFICIE,
    "savefig.facecolor": SUPERFICIE,
    "font.family": "sans-serif",
    "font.size": 10.5,
    "text.color": TINTA,
    "axes.edgecolor": EIXO,
    "axes.labelcolor": TINTA_SEC,
    "xtick.color": MUDO,
    "ytick.color": MUDO,
    "axes.grid": True,
    "axes.axisbelow": True,
    "grid.color": GRADE,
    "grid.linewidth": 0.8,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "legend.frameon": False,
})


def replay_bimodal():
    """nota 23 ao vivo: o histograma de horizonte se bifurcando (30000 ticks,
    151 snapshots instantaneos a cada 200 ticks, delta=0.95, seed=1)."""
    df = pd.read_csv(os.path.join(DADOS, "replay_bimodal.csv"))
    cols_h = [f"h{i}" for i in range(1, 13)]
    contagens = df[cols_h].to_numpy(dtype=float)
    total = contagens.sum(axis=1, keepdims=True)
    total[total == 0] = 1.0
    fracoes = contagens / total
    ticks = df["tick"].to_numpy()

    fig, ax = plt.subplots(figsize=(6.4, 4.2))
    barras = ax.bar(range(1, 13), fracoes[0], color=AZUL, width=0.68)
    ax.set_xlim(0.3, 12.7)
    ax.set_ylim(0, fracoes.max() * 1.12)
    ax.set_xticks(range(1, 13))
    ax.set_xlabel("horizonte (h)")
    ax.set_ylabel("fração da população viva")
    ax.grid(axis="x", visible=False)
    titulo = ax.set_title("", fontsize=11)

    def frame(i):
        for b, altura in zip(barras, fracoes[i]):
            b.set_height(altura)
        titulo.set_text(
            f"δ = 0,95 · a bifurcação do horizonte ao vivo — tick {ticks[i]:,}".replace(",", "."))
        return list(barras) + [titulo]

    anim = FuncAnimation(fig, frame, frames=len(ticks), interval=110, blit=False)
    # segura 20 quadros parados no final (~2s) para o vale ficar visivel antes do loop
    os.makedirs(SAIDA, exist_ok=True)
    caminho = os.path.join(SAIDA, "replay-bimodal.gif")
    anim.save(caminho, writer=PillowWriter(fps=9))
    plt.close(fig)
    print(f"   {caminho} ({len(ticks)} quadros)")


def replay_colapso():
    """nota 24 ao vivo: populacao + o detector de colapso disparando/
    desligando (imposto liga em t=2000, desliga em t=5000, 8000 ticks,
    custo=0.30, seed=2)."""
    df = pd.read_csv(os.path.join(DADOS, "replay_colapso.csv"))
    ticks = df["tick"].to_numpy()
    pop = df["pop"].to_numpy()
    ativo = df["ativo"].to_numpy()

    INICIO, FIM = 2000, 5000
    STRIDE = 25   # subamostra os quadros (8001 ticks -> ~320 quadros); o CSV fica intacto
    idx = list(range(0, len(ticks), STRIDE))
    if idx[-1] != len(ticks) - 1:
        idx.append(len(ticks) - 1)

    fig, ax = plt.subplots(figsize=(7.6, 4.2))
    ax.set_xlim(0, ticks.max())
    ax.set_ylim(0, pop.max() * 1.1)
    ax.axvspan(INICIO, FIM, color=VERMELHO_CRITICO, alpha=0.07, lw=0)
    ax.text(INICIO, pop.max() * 1.04, " imposto ligado", color=TINTA_SEC, fontsize=8.5, va="top")
    ax.set_xlabel("tick")
    ax.set_ylabel("população")
    ax.grid(axis="x", visible=False)

    linha_pop, = ax.plot([], [], color=AZUL, lw=1.4, zorder=3)
    faixa_ativo = ax.fill_between([], [], color=VERMELHO_CRITICO, alpha=0.35, lw=0)
    titulo = ax.set_title("", fontsize=11)

    def frame(k):
        nonlocal faixa_ativo
        i = idx[k]
        linha_pop.set_data(ticks[:i + 1], pop[:i + 1])
        faixa_ativo.remove()
        alt_faixa = pop.max() * 0.035
        faixa_ativo = ax.fill_between(
            ticks[:i + 1], 0, alt_faixa,
            where=ativo[:i + 1].astype(bool),
            color=VERMELHO_CRITICO, alpha=0.85, lw=0, step=None, zorder=2)
        estado = "COLAPSO ATIVO" if ativo[i] else "normal"
        titulo.set_text(f"o detector de colapso ao vivo — tick {ticks[i]:,} · {estado}".replace(",", "."))
        return [linha_pop, faixa_ativo, titulo]

    anim = FuncAnimation(fig, frame, frames=len(idx), interval=60, blit=False)
    os.makedirs(SAIDA, exist_ok=True)
    caminho = os.path.join(SAIDA, "replay-colapso.gif")
    anim.save(caminho, writer=PillowWriter(fps=16))
    plt.close(fig)
    print(f"   {caminho} ({len(idx)} quadros)")


if __name__ == "__main__":
    print("== replay bimodal (nota 23) ==")
    replay_bimodal()
    print("== replay colapso (nota 24) ==")
    replay_colapso()
    print("== fim ==")
