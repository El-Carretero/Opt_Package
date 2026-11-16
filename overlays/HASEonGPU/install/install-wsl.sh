#!/usr/bin/env bash
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_STATE="${OPT_PACKAGE_STATE_ROOT:-$HOME/.local/share/Opt_Package}/HASEonGPU"
mkdir -p "$PROJECT_STATE/bootstrap" "$SOURCE_ROOT/install/logs"
exec > >(tee "$SOURCE_ROOT/install/logs/install.log") 2>&1
ARCHIVE="$SOURCE_ROOT/install/micromamba-linux-64-2.10.0.tar.bz2"
if [ ! -f "$ARCHIVE" ]; then curl -fL --retry 3 'https://github.com/mamba-org/micromamba-releases/releases/download/2.10.0-0/micromamba-linux-64.tar.bz2' -o "$ARCHIVE"; fi
(cd "$SOURCE_ROOT/install" && sha256sum -c micromamba.sha256)
tar -xjf "$ARCHIVE" -C "$PROJECT_STATE/bootstrap" bin/micromamba
MAMBA="$PROJECT_STATE/bootstrap/bin/micromamba"
export MAMBA_ROOT_PREFIX="$PROJECT_STATE/mamba"
ENV_PREFIX="$PROJECT_STATE/env"
"$MAMBA" create -y -p "$ENV_PREFIX" -f "$SOURCE_ROOT/install/conda-linux-64.lock"
"$MAMBA" env export -p "$ENV_PREFIX" --explicit > "$SOURCE_ROOT/install/logs/installed-conda-linux-64.lock"
mkdir -p "$PROJECT_STATE/source"
tar -C "$SOURCE_ROOT" --exclude='./.git' --exclude='./install' --exclude='./runtime' --exclude='./build' -cf - . | tar -C "$PROJECT_STATE/source" -xf -
"$MAMBA" run -p "$ENV_PREFIX" bash "$SOURCE_ROOT/install/build-wsl.sh" "$SOURCE_ROOT" "$PROJECT_STATE"
printf '%s\n' "$ENV_PREFIX" > "$SOURCE_ROOT/install/wsl-env-path.txt"
printf '\nHASEonGPU installed. Environment: %s\n' "$ENV_PREFIX"
