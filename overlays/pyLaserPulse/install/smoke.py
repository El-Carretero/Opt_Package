import os
os.environ['MPLBACKEND']='Agg'
os.environ['QT_QPA_PLATFORM']='offscreen'
import numpy as np
from pyLaserPulse import grid,pulse
from pyLaserPulse import catalogue_components as cc
g=grid.grid(1030e-9,(950e-9,1100e-9),4e-12,verbose=False)
p=pulse.pulse(200e-15,[10,0.1],'sech',1e6,g)
assert np.isfinite(p.field).all() and np.sum(abs(p.field)**2)>0
p.get_energy_and_average_power(g,p.field)
print('PASS pyLaserPulse grid/pulse energy:',p.pulse_energy,'J',g.points,'points')
