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
from rayoptics.environment import OpticalModel, PupilSpec, FieldSpec, WvlSpec
opm=OpticalModel()
sm=opm['seq_model']; osp=opm['optical_spec']
sm.gaps[0].thi=1e10
osp['pupil']=PupilSpec(osp,key=['object','pupil'],value=10)
osp['fov']=FieldSpec(osp,key=['object','angle'],value=5,flds=[0,1])
osp['wvls']=WvlSpec([('d',1.0)],ref_wl=0)
opm.radius_mode=True
sm.add_surface([25.0,6.0,1.5,60.0]); sm.set_stop()
sm.add_surface([-75.0,34.0])
opm.update_model()
f=float(opm['analysis_results']['parax_data'].fod.efl)
assert 30<f<45, f
print("PASS: singlet paraxial calculation; focal length mm:",f)
from rayoptics.qtgui.rayopticsapp import main as gui_main
assert callable(gui_main)
print("PASS: GUI entry point imports")
