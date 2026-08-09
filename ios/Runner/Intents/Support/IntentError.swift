import AppIntents
import AucorsaKit
import Foundation

/// Failures an intent needs Siri to say out loud.
///
/// `CustomLocalizedStringResourceConvertible` is what lets Siri speak these
/// rather than showing a generic "something went wrong".
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case serviceUnavailable
    case lineDoesNotServeStop(lineID: String, stopName: String)

    init(_ error: Error) {
        switch error {
        case let error as IntentError:
            self = error
        case let error as AucorsaError:
            switch error {
            case .nonceUnavailable, .unexpectedResponse, .serviceUnavailable:
                self = .serviceUnavailable
            }
        default:
            self = .serviceUnavailable
        }
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .serviceUnavailable:
            LocalizedStringResource(
                "AUCORSA is not responding right now. Try again in a moment.",
                table: "Intents"
            )
        case let .lineDoesNotServeStop(lineID, stopName):
            LocalizedStringResource(
                "Line \(lineID) does not serve \(stopName). Choose another stop.",
                table: "Intents"
            )
        }
    }
}
