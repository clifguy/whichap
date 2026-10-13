import AppKit

enum MenuBarDisplayMode: String {
    case iconOnly, detailed
    static let preferenceKey = "menuBarDisplayMode"

    static func load(from defaults: UserDefaults = .standard) -> Self {
        Self(rawValue: defaults.string(forKey: preferenceKey) ?? "") ?? .iconOnly
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.preferenceKey)
    }
}

enum MenuBarIconState: CaseIterable {
    case connected, disconnected, poorSignal, internetProblem, permissionRequired, permissionPending

    static func resolve(locationAuthorized: Bool, permissionPending: Bool, connected: Bool,
                        poorSignal: Bool, internetProblem: Bool, checkInternet: Bool) -> Self {
        if !locationAuthorized { return permissionPending ? .permissionPending : .permissionRequired }
        if !connected { return .disconnected }
        if checkInternet && internetProblem { return .internetProblem }
        if poorSignal { return .poorSignal }
        return .connected
    }

    var statusDescription: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Not connected to Wi-Fi"
        case .poorSignal: return "Poor Wi-Fi signal"
        case .internetProblem: return "Internet access needs attention"
        case .permissionRequired: return "Location Services access required"
        case .permissionPending: return "Waiting for Location Services permission"
        }
    }
}

// Template images adapt to the menu bar's appearance and selection automatically.
// Cache all states once; Wi-Fi polls should not recreate the artwork.
enum MenuBarIcon {
    static let size = NSSize(width: 24, height: 18)
    private static let images = Dictionary(uniqueKeysWithValues: MenuBarIconState.allCases.map { ($0, draw($0)) })

    static func image(for state: MenuBarIconState) -> NSImage { images[state]! }

    private static func draw(_ state: MenuBarIconState) -> NSImage {
        let image = NSImage(size: size, flipped: false) { _ in
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            for (index, radius) in [6.0, 10.0, 14.0].enumerated() {
                let faint = state == .disconnected || state == .permissionPending || (state == .poorSignal && index > 0)
                NSColor.black.withAlphaComponent(faint ? 0.3 : 1).setStroke()
                let arc = NSBezierPath()
                arc.appendArc(withCenter: NSPoint(x: 10, y: 1.5), radius: radius,
                              startAngle: 50, endAngle: 130)
                arc.lineWidth = 2
                arc.lineCapStyle = .round
                arc.stroke()
            }
            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: 8.7, y: 0.2, width: 2.6, height: 2.6)).fill()

            if state == .disconnected {
                let slash = NSBezierPath()
                slash.move(to: NSPoint(x: 3, y: 2))
                slash.line(to: NSPoint(x: 16, y: 15))
                slash.lineWidth = 1.6
                slash.lineCapStyle = .round
                NSColor.black.setStroke()
                slash.stroke()
            }

            // Knock out the area behind the badge, then its lettering, so the
            // menu bar background shows through in every appearance.
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            NSBezierPath(roundedRect: NSRect(x: 12, y: 0, width: 12, height: 8), xRadius: 2, yRadius: 2).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSBezierPath(roundedRect: NSRect(x: 13, y: 0.5, width: 11, height: 7), xRadius: 1.5, yRadius: 1.5).fill()
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            ("AP" as NSString).draw(at: NSPoint(x: 14.1, y: 0.5), withAttributes: [
                .font: NSFont.systemFont(ofSize: 6.5, weight: .bold), .foregroundColor: NSColor.black
            ])
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            let marker: String?
            switch state {
            case .internetProblem, .permissionRequired: marker = "!"
            case .permissionPending: marker = "?"
            default: marker = nil
            }
            if let marker {
                (marker as NSString).draw(at: NSPoint(x: 20, y: 8), withAttributes: [
                    .font: NSFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: NSColor.black
                ])
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "WhichAP — \(state.statusDescription)"
        return image
    }
}
