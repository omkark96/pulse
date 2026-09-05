#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building..."
swift build -c release

echo "Copying app bundle..."
mkdir -p Pulse.app/Contents/MacOS
cp .build/release/Pulse Pulse.app/Contents/MacOS/Pulse
cp Info.plist Pulse.app/Contents/Info.plist

echo "Restarting Pulse..."
pkill -f "Pulse.app/Contents/MacOS/Pulse" 2>/dev/null || true
sleep 0.3
open Pulse.app

echo "Done. Pulse is running."
