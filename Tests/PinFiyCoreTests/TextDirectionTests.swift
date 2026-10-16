import XCTest
@testable import PinFiyCore

final class TextDirectionTests: XCTestCase {
    func testArabicIsRightToLeft() {
        let direction = TextDirectionDetector.direction(of: "مرحبا", systemIsArabic: false)
        XCTAssertEqual(direction, .rightToLeft)
        XCTAssertTrue(direction.pinOnTheRight)
    }

    func testLatinIsLeftToRight() {
        let direction = TextDirectionDetector.direction(of: "Hello", systemIsArabic: true)
        XCTAssertEqual(direction, .leftToRight)
        XCTAssertFalse(direction.pinOnTheRight)
    }

    func testMixedTextFollowsFirstStrongCharacter() {
        XCTAssertEqual(
            TextDirectionDetector.direction(of: "مرحبا Hello", systemIsArabic: false),
            .rightToLeft
        )
        XCTAssertEqual(
            TextDirectionDetector.direction(of: "Hello مرحبا", systemIsArabic: true),
            .leftToRight
        )
    }

    func testSkipsSpacesBeforeFirstStrongCharacter() {
        XCTAssertEqual(
            TextDirectionDetector.direction(of: "  مرحبا", systemIsArabic: false),
            .rightToLeft
        )
    }

    func testEmptyAndNumbersFollowSystemLanguage() {
        XCTAssertEqual(TextDirectionDetector.direction(of: "", systemIsArabic: true), .rightToLeft)
        XCTAssertEqual(TextDirectionDetector.direction(of: "", systemIsArabic: false), .leftToRight)
        XCTAssertEqual(TextDirectionDetector.direction(of: "123", systemIsArabic: true), .rightToLeft)
        XCTAssertEqual(TextDirectionDetector.direction(of: "١٢٣", systemIsArabic: false), .leftToRight)
        XCTAssertEqual(TextDirectionDetector.direction(of: "...", systemIsArabic: false), .leftToRight)
        XCTAssertEqual(TextDirectionDetector.direction(of: "،", systemIsArabic: true), .rightToLeft)
    }
}
