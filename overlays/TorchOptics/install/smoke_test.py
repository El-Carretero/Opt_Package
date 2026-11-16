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
import torch, torchoptics
from torchoptics import Field
from torchoptics.profiles import gaussian
device='cuda' if torch.cuda.is_available() else 'cpu'
torchoptics.set_default_spacing(10e-6)
torchoptics.set_default_wavelength(800e-9)
phase=torch.zeros((64,64),device=device,requires_grad=True)
amplitude=gaussian(64,waist_radius=100e-6).to(device)
f=Field(amplitude*torch.exp(1j*phase)).to(device)
g=f.propagate_to_z(.01)
loss=g.data.abs().square()[24:40,24:40].sum()
loss.backward()
assert torch.isfinite(g.data).all() and phase.grad is not None
assert torch.isfinite(phase.grad).all()
print('PASS:',device,'propagation and autograd;',torch.__version__,torch.cuda.get_device_name(0) if device=='cuda' else 'CPU fallback', 'loss=',loss.item())
