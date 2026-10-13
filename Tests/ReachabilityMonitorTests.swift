import Foundation
import AppKit
import Network

// This file is combined with the verbatim production ReachabilityMonitor by the
// test runner. Only URLSession transport is replaced; no reachability logic is mocked.
enum InternetReachability { case unknown, reachable, unreachable, captive }
final class URLSessionDataTask {
    let request: URLRequest
    let completion: (Data?, URLResponse?, Error?) -> Void
    var cancelled = false
    init(_ request: URLRequest, _ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.request = request; self.completion = completion
    }
    func resume() {}
    func cancel() { cancelled = true }
    func reply(_ body: String = "Success", error: Error? = nil) {
        completion(Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil), error)
    }
}
final class URLSession {
    static let shared = URLSession()
    var tasks: [URLSessionDataTask] = []
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSessionDataTask(request, completionHandler); tasks.append(task); return task
    }
}

extension ReachabilityMonitor {
    static func runChecks() {
        var failures = 0
        func check(_ value: Bool, _ name: String) { if !value { failures += 1; print("FAIL: \(name)") } }
        func settle() { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
        func ipTasks() -> [URLSessionDataTask] { URLSession.shared.tasks.filter { $0.request.url?.host == "icanhazip.com" } }
        func ready() -> ReachabilityMonitor {
            URLSession.shared.tasks = []
            let m = ReachabilityMonitor(); m.isRunning = true; m.current = .reachable
            return m
        }
        let m = ready()
        m.networkAssociationChanged(); let interrupted = URLSession.shared.tasks.last!
        m.triggerProbe(refreshIP: false); URLSession.shared.tasks.last!.reply(); settle()
        check(interrupted.cancelled && m.current == .reachable, "periodic preempts event")
        check(ipTasks().count == 1, "periodic preserves pending IP refresh")
        m.triggerProbe(refreshIP: false); URLSession.shared.tasks.last!.reply(); settle()
        check(ipTasks().count == 1, "coalesce pending IP refresh")
        ipTasks().last?.reply("8.8.8.8"); settle()
        check(m.externalIP == "8.8.8.8", "refresh restores public IP")
        let providerTask = URLSession.shared.tasks.last!
        providerTask.reply("{\"ip\":\"8.8.8.8\",\"organization_name\":\"Google LLC\"}"); settle()
        check(m.externalProvider == "Google LLC", "refresh restores provider")
        for _ in 0..<3 { m.triggerProbe(refreshIP: false); URLSession.shared.tasks.last!.reply(); settle() }
        check(ipTasks().count == 1, "steady periodic probes skip IP")
        check(URLSession.shared.tasks.filter { $0.request.url?.host == "get.geojs.io" }.count == 1, "steady periodic probes skip provider")
        m.stop()

        let n = ready(); n.networkAssociationChanged()
        URLSession.shared.tasks.last!.reply(error: URLError(.timedOut)); settle()
        check(n.current == .reachable && n.consecutiveFailures == 1, "single probe failure retains reachability")
        n.triggerProbe(refreshIP: false); URLSession.shared.tasks.last!.reply(); settle()
        check(ipTasks().count == 1, "event timeout retries IP after periodic success")
        ipTasks().last?.reply(error: URLError(.timedOut)); settle()
        n.triggerProbe(refreshIP: false); URLSession.shared.tasks.last!.reply(); settle()
        check(ipTasks().count == 2, "IP timeout retains pending refresh")
        n.stop()

        let stale = ready(); stale.networkAssociationChanged()
        URLSession.shared.tasks.last!.reply(); settle()
        guard let oldIP = ipTasks().last else { check(false, "event starts IP request"); exit(1) }
        stale.networkAssociationChanged(); oldIP.reply("8.8.8.8"); settle()
        check(stale.externalIP == nil && stale.externalProvider == nil, "old network IP cannot repopulate")
        let last = URLSession.shared.tasks.last!; stale.stop(); last.reply(); settle()
        check(stale.externalIP == nil && stale.current == .unknown, "disabled monitor ignores late probe")

        let constrained = ready(); constrained.allowsProbes = false; constrained.networkAssociationChanged()
        check(URLSession.shared.tasks.isEmpty, "constrained association skips probes")
        constrained.stop()
        if failures > 0 { print("\(failures) reachability checks failed"); exit(1) }
        print("Reachability integration checks passed")
    }
}
@main struct ReachabilityChecks { static func main() { ReachabilityMonitor.runChecks() } }
