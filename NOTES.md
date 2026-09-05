# Pulse — Dev Notes

## Inactive-display dimming (solved)

### Problem
Pulse text was brighter than native menu bar icons (Wi-Fi, clock, etc.) on the inactive/secondary display.

### Root cause (three layers of investigation)
1. **`isOnMainScreen` always returned `true`** — `NSStatusItem` has exactly one `NSStatusBarWindow`, and that window lives on `NSScreen.main`. The system *mirrors* the item to secondary display menu bars as an OS-managed copy. So `window?.screen == NSScreen.main` is always true; the inactive branch was dead code.

2. **`alphaValue` on the custom subview did nothing** — Setting `NSView.alphaValue` on our `MetricsView` only affected the original item on the main display. The system's mirror on the secondary display was not controlled by our view hierarchy at all.

3. **Custom `NSView` subview bypasses the system's inactive-dim pass** — macOS dims secondary-display menu bars at the compositor (window-layer) level. Native icons (Wi-Fi, Bluetooth, etc.) are all rendered as template `NSImage`s set on `NSStatusBarButton.image`. Template images go through the system's compositing path and receive the inactive-dim automatically. A custom `NSView` subview is composited after that pass and is skipped.

### Fix
Remove the custom `MetricsView` subview entirely. Instead, render metrics into an `NSImage` (with `isTemplate = true`) and set it as `statusItem.button?.image` every second.

```swift
let image = NSImage(size: ...)
image.isTemplate = true
image.lockFocus()
// draw text using NSAttributedString with NSColor.black
image.unlockFocus()
statusItem.button?.image = image
```

**Why template images work:**
- `isTemplate = true` tells AppKit this image should be treated as a mask, not literal pixels.
- AppKit recolors it correctly for dark/light mode.
- The system's inactive-display dim, click-highlight, and accessibility tints all apply automatically — exactly the same as Wi-Fi, battery, and every other native menu bar icon.

### What does NOT work (for reference)
| Approach | Why it fails |
|---|---|
| `NSColor.labelColor.withAlphaComponent(x)` in custom draw | Color alpha only affects the main-display item; mirror is uncontrolled |
| `view.alphaValue = x` on the subview | Same — mirror is uncontrolled |
| `window?.screen == NSScreen.main` check | `window` is always on main screen; check is always true |
| `NSWorkspace.didActivateApplicationNotification` + redraw | Notification fires correctly but there is nothing to redraw on the mirror |

---

## Architecture

| File | Role |
|---|---|
| `StatusBarController.swift` | Owns `NSStatusItem`, renders metrics to template image, drives 1-second timer |
| `SystemMetrics.swift` | Samples CPU %, battery %, and network KB/s via system APIs |
| `AppDelegate.swift` | Instantiates `StatusBarController`, keeps it alive |
| `run.sh` | Builds via SwiftPM, rsyncs binary into `Pulse.app`, restarts the process |

## Display modes
`DisplayMode` enum controls what is shown and the item width:
- `all` — CPU, BAT, ↓, ↑ (148 pt)
- `networkOnly` — ↓, ↑ (110 pt)
- `cpuOnly` — CPU (80 pt)
- `batteryOnly` — BAT (80 pt)

Selected via right-click menu; persists only for the session (no `UserDefaults` yet).
