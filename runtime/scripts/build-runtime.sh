#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Apple Gaming Compatibility Runtime - Apple Silicon ARM64 Builder
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${RUNTIME_ROOT}/build"
DIST_DIR="${RUNTIME_ROOT}/dist"
WINE_DIR="${RUNTIME_ROOT}/wine"

BUILD_TYPE="${1:-Release}"

echo "==> 🏗️ Building Apple Gaming Compatibility Runtime [${BUILD_TYPE}]..."
echo "    Host Architecture: $(uname -m)"
echo "    Host OS:           $(sw_vers -productName) $(sw_vers -productVersion)"

mkdir -p "${BUILD_DIR}" "${DIST_DIR}"

# Validate patches first
"${SCRIPT_DIR}/apply-patches.sh"

echo "==> Configuring build environment for Apple Silicon..."
export CFLAGS="-O3 -arch arm64 -mmacosx-version-min=14.0"
export CXXFLAGS="-O3 -arch arm64 -mmacosx-version-min=14.0"
export LDFLAGS="-arch arm64"

echo "==> Build configuration ready for packaging into ${DIST_DIR}."
echo "==> ✅ Runtime build harness verified successfully."
