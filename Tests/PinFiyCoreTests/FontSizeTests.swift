import XCTest
@testable import PinFiyCore

final class FontSizeTests: XCTestCase {
    func testClampBounds() {
        XCTAssertEqual(FontSize.clamp(11), 12)
        XCTAssertEqual(FontSize.clamp(12), 12)
        XCTAssertEqual(FontSize.clamp(36), 36)
        XCTAssertEqual(FontSize.clamp(37), 36)
        XCTAssertEqual(FontSize.clamp(20), 20)
    }

    func testDefaultFontSizeDoesNotChangeExistingNotes() {
        var document = sampleDocument(noteSize: 16)
        document.updateDefaultFontSize(20)
        XCTAssertEqual(document.defaultFontSize, 20)
        XCTAssertEqual(document.notes[0].fontSize, 16)
        let created = document.makingNote(beside: nil, on: sampleScreen)
        XCTAssertEqual(created.fontSize, 20)
        XCTAssertEqual(created.colorHex, NotePalette.defaultHex)
    }

    func testApplyDefaultFontSizeToAllNotes() {
        var document = sampleDocument(noteSize: 16)
        document.updateDefaultFontSize(18)
        document.notes.append(document.notes[0])
        document.applyDefaultFontSizeToAllNotes()
        XCTAssertEqual(document.notes.map(\.fontSize), [18, 18])
    }

    func testApplyDefaultFontSizeSkipsLockedNotes() {
        var document = sampleDocument(noteSize: 16)
        document.updateDefaultFontSize(22)
        var locked = sampleNote(text: "stay", fontSize: 14)
        locked.locked = true
        document.notes.append(locked)
        document.applyDefaultFontSizeToAllNotes()
        XCTAssertEqual(document.notes[0].fontSize, 22)
        XCTAssertEqual(document.notes[1].fontSize, 14)
        XCTAssertTrue(document.notes[1].locked)
    }
}
