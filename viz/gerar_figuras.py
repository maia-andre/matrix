#!/usr/bin/env python3
"""Gera as figuras dos dois papers a partir dos CSVs de datasets/ e viz/data/.

So le CSVs ja commitados (ou tabelas ja publicadas, transcritas em viz/data/
com comentario de proveniencia) -- nao toca main.c, nao roda a simulacao.
Escreve PNGs em papers/figs/{pt,en}/ (uma versao por idioma, rotulos e
titulos traduzidos; os dados sao os mesmos).

    python3 viz/gerar_figuras.py

Requer pandas + matplotlib (nao vem com o resto do projeto, que e libc pura):

    pip install --user pandas matplotlib
"""
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np
import pandas as pd

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DADOS = os.path.join(RAIZ, "viz", "data")
DATASETS = os.path.join(RAIZ, "datasets")
FIGS = os.path.join(RAIZ, "papers", "figs")

# paleta (references/palette.md do skill dataviz) -----------------------------
AZUL, LARANJA, AGUA = "#2a78d6", "#eb6834", "#1baf7a"
VERMELHO_CRITICO = "#d03b3b"
TINTA, TINTA_SEC, MUDO = "#0b0b0b", "#52514e", "#898781"
GRADE, EIXO = "#e1e0d9", "#c3c2b7"
SUPERFICIE = "#fcfcfb"
# rampa sequencial azul (steps 200/300/450/550/650), clara -> escura
AZUL_SEQ_3 = ["#9ec5f4", "#2a78d6", "#104281"]
AZUL_SEQ_5 = ["#9ec5f4", "#6da7ec", "#2a78d6", "#1c5cab", "#104281"]

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


def limpar(ax, grade_x=False):
    ax.grid(axis="x" if grade_x else "y")
    if not grade_x:
        ax.grid(axis="x", visible=False)


