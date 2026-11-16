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
import os
os.chdir(Path(__file__).parent/"logs")
import pychi
from importlib.metadata import version
frequency=np.linspace(50e12,600e12,512)
n_eff=np.full(frequency.shape,1.45)
wg=pychi.materials.Waveguide(frequency,n_eff,0.0,0.0,1e-10,1e-5,t_pts=1024)
pulse=pychi.light.Gaussian(wg,50e-15,1e-12,1.03e-6)
model=pychi.models.Spm(wg,pulse)
solver=pychi.solvers.Solver(model,z_pts=3,local_error=1e-4)
solver.solve()
assert np.isfinite(pulse.waveform).all() and len(pulse.z_save)==3
print('PASS: short zero-nonlinearity pulse propagation; distribution version',version('pychi'))
