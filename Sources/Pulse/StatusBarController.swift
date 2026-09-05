import AppKit

enum DisplayMode: String, CaseIterable {
    case all          = "Show All"
    case networkOnly  = "Only Network"
    case cpuOnly      = "Only CPU"
    case batteryOnly  = "Only Battery"

    var itemWidth: CGFloat {
        switch self {
        case .all:         return 148
        case .networkOnly: return 110
        case .cpuOnly:     return 80
        case .batteryOnly: return 80
        }
    }
}

class StatusBarController: NSObject {

    private let statusItem = NSStatusBar.system.statusItem(withLength: DisplayMode.all.itemWidth)
    private let metrics = SystemMetrics()
    private var mode: DisplayMode = .all {
        didSet {
            statusItem.length = mode.itemWidth
            updateMenuCheckmarks()
        }
    }

    private var modeMenuItems: [DisplayMode: NSMenuItem] = [:]

    // Current metric strings.
    private var cpuStr  = ""
    private var batStr  = ""
    private var downStr = ""
    private var upStr   = ""

    private let font         = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    private let rightColWidth: CGFloat = 72
    private let lineH: CGFloat = 12

    override init() {
        super.init()
        setupMenu()
        setupButton()

        _ = metrics.sample()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateMetrics()
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateMetrics()
            }
        }
    }

    // MARK: - Image rendering

    // Render current metrics into an NSImage sized to the status item button.
    // Using button.image (not a custom subview) means the system automatically
    // applies the same inactive-display dimming it uses for Wi-Fi and other icons.
    private func renderImage() -> NSImage {
        let width = mode.itemWidth
        let height = NSStatusBar.system.thickness

        // Use template rendering so the system recolors for dark/light mode and
        // applies the inactive-display dim pass that affects all native icons.
        let image = NSImage(size: NSSize(width: width, height: height))
        image.isTemplate = true

        image.lockFocus()

        let appearance = NSApp.effectiveAppearance
        appearance.performAsCurrentDrawingAppearance {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black  // template image: black = opaque; system tints it
            ]

            switch mode {
            case .all:
                let totalH = lineH * 2
                let baseY = (height - totalH) / 2
                let rightX = width - rightColWidth - 4
                drawStr(cpuStr,  attrs: attrs, at: NSPoint(x: 4, y: baseY + lineH))
                drawStr(batStr,  attrs: attrs, at: NSPoint(x: 4, y: baseY))
                drawStrRight(downStr, attrs: attrs, in: NSRect(x: rightX, y: baseY + lineH, width: rightColWidth, height: lineH))
                drawStrRight(upStr,   attrs: attrs, in: NSRect(x: rightX, y: baseY,          width: rightColWidth, height: lineH))

            case .networkOnly:
                let totalH = lineH * 2
                let baseY = (height - totalH) / 2
                drawStr(downStr, attrs: attrs, at: NSPoint(x: 4, y: baseY + lineH))
                drawStr(upStr,   attrs: attrs, at: NSPoint(x: 4, y: baseY))

            case .cpuOnly:
                let baseY = (height - lineH) / 2
                drawStr(cpuStr, attrs: attrs, at: NSPoint(x: 4, y: baseY))

            case .batteryOnly:
                let baseY = (height - lineH) / 2
                drawStr(batStr, attrs: attrs, at: NSPoint(x: 4, y: baseY))
            }
        }

        image.unlockFocus()
        return image
    }

    private func drawStr(_ s: String, attrs: [NSAttributedString.Key: Any], at point: NSPoint) {
        NSAttributedString(string: s, attributes: attrs).draw(at: point)
    }

    private func drawStrRight(_ s: String, attrs: [NSAttributedString.Key: Any], in rect: NSRect) {
        let str = NSAttributedString(string: s, attributes: attrs)
        str.draw(at: NSPoint(x: rect.maxX - str.size().width, y: rect.minY))
    }

    private func refreshImage() {
        statusItem.button?.image = renderImage()
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
    }

    private func setupMenu() {
        let menu = NSMenu()

        for m in DisplayMode.allCases {
            let item = NSMenuItem(title: m.rawValue, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = m
            item.state = (m == mode) ? .on : .off
            menu.addItem(item)
            modeMenuItems[m] = item
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let selected = sender.representedObject as? DisplayMode else { return }
        mode = selected
        refreshImage()
    }

    private func updateMenuCheckmarks() {
        for (m, item) in modeMenuItems {
            item.state = (m == mode) ? .on : .off
        }
    }

    // MARK: - Metrics

    private func updateMetrics() {
        let s = metrics.sample()

        cpuStr = "CPU \(s.cpu)%"
        if let pct = s.battery {
            batStr = s.isPluggedIn ? "BAT \(pct)%+" : "BAT \(pct)%"
        } else {
            batStr = "BAT --"
        }
        downStr = "↓ \(formatSpeed(s.downKBps))"
        upStr   = "↑ \(formatSpeed(s.upKBps))"

        refreshImage()
    }

    private func formatSpeed(_ kbps: Double) -> String {
        if kbps < 1000 {
            return String(format: "%.1f KB/s", kbps)
        } else {
            return String(format: "%.1f MB/s", kbps / 1000)
        }
    }
}
