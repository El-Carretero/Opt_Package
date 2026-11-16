"""Small native ASE solve on CPU and CUDA; checks finite positive fluorescence."""
import json
from pathlib import Path
import numpy as np
import HASEonGPU as h
from pyInclude.openpmd import backendFlat
from pyInclude.laser import CrossSectionData

topology = h.MeshTopology(
    np.array([[0., 0.], [1., 0.], [0., 1.]], dtype=np.float64),
    np.array([[0, 1, 2]], dtype=np.uint32), levels=2, thickness=1.0)
medium = h.GainMedium(topology).withPhysicalProperties(
    betaVolume=backendFlat(np.array([0.2], dtype=np.float64)),
    betaCells=backendFlat(np.full(6, 0.2, dtype=np.float64)),
    claddingCellTypes=np.array([0], dtype=np.uint32),
    refractiveIndices=np.array([1.5, 1.0, 1.5, 1.0], dtype=np.float32),
    reflectivities=backendFlat(np.zeros(2, dtype=np.float32)),
    nTot=1e20, crystalTFluo=1e-3, claddingNumber=99, claddingAbsorption=0.0)
cross_sections = CrossSectionData(
    wavelengthsAbsorption=np.array([900e-9]), crossSectionAbsorption=np.array([1e-22]),
    wavelengthsEmission=np.array([1000e-9]), crossSectionEmission=np.array([2e-21]), resolution=1)
available = h.AlpakaBackends.all()
chosen = ["Host_Cpu_CpuSerial"]
if "Cuda_NvidiaGpu_GpuCuda" in available:
    chosen.append("Cuda_NvidiaGpu_GpuCuda")
else:
    print("CPU-only build: CUDA execution is unavailable and is not tested.")
records = []
for backend in chosen:
    assert backend in available, (backend, available)
    solver = h.PhiASE(crossSections=cross_sections, minRaysPerSample=64, maxRaysPerSample=64,
        mseThreshold=0.5, repetitions=1, adaptiveSteps=1, useReflections=False,
        backend=backend, parallelMode="single", numDevices=1, minSampleRange=0,
        maxSampleRange=5, rngSeed=1234, openpmdBackend="hdf5")
    solver.run(gainMedium=medium)
    result = solver.getResults()
    values = np.asarray(result.phiAse)
    assert values.shape == (6,), values.shape
    assert np.all(np.isfinite(values)), values
    assert np.any(values > 0), values
    assert np.all(np.asarray(result.totalRays) > 0), result.totalRays
    record = {"backend": backend, "phiASE": values.tolist(), "totalRays": np.asarray(result.totalRays).tolist()}
    records.append(record)
    print("PASS", backend, "finite positive ASE for six mesh samples; phiASE range", float(values.min()), float(values.max()))
Path(__file__).with_name("logs").joinpath("smoke-results.json").write_text(json.dumps(records, indent=2))
print("HASEonGPU", h.__version__, "numerical smoke complete for", ", ".join(chosen))
