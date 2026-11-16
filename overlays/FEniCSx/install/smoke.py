from mpi4py import MPI
from petsc4py import PETSc
import dolfinx
from dolfinx import fem, mesh
from dolfinx.fem.petsc import LinearProblem
import ufl
import numpy as np

domain = mesh.create_unit_square(MPI.COMM_WORLD, 12, 12)
V = fem.functionspace(domain, ("Lagrange", 2))
u_exact = fem.Function(V)
u_exact.interpolate(lambda x: x[0] ** 2 + x[1] ** 2)
fdim = domain.topology.dim - 1
facets = mesh.locate_entities_boundary(domain, fdim, lambda x: np.full(x.shape[1], True))
dofs = fem.locate_dofs_topological(V, fdim, facets)
bc = fem.dirichletbc(u_exact, dofs)
u, v = ufl.TrialFunction(V), ufl.TestFunction(V)
a = ufl.inner(ufl.grad(u), ufl.grad(v)) * ufl.dx
L = fem.Constant(domain, PETSc.ScalarType(-4.0)) * v * ufl.dx
problem = LinearProblem(a, L, bcs=[bc], petsc_options_prefix="opt_sim_smoke_", petsc_options={"ksp_type": "preonly", "pc_type": "lu"})
uh = problem.solve()
local_error = fem.assemble_scalar(fem.form((uh-u_exact)**2 * ufl.dx))
error = np.sqrt(domain.comm.allreduce(local_error, op=MPI.SUM))
assert error < 1e-10, error
print(f"PASS DOLFINx {dolfinx.__version__}; 2D Poisson FEM solve L2 error={error:.3e}; PETSc {PETSc.Sys.getVersion()}")
