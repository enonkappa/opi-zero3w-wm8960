#!/bin/bash
# OrangePi Zero 3W + Waveshare WM8960 Audio HAT setup
# Tested: Debian Bookworm, BSP kernel 6.6.98-sun60iw2
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_VER=$(uname -r)

echo "=== Step 1: Install build deps ==="
sudo apt-get install -y build-essential linux-headers-$KERNEL_VER bc flex bison libssl-dev

echo ""
echo "=== Step 2: Build WM8960 kernel module ==="
# BSP kernel source must be at ~/kernel-src OR set KDIR env var
KDIR="${KDIR:-$HOME/kernel-src}"

if [ ! -d "$KDIR" ]; then
  echo "ERROR: Kernel source not found at $KDIR"
  echo "Clone the BSP kernel source and set KDIR= or place it at ~/kernel-src"
  exit 1
fi

mkdir -p /tmp/wm8960-build
cp "$REPO_DIR/kernel-module/wm8960.c" "$REPO_DIR/kernel-module/wm8960.h" \
   "$REPO_DIR/kernel-module/Makefile" /tmp/wm8960-build/

echo "#define UTS_RELEASE \"$KERNEL_VER\"" > "$KDIR/include/generated/utsrelease.h"
cd /tmp/wm8960-build
make KDIR="$KDIR" KBUILD_MODPOST_WARN=1
sudo cp snd-soc-wm8960.ko /lib/modules/$KERNEL_VER/extra/
sudo depmod -a
echo "Module installed: /lib/modules/$KERNEL_VER/extra/snd-soc-wm8960.ko"

echo ""
echo "=== Step 3: Install DTS overlay ==="
OVERLAY_DIR="/boot/dtb-$KERNEL_VER/allwinner/overlay"
dtc -@ -I dts -O dtb \
    -o /tmp/sun60i-a733-wm8960.dtbo \
    "$REPO_DIR/sun60i-a733-wm8960.dts"
sudo cp /tmp/sun60i-a733-wm8960.dtbo "$OVERLAY_DIR/"
echo "Overlay installed: $OVERLAY_DIR/sun60i-a733-wm8960.dtbo"

echo ""
echo "=== Step 4: Configure boot overlays ==="
# Ensure i2c0 and wm8960 overlays are enabled in orangepiEnv.txt
sudo cp "$REPO_DIR/boot/orangepiEnv.txt" /boot/orangepiEnv.txt
echo "Boot config updated: /boot/orangepiEnv.txt"
echo "  overlays=i2c0 wm8960 spi3-cs0-cs1-spidev"

echo ""
echo "=== Step 5: Disable PipeWire, use stock PulseAudio ==="
sudo systemctl --global mask pipewire pipewire-pulse pipewire.socket pipewire-pulse.socket wireplumber 2>/dev/null || true
sudo systemctl mask pipewire pipewire-pulse pipewire.socket pipewire-pulse.socket wireplumber 2>/dev/null || true
sudo apt-get install -y pulseaudio

echo ""
echo "=== Step 6: Install PulseAudio config ==="
sudo cp "$REPO_DIR/etc/pulse/default.pa" /etc/pulse/default.pa
echo "PulseAudio config installed."
echo "  - module-udev-detect disabled (BSP platform cards lack UCM)"
echo "  - Sinks: wm8960-speaker (s32le 48kHz), HDMI-Playback (s16le 44.1kHz)"
echo "  - Source: hyperx_solocast (16kHz mono) — remove if not using HyperX SoloCast 2"

echo ""
echo "=== Step 7: Restore ALSA mixer state ==="
# Reboot first, then run: sudo alsactl restore 1 -f alsa/wm8960-state.conf
echo "After reboot, run:"
echo "  sudo alsactl restore 1 -f '$REPO_DIR/alsa/wm8960-state.conf'"

echo ""
echo "=== All done. REBOOT required ==="
echo ""
echo "After reboot, verify:"
echo "  aplay -l                          # should show card sndwm8960"
echo "  i2cdetect -y 0                    # should show 1a at address 0x1a"
echo "  pactl list sinks short            # should show wm8960-speaker"
echo "  paplay /usr/share/sounds/alsa/Front_Left.wav  # test playback"
