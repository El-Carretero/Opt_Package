#!/usr/bin/env bash
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_STATE="${OPT_PACKAGE_STATE_ROOT:-$HOME/.local/share/Opt_Package}/FEniCSx"
export MAMBA_ROOT_PREFIX="$PROJECT_STATE/mamba"
cd "$SOURCE_ROOT"
exec "$PROJECT_STATE/bootstrap/bin/micromamba" run -p "$PROJECT_STATE/env" bash --norc -i