def salvar(fig, lang, nome):
    out = os.path.join(FIGS, lang)
    os.makedirs(out, exist_ok=True)
    caminho = os.path.join(out, nome + ".png")
    fig.savefig(caminho, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print("  ->", os.path.relpath(caminho, RAIZ))


# ============================================================ PAPER 1 =======

def p1_fig1_modelo_ablacao(lang):
    df = pd.read_csv(os.path.join(DADOS, "p1_modo1_ablacao.csv"), comment="#")
    L = {
        "pt": dict(titulo='Modo 1 — o mostrador "modelo" (quebrado) sob 4 ablações',
                   y1="modelo (leitura)", y2="população (fim)",
                   cond=["controle", "horizonte=1", "prever_valor=0", "solipsista"],
                   extinta="população\nextinta"),
        "en": dict(titulo='Failure mode 1 — the (broken) "modelo" gauge under 4 ablations',
                   y1="modelo (reading)", y2="population (final)",
                   cond=["control", "horizon=1", "prever_valor=0", "solipsist"],
                   extinta="population\nextinct"),
    }[lang]

    fig, (a1, a2) = plt.subplots(2, 1, figsize=(6.2, 5.4), sharex=True,
                                  gridspec_kw={"height_ratios": [1.3, 1]})
    x = np.arange(len(df))
    cores = [AZUL, AZUL, VERMELHO_CRITICO, AZUL]
    a1.bar(x, df["modelo"], color=cores, width=0.6)
    a1.set_ylabel(L["y1"]); a1.set_ylim(0, 1.08)
    for xi, v in zip(x, df["modelo"]):
        a1.text(xi, v + 0.02, f"{v:.3f}", ha="center", va="bottom",
                fontsize=9, color=TINTA_SEC)
    limpar(a1)

    pop = df["pop"].to_numpy(dtype=float)
    cores2 = [AZUL if not e else VERMELHO_CRITICO for e in df["extinta"]]
    a2.bar(x, np.nan_to_num(pop, nan=0.0), color=cores2, width=0.6)
    for xi, v, e in zip(x, pop, df["extinta"]):
        if e:
            a2.text(xi, 8, L["extinta"], ha="center", va="bottom", fontsize=8.5,
                    color=VERMELHO_CRITICO)
        else:
            a2.text(xi, v + 6, f"{v:.0f}", ha="center", va="bottom",
                    fontsize=9, color=TINTA_SEC)
    a2.set_ylabel(L["y2"]); a2.set_ylim(0, 340)
    a2.set_xticks(x); a2.set_xticklabels(L["cond"], rotation=12, ha="right")
    limpar(a2)

    fig.suptitle(L["titulo"], fontsize=11.5, y=0.99)
    fig.tight_layout()
    salvar(fig, lang, "p1-fig1-modelo-ablacao")


def p1_fig2_agencia_regra4(lang):
    df = pd.read_csv(os.path.join(DADOS, "p1_modo2_agencia.csv"), comment="#")
    L = {
        "pt": dict(titulo="Regra 4 — congelar o traço decide: a régua é estável,\no objeto é que muda",
                   y="agência (leitura)", x="tick",
                   livre="peso_espaço livre", congelado="peso_espaço congelado"),
        "en": dict(titulo="Rule 4 — freezing the trait decides: the gauge is stable,\nthe object is what changes",
                   y="agencia (reading)", x="tick",
                   livre="peso_espaço free", congelado="peso_espaço frozen"),
    }[lang]

    fig, ax = plt.subplots(figsize=(6, 4))
    x = np.arange(len(df))
    ax.plot(x, df["agencia_peso_espaco_livre"], "-o", color=AZUL, label=L["livre"])
    ax.plot(x, df["agencia_peso_espaco_congelado"], "-o", color=LARANJA, label=L["congelado"])
    ax.set_xticks(x); ax.set_xticklabels([f"{t:,}".replace(",", " ") for t in df["tick"]])
    ax.set_xlabel(L["x"]); ax.set_ylabel(L["y"]); ax.set_ylim(0, 0.55)
    ax.legend(loc="center left")
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p1-fig2-agencia-regra4")


def p1_fig3_modelo_do_outro_alpha(lang):
    df = pd.read_csv(os.path.join(DADOS, "p1_modo3_alpha.csv"), comment="#")
    L = {
        "pt": dict(titulo="Modo 3 — o parâmetro escondido: modelo_do_outro em função de α",
                   x="α (força da antecipação)", y="modelo_do_outro (leitura)",
                   anot="sonda antiga\n(α = 0,5)"),
        "en": dict(titulo="Failure mode 3 — the hidden parameter: modelo_do_outro vs. α",
                   x="α (anticipation strength)", y="modelo_do_outro (reading)",
                   anot="old probe\n(α = 0.5)"),
    }[lang]

    fig, ax = plt.subplots(figsize=(6, 4))
    x = np.arange(len(df))
    seeds = ["seed7", "seed42", "seed1234"]
    for s, cor in zip(seeds, [AZUL, LARANJA, AGUA]):
        ax.plot(x, df[s], "-o", color=cor, label=s.replace("seed", "seed "))
    ax.set_xticks(x)
    ax.set_xticklabels(["0", "0,25" if lang == "pt" else "0.25", "0,5" if lang == "pt" else "0.5", "1", "≥4 (→∞)"])
    i05 = list(df["alpha"]).index(0.5)
    ax.axvline(i05, color=MUDO, lw=1)
    ax.text(i05 + 0.08, 0.05, L["anot"], color=MUDO, fontsize=8.5, va="bottom")
    ax.set_xlabel(L["x"]); ax.set_ylabel(L["y"])
    ax.legend(loc="lower right")
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p1-fig3-modelo-do-outro-alpha")


def p1_fig4_phi_ablacao(lang):
    df = pd.read_csv(os.path.join(DADOS, "p1_modo4_phi_ablacao.csv"), comment="#")
    L = {
        "pt": dict(titulo='Modo 4 — "phi" (velha) não zera em nenhuma ablação',
                   y="phi (leitura, definição velha)"),
        "en": dict(titulo='Failure mode 4 — the (old) "phi" never hits zero',
                   y="phi (reading, old definition)"),
    }[lang]
    fig, ax = plt.subplots(figsize=(6.2, 4))
    x = np.arange(len(df))
    ax.bar(x, df["phi_velha"], color=AZUL, width=0.6)
    for xi, v in zip(x, df["phi_velha"]):
        ax.text(xi, v + 0.006, f"{v:.3f}", ha="center", va="bottom", fontsize=9, color=TINTA_SEC)
    ax.set_xticks(x); ax.set_xticklabels(df["condicao"], rotation=12, ha="right")
    ax.set_ylabel(L["y"]); ax.set_ylim(0, 0.32)
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p1-fig4-phi-ablacao")


def p1_fig5_replicacao(lang):
    df = pd.read_csv(os.path.join(DATASETS, "replicacao50.csv"))
    ctl = df[df["cond"] == "ctl"]
    metricas = [("mod_med", "modelo"), ("ag_med", "agência" if lang == "pt" else "agencia"),
                ("mo_med", "modelo_do_outro"), ("phi_med", "phi"),
                ("rel_med", "relato"), ("ac_med", "autocausa")]
    medias = [ctl[c].mean() for c, _ in metricas]
    desvios = [ctl[c].std() for c, _ in metricas]
    rotulos = [n for _, n in metricas]

    L = {
        "pt": dict(titulo="Réplica: os 6 mostradores em 50 seeds (média ± desvio-padrão)",
                   y="leitura [0, 1]"),
        "en": dict(titulo="Replication: the 6 gauges across 50 seeds (mean ± s.d.)",
                   y="reading [0, 1]"),
    }[lang]

    fig, ax = plt.subplots(figsize=(7, 4.2))
    x = np.arange(len(rotulos))
    ax.bar(x, medias, yerr=desvios, color=AZUL, width=0.55,
           error_kw=dict(ecolor=TINTA, elinewidth=1, capsize=3))
    ax.set_xticks(x); ax.set_xticklabels(rotulos, rotation=15, ha="right")
    ax.set_ylabel(L["y"]); ax.set_ylim(0, 0.85)
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p1-fig5-replicacao-50-seeds")


# ============================================================ PAPER 2 =======

def p2_fig1_bem_posicional(lang):
    grupo = pd.read_csv(os.path.join(DADOS, "p2_paisagem_grupo.csv"), comment="#")
    inv = pd.read_csv(os.path.join(DADOS, "p2_invasao_h3_h9.csv"), comment="#")

    L = {
        "pt": dict(t1="Paisagem de grupo: a população cai com o horizonte pregado",
                   x1="horizonte pregado (h)", y1="população de equilíbrio",
                   t2="Ensaio de invasão: h=9 desloca h=3",
                   x2="tick", y2="frequência de h=9", ref="50/50 inicial"),
        "en": dict(t1="Group landscape: population falls as the fixed horizon deepens",
                   x1="fixed horizon (h)", y1="equilibrium population",
                   t2="Invasion assay: h=9 displaces h=3",
                   x2="tick", y2="frequency of h=9", ref="initial 50/50"),
    }[lang]

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10, 4))

    x = np.arange(len(grupo))
    a1.plot(x, grupo["pop"], "-o", color=AZUL)
    a1.set_xticks(x); a1.set_xticklabels(grupo["h"])
    a1.set_xlabel(L["x1"]); a1.set_ylabel(L["y1"])
    a1.set_title(L["t1"], fontsize=10.5)
    limpar(a1)

    xi = np.arange(len(inv))
    for s, cor in zip(["seed7", "seed42", "seed1234"], [AZUL, LARANJA, AGUA]):
        a2.plot(xi, inv[s], "-o", color=cor, label=s.replace("seed", "seed "))
    a2.axhline(0.5, color=MUDO, lw=1)
    a2.text(0.05, 0.51, L["ref"], color=MUDO, fontsize=8.5, transform=a2.get_yaxis_transform())
    a2.set_xticks(xi); a2.set_xticklabels(inv["tick"])
    a2.set_xlabel(L["x2"]); a2.set_ylabel(L["y2"]); a2.set_ylim(0.35, 1.0)
    a2.legend(loc="lower right", fontsize=8.5)
    a2.set_title(L["t2"], fontsize=10.5)
    limpar(a2)

    fig.tight_layout()
    salvar(fig, lang, "p2-fig1-bem-posicional")


