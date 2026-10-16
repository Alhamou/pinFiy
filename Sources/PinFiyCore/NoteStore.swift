import Foundation

public struct NoteStore {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public var notesURL: URL {
        directory.appendingPathComponent("notes.json")
    }

    public var backupURL: URL {
        directory.appendingPathComponent("notes.json.bak")
    }

    public var temporaryURL: URL {
        directory.appendingPathComponent("notes.json.tmp")
    }

    public func save(_ document: NoteDocument) throws {
        try stage(document)
        try commitStaged()
    }

    public func stage(_ document: NoteDocument) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document.normalized())
        try data.write(to: temporaryURL, options: .atomic)
    }

    public func commitStaged() throws {
        let manager = FileManager.default
        if readValid(notesURL) != nil {
            if manager.fileExists(atPath: backupURL.path) {
                try manager.removeItem(at: backupURL)
            }
            try manager.copyItem(at: notesURL, to: backupURL)
        }
        if manager.fileExists(atPath: notesURL.path) {
            _ = try manager.replaceItemAt(notesURL, withItemAt: temporaryURL)
        } else {
            try manager.moveItem(at: temporaryURL, to: notesURL)
        }
    }

    public func load(mainScreen: ScreenRect) -> NoteDocument {
        if let current = readValid(notesURL) {
            return current.withAtLeastOneNote(on: mainScreen)
        }
        if let backup = readValid(backupURL) {
            return backup.withAtLeastOneNote(on: mainScreen)
        }
        return NoteDocument.singleEmptyNote(on: mainScreen)
    }

    private func readValid(_ url: URL) -> NoteDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let document = try? JSONDecoder().decode(NoteDocument.self, from: data) else { return nil }
        return document.normalized()
    }
}
