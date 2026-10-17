import Foundation

public struct Note: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var text: String
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var colorHex: String
    public var fontSize: Double
    public var pinned: Bool
    public var locked: Bool

    public init(
        id: UUID,
        text: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        colorHex: String,
        fontSize: Double,
        pinned: Bool,
        locked: Bool = false
    ) {
        self.id = id
        self.text = ArabicNumerals.convertToEnglish(text)
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.colorHex = colorHex
        self.fontSize = fontSize
        self.pinned = pinned
        self.locked = locked
    }
}

public struct NoteDocument: Codable, Equatable, Sendable {
    public var defaultFontSize: Double
    public var notes: [Note]

    public init(defaultFontSize: Double, notes: [Note]) {
        self.defaultFontSize = defaultFontSize
        self.notes = notes
    }

    public static func singleEmptyNote(on screen: ScreenRect) -> NoteDocument {
        let document = NoteDocument(defaultFontSize: FontSize.standard, notes: [])
        return document.withAtLeastOneNote(on: screen)
    }

    public func withAtLeastOneNote(on screen: ScreenRect) -> NoteDocument {
        guard notes.isEmpty else { return normalized() }
        var copy = self
        copy.defaultFontSize = FontSize.clamp(copy.defaultFontSize)
        copy.notes = [
            NotePlacement.centeredNote(on: screen, fontSize: copy.defaultFontSize)
        ]
        return copy
    }

    public func normalized() -> NoteDocument {
        var copy = self
        copy.defaultFontSize = FontSize.clamp(copy.defaultFontSize)
        copy.notes = notes.map { $0.normalized() }
        return copy
    }

    public mutating func updateDefaultFontSize(_ size: Double) {
        defaultFontSize = FontSize.clamp(size)
    }

    public mutating func applyDefaultFontSizeToAllNotes() {
        let size = defaultFontSize
        for index in notes.indices where !notes[index].locked {
            notes[index].fontSize = size
        }
    }

    public func makingNote(beside existing: Note?, on screen: ScreenRect) -> Note {
        if let existing {
            return NotePlacement.note(beside: existing, fontSize: defaultFontSize)
        }
        return NotePlacement.centeredNote(on: screen, fontSize: defaultFontSize)
    }
}

extension Note {
    private enum CodingKeys: String, CodingKey {
        case id, text, x, y, width, height, colorHex, fontSize, pinned, locked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let rawText = try container.decode(String.self, forKey: .text)
        text = ArabicNumerals.convertToEnglish(rawText)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        fontSize = try container.decode(Double.self, forKey: .fontSize)
        pinned = try container.decode(Bool.self, forKey: .pinned)
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(pinned, forKey: .pinned)
        try container.encode(locked, forKey: .locked)
    }

    public func normalized() -> Note {
        var copy = self
        copy.text = ArabicNumerals.convertToEnglish(copy.text)
        copy.fontSize = FontSize.clamp(copy.fontSize)
        let size = NoteMetrics.clamp(width: copy.width, height: copy.height)
        copy.width = size.width
        copy.height = size.height
        if !NotePalette.contains(copy.colorHex) {
            copy.colorHex = NotePalette.defaultHex
        }
        return copy
    }
}