def p2_fig2_torneio_heatmap(lang):
    df = pd.read_csv(os.path.join(DATASETS, "torneio.csv"))
    med = df.groupby(["hi", "hj"])["freq_hj"].mean().reset_index()
    hs = list(range(1, 13))
    M = pd.DataFrame(0.5, index=hs, columns=hs)
    for _, r in med.iterrows():
        hi, hj, f = int(r["hi"]), int(r["hj"]), r["freq_hj"]
        M.loc[hi, hj] = f
        M.loc[hj, hi] = 1 - f

    L = {
        "pt": dict(titulo="O torneio: dominância transitiva do horizonte (δ = 0,80)",
                   x="horizonte (coluna)", y="horizonte (linha)",
                   barra="frequência de vitória da coluna sobre a linha"),
        "en": dict(titulo="The tournament: transitive horizon dominance (δ = 0.80)",
                   x="horizon (column)", y="horizon (row)",
                   barra="win frequency, column over row"),
    }[lang]

    fig, ax = plt.subplots(figsize=(6.4, 5.4))
    cmap = matplotlib.colors.LinearSegmentedColormap.from_list(
        "azul_vermelho", ["#0d366b", "#2a78d6", "#f0efec", "#e34948", "#7a1414"])
    im = ax.imshow(M.to_numpy(), cmap=cmap, vmin=0, vmax=1, origin="lower")
    ax.set_xticks(range(12)); ax.set_xticklabels(hs)
    ax.set_yticks(range(12)); ax.set_yticklabels(hs)
    ax.set_xlabel(L["x"]); ax.set_ylabel(L["y"])
    ax.set_title(L["titulo"], fontsize=11)
    ax.grid(False)
    cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cb.set_label(L["barra"], fontsize=9)
    fig.tight_layout()
    salvar(fig, lang, "p2-fig2-torneio-heatmap")


