import Foundation

@main
struct ProviderLookupTests {
    static var failures = 0
    static func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        if !condition() { failures += 1; print("FAIL: \(name)") }
    }
    final class Fixture {
        var time = Date(timeIntervalSince1970: 1_000)
        var requests: [URLRequest] = []
        var completions: [ProviderLookup.Completion] = []
        var cancelled = 0
        lazy var lookup = ProviderLookup(now: { self.time }, transport: { req, done in
            self.requests.append(req); self.completions.append(done)
            return { self.cancelled += 1 }
        })
        func reply(_ index: Int, ip: String = "8.8.8.8", name: String = "Google LLC", status: Int = 200, headers: [String: String] = [:], overrideData: Data? = nil, error: Error? = nil) {
            let data = try! JSONSerialization.data(withJSONObject: ["ip": ip, "organization_name": name])
            let response = HTTPURLResponse(url: requests[index].url!, statusCode: status, httpVersion: nil, headerFields: headers)!
            completions[index](overrideData ?? data, response, error)
        }
    }
    static func main() {
        check(ProviderLookup.normalizedIP(" 2001:4860:4860:0:0:0:0:8888\n") == "2001:4860:4860::8888", "normalize IPv6")
        check(ProviderLookup.normalizedIP("not-an-ip") == nil, "reject invalid IP")
        let invalid = Fixture(); invalid.lookup.update(ip: "garbage")
        check(invalid.requests.isEmpty && invalid.lookup.provider == nil, "invalid IP never requests")
        let f = Fixture(); f.lookup.update(ip: "8.8.8.8")
        check(f.requests.count == 1, "first lookup requests once")
        if f.requests.count == 1 {
            check(f.requests[0].url?.absoluteString == "https://get.geojs.io/v1/ip/geo/8.8.8.8.json", "HTTPS exact-IP endpoint")
            check(f.requests[0].timeoutInterval == 5, "bounded timeout")
            f.lookup.update(ip: "8.8.8.8"); check(f.requests.count == 1, "coalesce pending request")
            var changes = 0; f.lookup.onChange = { changes += 1 }
            f.reply(0); check(changes == 1, "notify provider arrival"); check(f.lookup.provider == "Google LLC", "decode organization")
            f.lookup.invalidate(); f.lookup.update(ip: "8.8.8.8")
            check(f.requests.count == 1 && f.lookup.provider == "Google LLC", "reuse cache across roam")
            f.time.addTimeInterval(86400); f.lookup.update(ip: "8.8.8.8")
            check(f.requests.count == 2 && f.lookup.provider == nil, "expire cache at 24h")
        }
        let stale = Fixture(); stale.lookup.update(ip: "8.8.8.8"); stale.lookup.invalidate(); stale.lookup.update(ip: "1.1.1.1")
        check(stale.cancelled == 1, "cancel obsolete request")
        check(stale.requests.count == 2, "new IP starts fresh lookup")
        if stale.requests.count == 2 {
            stale.reply(0); check(stale.lookup.provider == nil, "reject late old response")
            stale.reply(1, ip: "1.1.1.1", name: "Cloudflare, Inc."); check(stale.lookup.provider == "Cloudflare, Inc.", "new network provider")
            stale.lookup.invalidate(clearCache: true); stale.lookup.update(ip: "1.1.1.1")
            check(stale.requests.count == 3 && stale.lookup.provider == nil, "disable clears cached state")
        }
        let bad = Fixture(); bad.lookup.update(ip: "8.8.8.8")
        check(bad.requests.count == 1, "bad fixture starts request")
        if !bad.requests.isEmpty {
            bad.reply(0, ip: "1.1.1.1"); check(bad.lookup.provider == nil, "reject mismatched response IP")
            bad.lookup.update(ip: "8.8.8.8"); check(bad.requests.count == 1, "failure backoff")
            bad.time.addTimeInterval(60); bad.lookup.update(ip: "8.8.8.8")
            check(bad.requests.count == 2, "retry after backoff")
        }
        let rate = Fixture(); rate.lookup.update(ip: "8.8.8.8")
        check(rate.requests.count == 1, "rate fixture starts request")
        if !rate.requests.isEmpty {
            rate.reply(0, status: 429, headers: ["Retry-After": "120"])
            rate.lookup.update(ip: "1.1.1.1"); check(rate.requests.count == 1, "429 cooldown spans IPs")
            rate.time.addTimeInterval(120); rate.lookup.update(ip: "1.1.1.1")
            check(rate.requests.count == 2, "429 retries only after deadline")
        }
        for mode in ["malformed", "unknown", "timeout", "http500"] {
            let x = Fixture(); x.lookup.update(ip: "8.8.8.8")
            check(x.requests.count == 1, "\(mode) fixture starts request")
            if !x.requests.isEmpty {
                switch mode {
                case "malformed": x.reply(0, overrideData: Data("<html>portal</html>".utf8))
                case "unknown": x.reply(0, name: "Unknown")
                case "timeout": x.reply(0, error: URLError(.timedOut))
                default: x.reply(0, status: 500)
                }
                x.lookup.update(ip: "8.8.8.8")
                check(x.lookup.provider == nil && x.requests.count == 1, "\(mode) preserves absence and backs off")
            }
        }
        for name in ["", "Acme\nInjected", String(repeating: "x", count: 257)] {
            let x = Fixture(); x.lookup.update(ip: "8.8.8.8")
            check(x.requests.count == 1, "name boundary fixture starts request")
            if !x.requests.isEmpty { x.reply(0, name: name); check(x.lookup.provider == nil, "reject unsafe or empty name") }
        }
        let bound = Fixture()
        for i in 1...33 {
            bound.time.addTimeInterval(1)
            let ip = "8.8.8.\(i)"; bound.lookup.update(ip: ip)
            if bound.requests.count == i { bound.reply(i - 1, ip: ip) }
        }
        bound.lookup.update(ip: "8.8.8.1")
        check(bound.requests.count == 34, "cache evicts after 32 entries")
        let v6 = Fixture(); v6.lookup.update(ip: "2001:4860:4860::8888")
        check(v6.requests.count == 1, "v6 fixture starts request")
        if !v6.requests.isEmpty { v6.reply(0, ip: "2001:4860:4860:0:0:0:0:8888"); check(v6.lookup.provider == "Google LLC", "IPv6 response equivalence") }
        check(ProviderPresentation.title(ip: "8.8.8.8", provider: "Google LLC") == "Provider: Google LLC", "explicit Provider label")
        check(ProviderPresentation.title(ip: nil, provider: "Old") == nil, "hide without current IP")
        check(ProviderPresentation.supportLines(ip: "8.8.8.8", provider: "Google LLC") == "Public IP: 8.8.8.8\nProvider: Google LLC\n", "copy support values")
        let long = String(repeating: "x", count: 100)
        check(ProviderPresentation.title(ip: "8.8.8.8", provider: long)?.count == 70, "bound long menu title")
        check(ProviderPresentation.supportLines(ip: "8.8.8.8", provider: long).contains(long), "copy full long provider")
        if failures > 0 { print("\(failures) failed checks"); exit(1) }
        print("Provider checks passed")
    }
}
