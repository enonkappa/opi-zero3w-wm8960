# OrangePi Zero 3W + Waveshare WM8960 Audio HAT

Working setup for Debian Bookworm / BSP kernel 6.6.98-sun60iw2.

## Files

| File | Purpose |
|------|---------|
| `sun60i-a733-wm8960.dts` | DTS overlay — enables WM8960 on I2S0 + TWI0 |
| `kernel-module/wm8960.c` | Kernel codec driver source |
| `kernel-module/wm8960.h` | Codec driver header |
| `kernel-module/Makefile` | Build against local BSP kernel tree |
| `etc/pulse/default.pa` | PulseAudio config (manual sinks, no udev-detect) |
| `boot/orangepiEnv.txt` | Boot overlay config |
| `alsa/wm8960-state.conf` | ALSA mixer saved state (alsactl restore) |
| `scripts/setup.sh` | Step-by-step setup script |

## Quick Start

See `scripts/setup.sh` for the full process.

### Key Points
- BSP kernel has **no simple-audio-card** — must use `sunxi-snd-mach`
- I2S slot width **must be 32-bit** (`s32le`); 16-bit = silence
- Disable `module-udev-detect` in PulseAudio — BSP platform cards have no UCM
- Disable PipeWire: `sudo systemctl --global mask pipewire pipewire-pulse wireplumber`
- WM8960 I2C address: `0x1a` on TWI0 (`/dev/i2c-0`)

## Hardware Connections

| Signal | SoC Pin | Header Pin |
|--------|---------|------------|
| MCLK   | PB4     | 7          |
| BCLK   | PB5     | 12         |
| LRCK   | PB6     | 35         |
| DOUT   | PB7     | 40         |
| DIN    | PB8     | 38         |
| SDA    | PB2     | 3          |
| SCL    | PB3     | 5          |

