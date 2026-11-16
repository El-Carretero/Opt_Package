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
from LightPipes import Begin, GaussBeam, Forvard, Power, mm, nm
f=Begin(5*mm,800*nm,64)
f=GaussBeam(f,.5*mm)
p0=Power(f)
g=Forvard(f,.05)
p1=Power(g)
assert np.isfinite(g.field).all() and p0>0 and p1>0
assert abs(p1/p0-1)<1e-10,(p0,p1)
print("PASS: Gaussian FFT propagation; power ratio:",p1/p0)
