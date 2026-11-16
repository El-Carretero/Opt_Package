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
from diffractio import um,mm
from diffractio.scalar_sources_XY import Scalar_source_XY
x=np.linspace(-100*um,100*um,64)
f=Scalar_source_XY(x=x,y=x,wavelength=.8*um)
f.gauss_beam(r0=(0,0),w0=(25*um,25*um),z0=0)
g=f.RS(z=.1*mm,new_field=True,verbose=False)
assert g.u.shape==(64,64) and np.isfinite(g.u).all()
assert np.sum(np.abs(g.u)**2)>0
print("PASS: Gaussian Rayleigh-Sommerfeld propagation; grid",g.u.shape)
