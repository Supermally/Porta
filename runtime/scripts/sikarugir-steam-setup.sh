#!/usr/bin/env bash
#
# Windows Steam on Apple Silicon via Sikarugir — automated setup.
#
# Builds a self-contained Sikarugir wrapper running the Windows Steam client with
# D3DMetal (DirectX 11 + 12 on Metal). Everything is done from the CLI; the
# Sikarugir GUI is never needed.
#
# THE ONE THING THAT MATTERS: use engine WS12WineSikarugir10.0_6.
# The CrossOver-derived WS12WineCX24.0.7_7 fails with "Unexpected Transport
# Error (0x3008)" — its Steam client rejects its own steamwebhelper during the
# local handshake. Same wrapper, same prefix, same Steam install: only the
# engine matters.
#
# Requirements: Apple Silicon, macOS 14+ (Sonoma), Rosetta 2, Homebrew, ~12 GB free.
# NOT required: Python, Node, Xcode, CLT, Vulkan SDK, MoltenVK, winetricks,
# CrossOver license. The wrapper ships its own Wine, MoltenVK and D3DMetal.
#
# Verified on: MacBook Air (Mac14,2), Apple M2, 16 GB, macOS 26.5.2 (arm64),
# Homebrew 6.0.12, Sikarugir Creator 1.0.1, Template-1.0.11, Steam build
# 1784778118 (July 2026). Heroes of Might & Magic: Olden Era installs and plays
# on this setup (FPS numbers: will add).
#
# Verification status, precisely: steps 1-5 were run from scratch into a
# throwaway wrapper (fresh assembly + fresh prefix, both fine); steps 6-7 and a
# full idempotent re-run were verified against a working wrapper; every command
# here was also executed by hand first. The one path not machine-verified is a
# single uninterrupted run on a machine with no Sikarugir at all.
#
# Two steps need mouse clicks: the Steam installer wizard and the Steam login.
# The script pauses and tells you exactly what to click.
#
# Usage:  ./sikarugir-steam-setup.sh
# Re-runnable: existing downloads are reused; an existing wrapper is left alone
# unless you pass --rebuild.
#
# You must already own the game on Steam. This makes a game you bought run on
# hardware it was not built for; it does not obtain games and does not touch
# payment, DRM, anti-cheat or region locks.
#
# Nobody supports the result: not the author, not the Wine project, not Valve,
# not Ubisoft or the game's developers, not Sikarugir. A Steam, game, macOS or
# engine update can break it at any time, with no one obliged to fix it. If you
# need something that keeps working, buy CrossOver.
#
# Licensed under CC0 / public domain. No warranty. That covers this script and
# the accompanying docs only — it grants nothing regarding Sikarugir, Wine,
# Steam or any game. Sikarugir itself currently ships without a licence file.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Engine and template versions. Current lists:
#   https://raw.githubusercontent.com/Sikarugir-App/Engines/main/EngineList.txt
#   https://raw.githubusercontent.com/Sikarugir-App/Wrapper/main/NewestVersion.txt
ENGINE="WS12WineSikarugir10.0_6"
TEMPLATE="Template-1.0.11"

# Where the wrapper is built. One wrapper = one self-contained Windows install,
# so override this to keep several side by side:
#   WRAPPER=~/Applications/Sikarugir/Steam2.app ./sikarugir-steam-setup.sh
WRAPPER="${WRAPPER:-$HOME/Applications/Sikarugir/Steam.app}"

# Sikarugir Creator's own cache dir; putting downloads here means the GUI also
# sees them as already fetched.
CACHE="$HOME/Library/Application Support/Sikarugir"

ENGINE_URL="https://github.com/Sikarugir-App/Engines/releases/download/v1.0/${ENGINE}.tar.xz"
TEMPLATE_URL="https://github.com/Sikarugir-App/Wrapper/releases/download/v1.0/${TEMPLATE}.tar.xz"
STEAM_URL="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"
STEAM_SETUP="$HOME/Applications/Sikarugir/SteamSetup.exe"

REBUILD=0
case "${1:-}" in
  --rebuild) REBUILD=1 ;;
  "")        ;;
  *)         printf 'Usage: %s [--rebuild]\n' "$0" >&2; exit 2 ;;
esac

say()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }
# Waits for Enter when run interactively; with no terminal on stdin (CI, a pipe,
# an agent shell) it just prints the note and carries on — the GUI steps it
# guards are blocking anyway.
pause() {
  printf '\n\033[1;35m[?]\033[0m %s\n' "$*"
  if [[ -t 0 ]]; then
    printf '    Press Enter when done… '
    read -r _ || true
  else
    printf '    (non-interactive: continuing)\n'
  fi
}

# ---------------------------------------------------------------------------
# Step 1 — Prerequisites
# ---------------------------------------------------------------------------

