import Foundation

/// Failures the intent layer needs to turn into something speakable.
public enum AucorsaError: Error, Equatable, Sendable {
    /// The homepage did not contain the `ajax_nonce` the API requires. Usually
    /// means the site changed shape.
    case nonceUnavailable
    /// The service answered, but not with success. `statusCode` is nil for
    /// transport failures.
    case serviceUnavailable(statusCode: Int?)
    /// The response body was not in the shape this client knows how to read.
    case unexpectedResponse

    /// Whether retrying immediately could plausibly help.
    public var isTransient: Bool {
        switch self {
        case .serviceUnavailable: true
        case .nonceUnavailable, .unexpectedResponse: false
        }
    }
}
