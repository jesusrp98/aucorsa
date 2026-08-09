import Flutter
import UIKit
import XCTest
import AucorsaKit

@testable import Runner

class RunnerTests: XCTestCase {

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

}
