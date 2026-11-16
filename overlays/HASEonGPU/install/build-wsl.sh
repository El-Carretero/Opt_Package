#!/usr/bin/env bash
set -euo pipefail
SOURCE_ROOT="$1"
PROJECT_STATE="$2"
cd "$PROJECT_STATE/source"
if [ -f README.upstream.md ]; then cp README.upstream.md README.md; fi
export CMAKE_BUILD_PARALLEL_LEVEL=2
export CMAKE_PREFIX_PATH="$CONDA_PREFIX"
export CMAKE_ARGS="-DHASE_OPENPMD_PROVIDER=system -DDISABLE_MPI=ON -DHASE_NATIVE_OPTIMIZATIONS=OFF"
ALPAKA_ARCHIVE="$SOURCE_ROOT/install/alpaka3-58065f93.tar.gz"
if [ ! -f "$ALPAKA_ARCHIVE" ]; then curl -fL --retry 3 'https://codeload.github.com/alpaka-group/alpaka3/tar.gz/58065f933b3d46406c4abb7c74111567938a0ee6' -o "$ALPAKA_ARCHIVE"; fi
echo '7216ab9d5c6b1693cec0fed44d63a7030a70dc7731e359da329ebf8bdb940f7d  '"$ALPAKA_ARCHIVE" | sha256sum -c -
mkdir -p "$PROJECT_STATE/dependencies/alpaka3"
tar -xzf "$ALPAKA_ARCHIVE" -C "$PROJECT_STATE/dependencies/alpaka3" --strip-components=1
export CMAKE_ARGS="$CMAKE_ARGS -DFETCHCONTENT_SOURCE_DIR_ALPAKA=$PROJECT_STATE/dependencies/alpaka3"
if nvidia-smi -L >/dev/null 2>&1; then
  export CUDACXX="$CONDA_PREFIX/bin/nvcc"
  export CMAKE_ARGS="$CMAKE_ARGS -DHASE_SELECT_BACKEND_ALPAKA=OFF -DHASE_CUDA_ARCHITECTURES=native"
else
  unset CUDACXX
  export CMAKE_ARGS="$CMAKE_ARGS -DHASE_SELECT_BACKEND_ALPAKA=ON -Dalpaka_DEP_CUDA=OFF -Dalpaka_DEP_HIP=OFF -Dalpaka_DEP_ONEAPI=OFF -Dalpaka_DEP_OMP=ON -Dalpaka_EXEC_CpuSerial=ON"
  echo 'No NVIDIA GPU visible: selecting CPU backend. CUDA build tools remain isolated in this environment.'
fi
python -m pip install --no-deps --require-hashes -r "$SOURCE_ROOT/install/build-requirements.lock.txt"
python -m pip install --no-deps --no-build-isolation .
python -m pip freeze > "$SOURCE_ROOT/install/pip-freeze.txt"
python -c 'import HASEonGPU; print("HASEonGPU", HASEonGPU.__version__); print("Alpaka backends", HASEonGPU.AlpakaBackends.all()); print("openPMD backends", HASEonGPU.OpenPmdBackends.all())' | tee "$SOURCE_ROOT/install/logs/smoke.log"
OMP_NUM_THREADS=2 python "$SOURCE_ROOT/install/smoke.py" | tee -a "$SOURCE_ROOT/install/logs/smoke.log"
