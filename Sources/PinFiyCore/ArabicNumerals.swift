import Foundation

public enum ArabicNumerals {
    /// Converts Eastern Arabic numerals (٠-٩) and Extended Arabic/Persian numerals (۰-۹) to standard Western/English digits (0-9).
    public static func convertToEnglish(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = ""
        result.reserveCapacity(text.count)
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: // Eastern Arabic-Indic digits ٠...٩
                let asciiValue = UInt32(0x30) + (scalar.value - 0x0660)
                result.append(Character(UnicodeScalar(asciiValue)!))
            case 0x06F0...0x06F9: // Extended Arabic-Indic digits ۰...۹
                let asciiValue = UInt32(0x30) + (scalar.value - 0x06F0)
                result.append(Character(UnicodeScalar(asciiValue)!))
            default:
                result.append(Character(scalar))
            }
        }
        return result
    }

    /// Checks if a string contains any Eastern Arabic or Extended Arabic/Persian numerals.
    public static func containsArabicNumerals(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0660...0x0669).contains(scalar.value) || (0x06F0...0x06F9).contains(scalar.value)
        }
    }
}

extension String {
    public var withEnglishNumerals: String {
        ArabicNumerals.convertToEnglish(self)
    }
}
