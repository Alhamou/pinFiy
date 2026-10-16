import Foundation

public enum NoteMetrics {
    public static let minimumWidth = 220.0
    public static let minimumHeight = 180.0
    public static let defaultWidth = 280.0
    public static let defaultHeight = 240.0

    public static func clamp(width: Double, height: Double) -> (width: Double, height: Double) {
        (max(width, minimumWidth), max(height, minimumHeight))
    }
}

public enum NotePlacement {
    public static func centeredNote(on screen: ScreenRect, fontSize: Double) -> Note {
        let frame = screen.centeredFrame(width: NoteMetrics.defaultWidth, height: NoteMetrics.defaultHeight)
        return Note(
            id: UUID(),
            text: "",
            x: frame.x,
            y: frame.y,
            width: frame.width,
            height: frame.height,
            colorHex: NotePalette.defaultHex,
            fontSize: FontSize.clamp(fontSize),
            pinned: false,
            locked: false
        )
    }

    public static func note(beside other: Note, fontSize: Double) -> Note {
        Note(
            id: UUID(),
            text: "",
            x: other.x + 28,
            y: other.y - 28,
            width: NoteMetrics.defaultWidth,
            height: NoteMetrics.defaultHeight,
            colorHex: NotePalette.defaultHex,
            fontSize: FontSize.clamp(fontSize),
            pinned: false,
            locked: false
        )
    }
}

public enum CloseDecision: Equatable, Sendable {
    case deleteImmediately
    case needsConfirmation
}

public enum NoteClosing {
    public static func decision(text: String) -> CloseDecision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .deleteImmediately : .needsConfirmation
    }

    public static func applyingClose(
        document: NoteDocument,
        id: UUID,
        confirmed: Bool,
        on screen: ScreenRect
    ) -> NoteDocument {
        guard let note = document.notes.first(where: { $0.id == id }) else {
            return document
        }
        if decision(text: note.text) == .needsConfirmation && !confirmed {
            return document
        }
        var copy = document
        copy.notes.removeAll { $0.id == id }
        return copy.withAtLeastOneNote(on: screen)
    }
}
