import Foundation
import AppKit

/// Measures native menu construction/layout, not mouse click-to-visible latency.
@main struct ProviderMenuPerformance {
    static func main() {
        _ = NSApplication.shared
        var samples: [Double] = []
        for _ in 0..<100 {
            autoreleasepool {
                let start = ProcessInfo.processInfo.systemUptime
                let menu = NSMenu()
                menu.addItem(withTitle: "Internet: reachable (2001:4860:4860::8888)", action: nil, keyEquivalent: "")
                let name = String(repeating: "Network operator ", count: 10)
                let title = ProviderPresentation.title(ip: "2001:4860:4860::8888", provider: name)!
                menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
                menu.addItem(withTitle: "Mac Uptime: 2d 4h", action: nil, keyEquivalent: "")
                precondition(menu.size.width > 0 && menu.size.height > 0)
                samples.append((ProcessInfo.processInfo.systemUptime - start) * 1000)
            }
        }
        let sorted = samples.sorted()
        print(String(format: "Native Provider menu construction/layout: n=%d first_ms=%.3f median_ms=%.3f p95_ms=%.3f max_ms=%.3f", samples.count, samples[0], sorted[50], sorted[95], sorted.last!))
    }
}
