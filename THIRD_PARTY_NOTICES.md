# Third-party source and dependencies

Opt_Package is an installation collection. It downloads each upstream source at
the full commit recorded in `packages.lock.json`; it does not claim authorship
of those projects or change their licenses. Downloaded source retains upstream
LICENSE/COPYING files, and the installer preserves an upstream README before
adding its local guide.

The original orchestration code and newly authored examples are MIT licensed.
Any upstream material copied into `overlays` retains its original copyright
and license. Changes to reZonator source are under its upstream GPL license;
the overlay contains its license, the changed source files, and a reviewable
patch against the recorded commit. Its native executable is built locally.

Python, uv, Julia, Octave, Qt, MinGW, Graphviz, Microsoft runtimes, NVIDIA CUDA,
conda packages, pip packages and other dependencies have their own licenses.
They are obtained from the original release or package distribution endpoints
by the installers. This repository does not grant additional rights to them.

modelock_sim's recorded source snapshot does not contain a LICENSE file.
Opt_Package records its upstream URL and downloads the requested source for
local use; it does not redistribute that upstream source in this repository.

Review the upstream license and dependency notices before redistributing an
installed environment. Source URLs, commit IDs, versions and verification
hashes are recorded in the lock files and project-specific installer metadata.
