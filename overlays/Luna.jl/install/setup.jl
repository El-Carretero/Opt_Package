ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"
import Pkg
Pkg.instantiate()
Pkg.build("PyCall")
Pkg.precompile()
println("Luna Julia environment instantiated and precompiled.")
