import XCTest
@testable import PinFiyCore

final class ScreenLayoutTests: XCTestCase {
    func testFrameInsideScreenStays() {
        let screen = ScreenRect(x: 0, y: 0, width: 1000, height: 800)
        let frame = ScreenRect(x: 40, y: 50, width: 280, height: 240)
        XCTAssertEqual(ScreenLayout.visibleFrame(for: frame, screens: [screen], mainScreen: screen), frame)
    }

    func testFrameOutsideScreensMovesToMainCenter() {
        let screen = ScreenRect(x: 0, y: 0, width: 1000, height: 800)
        let frame = ScreenRect(x: 4000, y: 4000, width: 200, height: 180)
        let result = ScreenLayout.visibleFrame(for: frame, screens: [screen], mainScreen: screen)
        XCTAssertEqual(result, screen.centeredFrame(width: 200, height: 180))
    }
}
