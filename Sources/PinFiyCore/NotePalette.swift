import Foundation

public struct NoteColor: Equatable, Sendable {
    public let hex: String
    public let textHex: String

    public init(hex: String, textHex: String) {
        self.hex = hex
        self.textHex = textHex
    }
}

public enum NotePalette {
    public static let textHex = "#2C2A26"
    public static let lightTextHex = "#F6F3EC"
    public static let defaultHex = "#F3C15B"

    public static let lightColors: [NoteColor] = [
        NoteColor(hex: "#F3C15B", textHex: textHex),
        NoteColor(hex: "#F3E7A1", textHex: textHex),
        NoteColor(hex: "#F3C7B0", textHex: textHex),
        NoteColor(hex: "#C9E4D4", textHex: textHex),
        NoteColor(hex: "#D5DDB8", textHex: textHex),
        NoteColor(hex: "#C5DDF0", textHex: textHex),
        NoteColor(hex: "#D9D0EE", textHex: textHex),
        NoteColor(hex: "#F0D0D6", textHex: textHex),
        NoteColor(hex: "#E6D7C3", textHex: textHex),
        NoteColor(hex: "#D5DDE3", textHex: textHex)
    ]

    public static let darkColors: [NoteColor] = [
        NoteColor(hex: "#5C4518", textHex: lightTextHex),
        NoteColor(hex: "#4E4830", textHex: lightTextHex),
        NoteColor(hex: "#5C3A32", textHex: lightTextHex),
        NoteColor(hex: "#234338", textHex: lightTextHex),
        NoteColor(hex: "#3A432C", textHex: lightTextHex),
        NoteColor(hex: "#24384C", textHex: lightTextHex),
        NoteColor(hex: "#3A3454", textHex: lightTextHex),
        NoteColor(hex: "#4C3038", textHex: lightTextHex),
        NoteColor(hex: "#3E362C", textHex: lightTextHex),
        NoteColor(hex: "#2C343C", textHex: lightTextHex)
    ]

    public static let colors: [NoteColor] = lightColors + darkColors

    public static func contains(_ hex: String) -> Bool {
        colors.contains { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }
    }

    public static func textHex(for background: String) -> String {
        colors.first { $0.hex.caseInsensitiveCompare(background) == .orderedSame }?.textHex ?? textHex
    }
}
