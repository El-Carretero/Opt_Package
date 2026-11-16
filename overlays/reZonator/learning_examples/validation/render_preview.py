"""Optional figure regeneration; requires matplotlib, not needed to run the .rez example.

All plotted numerical samples come from the native reZonator report.
"""
import json
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

example = Path(__file__).resolve().parents[1]
latest = json.loads((example / "validation/latest.json").read_text(encoding="utf-8"))
report = json.loads((example / latest["run"] / latest["report"]).read_text(encoding="utf-8"))
assert report["status"] == "PASS"
beam = report["planes"]["T"]["samples"]
stability = report["stability_samples"]
plt.rcParams.update({"font.size": 11, "axes.spines.top": False, "axes.spines.right": False})
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11, 4.1), constrained_layout=True)
x = [s["z_m"] * 1000 for s in beam]
y = [s["beam_radius_m"] * 1e6 for s in beam]
ax1.plot(x, y, color="#175d97", linewidth=2.5)
ax1.scatter([0, 50, 100], [y[0], y[50], y[-1]], color="#175d97", zorder=3)
ax1.annotate("waist 132.076 um", (50, y[50]), xytext=(25, 137), arrowprops={"arrowstyle":"->"})
ax1.annotate("mirror 152.508 um", (0, y[0]), xytext=(15, 151), arrowprops={"arrowstyle":"->"})
ax1.set(xlabel="Position from M1 (mm)", ylabel="Beam radius w (um)",
        title="Gaussian eigenmode: L = 100 mm", xlim=(0,100), ylim=(128,157))
ax1.grid(alpha=0.2)
ax2.axhspan(-1, 1, color="#d9eddf", alpha=0.65, label="strict stability: |s| < 1")
ax2.plot([s["length_m"]*1000 for s in stability], [s["stability_normal"] for s in stability],
         color="#175d97", linewidth=2.5, label="native reZonator")
ax2.scatter([100], [-0.5], color="#b74334", zorder=3)
ax2.annotate("example: (100, -0.5)", (100,-0.5), xytext=(40,0.3), arrowprops={"arrowstyle":"->"})
ax2.scatter([0,200,400],[1,-1,1],facecolors="white",edgecolors="#175d97",zorder=3)
ax2.set(xlabel="Mirror separation L (mm)", ylabel="s = (A+D)/2", title="R1 = R2 = 200 mm",
        xlim=(0,450), ylim=(-1.2,2.3))
ax2.grid(alpha=0.2)
ax2.legend(loc="upper left", fontsize=9)
fig.suptitle("reZonator beginner example | native C++ calculation", fontsize=14)
fig.savefig(example / "preview.png", dpi=170)
plt.close(fig)
