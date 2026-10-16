import XCTest
@testable import PinFiyCore

final class NoteCodingTests: XCTestCase {
    func testJSONRoundTripKeepsFields() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let note = Note(
            id: id,
            text: "مرحبا",
            x: 12,
            y: 34,
            width: 280,
            height: 240,
            colorHex: "#C5DDF0",
            fontSize: 18,
            pinned: true,
            locked: true
        )
        let document = NoteDocument(defaultFontSize: 20, notes: [note])
        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(NoteDocument.self, from: data)
        XCTAssertEqual(decoded.defaultFontSize, 20)
        XCTAssertEqual(decoded.notes, [note])
        XCTAssertTrue(decoded.notes[0].locked)
    }

    func testMissingLockDecodesAsUnlocked() throws {
        let json = """
        {"defaultFontSize":16,"notes":[{"colorHex":"#F3C15B","fontSize":16,"height":240,"id":"00000000-0000-0000-0000-000000000002","pinned":false,"text":"old","width":280,"x":1,"y":2}]}
        """
        let decoded = try JSONDecoder().decode(NoteDocument.self, from: Data(json.utf8))
        XCTAssertFalse(decoded.notes[0].locked)
        XCTAssertEqual(decoded.notes[0].text, "old")
    }
}
