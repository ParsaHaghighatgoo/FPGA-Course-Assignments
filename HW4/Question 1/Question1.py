#!/usr/bin/env python3
"""
Multi-Mode CORDIC (Rotation Mode) - Fixed-Point Accuracy + Plots

What this script does:
1) Sweeps iteration count N and prints max error for:
   - Circular mode: max(|cos_err|, |sin_err|) over theta ∈ [-pi/2, +pi/2]
   - Linear mode  : max(|mul_err|) over a,b ∈ [-0.999, +0.999]
2) Finds the minimum N that meets a target threshold (default: 10 LSB)
3) Generates plots:
   - Plot A: max error vs N (circular + linear)
   - Plot B: cos/sin absolute error vs theta for chosen N
   - Plot C: multiplication absolute error heatmap (a,b grid) for chosen N

Dependencies: numpy, matplotlib
Run:
  python cordic_sweep_plot.py
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Callable, Optional, Tuple

import numpy as np
import matplotlib.pyplot as plt


# ============================================================
# Fixed-point configuration and helpers
# ============================================================

@dataclass(frozen=True)
class FixedPointCfg:
    frac: int = 14
    guard: int = 2
    int_bits: int = 2  # Q2.frac

    @property
    def nbits(self) -> int:
        return self.int_bits + self.frac + self.guard

    @property
    def lsb(self) -> float:
        return 2.0 ** (-self.frac)


def clip_signed(v: int, nbits: int) -> int:
    lo = -(1 << (nbits - 1))
    hi = (1 << (nbits - 1)) - 1
    if v < lo:
        return lo
    if v > hi:
        return hi
    return v


def to_fixed(x: float, frac: int, nbits: int) -> int:
    return clip_signed(int(round(x * (1 << frac))), nbits)


def from_fixed(v: int, frac: int) -> float:
    return v / float(1 << frac)


# ============================================================
# CORDIC constants (gain + LUTs)
# ============================================================

def cordic_gain(iters: int) -> float:
    g = 1.0
    for k in range(iters):
        g *= math.sqrt(1.0 + (2.0 ** (-2 * k)))
    return g


def atan_lut(iters: int, cfg: FixedPointCfg) -> list[int]:
    return [to_fixed(math.atan(2.0 ** -k), cfg.frac, cfg.nbits) for k in range(iters)]


def step_lut(iters: int, cfg: FixedPointCfg) -> list[int]:
    return [to_fixed(2.0 ** -k, cfg.frac, cfg.nbits) for k in range(iters)]


# ============================================================
# CORDIC simulation (fixed-point)
# ============================================================

def cordic_circular(theta: float, iters: int, cfg: FixedPointCfg) -> Tuple[float, float]:
    """Circular rotation-mode CORDIC returning (cos, sin), using 1/K pre-scale."""
    nbits = cfg.nbits
    k_inv = 1.0 / cordic_gain(iters)

    x = to_fixed(k_inv, cfg.frac, nbits)
    y = 0
    z = to_fixed(theta, cfg.frac, nbits)

    lut = atan_lut(iters, cfg)

    for k in range(iters):
        d = 1 if z >= 0 else -1
        x_sh = x >> k
        y_sh = y >> k

        x = clip_signed(x - d * y_sh, nbits)
        y = clip_signed(y + d * x_sh, nbits)
        z = clip_signed(z - d * lut[k], nbits)

    return from_fixed(x, cfg.frac), from_fixed(y, cfg.frac)


def cordic_linear_mul(a: float, b: float, iters: int, cfg: FixedPointCfg) -> float:
    """Linear mode: y ~= a*b for |b|<1-ish."""
    nbits = cfg.nbits

    x = to_fixed(a, cfg.frac, nbits)
    y = 0
    z = to_fixed(b, cfg.frac, nbits)

    lut = step_lut(iters, cfg)

    for k in range(iters):
        d = 1 if z >= 0 else -1
        y = clip_signed(y + d * (x >> k), nbits)
        z = clip_signed(z - d * lut[k], nbits)

    return from_fixed(y, cfg.frac)


# ============================================================
# Error computations (for sweeps + plotting)
# ============================================================

def circular_err_over_theta(iters: int, cfg: FixedPointCfg, samples: int = 2001):
    thetas = np.linspace(-math.pi / 2.0, math.pi / 2.0, samples)
    cos_err = np.zeros_like(thetas)
    sin_err = np.zeros_like(thetas)

    for i, th in enumerate(thetas):
        c_hat, s_hat = cordic_circular(float(th), iters, cfg)
        cos_err[i] = abs(c_hat - math.cos(float(th)))
        sin_err[i] = abs(s_hat - math.sin(float(th)))

    return thetas, cos_err, sin_err


def max_err_circular(iters: int, cfg: FixedPointCfg, samples: int = 2001) -> float:
    _, ce, se = circular_err_over_theta(iters, cfg, samples)
    return float(max(np.max(ce), np.max(se)))


def linear_err_grid(iters: int, cfg: FixedPointCfg, grid: int = 41):
    pts = np.linspace(-0.999, 0.999, grid)
    err = np.zeros((grid, grid), dtype=float)

    for i, a in enumerate(pts):
        for j, b in enumerate(pts):
            y_hat = cordic_linear_mul(float(a), float(b), iters, cfg)
            err[i, j] = abs(y_hat - (float(a) * float(b)))

    return pts, err


def max_err_linear(iters: int, cfg: FixedPointCfg, grid: int = 41) -> float:
    _, err = linear_err_grid(iters, cfg, grid)
    return float(np.max(err))


# ============================================================
# Iteration sweep + selection
# ============================================================

def sweep_iters(
    n_min: int,
    n_max: int,
    err_fn: Callable[[int], float],
    target: float,
    label: str,
) -> Tuple[np.ndarray, np.ndarray, Optional[int]]:
    ns = np.arange(n_min, n_max + 1)
    errs = np.zeros_like(ns, dtype=float)
    first_ok: Optional[int] = None

    print(f"========== {label} ==========")
    for idx, n in enumerate(ns):
        e = err_fn(int(n))
        errs[idx] = e
        ok = (e <= target)
        if first_ok is None and ok:
            first_ok = int(n)
        print(f"N={int(n):2d}  max_err={e:.8e}  {'OK' if ok else ''}")
    print()
    return ns, errs, first_ok


# ============================================================
# Main
# ============================================================

def main() -> None:
    # Config (match your Verilog)
    cfg = FixedPointCfg(frac=14, guard=2, int_bits=2)

    # Target = 10 LSB
    target = 10.0 * cfg.lsb

    # Sweep settings
    n_min, n_max = 6, 21
    circ_samples = 2001
    mul_grid = 41

    print("========== FIXED-POINT SETUP ==========")
    print(f"Format          : Q{cfg.int_bits}.{cfg.frac} (internal bits={cfg.nbits})")
    print(f"LSB             : {cfg.lsb:.8e}")
    print(f"Target error    : 10 LSB = {target:.8e}")
    print()
    print("Ranges:")
    print("  Circular: theta in [-pi/2, +pi/2] (no quadrant correction)")
    print("  Linear  : a,b in [-0.999, +0.999]")
    print()

    # Iteration sweeps
    ns_c, err_c, n_circ = sweep_iters(
        n_min, n_max,
        err_fn=lambda n: max_err_circular(n, cfg, samples=circ_samples),
        target=target,
        label="CIRCULAR MODE (sin/cos) SWEEP"
    )

    ns_l, err_l, n_lin = sweep_iters(
        n_min, n_max,
        err_fn=lambda n: max_err_linear(n, cfg, grid=mul_grid),
        target=target,
        label="LINEAR MODE (multiply) SWEEP"
    )

    # Pick hardware N
    picks = [n for n in (n_circ, n_lin) if n is not None]
    chosen = max(picks) if picks else None

    print("========== SUMMARY ==========")
    print(f"Minimum N (circular) : {n_circ}")
    print(f"Minimum N (linear)   : {n_lin}")
    print(f"Chosen hardware N    : {chosen}")
    if chosen is not None:
        k = cordic_gain(chosen)
        print(f"K(N)                 : {k:.8f}")
        print(f"1/K                  : {1.0/k:.8f}")
    print()

    # ----------------------------
    # Plot A: max error vs N
    # ----------------------------
    plt.figure()
    plt.plot(ns_c, err_c, marker="o", label="Circular: max(|cos_err|,|sin_err|)")
    plt.plot(ns_l, err_l, marker="o", label="Linear: max(|mul_err|)")
    plt.axhline(target, linestyle="--", label="Target (10 LSB)")
    if chosen is not None:
        plt.axvline(chosen, linestyle="--", label=f"Chosen N = {chosen}")
    plt.xlabel("Iterations N")
    plt.ylabel("Worst-case absolute error")
    plt.title("CORDIC Worst-Case Error vs Iterations")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()

    # ----------------------------
    # Plot B: error vs theta (chosen N)
    # ----------------------------
    if chosen is not None:
        thetas, cos_err, sin_err = circular_err_over_theta(chosen, cfg, samples=circ_samples)

        plt.figure()
        plt.plot(thetas, cos_err, label="|cos_err|")
        plt.plot(thetas, sin_err, label="|sin_err|")
        plt.axhline(target, linestyle="--", label="Target (10 LSB)")
        plt.xlabel("theta (radians)")
        plt.ylabel("Absolute error")
        plt.title(f"Circular Mode Error vs Angle (N={chosen})")
        plt.grid(True)
        plt.legend()
        plt.tight_layout()

    # ----------------------------
    # Plot C: multiplication error heatmap (chosen N)
    # ----------------------------
    if chosen is not None:
        pts, err2d = linear_err_grid(chosen, cfg, grid=mul_grid)

        plt.figure()
        plt.imshow(
            err2d,
            origin="lower",
            extent=[pts[0], pts[-1], pts[0], pts[-1]],
            aspect="auto"
        )
        plt.colorbar(label="|mul_err|")
        plt.xlabel("b")
        plt.ylabel("a")
        plt.title(f"Linear Mode Multiply Error Heatmap (N={chosen})")
        plt.tight_layout()

    # Show plots
    plt.show()


if __name__ == "__main__":
    main()
