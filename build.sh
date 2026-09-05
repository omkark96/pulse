#!/bin/bash
set -e

swift build -c release

APP="Pulse.app/Contents/MacOS"
mkdir -p "$APP"
cp .build/release/Pulse "$APP/"
cp Info.plist Pulse.app/Contents/

# Unregister stale local copy to prevent duplicate LS entries
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -u Pulse.app 2>/dev/null || true

mkdir -p ~/Applications
cp -R Pulse.app ~/Applications/

# Strip resource forks then ad-hoc sign
xattr -cr ~/Applications/Pulse.app
codesign --sign - --force --deep ~/Applications/Pulse.app

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -u ~/Applications/Pulse.app 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f ~/Applications/Pulse.app

echo "Done. Run with: open ~/Applications/Pulse.app"