def p2_fig3_inversao_escada(lang):
    df = pd.read_csv(os.path.join(DATASETS, "desconto.csv"))
    df = df[df["hj"] == df["hi"] + 1]
    piv = df.groupby(["desconto", "hj"])["freq_hj"].mean().unstack("desconto")

    L = {
        "pt": dict(titulo="A escada inverte: vantagem do passo adjacente, por δ",
                   x="horizonte (h), contra h−1", y="frequência de h vencer h−1",
                   ref="empate"),
        "en": dict(titulo="The ladder inverts: adjacent-step advantage, by δ",
                   x="horizon (h), versus h−1", y="frequency of h beating h−1",
                   ref="toss-up"),
    }[lang]

    fig, ax = plt.subplots(figsize=(6.6, 4.4))
    deltas = sorted(piv.columns)
    for d, cor in zip(deltas, AZUL_SEQ_5):
        ax.plot(piv.index, piv[d], "-o", color=cor, label=f"δ = {d:.2f}".replace(".", ","))
    ax.axhline(0.5, color=MUDO, lw=1)
    ax.text(1.15, 0.515, L["ref"], color=MUDO, fontsize=8.5)
    ax.set_xlabel(L["x"]); ax.set_ylabel(L["y"])
    ax.set_xticks(list(piv.index))
    ax.legend(loc="lower left", fontsize=8.5, ncol=2)
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p2-fig3-inversao-escada")


def p2_fig4_dose_resposta(lang):
    df = pd.read_csv(os.path.join(DATASETS, "tipo-unico.csv"))
    base = df[df["horizonte"] == 1].set_index(["desconto", "seed"])["comida_total"]
    df = df.copy()
    df["base"] = df.set_index(["desconto", "seed"]).index.map(base)
    df["diff"] = df["comida_total"] - df["base"]
    piv = df.groupby(["desconto", "horizonte"])["diff"].mean().unstack("desconto")

    L = {
        "pt": dict(titulo="O freio é ruído: a colheita piora com a profundidade,\nmais rápido quanto maior δ",
                   x="horizonte (h)", y="comida em pé, contra h = 1",
                   ref="nível do míope (h = 1)"),
        "en": dict(titulo="The brake is noise: harvest worsens with depth,\nfaster as δ grows",
                   x="horizon (h)", y="standing food, vs. h = 1",
                   ref="myopic baseline (h = 1)"),
    }[lang]

    fig, ax = plt.subplots(figsize=(6.6, 4.4))
    deltas = sorted(piv.columns)
    for d, cor in zip(deltas, AZUL_SEQ_3):
        ax.plot(piv.index, piv[d], "-o", color=cor, label=f"δ = {d:.2f}".replace(".", ","))
    ax.axhline(0.0, color=MUDO, lw=1)
    ax.text(9.4, 3, L["ref"], color=MUDO, fontsize=8.5)
    ax.set_xlabel(L["x"]); ax.set_ylabel(L["y"])
    ax.legend(loc="upper left", fontsize=9)
    ax.set_title(L["titulo"], fontsize=11)
    limpar(ax)
    fig.tight_layout()
    salvar(fig, lang, "p2-fig4-dose-resposta-colheita")


