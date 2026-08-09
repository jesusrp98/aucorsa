import Foundation

/// Caches the WordPress nonce the estimations endpoint requires.
///
/// Worth caching because obtaining one means downloading the entire AUCORSA
/// homepage. Doing that on every Siri invocation would be wasteful on cellular
/// and slow enough to matter against Siri's response budget.
///
/// Upstream nonces live around 24 hours; the TTL here is deliberately shorter,
/// and an expired nonce is caught by the 403 retry in `AucorsaClient` anyway.
struct NonceStore: Sendable {
    static let ttl: TimeInterval = 6 * 60 * 60

    private let valueKey = "aucorsa.nonce.value"
    private let dateKey = "aucorsa.nonce.storedAt"

    /// Falls back to standard defaults so the client still works before the App
    /// Group is provisioned (it just does not share the nonce with the app).
    private var defaults: UserDefaults { AppGroup.defaults ?? .standard }

    func load(now: Date = Date()) -> String? {
        guard
            let value = defaults.string(forKey: valueKey),
            !value.isEmpty
        else { return nil }

        let storedAt = Date(
            timeIntervalSince1970: defaults.double(forKey: dateKey)
        )
        guard now.timeIntervalSince(storedAt) < Self.ttl else { return nil }

        return value
    }

    func save(_ nonce: String, now: Date = Date()) {
        defaults.set(nonce, forKey: valueKey)
        defaults.set(now.timeIntervalSince1970, forKey: dateKey)
    }

    func invalidate() {
        defaults.removeObject(forKey: valueKey)
        defaults.removeObject(forKey: dateKey)
    }
}
