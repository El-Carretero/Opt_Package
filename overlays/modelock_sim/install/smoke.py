import os,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
os.chdir(root);sys.path.insert(0,str(root))
os.environ['MPLBACKEND']='Agg'
import numpy as np
import calc_diode_capi
from cavity import CavityDataPartsKerr
c=CavityDataPartsKerr();c.parameters[0].value=64;c.finalize();c.restart(123)
for i in range(3):c.simulation_step()
assert np.isfinite(c.Ew).all()
print('PASS modelock_sim: CPU DLL and 3 Kerr cavity round trips, bins=',c.n)
from starlette.testclient import TestClient
from app import app
with TestClient(app) as client:
 r=client.get('/')
 assert r.status_code==200, r.status_code
print('PASS modelock_sim web root HTTP 200')
