"""Two slits in an ideal lens's focal plane: direct FFT vs sinc² cos²."""
import argparse
import numpy as np
from LightPipes import Begin, RectAperture, BeamMix, LensFarfield, Intensity
from common import (plt, output_folder, save_csv, save_checks, check_below,
                    check_above, image_extent)


def calculate(window, wavelength, grid, width, separation, height, focal_length):
    plane = Begin(window, wavelength, grid)
    # A half-pixel translation places default aperture edges between samples.
    # Translating BOTH slits changes focal-plane phase, not intensity.
    shift = plane.dx / 2
    left = RectAperture(plane, width, height, x_shift=-separation / 2 + shift, y_shift=shift)
    right = RectAperture(plane, width, height, x_shift=separation / 2 + shift, y_shift=shift)
    aperture = BeamMix(left, right)
    focal = LensFarfield(aperture, focal_length)
    intensity = Intensity(focal, 0)
    profile = intensity[grid // 2] / intensity[grid // 2, grid // 2]
    # LensFarfield uses an unnormalized FFT. This factor restores the physical
    # Fresnel amplitude scale for integrated-intensity conservation only.
    amplitude_scale = plane.dx**2 / (wavelength * focal_length)
    power_ratio = intensity.sum() * amplitude_scale**2 * focal.dx**2 / (
        Intensity(aperture, 0).sum() * aperture.dx**2)
    occupied_left = np.flatnonzero(Intensity(left, 0)[grid // 2] > 0)
    occupied_right = np.flatnonzero(Intensity(right, 0)[grid // 2] > 0)
    effective_width = len(occupied_left) * plane.dx
    effective_separation = (occupied_right.mean() - occupied_left.mean()) * plane.dx
    return aperture, focal, profile, power_ratio, effective_width, effective_separation


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wavelength-nm", type=float, default=632.8)
    parser.add_argument("--slit-width-mm", type=float, default=0.125)
    parser.add_argument("--separation-mm", type=float, default=0.5)
    parser.add_argument("--focal-length-mm", type=float, default=500.0)
    parser.add_argument("--grid", type=int, default=1024)
    parser.add_argument("--output-name", default="02_double_slit")
    args = parser.parse_args()
    if min(args.wavelength_nm, args.slit_width_mm, args.separation_mm, args.focal_length_mm) <= 0:
        parser.error("All physical parameters must be positive.")
    if args.slit_width_mm >= args.separation_mm:
        parser.error("The slit width must be smaller than center-to-center separation.")
    if args.grid < 256 or args.grid % 2 or args.grid > 2048:
        parser.error("Use an even grid between 256 and 2048.")
    wavelength = args.wavelength_nm * 1e-9
    width = args.slit_width_mm * 1e-3
    separation = args.separation_mm * 1e-3
    focal_length = args.focal_length_mm * 1e-3
    window, height = 8e-3, 1e-3
    if width + separation > window * 0.8:
        parser.error("The two slits must fit comfortably inside the 8 mm window.")
    folder = output_folder(args.output_name)
    aperture, focal, profile, power_ratio, a, d = calculate(
        window, wavelength, args.grid, width, separation, height, focal_length)
    x = focal.xvalues
    fringe = wavelength * focal_length / d
    envelope_zero = wavelength * focal_length / a
    envelope = np.sinc(a * x / (wavelength * focal_length))**2
    analytic = envelope * np.cos(np.pi * d * x / (wavelength * focal_length))**2
    central = np.abs(x) <= envelope_zero
    refined = calculate(window, wavelength, args.grid * 2, width, separation, height, focal_length)
    # With fixed input window, the focal-plane sample spacing is independent of N.
    fine_profile = refined[2]
    fine_center = len(fine_profile) // 2
    fine_aligned = fine_profile[fine_center - args.grid // 2:fine_center + args.grid // 2]
    save_csv(folder / "focal_profile.csv",
             ["x_m", "FFT_normalized_intensity", "analytic_sinc2_cos2", "single_slit_envelope"],
             zip(x, profile, analytic, envelope))
    view = min(1.5 * envelope_zero, abs(x[0]) * 0.8)
    fig, axes = plt.subplots(1, 3, figsize=(13.2, 4.6), layout="constrained")
    axes[0].imshow(Intensity(aperture, 0), origin="lower", cmap="gray",
                   extent=image_extent(aperture), interpolation="nearest", vmin=0, vmax=1)
    axes[0].set(xlabel="Input x (mm)", ylabel="Input y (mm)",
                xlim=(-0.8, 0.8), ylim=(-0.8, 0.8),
                title=f"Two coherent slits\na = {a * 1e3:.3f} mm, d = {d * 1e3:.3f} mm")
    focal_intensity = Intensity(focal, 0)
    axes[1].imshow(focal_intensity / focal_intensity.max(), origin="lower", cmap="magma",
                   extent=image_extent(focal), interpolation="nearest", vmin=0, vmax=1,
                   aspect="auto")
    axes[1].set(xlabel="Focal-plane x (mm)", ylabel="Focal-plane y (mm)",
                xlim=(-view * 1e3, view * 1e3), ylim=(-0.8, 0.8),
                title=f"Direct FFT: lens focal plane\nf = {args.focal_length_mm:g} mm")
    dense = np.linspace(-view, view, 1200)
    dense_env = np.sinc(a * dense / (wavelength * focal_length))**2
    axes[2].plot(dense * 1e3, dense_env * np.cos(np.pi * d * dense / (wavelength * focal_length))**2,
                 color="#235bd3", lw=1.6, label="Analytic sinc² × cos²")
    axes[2].plot(x * 1e3, profile, "o", ms=3, markerfacecolor="white", color="#d76524", label="FFT")
    axes[2].plot(dense * 1e3, dense_env, "--", color="#67717e", label="Single-slit envelope")
    axes[2].set(xlabel="Focal-plane x (mm)", ylabel="Intensity / central maximum",
                xlim=(-view * 1e3, view * 1e3), ylim=(-0.03, 1.1),
                title=f"Fringe carrier period λf/d = {fringe * 1e3:.4f} mm")
    axes[2].grid(True)
    axes[2].legend(fontsize=8, loc="upper right")
    fig.suptitle("Double slit: diffraction envelope × two-beam interference", fontsize=14)
    fig.savefig(folder / "01_double_slit_fft.png", bbox_inches="tight")
    plt.close(fig)
    save_checks(folder, vars(args) | {"input_window_m": window, "slit_height_m": height},
                {"effective_sampled_slit_width_m": a, "effective_sampled_separation_m": d,
                 "input_step_m": aperture.dx, "output_step_m": focal.dx,
                 "fringe_carrier_period_m": fringe, "first_envelope_zero_m": envelope_zero,
                 "note": "Envelope shifts intensity maxima slightly; lambda*f/d is the cos² carrier period.",
                 "model": "LightPipes.LensFarfield: direct FFT, ideal paraxial lens focal plane",
                 "refined_grid": args.grid * 2},
                [check_above("samples across each slit", a / aperture.dx, 12),
                 check_above("samples per fringe carrier period", fringe / focal.dx, 12),
                 check_below("sampled slit width vs requested", abs(a / width - 1), 0.02),
                 check_below("sampled separation vs requested", abs(d / separation - 1), 0.02),
                 check_below("maximum central-envelope error vs continuous analytic", np.abs(profile[central] - analytic[central]).max(), 0.003),
                 check_below("maximum central-envelope change on doubling grid", np.abs(profile[central] - fine_aligned[central]).max(), 0.003),
                 check_below("integrated intensity drift with physical FFT scaling", abs(power_ratio - 1), 1e-9)])


if __name__ == "__main__":
    main()
