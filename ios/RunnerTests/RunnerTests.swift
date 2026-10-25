import Flutter
import UIKit
import XCTest
import AucorsaKit
import ActivityKit

@testable import Runner

class RunnerTests: XCTestCase {

  func testLegacySessionsAreCappedAtFifteenMinutesAfterActivation() throws {
    guard #available(iOS 16.2, *) else { return }
    let data = Data(#"{"stopID":141,"stopName":"Casa","preferredLineID":"5","language":"en","endsAt":1800001800,"sessionID":"legacy"}"#.utf8)
    let attributes = try JSONDecoder().decode(BusArrivalAttributes.self, from: data)
    XCTAssertNil(attributes.startedAt)
    XCTAssertEqual(attributes.deadline, 1_800_000_900)
  }

  @MainActor
  func testDeadlineEndsActivityAndClearsFollowingWithoutWaitingForAPoll() async throws {
    guard #available(iOS 16.2, *) else { return }
    // Exercise the last second of a real 15-minute session, without waiting 15 minutes.
    let startedAt = Date.now.timeIntervalSince1970 - 899
    let attributes = BusArrivalAttributes(stopID: 141, stopName: "Expiry test",
      preferredLineID: "5", language: "en", endsAt: startedAt + 900,
      sessionID: UUID().uuidString, startedAt: startedAt)
    let snapshot = BusArrivalSnapshot(fetchedAt: startedAt, lines: [])
    let activity = try Activity.request(attributes: attributes,
      content: ActivityContent(state: snapshot, staleDate: .now), pushType: nil)
    var sawFollowing = false
    var sawCleared = false
    let coordinator = BusArrivalActivityCoordinator { status in
      if status["stopID"] as? Int == 141 { sawFollowing = true }
      if sawFollowing && status["stopID"] == nil { sawCleared = true }
    }
    await coordinator.restore()
    XCTAssertEqual(coordinator.status["endsAt"] as? Double, startedAt + 900)
    await coordinator.updateStopName(stopID: 141, lineID: "5", name: "Renamed")
    XCTAssertEqual(activity.attributes.deadline, startedAt + 900)
    try await Task.sleep(nanoseconds: 2_000_000_000)
    XCTAssertNil(coordinator.status["stopID"])
    XCTAssertTrue(sawCleared)
    XCTAssertTrue(activity.activityState == .ended || activity.activityState == .dismissed)
    await coordinator.stop()
  }

  @MainActor
  func testRestoringAnExpiredSessionEndsItAndClearsFollowing() async throws {
    guard #available(iOS 16.2, *) else { return }
    let startedAt = Date.now.timeIntervalSince1970 - 901
    let attributes = BusArrivalAttributes(stopID: 141, stopName: "Expired test",
      preferredLineID: "5", language: "en", endsAt: startedAt + 900,
      sessionID: UUID().uuidString, startedAt: startedAt)
    let activity = try Activity.request(attributes: attributes,
      content: ActivityContent(state: BusArrivalSnapshot(fetchedAt: startedAt, lines: []),
                               staleDate: .now), pushType: nil)
    var lastStatus: [String: Any] = [:]
    let coordinator = BusArrivalActivityCoordinator { lastStatus = $0 }
    await coordinator.restore()
    XCTAssertNil(lastStatus["stopID"])
    XCTAssertTrue(activity.activityState == .ended || activity.activityState == .dismissed)
    await coordinator.stop()
  }

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

  func testSpokenArrivalsSkipUnavailableLinesBeforeApplyingLimit() {
    let selection = ArrivalsFormatter.spokenSelection(from: [
      BusStopLineEstimation(lineID: "1", arrivals: []),
      BusStopLineEstimation(lineID: "2", arrivals: []),
      BusStopLineEstimation(lineID: "3", arrivals: []),
      BusStopLineEstimation(lineID: "4", arrivals: [5]),
      BusStopLineEstimation(lineID: "5", arrivals: [8]),
      BusStopLineEstimation(lineID: "6", arrivals: [11]),
      BusStopLineEstimation(lineID: "7", arrivals: [14]),
    ])

    XCTAssertEqual(selection.estimations.map(\.lineID), ["4", "5", "6"])
    XCTAssertEqual(selection.remainingCount, 1)
  }

  func testSystemAppearanceUsesScreenTraitsInsideTheIntentExtension() {
    let style = SystemAppearance.selectStyle(
      scene: nil,
      current: .light,
      screen: .dark,
      preferScreen: true
    )

    XCTAssertEqual(style, .dark)
  }

  func testLineDialogLocalizesDurationsUsingTheDialogLocale() {
    let estimation = BusStopLineEstimation(lineID: "5", arrivals: [1, 40])
    var resource = ArrivalsFormatter.lineDialogResource(
      for: estimation,
      lineID: "5",
      stopName: "Casa"
    )
    resource.locale = Locale(identifier: "es")

    XCTAssertEqual(
      String(localized: resource),
      "La línea 5 llega a Casa en 1 minuto, y luego en 40 minutos."
    )
  }

}
