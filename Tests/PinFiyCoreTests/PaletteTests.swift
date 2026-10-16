import XCTest
@testable import PinFiyCore

final class PaletteTests: XCTestCase {
    func testLightAndDarkColorsKeepDefaultAmber() {
        XCTAssertEqual(NotePalette.lightColors.count, 10)
        XCTAssertEqual(NotePalette.darkColors.count, 10)
        XCTAssertEqual(Array(NotePalette.colors.map(\.hex).prefix(10)), NotePalette.lightColors.map(\.hex))
        XCTAssertEqual(
            NotePalette.lightColors.map(\.hex),
            [
                "#F3C15B",
                "#F3E7A1",
                "#F3C7B0",
                "#C9E4D4",
                "#D5DDB8",
                "#C5DDF0",
                "#D9D0EE",
                "#F0D0D6",
                "#E6D7C3",
                "#D5DDE3"
            ]
        )
        XCTAssertEqual(
            NotePalette.darkColors.map(\.hex),
            [
                "#5C4518",
                "#4E4830",
                "#5C3A32",
                "#234338",
                "#3A432C",
                "#24384C",
                "#3A3454",
                "#4C3038",
                "#3E362C",
                "#2C343C"
            ]
        )
        XCTAssertEqual(NotePalette.defaultHex, "#F3C15B")
        XCTAssertEqual(NotePalette.colors.first?.hex, NotePalette.defaultHex)
        XCTAssertTrue(NotePalette.lightColors.allSatisfy { $0.textHex == NotePalette.textHex })
        XCTAssertTrue(NotePalette.darkColors.allSatisfy { $0.textHex == NotePalette.lightTextHex })
        XCTAssertEqual(NotePalette.textHex(for: "#F3C15B"), NotePalette.textHex)
        XCTAssertEqual(NotePalette.textHex(for: "#24384C"), NotePalette.lightTextHex)
        XCTAssertEqual(Set(NotePalette.colors.map(\.hex)).count, 20)
    }
}
