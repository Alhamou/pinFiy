import Foundation
@testable import PinFiyCore

let sampleScreen = ScreenRect(x: 0, y: 0, width: 1440, height: 900)

func sampleNote(text: String, fontSize: Double = 16) -> Note {
    Note(
        id: UUID(),
        text: text,
        x: 100,
        y: 200,
        width: 280,
        height: 240,
        colorHex: "#C5DDF0",
        fontSize: fontSize,
        pinned: true
    )
}

func sampleDocument(noteSize: Double) -> NoteDocument {
    NoteDocument(defaultFontSize: 16, notes: [sampleNote(text: "note", fontSize: noteSize)])
}

func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("pinfiy-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}
