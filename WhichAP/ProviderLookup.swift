import Foundation
import Darwin

/// Main-thread-owned enrichment; callbacks and mutations stay on that thread.
/// Cache is memory-only and bounded so public-IP history does not persist to disk.
final class ProviderLookup {
    typealias Completion = (Data?, HTTPURLResponse?, Error?) -> Void
    typealias Transport = (URLRequest, @escaping Completion) -> (() -> Void)
    private struct Entry { let name: String?; let expires: Date }
    private struct Payload: Decodable { let ip: String; let organization_name: String }
    private let now: () -> Date
    private let transport: Transport
    private var cache: [String: Entry] = [:]
    private var currentIP: String?
    private var cancel: (() -> Void)?
    private var generation = UUID()
    private var cooldown = Date.distantPast
    private(set) var provider: String? {
        didSet { if oldValue != provider { onChange?() } }
    }
    var onChange: (() -> Void)?

    init(now: @escaping () -> Date = Date.init, transport: Transport? = nil) {
        self.now = now
        self.transport = transport ?? { request, done in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async { done(data, response as? HTTPURLResponse, error) }
            }
            task.resume()
            return { task.cancel() }
        }
    }

    func update(ip: String?) {
        precondition(Thread.isMainThread)
        guard let ip = ip.flatMap(Self.normalizedIP) else { invalidate(); return }
        if currentIP != ip { invalidate(); currentIP = ip }
        guard cancel == nil else { return }
        let date = now()
        if let entry = cache[ip], entry.expires > date { provider = entry.name; return }
        provider = nil
        guard cooldown <= date else { return }
        cache = cache.filter { $0.value.expires > date }
        if cache.count >= 32, let oldest = cache.min(by: { $0.value.expires < $1.value.expires })?.key {
            cache.removeValue(forKey: oldest)
        }
        let token = generation
        var request = URLRequest(url: URL(string: "https://get.geojs.io/v1/ip/geo/\(ip).json")!)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("WhichAP", forHTTPHeaderField: "User-Agent")
        cancel = transport(request) { [weak self] data, response, error in
            guard let self, self.generation == token, self.currentIP == ip else { return }
            self.cancel = nil
            let date = self.now()
            if response?.statusCode == 429 {
                // Apply service-wide cooldown: changing IP must not evade throttling.
                let value = response?.value(forHTTPHeaderField: "Retry-After") ?? ""
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
                let interval = TimeInterval(value) ?? formatter.date(from: value)?.timeIntervalSince(date) ?? 60
                self.cooldown = date.addingTimeInterval(max(60, interval.isFinite ? interval : 60))
            }
            var name: String?
            if error == nil, response?.statusCode == 200, let data, data.count <= 64 * 1024,
               let payload = try? JSONDecoder().decode(Payload.self, from: data),
               Self.normalizedIP(payload.ip) == ip {
                let cleaned = payload.organization_name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty, cleaned.lowercased() != "unknown", cleaned.count <= 256,
                   cleaned.rangeOfCharacter(from: .controlCharacters) == nil {
                    name = cleaned
                }
            }
            self.cache[ip] = Entry(name: name, expires: date.addingTimeInterval(name == nil ? 60 : 86400))
            self.provider = name
        }
    }

    func invalidate(clearCache: Bool = false) {
        precondition(Thread.isMainThread)
        generation = UUID()
        cancel?(); cancel = nil
        currentIP = nil
        provider = nil
        if clearCache { cache.removeAll() }
        // Retain a service cooldown even when checking is disabled/re-enabled.
    }

    static func normalizedIP(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        for family in [AF_INET, AF_INET6] {
            var bytes = [UInt8](repeating: 0, count: 16)
            guard inet_pton(family, value, &bytes) == 1 else { continue }
            var output = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            guard inet_ntop(family, &bytes, &output, socklen_t(output.count)) != nil else { return nil }
            return String(cString: output)
        }
        return nil
    }
}

enum ProviderPresentation {
    static func title(ip: String?, provider: String?) -> String? {
        guard ip != nil, let provider else { return nil }
        let display = provider.count > 60 ? String(provider.prefix(59)) + "…" : provider
        return "Provider: \(display)"
    }
    static func supportLines(ip: String?, provider: String?) -> String {
        guard let ip else { return "" }
        return "Public IP: \(ip)\n" + (provider.map { "Provider: \($0)\n" } ?? "")
    }
}
