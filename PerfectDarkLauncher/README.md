# Carrington

A native macOS launcher application for the Perfect Dark PC Port, named after the Carrington Institute.

## Features

- **ROM Selection**: Drag & drop or browse to select your Perfect Dark ROM file (.z64 format)
- **Region Detection**: Automatically detects ROM region (NTSC, PAL, JPN) or manually select
- **Video Settings**:
  - Custom resolution with preset options
  - Fullscreen and exclusive fullscreen modes
  - VSync control (Off, On, Adaptive)
  - Anti-aliasing (MSAA) up to 8×
  - Texture filtering options (Nearest, Linear, 3-Point N64-like)
  - Framerate limiting
- **Game Settings**:
  - Skip intro videos
  - HUD positioning modes
  - Screen shake intensity
  - Memory size allocation
  - GoldenEye-style muzzle flashes
  - Explosion count limits
- **Player Settings**:
  - Custom field of view (FOV)
  - Mouse aim mode and sensitivity
- **Audio Settings**:
  - Sound enable/disable
- **Advanced Settings**:
  - Custom executable and data paths
  - Direct config file access

## Requirements

- macOS 12.0 (Monterey) or later
- Perfect Dark ROM file in .z64 format (NTSC v1.1, PAL, or JPN)
- Built Perfect Dark PC Port executable

## Building the Game

Before using the launcher, you need to build the Perfect Dark port:

```bash
cd /path/to/perfect_dark
mkdir build && cd build
cmake ..
make -j$(sysctl -n hw.ncpu)
```

The executable will be created in the build directory.

## Building the Launcher

Open `PerfectDarkLauncher.xcodeproj` in Xcode and build (⌘B) or:

```bash
cd PerfectDarkLauncher
xcodebuild -project PerfectDarkLauncher.xcodeproj -scheme PerfectDarkLauncher -configuration Release
```

## Usage

1. Launch the Perfect Dark Launcher
2. Select your ROM file (drag & drop or click to browse)
3. Verify the ROM region is correct
4. Configure video, game, and player settings as desired
5. Click "Launch Game"

The launcher will:
- Create/update the `pd.ini` configuration file
- Set up the ROM file path
- Launch the game with your settings

## Configuration

Settings are saved automatically and persist between sessions. The launcher stores its preferences in macOS user defaults.

Game-specific settings are written to `pd.ini` in the game's working directory.

## Troubleshooting

**"Game executable not found"**: Either build the game or specify the executable path in Advanced settings.

**"ROM file not found"**: Ensure your ROM file exists at the specified path and is in .z64 format.

**"Wrong ROM file"**: Make sure you're using a valid Perfect Dark ROM (NTSC v1.1, PAL, or JPN) in big-endian (.z64) format.

## License

This launcher is provided as part of the Perfect Dark PC Port project.
