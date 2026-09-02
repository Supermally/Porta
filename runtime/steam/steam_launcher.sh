#!/bin/bash
# Porta Runtime - Stage 5 Steam Launcher
# Automates the execution of Steam.exe and steamwebhelper.exe within the Porta Wine prefix

export WINEPREFIX="${WINEPREFIX:-$HOME/Library/Application Support/Porta/prefixes/steam_test}"
export WINE_OPENGL_CORE=1
export WINE_RETINA=1

# Inject Stage 4 Chromium Sandbox bypass for steamwebhelper.exe
#export DYLD_INSERT_LIBRARIES="/opt/porta/lib/libsandbox_bypass.dylib"

# Enable Apple Silicon optimisations for translation
export DXVK_FILTER_DEVICE_NAME="Apple M"
export DXVK_ENABLE_NVAPI=1

STEAM_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steam.exe"

if [ ! -f "$STEAM_EXE" ]; then
    echo "[Steam] Steam not installed. Launching SteamSetup.exe..."
    SETUP_EXE="$WINEPREFIX/SteamSetup.exe"
    if [ -f "$SETUP_EXE" ]; then
        wine "$SETUP_EXE"
        exit 0
    else
        echo "[Steam] Error: SteamSetup.exe not found at $SETUP_EXE"
        exit 1
    fi
fi

echo "[Steam] Launching Windows Steam natively via Porta Runtime..."
# -no-cef-sandbox satisfies Chromium, -vgui is sometimes needed for legacy UI, but we want modern web UI
wine "$STEAM_EXE" -no-cef-sandbox "$@"
