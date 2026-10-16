import XCTest
@testable import PinFiyCore

final class NoteRulesTests: XCTestCase {
    func testNewNoteBesideUsesDefaultColorAndFont() {
        let current = sampleNote(text: "here", fontSize: 22)
        var document = NoteDocument(defaultFontSize: 16, notes: [current])
        document.updateDefaultFontSize(19)
        let created = document.makingNote(beside: current, on: sampleScreen)
        XCTAssertEqual(created.x, current.x + 28)
        XCTAssertEqual(created.y, current.y - 28)
        XCTAssertEqual(created.colorHex, "#F3C15B")
        XCTAssertEqual(created.fontSize, 19)
        XCTAssertEqual(created.text, "")
        XCTAssertNotEqual(created.id, current.id)
    }

    func testMinimumSize() {
        XCTAssertEqual(NoteMetrics.clamp(width: 40, height: 40).width, 220)
        XCTAssertEqual(NoteMetrics.clamp(width: 40, height: 40).height, 180)
        XCTAssertEqual(NoteMetrics.clamp(width: 300, height: 260).width, 300)
        XCTAssertEqual(NoteMetrics.clamp(width: 300, height: 260).height, 260)
    }

    func testEmptyCloseDeletesWithoutConfirmation() {
        XCTAssertEqual(NoteClosing.decision(text: ""), .deleteImmediately)
        XCTAssertEqual(NoteClosing.decision(text: "  \n"), .deleteImmediately)
        let note = sampleNote(text: "   ")
        let document = NoteDocument(defaultFontSize: 16, notes: [note, sampleNote(text: "keep")])
        let result = NoteClosing.applyingClose(document: document, id: note.id, confirmed: false, on: sampleScreen)
        XCTAssertEqual(result.notes.count, 1)
        XCTAssertEqual(result.notes[0].text, "keep")
    }

    func testNonEmptyCloseNeedsConfirmation() {
        XCTAssertEqual(NoteClosing.decision(text: "hello"), .needsConfirmation)
        let note = sampleNote(text: "hello")
        let document = NoteDocument(defaultFontSize: 16, notes: [note])
        let kept = NoteClosing.applyingClose(document: document, id: note.id, confirmed: false, on: sampleScreen)
        XCTAssertEqual(kept.notes, [note])
        let deleted = NoteClosing.applyingClose(document: document, id: note.id, confirmed: true, on: sampleScreen)
        XCTAssertEqual(deleted.notes.count, 1)
        XCTAssertEqual(deleted.notes[0].text, "")
        XCTAssertNotEqual(deleted.notes[0].id, note.id)
    }
}
