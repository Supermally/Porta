#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Apple Gaming Compatibility Runtime - Upstream Wine Synchronizer
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WINE_DIR="${RUNTIME_ROOT}/wine"
UPSTREAM_REMOTE="https://github.com/wine-mirror/wine.git"
DEFAULT_TAG="${1:-wine-9.0}"

echo "==> 🍷 Synchronizing upstream Wine repository..."
echo "    Target directory: ${WINE_DIR}"
echo "    Upstream remote:  ${UPSTREAM_REMOTE}"
echo "    Target tag/ref:   ${DEFAULT_TAG}"

if [ ! -d "${WINE_DIR}/.git" ]; then
    echo "==> Initializing wine submodule / repository tracking..."
    git clone --depth 1 --branch "${DEFAULT_TAG}" "${UPSTREAM_REMOTE}" "${WINE_DIR}"
else
    echo "==> Fetching latest tags from upstream..."
    cd "${WINE_DIR}"
    git fetch --tags "${UPSTREAM_REMOTE}"
    git checkout -f "${DEFAULT_TAG}"
fi

echo "==> ✅ Successfully synchronized upstream Wine at $(cd "${WINE_DIR}" && git rev-parse --short HEAD)"
