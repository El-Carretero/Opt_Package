import os
os.environ['MPLBACKEND']='Agg'
import numpy as np
from pyfiberamp.steady_state import SteadyStateSimulation
from pyfiberamp.fibers import YbDopedFiber
fiber=YbDopedFiber(length=0.1,core_radius=3e-6,ion_number_density=2e25,background_loss=0,core_na=0.12)
s=SteadyStateSimulation(fiber=fiber)
s.add_forward_signal(wl=1035e-9,input_power=2e-3)
s.add_forward_pump(wl=976e-9,input_power=300e-3)
s.add_ase(wl_start=1000e-9,wl_end=1080e-9,n_bins=4)
r=s.run(tol=1e-4)
assert np.isfinite(r.powers).all()
print('PASS PyFiberAmp Yb steady state:',r.powers.shape)
