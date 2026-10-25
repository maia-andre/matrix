"""Trilha de fundo original da série (sintetizada, determinística, sem samples nem melodia de terceiros).

  python gerar_trilha.py <saida.ogg> <duracao_s> [--bpm 96] [--semente 7]

Clima "Matrix": grave pulsante em lá menor, pad escuro, batida quebrada leve e arpejo digital
com eco. A progressão Am · F · Dm · E se repete a cada 4 compassos; as camadas entram aos poucos
(pad → grave → arpejo → batida) e tudo sai num fade nos últimos 6 s. Mesma semente, mesmo arquivo.
Precisa de numpy, soundfile e ffmpeg no PATH (rodar com o venv do Treinamentos).
"""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf

SR = 48000


def hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


def passa_baixa(x: np.ndarray, corte: float) -> np.ndarray:
    """Passa-baixa de um polo aplicado no domínio da frequência (só numpy; suficiente para escurecer serras)."""
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(np.fft.rfft(x) / (1 + 1j * f / corte), len(x)).astype(np.float32)


def serra(f: float, n: int, fase: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    return 2 * ((t * f + fase) % 1.0) - 1


def env(n: int, ataque: float, decai: float) -> np.ndarray:
    t = np.arange(n) / SR
    return np.minimum(1, t / max(ataque, 1e-4)) * np.exp(-t * decai)


def gerar(dur: float, bpm: float, semente: int) -> np.ndarray:
    rng = np.random.default_rng(semente)
    n = int(dur * SR)
    out = np.zeros(n + SR * 4, np.float32)
    batida = 60.0 / bpm
    compasso = 4 * batida
    acordes = [(57, [57, 60, 64]), (53, [53, 57, 60]), (50, [50, 53, 57]), (52, [52, 56, 59])]  # Am F Dm E
    escala = [57, 60, 62, 64, 67, 69, 72, 74, 76]  # lá menor pentatônica + 9ª
    n_comp = int(np.ceil(dur / compasso))
    ruido = rng.standard_normal(int(0.25 * SR)).astype(np.float32)

    def soma(i0: int, x: np.ndarray, g: float):
        i1 = min(len(out), i0 + len(x))
        if i1 > i0:
            out[i0:i1] += g * x[: i1 - i0]

    for c in range(n_comp):
        raiz, notas = acordes[(c // 2) % 4]  # cada acorde dura 2 compassos
        t0 = c * compasso
        i0 = int(t0 * SR)
        nc = int(compasso * SR)
        # pad: três serras desafinadas por nota, filtradas (entra já no começo)
        if c % 2 == 0:
            m = int(2 * compasso * SR)
            pad = np.zeros(m, np.float32)
            for nota in notas:
                for d in (-0.08, 0.0, 0.07):
                    pad += serra(hz(nota - 12 + d), m, rng.random()).astype(np.float32)
            pad = passa_baixa(pad, 700.0) * np.minimum(1, np.arange(m) / (0.8 * SR)) * np.minimum(1, (m - np.arange(m)) / (0.8 * SR))
            soma(i0, pad.astype(np.float32), 0.05)
        # grave pulsante em colcheias (a partir do compasso 2)
        if c >= 2:
            for k in range(8):
                ib = i0 + int(k * batida / 2 * SR)
                nb = int(batida / 2 * SR)
                f = hz(raiz - 24 + (12 if k in (3, 7) else 0))
                tb = np.arange(nb) / SR
                b = (np.sin(2 * np.pi * f * tb) + 0.3 * np.sign(np.sin(2 * np.pi * f * tb))) * env(nb, 0.004, 9.0)
                soma(ib, b.astype(np.float32), 0.22)
        # arpejo digital em semicolcheias, com eco (a partir do compasso 4)
        if c >= 4:
            for k in range(16):
                if rng.random() < 0.35:
                    continue
                nota = escala[int(rng.integers(0, len(escala)))]
                ia = i0 + int(k * batida / 4 * SR)
                na = int(0.22 * SR)
                ta = np.arange(na) / SR
                p = np.sign(np.sin(2 * np.pi * hz(nota) * ta)) * 0.5 + np.sin(2 * np.pi * hz(nota) * 2 * ta) * 0.3
                p = (p * env(na, 0.002, 18.0)).astype(np.float32)
                for eco, g in ((0, 0.06), (0.375, 0.03), (0.75, 0.015)):
                    soma(ia + int(eco * batida * SR), p, g)
        # batida quebrada (a partir do compasso 8): bumbo, caixa abafada e chimbal
        if c >= 8:
            for k, (tipo, g) in enumerate([("b", .5), ("h", .1), ("h", .06), ("b", .3), ("s", .28), ("h", .08), ("b", .35), ("h", .06),
                                           ("h", .1), ("b", .4), ("h", .06), ("h", .08), ("s", .28), ("h", .06), ("b", .2), ("h", .1)]):
                ik = i0 + int(k * batida / 4 * SR)
                if tipo == "b":
                    nk = int(0.3 * SR)
                    tk = np.arange(nk) / SR
                    x = np.sin(2 * np.pi * (45 + 90 * np.exp(-tk * 35)) * tk) * env(nk, 0.002, 12.0)
                elif tipo == "s":
                    nk = int(0.18 * SR)
                    x = passa_baixa(ruido[:nk].copy(), 2500.0) * env(nk, 0.001, 22.0) * 2
                else:
                    nk = int(0.05 * SR)
                    x = np.diff(ruido[: nk + 1]) * env(nk, 0.0005, 70.0) * 0.5
                soma(ik, x.astype(np.float32), g)

    out = out[:n]
    fim = int(min(6.0, dur / 4) * SR)
    out[-fim:] *= np.linspace(1, 0, fim) ** 2
    ini = int(1.5 * SR)
    out[:ini] *= np.linspace(0, 1, ini)
    return (out / np.max(np.abs(out)) * 10 ** (-1 / 20)).astype(np.float32)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("saida", type=Path)
    ap.add_argument("duracao", type=float)
    ap.add_argument("--bpm", type=float, default=96)
    ap.add_argument("--semente", type=int, default=7)
    a = ap.parse_args()
    x = gerar(a.duracao, a.bpm, a.semente)
    a.saida.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        wav = Path(d) / "t.wav"
        sf.write(wav, x, SR)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5", str(a.saida)], check=True)
    print(f"{a.saida} · {a.duracao:.1f} s · {a.bpm:g} bpm · semente {a.semente}")


if __name__ == "__main__":
    main()
