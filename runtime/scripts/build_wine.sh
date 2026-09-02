#!/bin/bash
set -e

echo "Building Porta Wine (ARM64 & WoW64)"
cd "$(dirname "$0")/../wine"

# Basic configure for new WoW64 mode on macOS
./configure \
    --enable-archs=arm64,x86_64 \
    --without-x \
    --without-oss \
    --without-alsa \
    --without-capi \
    --without-dbus \
    --without-fontconfig \
    --without-gphoto \
    --without-gstreamer \
    --without-v4l2

echo "Configure complete. Building..."
make -j$(sysctl -n hw.ncpu)
echo "Build complete!"
