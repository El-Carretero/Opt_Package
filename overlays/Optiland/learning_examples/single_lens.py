"""양볼록 렌즈의 평행광 굴절: Optiland 실광선과 근축 계산을 비교한다.

실행: RUN.bat 또는 ../.venv/Scripts/python.exe single_lens.py
길이는 mm, Optiland에 넘기는 파장은 um(마이크로미터)이다.
"""
from pathlib import Path
import csv
import importlib.metadata
import json
import os
import platform

HERE = Path(__file__).resolve().parent
OUTPUT = HERE / "output"
OUTPUT.mkdir(exist_ok=True)
os.environ["MPLBACKEND"] = "Agg"
os.environ["MPLCONFIGDIR"] = str(HERE / ".mplconfig")

import matplotlib.pyplot as plt
import numpy as np
from optiland.materials import IdealMaterial
from optiland.optic import Optic


# 먼저 이 값들만 하나씩 바꾸어 결과를 비교하세요.
N_GLASS = 1.5                 # 굴절률, 무차원. 파장에 따라 변하지 않는 가상 유리.
R_FRONT_MM = 50.0             # 빛은 +z 방향. 곡률 중심이 면의 오른쪽이면 R > 0.
R_BACK_MM = -50.0             # 양볼록 렌즈의 뒤쪽 면은 R < 0.
THICKNESS_MM = 5.0            # 두 면의 꼭짓점 사이 중심 두께.
BEAM_DIAMETER_MM = 16.0       # 입사 평행광의 지름(입사동공 지름).
WAVELENGTH_UM = 0.55          # 0.55 um = 550 nm. 이 예제는 단일 파장만 사용.
SCREEN_AFTER_REAR_MM = 60.0   # 광선 기록을 끝낼 관측면. 렌즈 초점거리와 별개.
N_RAYS = 9


def build_lens():
    lens = Optic()
    # 무한대 물체 = 광축에 평행한 입사광. 첫 굴절면 꼭짓점은 z=0.
    lens.surfaces.add(index=0, thickness=float("inf"))
    lens.surfaces.add(index=1, radius=R_FRONT_MM, thickness=THICKNESS_MM,
                      material=IdealMaterial(N_GLASS), is_stop=True)
    lens.surfaces.add(index=2, radius=R_BACK_MM, thickness=SCREEN_AFTER_REAR_MM,
                      material=IdealMaterial(1.0))  # 렌즈 뒤에는 공기.
    lens.surfaces.add(index=3)  # 기록용 관측면; 추가 굴절력 없음.
    lens.set_aperture(aperture_type="EPD", value=BEAM_DIAMETER_MM)
    lens.fields.set_type("angle")
    lens.fields.add(y=0)
    lens.wavelengths.add(value=WAVELENGTH_UM, is_primary=True)
    return lens


def trace_heights(lens, heights_mm):
    """Optiland가 교점과 굴절을 계산한다. 직접 Snell 추적기를 작성하지 않는다."""
    heights_mm = np.asarray(heights_mm, dtype=float)
    pupil_y = heights_mm / (BEAM_DIAMETER_MM / 2)
    lens.trace_generic(0, 0, np.zeros_like(pupil_y), pupil_y, WAVELENGTH_UM)
    # 다음 trace 호출은 면의 기록을 덮어쓰므로 여기서 배열을 복사한다.
    return [{key: np.asarray(getattr(surface, key), dtype=float).copy()
             for key in ("x", "y", "z", "L", "M", "N")}
            for surface in lens.surfaces]


def axis_crossings(last_surface):
    # 굴절 후 공기 중 직선의 광축(y=0) 교점. M,N은 y,z 방향 코사인.
    return last_surface["z"] - last_surface["y"] * last_surface["N"] / last_surface["M"]


def save_csv(path, columns, rows):
    with path.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(columns)
        writer.writerows(rows)


