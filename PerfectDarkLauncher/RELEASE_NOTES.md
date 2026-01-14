# Carrington for macOS

A native SwiftUI launcher for the Perfect Dark PC port, named after the Carrington Institute.

## Features

- 🎮 **Easy ROM Selection** - Drag & drop or browse for your ROM file
- 🖥️ **MacBook-Optimized Resolutions** - Preset resolutions for 16:10 displays (1440×900, 1680×1050, etc.)
- ⚙️ **Full Settings Control** - Video, game, audio, and player settings
- 🎯 **Trackpad Mode** - Optimized mouse sensitivity for trackpad users
- 🔲 **Retina/HiDPI Support** - Optional high-DPI rendering
- 🌍 **Multi-Region Support** - NTSC, PAL, and JPN ROM support
- 📦 **Self-Contained** - Bundled game executables and SDL2 framework

## Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon Mac (arm64)
- Perfect Dark ROM file (not included)
- Game data folder from the PC port

## Installation

1. Download and mount the DMG
2. Drag Carrington to Applications
3. Launch and select your ROM file
4. Ensure your ROM is in the same directory as the `data` folder
5. Configure settings and launch!

## Notes

- The launcher writes configuration to `~/Library/Application Support/perfectdark/pd.ini`
- Settings are applied before each launch
- Built with ❤️ for the Perfect Dark community
