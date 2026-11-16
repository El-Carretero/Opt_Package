ENV["MPLCONFIGDIR"] = joinpath(dirname(@__DIR__), ".cache", "matplotlib")
using Luna
using Test
println("Julia version: ", VERSION)
println("Luna version: ", pkgversion(Luna))
Luna.set_fftw_mode(:estimate)
Luna.set_fftw_threads(1)
# Linear GNLSE propagation is a small conservation check of the real solver.
out = prop_gnlse(0.0, 0.001, [0.0, 0.0, -1e-26]; λ0=800e-9,
    τfwhm=30e-15, power=100.0, pulseshape=:gauss,
    λlims=(500e-9, 1200e-9), trange=400e-15, saveN=3,
    shotnoise=false, raman=false)
energy = Processing.energy(out)
@test all(isfinite, energy)
@test all(energy .> 0)
@test maximum(energy)/minimum(energy) < 1.001
println("PASS: finite GNLSE output and energy conserved to 0.1%.")
println("Output spectrum shape: ", size(out["Eω"]))
