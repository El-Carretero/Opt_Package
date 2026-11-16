"""Numerical FFT propagation of a Gaussian beam, checked against w(z)."""
import argparse
import numpy as np
from LightPipes import Begin, GaussBeam, Forvard, Intensity
from common import (plt, output_folder, save_csv, save_checks, check_below,
                    check_above, image_extent)


def measure(field):
    intensity = Intensity(field, 0)
    x = field.xvalues
    weights_x = intensity.sum(axis=0)
    weights_y = intensity.sum(axis=1)
    total = intensity.sum()
    center_x = np.dot(x, weights_x) / total
    center_y = np.dot(field.yvalues, weights_y) / total
    # I(x,y) = I0 exp(-2 r^2/w^2): sigma_x = w/2, so w = 2 sigma_x.
    wx = 2 * np.sqrt(np.dot((x - center_x)**2, weights_x) / total)
    wy = 2 * np.sqrt(np.dot((field.yvalues - center_y)**2, weights_y) / total)
    outside = (np.abs(x)[None, :] > 0.4 * field.siz) | (
        np.abs(field.yvalues)[:, None] > 0.4 * field.siz)
    return wx, wy, total * field.dx**2, intensity[outside].sum() / total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wavelength-nm", type=float, default=632.8)
    parser.add_argument("--waist-mm", type=float, default=0.5)
    parser.add_argument("--window-mm", type=float, default=8.0)
    parser.add_argument("--grid", type=int, default=512)
    parser.add_argument("--z-max-zr", type=float, default=2.0)
    parser.add_argument("--output-name", default="01_gaussian")
    args = parser.parse_args()
    if min(args.wavelength_nm, args.waist_mm, args.window_mm, args.z_max_zr) <= 0:
        parser.error("Wavelength, waist, window and distance must be positive.")
    if args.grid < 128 or args.grid % 2 or args.grid > 2048:
        parser.error("Use an even grid between 128 and 2048.")
    wavelength = args.wavelength_nm * 1e-9
    waist = args.waist_mm * 1e-3
    window = args.window_mm * 1e-3
    zr = np.pi * waist**2 / wavelength
    folder = output_folder(args.output_name)

    # GaussBeam initializes only the waist. Every propagated field below uses
    # Forvard, the numerical FFT Fresnel transfer-function implementation.
    source = GaussBeam(Begin(window, wavelength, args.grid), waist)
    source_power = measure(source)[2]
    zs = np.linspace(0, args.z_max_zr * zr, 25)
    rows = []
    for z in zs:
        field = Forvard(source, float(z))
        wx, wy, power, boundary_fraction = measure(field)
        analytic_w = waist * np.sqrt(1 + (z / zr)**2)
        rows.append((z, z / zr, wx, wy, analytic_w,
                     abs(wx / analytic_w - 1), power / source_power, boundary_fraction))
    data = np.array(rows)
    save_csv(folder / "beam_radius.csv",
             ["z_m", "z_over_zR", "w_x_m", "w_y_m", "analytic_w_m",
              "relative_radius_error", "relative_integrated_intensity", "outer_10pct_fraction"], rows)

    # An independent finer grid checks sampling, while the boundary check
    # detects the periodic-window limitation that a power check alone misses.
    fine_source = GaussBeam(Begin(window, wavelength, args.grid * 2), waist)
    fine_radius = measure(Forvard(fine_source, float(zs[-1])))[0]
    grid_difference = abs(fine_radius / data[-1, 2] - 1)
    selected_zs = [0.0, float(zs[-1] / 2), float(zs[-1])]
    fields = [Forvard(source, float(z)) for z in selected_zs]
    fig, axes = plt.subplots(1, 3, figsize=(12.4, 4.2), layout="constrained")
    display_radius = 2.6 * waist * np.sqrt(1 + max(1, args.z_max_zr)**2) * 1e3
    for ax, z, field in zip(axes, selected_zs, fields):
        intensity = Intensity(field, 0)
        picture = ax.imshow(intensity, origin="lower", extent=image_extent(field),
                            cmap="magma", vmin=0, vmax=1, interpolation="nearest")
        expected = waist * np.sqrt(1 + (z / zr)**2) * 1e3
        ax.add_patch(plt.Circle((0, 0), expected, fill=False, color="#65e3f2",
                               linewidth=1.4, linestyle="--"))
        ax.set(xlabel="x (mm)", ylabel="y (mm)",
               title=f"z = {z / zr:.1f} zR  ({z:.3f} m)\nw = {expected:.3f} mm",
               xlim=(-display_radius, display_radius), ylim=(-display_radius, display_radius))
    fig.colorbar(picture, ax=axes, label="Intensity / initial on-axis intensity", shrink=0.8)
    fig.suptitle("Gaussian beam: numerical free-space propagation\nDashed circle: analytic 1/e² intensity radius", fontsize=14)
    fig.savefig(folder / "01_beam_maps.png", bbox_inches="tight")
    plt.close(fig)

    fig, axes = plt.subplots(1, 2, figsize=(11.5, 4.6), layout="constrained")
    dense = np.linspace(0, zs[-1], 250)
    axes[0].plot(dense / zr, waist * np.sqrt(1 + (dense / zr)**2) * 1e3,
                 color="#235bd3", linewidth=2.4, label="Analytic w(z)")
    axes[0].plot(data[:, 1], data[:, 2] * 1e3, "o", ms=4,
                 markerfacecolor="white", color="#d76524", label="FFT / second moment")
    axes[0].set(xlabel="Propagation distance z / zR", ylabel="1/e² intensity radius w (mm)",
                title=f"zR = {zr:.6f} m; w0 = {args.waist_mm:g} mm")
    axes[0].legend()
    for z, field in zip(selected_zs, fields):
        centerline = Intensity(field, 0)[field.N // 2]
        axes[1].plot(field.xvalues * 1e3, centerline / centerline.max(),
                     label=f"z / zR = {z / zr:.1f}")
    axes[1].axhline(np.exp(-2), color="#67717e", linestyle="--", label="1/e² = 0.1353")
    axes[1].set(xlabel="x (mm)", ylabel="Intensity / this plane's peak",
                xlim=(-display_radius, display_radius), ylim=(0, 1.05),
                title="Normalized centerline: radius grows")
    axes[1].legend(fontsize=9)
    for ax in axes:
        ax.grid(True)
    fig.suptitle("The same field: numerical propagation vs Gaussian-beam theory", fontsize=14)
    fig.savefig(folder / "02_radius_and_profiles.png", bbox_inches="tight")
    plt.close(fig)
    save_csv(folder / "centerline_profiles.csv",
             ["x_m"] + [f"intensity_z_{z / zr:.4g}_zR" for z in selected_zs],
             zip(fields[0].xvalues, *(Intensity(f, 0)[f.N // 2] for f in fields)))

    save_checks(folder, vars(args) | {"rayleigh_range_m": zr, "grid_step_m": source.dx},
                {"final_radius_m": float(data[-1, 2]), "final_analytic_radius_m": float(data[-1, 4]),
                 "refined_grid": args.grid * 2, "refined_final_radius_m": float(fine_radius),
                 "radius_definition": "2 sigma_x = 1/e^2 intensity radius for a Gaussian",
                 "propagation": "LightPipes.Forvard: numerical FFT Fresnel transfer function"},
                [check_above("samples across waist radius", waist / source.dx, 20),
                 check_below("maximum radius relative error vs analytic", data[:, 5].max(), 0.001),
                 check_below("maximum integrated intensity drift", np.abs(data[:, 6] - 1).max(), 1e-9),
                 check_below("maximum intensity fraction in outer 10% border", data[:, 7].max(), 1e-5),
                 check_below("final radius change on doubling grid", grid_difference, 0.001),
                 check_below("x/y radius asymmetry", np.abs(data[:, 2] / data[:, 3] - 1).max(), 1e-9)])


if __name__ == "__main__":
    main()
