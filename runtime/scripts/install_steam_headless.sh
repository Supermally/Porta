#!/bin/bash
set -e

WRAPPER="$HOME/Applications/Sikarugir/Steam.app"
LAUNCH="$WRAPPER/Contents/MacOS/Sikarugir"
PLIST="$WRAPPER/Contents/Info.plist"
STEAM_SETUP="$HOME/Library/Application Support/MacGaming/prefixes/steam_test/SteamSetup.exe"

# If Steam isn't installed yet, copy it or run silent installer
if [[ ! -f "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/steam.exe" ]]; then
  echo "==> Setting up Steam files in wrapper..."
  mkdir -p "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam"
  if [[ -d "$HOME/Library/Application Support/MacGaming/prefixes/steam_test/drive_c/Program Files (x86)/Steam" ]]; then
    echo "==> Reusing downloaded Steam client from existing prefix..."
    cp -R "$HOME/Library/Application Support/MacGaming/prefixes/steam_test/drive_c/Program Files (x86)/Steam/"* "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/"
  fi
fi

echo "==> Configuring wrapper with D3DMetal..."
plutil -replace "D3DMETAL" -integer 1 "$PLIST"
plutil -replace "Program Name and Path" -string "/Program Files (x86)/Steam/Steam.exe" "$PLIST"
plutil -replace "Skip Gecko" -integer 1 "$PLIST"
plutil -replace "Skip Mono"  -integer 1 "$PLIST"

echo "==> Ready!"
