import AppKit

@main
struct MenuBarDisplayTests {
    static func main() {
        var failures = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            if !value() { print("FAIL: \(message)"); failures += 1 }
        }
        let suite = "WhichAP.MenuBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        check(MenuBarDisplayMode.load(from: defaults) == .iconOnly, "absent preference defaults to icon only")
        defaults.set(true, forKey: "geekMode")
        check(defaults.bool(forKey: "geekMode"), "legacy Geek preference is present in the fixture")
        check(MenuBarDisplayMode.load(from: defaults) == .iconOnly, "legacy Geek mode does not override the new default")
        MenuBarDisplayMode.detailed.save(to: defaults)
        check(MenuBarDisplayMode.load(from: UserDefaults(suiteName: suite)!) == .detailed, "detailed choice survives a fresh defaults instance")
        MenuBarDisplayMode.iconOnly.save(to: defaults)
        check(MenuBarDisplayMode.load(from: defaults) == .iconOnly, "switching back persists")
        defaults.set("invalid", forKey: MenuBarDisplayMode.preferenceKey)
        check(defaults.string(forKey: MenuBarDisplayMode.preferenceKey) == "invalid", "unknown saved mode is present in the fixture")
        check(MenuBarDisplayMode.load(from: defaults) == .iconOnly, "unknown saved mode safely defaults to icon")

        func state(authorized: Bool = true, pending: Bool = false, connected: Bool = true,
                   poor: Bool = false, internet: Bool = false, checking: Bool = false) -> MenuBarIconState {
            MenuBarIconState.resolve(locationAuthorized: authorized, permissionPending: pending,
                                     connected: connected, poorSignal: poor, internetProblem: internet,
                                     checkInternet: checking)
        }
        check(state() == .connected, "healthy connection")
        check(state(connected: false) == .disconnected, "disconnected")
        check(state(poor: true) == .poorSignal, "poor signal")
        check(state(internet: true) == .connected, "internet warnings disabled")
        check(state(internet: true, checking: true) == .internetProblem, "enabled internet warning")
        check(state(poor: true, internet: true, checking: true) == .internetProblem, "internet problem takes precedence over poor signal")
        check(state(authorized: false, poor: true) == .permissionRequired, "permission problem takes precedence over stale connection")
        check(state(authorized: false, pending: true, connected: false) == .permissionPending, "initial permission state")
        var rendered = Set<Data>()
        for state in MenuBarIconState.allCases {
            let image = MenuBarIcon.image(for: state)
            check(image.size == NSSize(width: 24, height: 18), "fixed image dimensions: \(state)")
            check(image.isTemplate, "appearance-aware template: \(state)")
            check(image === MenuBarIcon.image(for: state), "cached artwork: \(state)")
            check(image.accessibilityDescription?.contains(state.statusDescription) == true, "image accessibility status: \(state)")
            if let data = image.tiffRepresentation {
                rendered.insert(data)
            } else { check(false, "renderable image: \(state)") }
        }
        // Location and internet problems share the attention marker; the tooltip explains the cause.
        check(rendered.count == 5, "healthy, disconnected, poor, attention, and pending artwork differ")
        // Render the real production artwork for inspection without screen access.
        if let path = ProcessInfo.processInfo.environment["WHICHAP_ICON_PREVIEW"] {
            let canvas = NSImage(size: NSSize(width: 720, height: 200), flipped: false) { _ in
                NSColor.white.setFill()
                NSRect(x: 0, y: 100, width: 720, height: 100).fill()
                NSColor(calibratedWhite: 0.15, alpha: 1).setFill()
                NSRect(x: 0, y: 0, width: 720, height: 100).fill()
                for (i, state) in MenuBarIconState.allCases.enumerated() {
                    let image = MenuBarIcon.image(for: state).copy() as! NSImage
                    image.isTemplate = false
                    image.draw(in: NSRect(x: 24 + i * 120, y: 140, width: 72, height: 54))
                    let whiteImage = NSImage(size: image.size, flipped: false) { rect in
                        image.draw(in: rect)
                        NSColor.white.setFill()
                        rect.fill(using: .sourceAtop)
                        return true
                    }
                    whiteImage.draw(in: NSRect(x: 24 + i * 120, y: 40, width: 72, height: 54))
                    (String(describing: state) as NSString).draw(at: NSPoint(x: 5 + i * 120, y: 115), withAttributes: [.font: NSFont.systemFont(ofSize: 10)])
                }
                return true
            }
            let bitmap = NSBitmapImageRep(data: canvas.tiffRepresentation!)!
            try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
        }
        if failures > 0 { exit(1) }
        print("All menu bar display checks passed")
    }
}
