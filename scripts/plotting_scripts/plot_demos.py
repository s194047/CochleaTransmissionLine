#!/usr/bin/env python3

from typing import Final

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

OUTPUT_DIR: Final = Path("data/figures/demos")

COLUMN_WIDTH_PT: Final = 221.0
TEXT_WIDTH_PT: Final = 452.0

PT_PER_INCH: Final = 72.27
FIGURE_ASPECT_RATIO: Final = 4 / 3

FIG_WIDTH_IN = COLUMN_WIDTH_PT / PT_PER_INCH
FIG_HEIGHT_IN = FIG_WIDTH_IN / FIGURE_ASPECT_RATIO


plt.style.use("../paper.mplstyle")

def main() -> None:
    # Winding and rotation number demo.
    Ts = 0.001
    t = np.arange(0, 1+Ts, Ts,)
    f1 = 2
    f2 = 1

    x = 0.5 * np.cos(2*np.pi*f1*t) + 0.5 * np.cos(2*np.pi*f2*t) - 0.25
    y = 0.5 * np.sin(2*np.pi*f1*t) + 0.5 * np.sin(2*np.pi*f2*t)

    plt.figure(figsize=(FIG_WIDTH_IN, FIG_HEIGHT_IN))

    plt.plot(x, y, color="C2")
    plt.xlim(-1, 1)
    plt.ylim(-1, 1)

    arrow_indices = [int(len(t) * f) for f in [0.0, 0.15, 0.40, 0.6, 0.85]]
    for i in arrow_indices:
        dx = x[i+1] - x[i]
        dy = y[i+1] - y[i]
        plt.annotate("", xy=(x[i] + dx, y[i] + dy), xytext=(x[i], y[i]),
                    arrowprops=dict(arrowstyle="->", color="C2"))
    i1 = int(len(t) * 0.075)
    plt.plot([0, x[i1]], [0, y[i1]], "o:", color="C2")
    plt.annotate(r"$(0, 0)$", (0, 0), (0, -1), textcoords="offset fontsize")
    plt.annotate(r"$(y, v)$", (x[i1], y[i1]), (0, 0.5), textcoords="offset fontsize")
    plt.xticks([])
    plt.yticks([])

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    plt.savefig(OUTPUT_DIR / "winding_rotation.pdf")

if __name__ == "__main__":
    main()