def main():
    lens = build_lens()
    image_z = THICKNESS_MM + SCREEN_AFTER_REAR_MM

    # Optiland의 f2()는 유효초점거리(EFL)이다. F2()는 관측면 기준 초점 위치.
    # 라이브러리의 근축 계산을 먼저 수행하고 그 후 실광선을 기록한다.
    efl = float(lens.paraxial.f2())
    focus_z = image_z + float(lens.paraxial.F2())
    bfl = focus_z - THICKNESS_MM
    rear_principal_z = focus_z - efl

    # 독립적인 검산: 공기 속 두꺼운 구면 렌즈의 근축 lensmaker 식.
    # 얇은 렌즈 식은 두께 항을 버린 근사이므로 정답 판정에 사용하지 않는다.
    power = (N_GLASS - 1) * (1/R_FRONT_MM - 1/R_BACK_MM
             + (N_GLASS - 1)*THICKNESS_MM/(N_GLASS*R_FRONT_MM*R_BACK_MM))
    analytic_efl = 1 / power
    analytic_bfl = (1 - THICKNESS_MM*(N_GLASS - 1)/(N_GLASS*R_FRONT_MM)) / power
    thin_lens_efl = 1 / ((N_GLASS - 1)*(1/R_FRONT_MM - 1/R_BACK_MM))
    np.testing.assert_allclose(efl, analytic_efl, rtol=1e-11, atol=1e-10)
    np.testing.assert_allclose(bfl, analytic_bfl, rtol=1e-11, atol=1e-10)

    heights = np.linspace(-BEAM_DIAMETER_MM/2, BEAM_DIAMETER_MM/2, N_RAYS)
    history = trace_heights(lens, heights)
    for surface in history:
        assert all(np.isfinite(values).all() for values in surface.values())
        np.testing.assert_allclose(surface["L"]**2 + surface["M"]**2 + surface["N"]**2,
                                   1.0, rtol=1e-11, atol=1e-11)
    selected = np.flatnonzero(np.abs(heights) > 1e-12)
    last_noncentral = {key: values[selected] for key, values in history[-1].items()}
    crossings = axis_crossings(last_noncentral)
    marginal_focus_z = float(crossings[np.argmax(np.abs(heights[selected]))])

    # 중심에서 1 um 높이의 실광선은 근축 해에 가까워야 한다.
    near_axis = trace_heights(lens, [0.001])
    near_axis_focus_z = float(axis_crossings(near_axis[-1])[0])
    assert abs(near_axis_focus_z - focus_z) < 1e-5

    surface_names = ["incident_plane", "front_glass", "rear_glass", "observation_plane"]
    save_csv(OUTPUT / "ray_paths.csv",
             ["ray_id", "entrance_height_mm", "surface", "surface_name", "x_mm", "y_mm", "z_mm", "L", "M", "N"],
             [[j, float(height), i, surface_names[i], *[float(s[k][j]) for k in ("x", "y", "z", "L", "M", "N")]]
              for j, height in enumerate(heights) for i, s in enumerate(history)])
    save_csv(OUTPUT / "focus_positions.csv",
             ["entrance_height_mm", "axis_crossing_z_mm", "distance_from_rear_vertex_mm"],
             [[float(heights[j]), float(z), float(z-THICKNESS_MM)] for j, z in zip(selected, crossings)])

    summary = {
        "tool": "Optiland", "version": importlib.metadata.version("optiland"),
        "python": platform.python_version(),
        "parameters": {"n": N_GLASS, "R1_mm": R_FRONT_MM, "R2_mm": R_BACK_MM,
                       "thickness_mm": THICKNESS_MM, "beam_diameter_mm": BEAM_DIAMETER_MM,
                       "wavelength_um": WAVELENGTH_UM, "observation_plane_z_mm": image_z},
        "optiland": {"EFL_mm": efl, "BFL_mm": bfl, "paraxial_focus_z_mm": focus_z,
                     "rear_principal_plane_z_mm": rear_principal_z,
                     "marginal_ray_focus_z_mm": marginal_focus_z,
                     "near_axis_ray_focus_z_mm": near_axis_focus_z},
        "analytic_thick_lens": {"EFL_mm": analytic_efl, "BFL_mm": analytic_bfl},
        "thin_lens_approximation_EFL_mm": thin_lens_efl,
        "validation": {"status": "PASS", "EFL_absolute_error_mm": abs(efl-analytic_efl),
                       "BFL_absolute_error_mm": abs(bfl-analytic_bfl),
                       "near_axis_focus_error_mm": abs(near_axis_focus_z-focus_z),
                       "finite_rays_and_unit_directions": True},
    }
    (OUTPUT / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11,
                         "axes.spines.top": False, "axes.spines.right": False})
    fig = plt.figure(figsize=(12.8, 8.4), facecolor="#f6f8fb", layout="constrained")
    grid = fig.add_gridspec(2, 2, height_ratios=[1.3, 1], width_ratios=[1.25, 1])
    ax = fig.add_subplot(grid[0, :])
    zoom = fig.add_subplot(grid[1, 0])
    notes = fig.add_subplot(grid[1, 1]); notes.axis("off")
    fig.suptitle("Optiland | Parallel rays through one glass lens", fontsize=20, weight="bold")
    colors = plt.cm.viridis(np.linspace(.12, .88, N_RAYS))
    for j, height in enumerate(heights):
        z = [float(s["z"][j]) for s in history]
        y = [float(s["y"][j]) for s in history]
        ax.plot(z, y, color=colors[j], lw=1.6)
        zoom.plot(z, y, color=colors[j], lw=1.6)

    # 렌즈 윤곽도 Optiland의 면 형상에서 얻는다. 좌표축 단위는 모두 mm이다.
    contour_y = np.linspace(-BEAM_DIAMETER_MM*.53, BEAM_DIAMETER_MM*.53, 250)
    front_z = np.asarray(lens.surfaces[1].geometry.sag(0, contour_y))
    back_z = THICKNESS_MM + np.asarray(lens.surfaces[2].geometry.sag(0, contour_y))
    ax.fill_betweenx(contour_y, front_z, back_z, facecolor="#b7dff4", edgecolor="#296b91", alpha=.8)
    ax.axhline(0, color="#64748b", lw=.8)
    ax.axvline(focus_z, color="#d24e36", ls="--", lw=1.5)
    ax.text(THICKNESS_MM/2, BEAM_DIAMETER_MM*.61, f"n={N_GLASS:g}\nR=+{R_FRONT_MM:g} / {R_BACK_MM:g} mm",
            ha="center", color="#25445c", fontsize=10)
    ax.text(focus_z+1, BEAM_DIAMETER_MM*.50, "Paraxial\nfocus", color="#b44231")
    ax.text(-12, BEAM_DIAMETER_MM*.50, "Parallel\ninput", color="#374151")
    ax.set(xlim=(-14, image_z), ylim=(-BEAM_DIAMETER_MM*.69, BEAM_DIAMETER_MM*.78),
           xlabel="z from front vertex (mm)", ylabel="Ray height y (mm)",
           title="1  Refraction bends the rays toward the optical axis")
    ax.grid(alpha=.12)

    for a in (zoom,):
        a.axhline(0, color="#64748b", lw=.8)
        a.axvline(focus_z, color="#d24e36", ls="--", lw=1.5, label="Paraxial focus")
        a.scatter(crossings, np.zeros_like(crossings), c=colors[selected], s=28, zorder=4)
        span = max(abs(focus_z-marginal_focus_z), .25)
        a.set(xlim=(min(marginal_focus_z, focus_z)-.35*span, max(marginal_focus_z, focus_z)+.35*span),
              ylim=(-max(.18, .2*span), max(.18, .2*span)),
              xlabel="z from front vertex (mm)", ylabel="Ray height y (mm)",
              title="2  Edge rays focus earlier: spherical aberration")
        a.grid(alpha=.15); a.legend(loc="upper right", fontsize=9)

    notes.text(0, 1, "3  Two distances, two reference planes", fontsize=13, weight="bold", va="top")
    notes.text(0, .83,
               f"EFL = {efl:.4f} mm\nFrom rear principal plane H2 to paraxial focus\n\n"
               f"BFL = {bfl:.4f} mm\nFrom rear glass vertex to paraxial focus\n\n"
               f"H2 is at z = {rear_principal_z:.4f} mm\nRear vertex is at z = {THICKNESS_MM:g} mm\n\n"
               f"Thin-lens approximation: {thin_lens_efl:.4f} mm\nA useful approximation, not the thick-lens check.",
               va="top", fontsize=11, color="#26384c", linespacing=1.55)
    fig.savefig(OUTPUT / "single_lens_rays.png", dpi=160, facecolor=fig.get_facecolor())
    plt.close(fig)

    log = (f"PASS | Optiland {summary['version']} | Python {summary['python']}\n"
           f"EFL = {efl:.10f} mm; analytic thick-lens EFL = {analytic_efl:.10f} mm\n"
           f"BFL = {bfl:.10f} mm; analytic thick-lens BFL = {analytic_bfl:.10f} mm\n"
           f"Paraxial focus z = {focus_z:.10f} mm; marginal-ray focus z = {marginal_focus_z:.10f} mm\n"
           f"Near-axis real-ray focus error = {abs(near_axis_focus_z-focus_z):.3e} mm\n"
           f"Output: {OUTPUT}\n")
    (OUTPUT / "run.log").write_text(log, encoding="utf-8")
    print(log)


if __name__ == "__main__":
    main()
