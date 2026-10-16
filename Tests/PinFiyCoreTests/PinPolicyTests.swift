import XCTest
@testable import PinFiyCore

final class PinPolicyTests: XCTestCase {
    func testUnpinnedStaysNormal() {
        let policy = PinPolicy.policy(pinned: false)
        XCTAssertEqual(policy.level, .normal)
        XCTAssertFalse(policy.joinsAllSpaces)
        XCTAssertFalse(policy.fullScreenAuxiliary)
        XCTAssertFalse(policy.coversMenuBar)
    }

    func testPinnedFloatsOnAllSpacesWithoutCoveringMenuBar() {
        let policy = PinPolicy.policy(pinned: true)
        XCTAssertEqual(policy.level, .floating)
        XCTAssertTrue(policy.joinsAllSpaces)
        XCTAssertTrue(policy.fullScreenAuxiliary)
        XCTAssertFalse(policy.coversMenuBar)
    }
}
