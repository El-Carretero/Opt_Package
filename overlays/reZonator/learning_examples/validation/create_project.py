"""Recreate only this tutorial's native .rez file using the upstream example format."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]

def parameter(value, unit):
    return {"error": "", "expr": "", "unit": unit, "value": value}

def element(kind, label, title, params):
    return {"is_disabled": False, "label": label, "layout_draw_alt": False,
            "layout_show_label": True, "params": params, "title": title, "type": kind}

def window(xmax, ymin, ymax, ylabel):
    return {"cursor_enabled": True, "cursor_mode": "Both", "stored_views": {},
            "t_title": "", "ts_flipped": False, "ts_mode": "T+S",
            "x_min": 0, "x_max": xmax, "x_unit": "mm", "x_title": "L {(unit)}",
            "y_min": ymin, "y_max": ymax, "y_unit": "mm", "y_title": ylabel}

def arg(stop, points):
    return {"element_index": 1, "param": "L", "range": {"points": points,
            "start": {"unit": "mm", "value": 0}, "step": {"unit": "mm", "value": 1},
            "stop": {"unit": "mm", "value": stop}, "use_step": False}}

mirror_params = {"Alpha": parameter(0, "deg"), "R": parameter(200, "mm")}
caustic_window = window(100, 0.12, 0.16, "Beam radius w {(unit)}")
caustic_window["x_title"] = "Position from M1 {(unit)}"
stability_window = window(450, -1.1, 2.3, "(A+D)/2")
stability_window["y_unit"] = "none"
stability_window["stab_bound_markers"] = True
project = {
    "builtin_params": {"lambda": {"unit": "nm", "value": 632.8}},
    "custom_params": {},
    "elements": [element("ElemCurveMirror", "M1", "Left concave mirror", mirror_params),
                 element("ElemEmptyRange", "L", "Air / vacuum gap", {"L": parameter(100, "mm"), "n": parameter(1, "none")}),
                 element("ElemCurveMirror", "M2", "Right concave mirror", mirror_params)],
    "formulas": [], "notes": "Basic Gaussian optics: symmetric cavity, L=100 mm, R1=R2=200 mm, lambda=632.8 nm. See learning_examples/README.md.",
    "param_links": [], "pumps": [], "schema_version": "2.1", "title": "01 - Symmetric spherical-mirror cavity",
    "trip_type": "SW",
    "windows": [
        {"type": "Caustic", "function": {"arg": arg(100, 101), "mode": "BeamRadius"}, "window": caustic_window},
        {"type": "StabMap", "function": {"arg": arg(450, 451), "stab_calc_mode": "Normal"}, "window": stability_window}
    ]
}
(root / "01_symmetric_cavity.rez").write_text(json.dumps(project, indent=2), encoding="utf-8")
