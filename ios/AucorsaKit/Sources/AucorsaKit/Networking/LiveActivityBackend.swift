import Foundation

/// Registers Live Activity sessions with the backend in `backend/`, which
/// pushes fresh arrivals every 30 seconds while the app is suspended.
///
/// The backend is self-hosted, so only builds that name one get Live
/// Activities at all: see `configured`. Once a session runs, every call is
/// best-effort; if one fails, the activity refreshes while the app is open.
public struct LiveActivityBackend: Sendable {
    /// The APNs environment a push token belongs to.
    public enum Environment: String, Sendable {
        case sandbox, production

        /// Development-signed builds, including Release builds installed from
        /// Xcode, get sandbox tokens. App Store and TestFlight builds have no
        /// embedded provisioning profile and get production tokens.
        public static let current: Environment = {
            #if targetEnvironment(simulator)
            return .sandbox
            #else
            return Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
                .flatMap(apsEnvironment(inProfileAt:)) == "development" ? .sandbox : .production
            #endif
        }()

        static func apsEnvironment(inProfileAt url: URL) -> String? {
            // A CMS envelope around an XML plist; the plist is plain ASCII.
            guard let data = try? Data(contentsOf: url),
                  let profile = String(data: data, encoding: .isoLatin1),
                  let start = profile.range(of: "<?xml"),
                  let end = profile.range(of: "</plist>"),
                  let plist = try? PropertyListSerialization.propertyList(
                      from: Data(profile[start.lowerBound..<end.upperBound].utf8), format: nil
                  ) as? [String: Any],
                  let entitlements = plist["Entitlements"] as? [String: Any] else { return nil }
            return entitlements["aps-environment"] as? String
        }
    }

    /// The backend this build was given, or nil when Live Activities are off.
    ///
    /// The `personal` flavor sets `LiveActivityBackendHost` in Info.plist from
    /// the untracked `ios/LiveActivityBackend.xcconfig`. Other builds, including
    /// App Store ones, leave it empty and never contain a backend address.
    public static let configured: LiveActivityBackend? =
        (Bundle.main.object(forInfoDictionaryKey: "LiveActivityBackendHost") as? String)
            .flatMap(sessionsURL(host:))
            .map { LiveActivityBackend(baseURL: $0) }

    /// The sessions endpoint on a host such as
    /// `europe-west1-my-project.cloudfunctions.net`.
    static func sessionsURL(host: String) -> URL? {
        let host = host.trimmingCharacters(in: .whitespaces)
        // An unexpanded "$(...)" means the build setting was never defined.
        guard !host.isEmpty, !host.contains("$("), !host.contains("/"),
              let url = URL(string: "https://\(host)/liveActivitySessions"),
              url.host == host else { return nil }
        return url
    }

    private let session: URLSession
    private let baseURL: URL

    public init(session: URLSession? = nil, baseURL: URL) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 15
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
        self.baseURL = baseURL
    }

    private struct Registration: Encodable {
        let pushToken: String
        let apnsEnvironment: String
        let stopID: Int
        let lineID: String
        let stopName: String?
        let endsAt: Double
    }

    /// Starts server refreshes for a session, or updates its rotated push
    /// token. Safe to repeat: the backend never starts a second refresh chain.
    public func register(
        sessionID: String, pushToken: Data, environment: Environment = .current,
        stopID: Int, lineID: String, stopName: String?, endsAt: Double
    ) async throws {
        try await send("PUT", sessionID: sessionID, body: Registration(
            pushToken: pushToken.map { String(format: "%02x", $0) }.joined(),
            apnsEnvironment: environment.rawValue,
            stopID: stopID, lineID: lineID, stopName: stopName, endsAt: endsAt
        ))
    }

    /// Keeps pushed content using the stop's current custom name.
    public func rename(sessionID: String, stopName: String?) async throws {
        struct Rename: Encodable {
            let stopName: String?
            enum CodingKeys: CodingKey { case stopName }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                // `encode`, not `encodeIfPresent`: null clears the name.
                try container.encode(stopName, forKey: .stopName)
            }
        }
        try await send("PATCH", sessionID: sessionID, body: Rename(stopName: stopName))
    }

    /// Stops server refreshes. Repeating it, or calling it after the backend
    /// ended the session itself, is harmless.
    public func unregister(sessionID: String) async throws {
        try await send("DELETE", sessionID: sessionID)
    }

    private func send(_ method: String, sessionID: String, body: (any Encodable)? = nil) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(sessionID),
                                 cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw AucorsaError.serviceUnavailable(statusCode: nil)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(status) else {
            throw AucorsaError.serviceUnavailable(statusCode: status)
        }
    }
}