def p2_fig5_imposto(lang):
    rc = pd.read_csv(os.path.join(DATASETS, "reciclagem.csv"))
    queimado = rc[rc["recicla"] == 0].groupby("custo")
    reciclado = rc[rc["recicla"] == 1].groupby("custo")
    custos = sorted(rc["custo"].unique())

    L = {
        "pt": dict(t1="O imposto alinha a escolha: a profundidade\nefetiva cai ao ótimo de grupo",
                   x="custo (c)", y1="profundidade efetiva", ref1="ótimo de grupo (h = 1)",
                   t2="...mas custa: a população cai — reciclar recupera",
                   y2="população final", queimado="queimado", reciclado="reciclado (nota 21)"),
        "en": dict(t1="The tax aligns the choice: effective\ndepth falls to the group optimum",
                   x="cost (c)", y1="effective depth", ref1="group optimum (h = 1)",
                   t2="...but it costs: population falls — recycling recovers it",
                   y2="final population", queimado="burned", reciclado="recycled (note 21)"),
    }[lang]

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10, 4.2))

    prof = queimado["prof_efetiva"].mean()
    a1.plot(custos, [prof[c] for c in custos], "-o", color=AZUL)
    a1.axhline(1.0, color=MUDO, lw=1)
    a1.text(custos[2], 1.05, L["ref1"], color=MUDO, fontsize=8.5)
    a1.set_xlabel(L["x"]); a1.set_ylabel(L["y1"])
    a1.set_title(L["t1"], fontsize=10.5)
    limpar(a1)

    pop_q = queimado["pop_fim"].mean()
    pop_r = reciclado["pop_fim"].mean()
    a2.plot(custos, [pop_q[c] for c in custos], "-o", color=AZUL, label=L["queimado"])
    a2.plot(custos, [pop_r[c] for c in custos], "-o", color=LARANJA, label=L["reciclado"])
    a2.set_xlabel(L["x"]); a2.set_ylabel(L["y2"])
    a2.legend(loc="lower left", fontsize=9)
    a2.set_title(L["t2"], fontsize=10.5)
    limpar(a2)

    fig.tight_layout()
    salvar(fig, lang, "p2-fig5-imposto")


def p2_fig6_bimodalidade(lang):
    df = pd.read_csv(os.path.join(DATASETS, "bimodalidade.csv"))
    df = df[df["variante"] == "uni_h"]
    cols_h = [f"h{i}" for i in range(1, 13)]

    L = {
        "pt": dict(titulo="Do ponto de ramificação ao polimorfismo:\nhistograma do horizonte por δ",
                   x="horizonte (h)", y="fração da população"),
        "en": dict(titulo="From branching point to polymorphism:\nhorizon histogram by δ",
                   x="horizon (h)", y="population fraction"),
    }[lang]

    deltas = [0.80, 0.90, 0.95]
    fig, eixos = plt.subplots(1, 3, figsize=(10, 3.6), sharey=True)
    for ax, d in zip(eixos, deltas):
        sub = df[df["desconto"] == f"{d:.2f}"]
        contagens = sub[cols_h].to_numpy(dtype=float)
        fracoes = contagens / contagens.sum(axis=1, keepdims=True)
        media = fracoes.mean(axis=0)
        ax.bar(range(1, 13), media, color=AZUL, width=0.65)
        ax.set_title(f"δ = {d:.2f}".replace(".", ","), fontsize=10)
        ax.set_xlabel(L["x"])
        ax.set_xticks(range(1, 13, 2))
        limpar(ax)
    eixos[0].set_ylabel(L["y"])
    fig.suptitle(L["titulo"], fontsize=11, y=1.04)
    fig.tight_layout()
    salvar(fig, lang, "p2-fig6-bimodalidade")


FIGURAS = [
    p1_fig1_modelo_ablacao, p1_fig2_agencia_regra4, p1_fig3_modelo_do_outro_alpha,
    p1_fig4_phi_ablacao, p1_fig5_replicacao,
    p2_fig1_bem_posicional, p2_fig2_torneio_heatmap, p2_fig3_inversao_escada,
    p2_fig4_dose_resposta, p2_fig5_imposto, p2_fig6_bimodalidade,
]

if __name__ == "__main__":
    for lang in ("pt", "en"):
        print(f"[{lang}]")
        for f in FIGURAS:
            f(lang)
