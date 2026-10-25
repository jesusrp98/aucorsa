import Foundation
import os

/// Talks to the AUCORSA endpoints the app already uses.
///
/// Port of `lib/common/cubits/bus_service_cubit.dart`. Deliberately duplicated
/// rather than bridged through Flutter: intents run headlessly, often from a
/// cold process, where booting a Flutter engine is both slow and unavailable.
public actor AucorsaClient {
    public static let shared = AucorsaClient()

    private static let homepageURL = URL(string: "https://aucorsa.es/")!
    private static let estimationsURL = URL(
        string: "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop"
    )!
    private static let noncePattern = try! NSRegularExpression(
        pattern: #""ajax_nonce"\s*:\s*"([^"]+)""#
    )

    private static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "AucorsaClient"
    )

    private let session: URLSession
    private let nonceStore: NonceStore

    public init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            // Siri gives an intent a limited budget; failing fast and saying so
            // beats spinning until the system kills the request.
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 20
            configuration.waitsForConnectivity = false
            // Arrival responses and pages containing a nonce must not be
            // replayed from URLSession's persistent HTTP cache.
            configuration.urlCache = nil
            // This is a public, anonymous WordPress API. Cookies from other
            // app web sessions can make its public nonce fail validation.
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
            self.session = URLSession(configuration: configuration)
        }
        self.nonceStore = NonceStore()
    }

    init(session: URLSession, nonceStore: NonceStore) {
        self.session = session
        self.nonceStore = nonceStore
    }

    // MARK: - Public API

    /// Arrival estimations for a stop, in the app's line display order.
    ///
    /// An empty array is a valid answer: roughly one stop in six has no service
    /// at any given moment ("Sin estimaciones" upstream).
    public func estimations(forStop stopID: Int) async throws -> [BusStopLineEstimation] {
        let html = try await estimationsHTML(forStop: stopID, canRetry: true)
        return TransitCatalog.shared.sorted(EstimationParser.parse(html))
    }

    /// Forces the next request to fetch a fresh nonce. Exposed for the app to
    /// call if it ever needs to invalidate explicitly.
    public func invalidateNonce() {
        nonceStore.invalidate()
    }

    // MARK: - Internals

    private func estimationsHTML(
        forStop stopID: Int, canRetry: Bool
    ) async throws -> String {
        let nonce = try await currentNonce(forceRefresh: !canRetry)

        var components = URLComponents(
            url: Self.estimationsURL, resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "stop_id", value: String(stopID)),
            URLQueryItem(name: "_wpnonce", value: nonce)
        ]

        let (data, response) = try await perform(request(for: components.url!))
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        // An expired nonce reads as 403. Refresh once; a bounded retry keeps
        // this from looping when the service is simply rejecting us.
        if statusCode == 403, canRetry {
            Self.logger.debug("Nonce rejected; refreshing and retrying once")
            nonceStore.invalidate()
            return try await estimationsHTML(forStop: stopID, canRetry: false)
        }

        guard statusCode == 200 else {
            throw AucorsaError.serviceUnavailable(statusCode: statusCode)
        }

        // The endpoint returns a JSON-encoded *string* whose value is the HTML
        // fragment -- not raw HTML. The Dart client relies on the same shape
        // (it guards with `data is! String`).
        guard let html = try? JSONDecoder().decode(String.self, from: data) else {
            throw AucorsaError.unexpectedResponse
        }

        return html
    }

    private func currentNonce(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let cached = nonceStore.load() { return cached }

        var homepageURL = Self.homepageURL
        if forceRefresh {
            // A rejected nonce can also live in a proxy's cached homepage.
            // Use a fresh URL for the single recovery attempt, rather than
            // downloading that same cached page and retrying the old nonce.
            var components = URLComponents(url: homepageURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "_aucorsa_nonce_refresh", value: UUID().uuidString)]
            homepageURL = components.url!
        }
        let (data, response) = try await perform(request(for: homepageURL))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AucorsaError.serviceUnavailable(
                statusCode: (response as? HTTPURLResponse)?.statusCode
            )
        }

        guard
            let homepage = String(data: data, encoding: .utf8),
            let nonce = Self.parseNonce(homepage)
        else {
            throw AucorsaError.nonceUnavailable
        }

        nonceStore.save(nonce)
        return nonce
    }

    static func parseNonce(_ homepage: String) -> String? {
        let range = NSRange(homepage.startIndex..., in: homepage)
        guard
            let match = noncePattern.firstMatch(in: homepage, range: range),
            match.numberOfRanges > 1,
            let captured = Range(match.range(at: 1), in: homepage)
        else { return nil }

        return String(homepage[captured])
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpShouldHandleCookies = false
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("https://aucorsa.es/", forHTTPHeaderField: "Referer")
        // An explicit User-Agent is required, not cosmetic: the origin sits
        // behind Cloudflare, which rejects several default library agents with
        // "error code: 1010" before the request ever reaches AUCORSA.
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static let userAgent: String = {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        return "AucorsaGO/\(version) (iOS)"
    }()

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let result = try await session.data(for: request)
            if let response = result.1 as? HTTPURLResponse, response.statusCode >= 400 {
                let code = (try? JSONSerialization.jsonObject(with: result.0) as? [String: Any])?["code"] as? String
                NSLog("Aucorsa request failed: host=%@ status=%ld apiCode=%@ cache=%@", request.url?.host ?? "",
                      response.statusCode, code ?? "non-JSON response",
                      response.value(forHTTPHeaderField: "CF-Cache-Status") ?? "none")
            }
            return result
        } catch {
            Self.logger.error("Request failed: \(error.localizedDescription)")
            throw AucorsaError.serviceUnavailable(statusCode: nil)
        }
    }
}
