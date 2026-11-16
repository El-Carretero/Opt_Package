from pathlib import Path
import sys
import os
os.environ["MPLCONFIGDIR"]=str(Path(__file__).resolve().parents[1]/".runtime"/"matplotlib")
_logfile=(Path(__file__).parent/'logs'/'smoke-test.log').open('w',encoding='utf-8')
class _Tee:
    def __init__(self,stream): self.stream=stream
    def write(self,text):
        self.stream.write(text); _logfile.write(text); _logfile.flush()
    def flush(self): self.stream.flush(); _logfile.flush()
sys.stdout=_Tee(sys.stdout)
sys.stderr=_Tee(sys.stderr)
import numpy as np
from optiland.optic import Optic
lens=Optic()
lens.surfaces.add(index=0, thickness=float("inf"))
lens.surfaces.add(index=1,radius=25,thickness=6,material="N-BK7",is_stop=True)
lens.surfaces.add(index=2,radius=-75,thickness=34)
lens.surfaces.add(index=3)
lens.set_aperture(aperture_type="EPD",value=10)
lens.fields.set_type("angle")
lens.fields.add(y=0)
lens.wavelengths.add(value=.587,is_primary=True)
rays=lens.trace(0,0,.587,num_rays=3)
f=float(lens.paraxial.f2())
assert 30<f<45, f
assert np.isfinite(rays.x).all() and np.isfinite(rays.y).all()
print("PASS: singlet ray trace; focal length mm:",f)
from optiland_gui.run_gui import main as gui_main
assert callable(gui_main)
print("PASS: GUI entry point imports")
