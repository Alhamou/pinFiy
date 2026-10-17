import XCTest
@testable import PinFiyCore

final class ArabicNumeralsTests: XCTestCase {
    func testEasternArabicNumeralsConvertedToEnglish() {
        let input = "٠١٢٣٤٥٦٧٨٩"
        let output = ArabicNumerals.convertToEnglish(input)
        XCTAssertEqual(output, "0123456789")
    }

    func testExtendedArabicIndicNumeralsConvertedToEnglish() {
        let input = "۰۱۲۳۴۵۶۷۸۹"
        let output = ArabicNumerals.convertToEnglish(input)
        XCTAssertEqual(output, "0123456789")
    }

    func testMixedArabicTextWithNumbers() {
        let input = "مرحبا بكم، الرقم هو ١٢٣ والتاريخ ٢٠٢٦"
        let expected = "مرحبا بكم، الرقم هو 123 والتاريخ 2026"
        XCTAssertEqual(ArabicNumerals.convertToEnglish(input), expected)
    }

    func testEnglishTextWithExistingNumbersUntouched() {
        let input = "Meeting at 10:30 in room 4B"
        XCTAssertEqual(ArabicNumerals.convertToEnglish(input), input)
    }

    func testEmptyString() {
        XCTAssertEqual(ArabicNumerals.convertToEnglish(""), "")
    }

    func testStringExtension() {
        XCTAssertEqual("السعر ٥٠٠ دولار".withEnglishNumerals, "السعر 500 دولار")
    }

    func testContainsArabicNumerals() {
        XCTAssertTrue(ArabicNumerals.containsArabicNumerals("اختبار ١٢٣"))
        XCTAssertTrue(ArabicNumerals.containsArabicNumerals("تست ۱۲۳"))
        XCTAssertFalse(ArabicNumerals.containsArabicNumerals("اختبار 123"))
        XCTAssertFalse(ArabicNumerals.containsArabicNumerals("نص عربي فقط"))
    }

    func testNoteInitializationConvertsNumerals() {
        let note = Note(
            id: UUID(),
            text: "ملاحظة رقم ١",
            x: 0,
            y: 0,
            width: 280,
            height: 240,
            colorHex: "#F3C15B",
            fontSize: 16,
            pinned: false
        )
        XCTAssertEqual(note.text, "ملاحظة رقم 1")
    }

    func testNoteNormalizationConvertsNumerals() {
        var note = Note(
            id: UUID(),
            text: "test",
            x: 0,
            y: 0,
            width: 280,
            height: 240,
            colorHex: "#F3C15B",
            fontSize: 16,
            pinned: false
        )
        note.text = "ملاحظة رقم ٢"
        let normalized = note.normalized()
        XCTAssertEqual(normalized.text, "ملاحظة رقم 2")
    }

    func testNoteDecodingConvertsNumerals() throws {
        let json = """
        {"colorHex":"#F3C15B","fontSize":16,"height":240,"id":"00000000-0000-0000-0000-000000000003","pinned":false,"text":"قائمة رقم ٣ و ٤","width":280,"x":1,"y":2}
        """
        let decoded = try JSONDecoder().decode(Note.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.text, "قائمة رقم 3 و 4")
    }
}
