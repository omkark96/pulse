# Pulse

<p align="center">
  CPU, battery, and network speed in the macOS menu bar.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-111111?style=flat-square" alt="macOS 13 or later">
  <img src="https://img.shields.io/badge/swift-5.9%2B-111111?style=flat-square" alt="Swift 5.9 or later">
</p>

## Features

- Shows CPU use.
- Shows battery level and charging state.
- Shows download and upload speed.
- Offers CPU-only, battery-only, network-only, and all-metrics modes.
- Uses a native macOS status item.
- Uses no third-party runtime dependencies.

## Requirements

- Apple Silicon Mac
- macOS 13 or later
- Xcode Command Line Tools

## Install from source

```bash
git clone https://github.com/omkark96/pulse.git
cd pulse
./build.sh
open ~/Applications/Pulse.app
```

`build.sh` creates an ad-hoc signed app and copies it to `~/Applications`.

macOS can show an unidentified developer warning because this build is not
notarized. Open the app from Finder once, or remove quarantine after download:

```bash
xattr -dr com.apple.quarantine ~/Applications/Pulse.app
```

## Homebrew

Pulse can use a custom Homebrew tap after you publish a release and a cask:

```bash
brew tap omkark96/pulse
brew install --cask --no-quarantine omkark96/pulse/pulse
```

The `--no-quarantine` flag is needed for an unsigned or ad-hoc signed build.

## Build

```bash
swift build -c release
```

To build and launch the local app bundle:

```bash
./run.sh
```

## Display modes

Right-click the Pulse status item to choose what it shows:

- Show All
- Only Network
- Only CPU
- Only Battery

## License

Pulse is available under the MIT License. See [LICENSE](LICENSE).
