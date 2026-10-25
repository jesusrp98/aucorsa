import Foundation
import Testing

@testable import AucorsaKit

@Suite("Native arrival requests", .serialized)
struct AucorsaClientTests {
    @Test("Public arrivals do not send cookies from an existing web session")
    func ignoresExistingSessionCookies() async throws {
        let fixture = ArrivalHTTPFixture()
        try await withClient(fixture) { client, store in
            store.save("fresh")
            _ = try await client.estimations(forStop: 79)
            #expect(fixture.sentNonces == ["fresh"])
            #expect(fixture.requests.allSatisfy {
                $0.value(forHTTPHeaderField: "Cookie") == nil
            })
        }
    }

    @Test("A rejected nonce bypasses a cached homepage and is reused after recovery")
    func recoversFromStaleHomepage() async throws {
        let fixture = ArrivalHTTPFixture()
        try await withClient(fixture) { client, store in
            store.save("expired")
            _ = try await client.estimations(forStop: 79)
            _ = try await client.estimations(forStop: 79)
            #expect(fixture.sentNonces == ["expired", "fresh", "fresh"])
            #expect(fixture.homepages.count == 1)
            #expect(fixture.homepages.first?.query?.contains("_aucorsa_nonce_refresh=") == true)
            #expect(store.load() == "fresh")
            #expect(fixture.requests.allSatisfy {
                $0.cachePolicy == .reloadIgnoringLocalCacheData &&
                !$0.httpShouldHandleCookies &&
                $0.value(forHTTPHeaderField: "Cache-Control") == "no-cache"
            })
        }
    }

    @Test("A stale homepage on first use also recovers with a fresh URL")
    func recoversWithoutStoredNonce() async throws {
        let fixture = ArrivalHTTPFixture()
        try await withClient(fixture) { client, _ in
            _ = try await client.estimations(forStop: 79)
            #expect(fixture.sentNonces == ["expired", "fresh"])
            #expect(fixture.homepages.count == 2)
            #expect(fixture.homepages.first?.query == nil)
            #expect(fixture.homepages.last?.query?.contains("_aucorsa_nonce_refresh=") == true)
        }
    }

    @Test("A persistent rejection stops after one retry")
    func limitsRetries() async throws {
        let fixture = ArrivalHTTPFixture(rejectFreshNonce: true)
        try await withClient(fixture) { client, store in
            store.save("expired")
            await #expect(throws: AucorsaError.serviceUnavailable(statusCode: 403)) {
                _ = try await client.estimations(forStop: 79)
            }
            #expect(fixture.sentNonces == ["expired", "fresh"])
            #expect(fixture.homepages.count == 1)
        }
    }

    private func withClient(
        _ fixture: ArrivalHTTPFixture,
        body: (AucorsaClient, NonceStore) async throws -> Void
    ) async throws {
        let suite = "AucorsaClientTests.\(UUID().uuidString)"
        let store = NonceStore(suiteName: suite)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArrivalURLProtocol.self]
        // The isolated test session deliberately starts with a conflicting
        // cookie. No production or shared cookie store is read or modified.
        let cookie = HTTPCookie(properties: [
            .domain: ".aucorsa.es", .path: "/",
            .name: "wordpress_logged_in_fixture", .value: "test-session"
        ])!
        configuration.httpCookieStorage?.setCookie(cookie)
        let session = URLSession(configuration: configuration)
        ArrivalURLProtocol.fixture = fixture
        defer {
            session.invalidateAndCancel()
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        try await body(AucorsaClient(session: session, nonceStore: store), store)
    }
}

private final class ArrivalHTTPFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedRequests: [URLRequest] = []
    private let rejectFreshNonce: Bool

    init(rejectFreshNonce: Bool = false) {
        self.rejectFreshNonce = rejectFreshNonce
    }

    var requests: [URLRequest] { lock.withLock { recordedRequests } }
    var homepages: [URL] { requests.compactMap(\.url).filter { $0.host == "aucorsa.es" } }
    var sentNonces: [String] {
        requests.compactMap { request in
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "_wpnonce" }?.value
        }
    }

    func response(to request: URLRequest) -> (Int, Data) {
        lock.withLock { recordedRequests.append(request) }
        let url = request.url!
        if url.host == "aucorsa.es" {
            let nonce = url.query == nil ? "expired" : "fresh"
            return (200, Data("{\"ajax_nonce\":\"\(nonce)\"}".utf8))
        }
        let nonce = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "_wpnonce" }?.value
        if nonce != "fresh" || rejectFreshNonce || request.value(forHTTPHeaderField: "Cookie") != nil {
            return (403, Data(#"{"code":"rest_cookie_invalid_nonce"}"#.utf8))
        }
        return (200, Data(#""Sin estimaciones""#.utf8))
    }
}

private final class ArrivalURLProtocol: URLProtocol, @unchecked Sendable {
    // The suite is serialized and installs a fixture before starting each session.
    nonisolated(unsafe) static var fixture: ArrivalHTTPFixture!

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, data) = Self.fixture.response(to: request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                       httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
