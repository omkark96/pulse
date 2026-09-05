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

You do not need Xcode or the Xcode Command Line Tools to install the released app.

## Install with Homebrew

To install the latest release, add the Pulse tap and install the cask:

```bash
brew tap omkark96/pulse
brew install --cask omkark96/pulse/pulse
```

Homebrew trusts an explicitly requested cask on current versions. If Homebrew
reports that the cask is not trusted, trust only this cask:

```bash
brew trust --cask omkark96/pulse/pulse
```

Pulse is ad-hoc signed and not notarized. If macOS blocks the first launch,
open the app from Finder once, or remove its quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Pulse.app
open -a Pulse
```

## Display modes

Right-click the Pulse status item to choose what it shows:

- Show All
- Only Network
- Only CPU
- Only Battery

## License

Pulse is available under the MIT License. See [LICENSE](LICENSE).