say "Step 1/7 — checking prerequisites"

[[ "$(uname -m)" == "arm64" ]] || die "Apple Silicon required (got $(uname -m))."

# macOS 14+ (the cask declares depends_on macos: :sonoma).
macos_major="$(sw_vers -productVersion | cut -d. -f1)"
(( macos_major >= 14 )) || die "macOS 14 (Sonoma) or later required (got $(sw_vers -productVersion))."

command -v brew >/dev/null || die "Homebrew required: https://brew.sh"

# Wine executes x86 code, so Rosetta 2 is mandatory even though the wrapper
# binary itself is universal. oahd is the Rosetta daemon.
if ! /usr/bin/pgrep -q oahd; then
  warn "Rosetta 2 not detected — installing (needs your password)."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

# Wrapper ~1.2 GB + Steam ~1.5 GB + a 6.5 GB game. Ask for 12 GB.
free_gb="$(df -g / | awk 'NR==2 {print $4}')"
(( free_gb >= 12 )) || warn "Only ${free_gb} GB free; 12 GB recommended (game alone is 6.56 GB)."

printf '    arch=%s  macOS=%s  free=%sGB  rosetta=ok\n' \
  "$(uname -m)" "$(sw_vers -productVersion)" "$free_gb"

# ---------------------------------------------------------------------------
# Step 2 — Install Sikarugir Creator
# ---------------------------------------------------------------------------

say "Step 2/7 — installing Sikarugir Creator"

if [[ -d "/Applications/Sikarugir Creator.app" ]]; then
  echo "    already installed"
else
  # Homebrew 6.x refuses third-party taps until they are explicitly trusted.
  # The cask itself is minimal: it strips the quarantine flag, ad-hoc re-signs
  # the bundle and creates ~/Applications/Sikarugir. No pkg, no sudo, no launch
  # agents. Note the app is NOT notarized (ad-hoc signature, no Team ID), which
  # is why quarantine has to go — you are trusting the project, not Apple.
  brew trust Sikarugir-App/sikarugir
  brew install --cask Sikarugir-App/sikarugir/sikarugir
fi

# ---------------------------------------------------------------------------
# Step 3 — Fetch engine + template
# ---------------------------------------------------------------------------

say "Step 3/7 — fetching engine and wrapper template"

mkdir -p "$CACHE/Engines" "$CACHE/Template" "$HOME/Applications/Sikarugir"

fetch() {  # fetch <url> <dest>  — skip if already present and non-empty
  local url="$1" dest="$2"
  if [[ -s "$dest" ]]; then
    echo "    cached: $(basename "$dest")"
  else
    echo "    downloading: $(basename "$dest")"
    curl -fL --progress-bar -o "$dest" "$url"
  fi
}

fetch "$ENGINE_URL"   "$CACHE/Engines/${ENGINE}.tar.xz"     # ~159 MB
fetch "$TEMPLATE_URL" "$CACHE/Template/${TEMPLATE}.tar.xz"  # ~81 MB

# ---------------------------------------------------------------------------
# Step 4 — Assemble the wrapper
# ---------------------------------------------------------------------------

say "Step 4/7 — assembling the wrapper"

if [[ -d "$WRAPPER" && $REBUILD -eq 0 ]]; then
  echo "    $WRAPPER exists — keeping it (pass --rebuild to start over)"
else
  [[ $REBUILD -eq 1 ]] && { warn "--rebuild: deleting $WRAPPER"; rm -rf "$WRAPPER"; }

  # A wrapper is just a directory: the template .app with a Wine engine dropped
  # into Contents/SharedSupport/wine.
  tmp="$(mktemp -d)"
  tar -xf "$CACHE/Template/${TEMPLATE}.tar.xz" -C "$tmp"
  cp -R "$tmp/${TEMPLATE}.app" "$WRAPPER"
  tar -xf "$CACHE/Engines/${ENGINE}.tar.xz" -C "$WRAPPER/Contents/SharedSupport"
  mv "$WRAPPER/Contents/SharedSupport/wswine.bundle" "$WRAPPER/Contents/SharedSupport/wine"
  rm -rf "$tmp"

  echo "    engine: $(cat "$WRAPPER/Contents/SharedSupport/wine/version")"
fi

LAUNCH="$WRAPPER/Contents/MacOS/Sikarugir"

# The launcher is a full CLI, which is why no GUI is needed:
#   WSS-wineprefixcreate   create/refresh the prefix
#   WSS-installer <file>   run a Windows installer inside the wrapper
#   WSS-winecfg            winecfg
#   WSS-winetricks <verb>  winetricks
#   WSS-wineserverkill     kill all wine processes in this wrapper
#   config                 the GUI config app
#   debug                  run and keep logs

