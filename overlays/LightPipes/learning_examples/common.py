"""Small output helpers shared by the two beginner examples."""
from pathlib import Path
import csv
import json
import platform
from datetime import datetime, timezone

import os
os.environ["MPLCONFIGDIR"] = str(Path(__file__).resolve().parent / ".mplconfig")
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import LightPipes

HERE = Path(__file__).resolve().parent
plt.rcParams.update({
    "figure.facecolor": "#f6f8fb", "axes.facecolor": "white",
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.titlesize": 12, "axes.labelsize": 10, "font.size": 10,
    "grid.alpha": 0.22, "savefig.dpi": 170,
})


def output_folder(name):
    folder = HERE / "output" / name
    folder.mkdir(parents=True, exist_ok=True)
    return folder


def save_csv(path, columns, rows):
    with path.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(columns)
        writer.writerows(rows)


def save_checks(folder, parameters, measurements, checks):
    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "versions": {"python": platform.python_version(),
                     "LightPipes": LightPipes.__version__,
                     "numpy": np.__version__, "matplotlib": matplotlib.__version__},
        "parameters": parameters, "measurements": measurements,
        "checks": checks, "passed": all(item["passed"] for item in checks),
    }
    (folder / "results.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = [f"LightPipes {LightPipes.__version__} | {folder.name}"]
    for item in checks:
        lines.append(f"{'PASS' if item['passed'] else 'FAIL'} | {item['name']} | "
                     f"value={item['value']:.9g} | {item['criterion']}")
    lines.append("ALL CHECKS PASSED" if report["passed"] else "CHECKS FAILED: inspect parameters/grid.")
    text = "\n".join(lines) + "\n"
    (folder / "validation.log").write_text(text, encoding="utf-8")
    print(text, end="")
    print(f"Output: {folder}")
    if not report["passed"]:
        raise SystemExit(1)


def check_below(name, value, limit):
    return {"name": name, "value": float(value), "criterion": f"< {limit:g}",
            "passed": bool(value < limit)}


def check_above(name, value, limit):
    return {"name": name, "value": float(value), "criterion": f">= {limit:g}",
            "passed": bool(value >= limit)}


def image_extent(field, unit=1e-3):
    x = field.xvalues
    y = field.yvalues
    return [(x[0] - field.dx / 2) / unit, (x[-1] + field.dx / 2) / unit,
            (y[0] - field.dx / 2) / unit, (y[-1] + field.dx / 2) / unit]
