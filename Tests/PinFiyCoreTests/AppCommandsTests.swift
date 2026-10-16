import XCTest
@testable import PinFiyCore

final class AppCommandsTests: XCTestCase {
    func testShortcutsCoverNoteCommands() {
        XCTAssertEqual(
            AppCommands.all.map(\.keyEquivalent),
            ["n", "w", "p", ",", "q"]
        )
        XCTAssertEqual(
            AppCommands.all.map(\.identifier),
            ["new-note", "close-note", "toggle-pin", "settings", "quit"]
        )
    }
}
