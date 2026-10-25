import Foundation
import Testing

@testable import AucorsaKit

@Suite("Live Activity backend", .serialized)
struct LiveActivityBackendTests {
    private static let baseURL = URL(string: "https://backend.test/liveActivitySessions")!
    private static let sessionID = "0F4D2C6B-7A31-4E8B-9C55-2D1E6F8A9B03"

    @Test("Registering sends the session as the backend's PUT body")
    func register() async throws {
        let requests = try await withBackend(status: 201) { backend in
            try await backend.register(
                sessionID: Self.sessionID, pushToken: Data([0x0a, 0xff, 0x01]),
                environment: .sandbox, stopID: 105, lineID: "2", stopName: "Fátima",
                endsAt: 1_800_000_900
            )
        }
        let request = try #require(requests.first)
        #expect(request.method == "PUT")
        #expect(request.url == Self.baseURL.appendingPathComponent(Self.sessionID))
        #expect(request.contentType == "application/json")
        let body = try #require(request.json)
        #expect(body["pushToken"] as? String == "0aff01")
        #expect(body["apnsEnvironment"] as? String == "sandbox")
        #expect(body["stopID"] as? Int == 105)
        #expect(body["lineID"] as? String == "2")
        #expect(body["stopName"] as? String == "Fátima")
        #expect(body["endsAt"] as? Double == 1_800_000_900)
    }

    @Test("Clearing a custom name sends null")
    func renameToNil() async throws {
        let requests = try await withBackend(status: 204) { backend in
            try await backend.rename(sessionID: Self.sessionID, stopName: nil)
        }
        #expect(requests.first?.method == "PATCH")
        #expect(requests.first?.body == Data(#"{"stopName":null}"#.utf8))
    }

    @Test("Unregistering is a bodiless DELETE")
    func unregister() async throws {
        let requests = try await withBackend(status: 204) { backend in
            try await backend.unregister(sessionID: Self.sessionID)
        }
        #expect(requests.first?.method == "DELETE")
        #expect(requests.first?.body == nil)
    }

    @Test("A rejected request throws with its status")
    func rejected() async throws {
        _ = try await withBackend(status: 429) { backend in
            await #expect(throws: AucorsaError.serviceUnavailable(statusCode: 429)) {
                try await backend.unregister(sessionID: Self.sessionID)
            }
        }
    }

    @Test("Only a plain host turns the backend on")
    func sessionsURL() {
        #expect(LiveActivityBackend.sessionsURL(host: " europe-west1-demo.cloudfunctions.net ")
            == URL(string: "https://europe-west1-demo.cloudfunctions.net/liveActivitySessions"))
        #expect(LiveActivityBackend.sessionsURL(host: "") == nil)
        #expect(LiveActivityBackend.sessionsURL(host: "$(LIVE_ACTIVITY_BACKEND_HOST)") == nil)
        #expect(LiveActivityBackend.sessionsURL(host: "https://example.com") == nil)
    }

    @Test("Builds without a configured host have no backend")
    func unconfiguredByDefault() {
        // The test bundle's Info.plist has no LiveActivityBackendHost.
        #expect(LiveActivityBackend.configured == nil)
    }

    @Test("Development-signed profiles map to the APNs sandbox")
    func readsProvisioningProfile() throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict><key>Entitlements</key><dict>\
        <key>aps-environment</key><string>development</string></dict></dict></plist>
        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mobileprovision")
        // A signed profile wraps the plist in binary CMS data.
        try (Data([0x30, 0x80, 0xff, 0x00]) + Data(plist.utf8) + Data([0x00, 0xa0]))
            .write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(LiveActivityBackend.Environment.apsEnvironment(inProfileAt: url) == "development")
    }

    private func withBackend(
        status: Int, body: (LiveActivityBackend) async throws -> Void
    ) async throws -> [RecordedRequest] {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BackendURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        BackendURLProtocol.reset(status: status)
        try await body(LiveActivityBackend(session: session, baseURL: Self.baseURL))
        return BackendURLProtocol.requests
    }
}

private struct RecordedRequest {
    let method: String?
    let url: URL?
    let contentType: String?
    let body: Data?

    var json: [String: Any]? {
        body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }
}

private final class BackendURLProtocol: URLProtocol, @unchecked Sendable {
    // The suite is serialized and resets this before each session.
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private(set) static var requests: [RecordedRequest] = []

    static func reset(status: Int) {
        self.status = status
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(RecordedRequest(
            method: request.httpMethod, url: request.url,
            contentType: request.value(forHTTPHeaderField: "Content-Type"),
            body: request.httpBody ?? request.httpBodyStream.map(Self.read)
        ))
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                       httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// URLSession hands uploaded bodies to protocols as a stream.
    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
