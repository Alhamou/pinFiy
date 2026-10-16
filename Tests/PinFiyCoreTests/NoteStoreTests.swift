import XCTest
@testable import PinFiyCore

final class NoteStoreTests: XCTestCase {
    func testSaveRoundTripKeepsNoteFields() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = NoteStore(directory: directory)
        let note = sampleNote(text: "saved", fontSize: 21)
        let document = NoteDocument(defaultFontSize: 19, notes: [note])
        try store.save(document)
        let loaded = store.load(mainScreen: sampleScreen)
        XCTAssertEqual(loaded.defaultFontSize, 19)
        XCTAssertEqual(loaded.notes[0].text, "saved")
        XCTAssertEqual(loaded.notes[0].x, note.x)
        XCTAssertEqual(loaded.notes[0].y, note.y)
        XCTAssertEqual(loaded.notes[0].width, note.width)
        XCTAssertEqual(loaded.notes[0].height, note.height)
        XCTAssertEqual(loaded.notes[0].colorHex, note.colorHex)
        XCTAssertEqual(loaded.notes[0].fontSize, 21)
        XCTAssertTrue(loaded.notes[0].pinned)
    }

    func testStageWithoutCommitKeepsPreviousFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = NoteStore(directory: directory)
        var document = NoteDocument(defaultFontSize: 16, notes: [sampleNote(text: "old")])
        try store.save(document)
        document.notes[0].text = "new"
        try store.stage(document)
        let loaded = store.load(mainScreen: sampleScreen)
        XCTAssertEqual(loaded.notes[0].text, "old")
        let staged = try Data(contentsOf: store.temporaryURL)
        let stagedDocument = try JSONDecoder().decode(NoteDocument.self, from: staged)
        XCTAssertEqual(stagedDocument.notes[0].text, "new")
    }

    func testCorruptFileFallsBackToBackup() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = NoteStore(directory: directory)
        let older = NoteDocument(defaultFontSize: 16, notes: [sampleNote(text: "backup")])
        try store.save(older)
        var newer = older
        newer.notes[0].text = "current"
        try store.save(newer)
        try Data("<<<".utf8).write(to: store.notesURL)
        let loaded = store.load(mainScreen: sampleScreen)
        XCTAssertEqual(loaded.notes[0].text, "backup")
    }

    func testCorruptFileWithoutBackupStartsWithOneEmptyNote() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = NoteStore(directory: directory)
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try Data("<<<".utf8).write(to: store.notesURL)
        let loaded = store.load(mainScreen: sampleScreen)
        XCTAssertEqual(loaded.notes.count, 1)
        XCTAssertEqual(loaded.notes[0].text, "")
        XCTAssertEqual(loaded.notes[0].colorHex, NotePalette.defaultHex)
        XCTAssertFalse(loaded.notes[0].pinned)
    }
}