# ---------------------------------------------------------------------------
# Step 5 — Create the Wine prefix
# ---------------------------------------------------------------------------

say "Step 5/7 — creating the Wine prefix"

if [[ -d "$WRAPPER/Contents/drive_c/windows" ]]; then
  echo "    prefix already present"
else
  # A wineboot window may flash; that is normal.
  "$LAUNCH" WSS-wineprefixcreate
fi

# You need BOTH Program Files trees: the Steam client is 32-bit, games are
# 64-bit, so this must be a 64-bit prefix with WoW64.
[[ -d "$WRAPPER/Contents/drive_c/Program Files (x86)" ]] \
  || die "Prefix looks wrong: no 'Program Files (x86)'."

# ---------------------------------------------------------------------------
# Step 6 — Install the Windows Steam client
# ---------------------------------------------------------------------------

say "Step 6/7 — installing the Windows Steam client"

# This is the WINDOWS client. A native macOS Steam does not help: Windows-only
# games have no macOS depots, so they cannot even be installed by it. You will
# log in again and download games again inside this wrapper.

if [[ -f "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/steam.exe" ]]; then
  echo "    Steam already installed in the wrapper"
else
  fetch "$STEAM_URL" "$STEAM_SETUP"
  file "$STEAM_SETUP" | grep -q 'PE32 executable' \
    || die "SteamSetup.exe is not a Windows binary — download failed?"

  pause "The Steam installer will open. Keep the DEFAULT path
    C:\\Program Files (x86)\\Steam, and UNTICK 'Run Steam' at the end.
    (If a Mono/Gecko prompt appears, click Cancel — Steam needs neither.)"

  "$LAUNCH" WSS-installer "$STEAM_SETUP"

  [[ -f "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/steam.exe" ]] \
    || die "steam.exe not found — did you change the install path?"
fi

# ---------------------------------------------------------------------------
# Step 7 — Configure the wrapper
# ---------------------------------------------------------------------------

say "Step 7/7 — configuring the wrapper (D3DMetal + target EXE)"

# All wrapper settings live in Contents/Info.plist, so plutil replaces the GUI.
PLIST="$WRAPPER/Contents/Info.plist"
# Keep the pristine template plist: on a re-run the current file is already modified.
[[ -f "$PLIST.bak" ]] || cp "$PLIST" "$PLIST.bak"

# D3DMETAL is the only backend with DirectX 12 on Apple Silicon (WineD3D is
# DX11-and-below, VKD3D is partial DX12). DXVK/DXMT must stay off — they
# conflict with it. MOLTENVKCX / WINEESYNC / WINEMSYNC are already on in the
# template; leave them alone.
plutil -replace "D3DMETAL" -integer 1 "$PLIST"

# Target EXE. Paths are relative to drive_c (the default is "/nothing.exe").
plutil -replace "Program Name and Path" -string "/Program Files (x86)/Steam/Steam.exe" "$PLIST"

# Suppress two useless installer prompts; Steam needs neither.
plutil -replace "Skip Gecko" -integer 1 "$PLIST"
plutil -replace "Skip Mono"  -integer 1 "$PLIST"

# NOT set on purpose: Program Flags. Old forum posts recommend
# "-allosarches -cef-force-32bit"; -cef-force-32bit no longer exists in
# steam.exe at all, so it is a no-op, not a fix.

# `|| true`: a non-matching grep would abort the script under `set -e`.
plutil -p "$PLIST" | grep -Ei 'D3DMETAL|DXVK|DXMT|Program Name|Skip ' || true

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

# A stale wineserver would keep the old configuration alive, so kill it before
# launching. Only when one is actually running: otherwise the launcher prints a
# harmless but alarming `ERROR: "lockfile" couldn't be removed.` (on stdout).
if pgrep -qf "$WRAPPER/Contents/SharedSupport/wine/.*wineserver"; then
  "$LAUNCH" WSS-wineserverkill >/dev/null 2>&1 || true
fi

say "Done — launching Steam"

cat <<EOF

  First run takes a few minutes: the 2024 bootstrapper downloads the current
  client (the Steam folder grows ~9 MB -> ~110 MB+). The window may look
  frozen. Then log in.

  Recommended in Steam, both are common crash sources under Wine:
    Settings > Interface  -> disable "Enable GPU accelerated rendering in web views"
    Game Properties       -> disable Steam Overlay

  Launch later with:   open "$WRAPPER"
  Logs / debugging:    "$LAUNCH" debug
                       tail -30 "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/logs/transport_client.txt"
                       tail -30 "$WRAPPER/Contents/drive_c/Program Files (x86)/Steam/logs/connection_log.txt"

EOF

pause "Ready to launch?"
open "$WRAPPER"
