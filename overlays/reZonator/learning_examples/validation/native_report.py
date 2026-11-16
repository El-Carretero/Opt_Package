"""Run inside reZonator's Custom Plot Function, never in standalone Python.

schema.round_trip() delegates to reZonator's native BeamCalculator.
The independent formulas below are reference checks, not replacement optics.
"""
import csv
import json
import math
import os
from pathlib import Path
import traceback

import rezonator as Z
import schema


def figure():
    return {"title": "Native cavity validation", "x_dim": Z.DIM_LINEAR,
            "x_title": "Position", "y_dim": Z.DIM_LINEAR, "y_title": "Beam radius"}


def _number(value):
    value = complex(value)
    assert abs(value.imag) < 1e-13, "Expected real ABCD matrix"
    return value.real


def _near(actual, expected, name):
    assert math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-14), (
        f"{name}: native={actual!r}, analytic={expected!r}")


def calculate():
    report_path = os.environ.get("OPT_SIM_LEARNING_REPORT")
    result = {"engine": "reZonator native C++ BeamCalculator via embedded schema module",
              "status": "FAILED"}
    try:
        assert schema.is_sw(), "Expected standing-wave resonator"
        assert schema.elem_count() == 3, "Expected two mirrors and one empty range"
        length = schema.elem("L")
        mirror1 = schema.elem("M1")
        mirror2 = schema.elem("M2")
        lam = schema.wavelength()
        cavity_length = length.length
        radius1, radius2 = mirror1.param("R"), mirror2.param("R")
        for actual, expected, label in [(lam, 632.8e-9, "wavelength"),
                                        (cavity_length, 0.1, "length"),
                                        (radius1, 0.2, "R1"), (radius2, 0.2, "R2"),
                                        (mirror1.param("Alpha"), 0, "angle1"),
                                        (mirror2.param("Alpha"), 0, "angle2")]:
            _near(actual, expected, label)

        rayleigh = math.sqrt(cavity_length / 2 * (radius1 - cavity_length / 2))
        waist = math.sqrt(lam * rayleigh / math.pi)
        g1, g2 = 1 - cavity_length/radius1, 1 - cavity_length/radius2
        stability = 2*g1*g2 - 1
        result["parameters_SI"] = {"lambda_m": lam, "L_m": cavity_length,
                                   "R1_m": radius1, "R2_m": radius2}
        result["analytic"] = {"g1": g1, "g2": g2, "g1_g2": g1*g2,
                              "stability_normal": stability, "stability_squared": 1-stability**2,
                              "rayleigh_length_m": rayleigh, "waist_radius_m": waist,
                              "mirror_radius_m": waist*math.sqrt(1+(cavity_length/2/rayleigh)**2)}
        result["planes"] = {}
        rows = []
        old_offset = length.offset
        try:
            for plane in ("T", "S"):
                rt = schema.round_trip(ref=length, plane=plane, inside=True)
                samples = []
                for index in range(101):
                    z = cavity_length * index / 100
                    length.offset = z
                    native_w = rt.beam_radius()
                    analytic_w = waist * math.sqrt(1 + ((z-cavity_length/2)/rayleigh)**2)
                    _near(native_w, analytic_w, f"{plane} w(z={z})")
                    samples.append({"z_m": z, "beam_radius_m": native_w})
                    rows.append([plane, z, native_w, analytic_w])
                length.offset = cavity_length / 2
                matrix = [_number(v) for v in rt.matrix()]
                a,b,c,d = matrix
                _near(a*d-b*c, 1, f"{plane} determinant")
                _near((a+d)/2, stability, f"{plane} stability")
                _near(rt.stabil_nor, stability, f"{plane} native stability")
                _near(rt.stabil_sqr, 1-stability**2, f"{plane} squared stability")
                result["planes"][plane] = {"center_round_trip_ABCD_SI": matrix,
                                          "stability_normal": rt.stabil_nor,
                                          "stability_squared": rt.stabil_sqr,
                                          "center_beam_radius_m": rt.beam_radius(),
                                          "samples": samples}
        finally:
            length.offset = old_offset
        stability_samples = []
        length.lock()
        try:
            rt = schema.round_trip(ref=length, plane="T")
            for length_mm in range(451):
                length_m = length_mm / 1000
                length.set_param("L", length_m)
                a,b,c,d = [_number(v) for v in rt.matrix()]
                native_s = (a+d)/2
                _near(native_s, 2*(1-length_m/radius1)*(1-length_m/radius2)-1,
                      f"Stability sweep L={length_mm} mm")
                stability_samples.append({"length_m": length_m, "stability_normal": native_s})
        finally:
            length.unlock()
        result["stability_samples"] = stability_samples
        result["checks"] = {"beam_radius_samples_per_plane": 101, "planes": 2,
                             "stability_sweep_samples": 451,
                             "relative_tolerance": 1e-10, "absolute_tolerance": 1e-14,
                             "native_reader_and_ABCD_and_Gaussian": "PASS"}
        result["status"] = "PASS"
        if report_path:
            csv_path = Path(report_path).with_name("native_beam_samples.csv")
            with csv_path.open("w", encoding="utf-8", newline="") as stream:
                writer = csv.writer(stream)
                writer.writerow(["plane", "position_m", "native_radius_m", "analytic_radius_m"])
                writer.writerows(rows)
        return [{"label": "Native T", "x": [s["z_m"] for s in result["planes"]["T"]["samples"]],
                 "y": [s["beam_radius_m"] for s in result["planes"]["T"]["samples"]]}]
    except Exception:
        result["error"] = traceback.format_exc()
        raise
    finally:
        if report_path:
            target = Path(report_path)
            temporary = target.with_suffix(".tmp")
            temporary.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
            temporary.replace(target)
