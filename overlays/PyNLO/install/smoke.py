import os
os.environ['MPLBACKEND']='Agg'
import numpy as np
import pynlo
p=pynlo.light.DerivedPulses.SechPulse(power=1,T0_ps=0.05,center_wavelength_nm=1550,time_window_ps=5,NPTS=256,frep_MHz=100,power_is_avg=False)
p.set_epp(1e-12)
f=pynlo.media.fibers.fiber.FiberInstance()
f.generate_fiber(1e-4,center_wl_nm=1550,betas=(-120,0,0),gamma_W_m=1,gvd_units='ps^n/km',gain=0)
s=pynlo.interactions.FourWaveMixing.SSFM.SSFM(local_error=0.01,disable_Raman=True,disable_self_steepening=True)
y,aw,at,out=s.propagate(pulse_in=p,fiber=f,n_steps=2)
assert np.isfinite(out.AT).all() and out.calc_epp()>0
print('PASS PyNLO SSFM propagation:',out.calc_epp(),'J')
