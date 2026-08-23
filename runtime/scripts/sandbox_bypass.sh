#!/bin/bash
# MacGaming Runtime - Stage 4 Chromium Sandbox Bypass
# This script injects DYLD_INSERT_LIBRARIES to intercept Chromium's Windows Sandbox checks
# and satisfy them while ignoring macOS App Sandbox restrictions.

export DYLD_INSERT_LIBRARIES="/opt/macgaming/lib/libsandbox_bypass.dylib"
export CHROMIUM_DISABLE_SANDBOX_CHECK=1
export CROS_OZONE_DRM=1

echo "[MacGaming] Sandbox restrictions neutralized. Chromium executing freely."
exec "$@"
