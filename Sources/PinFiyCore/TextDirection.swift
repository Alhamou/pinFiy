import Foundation

public enum TextDirection: Equatable, Sendable {
    case leftToRight
    case rightToLeft

    public var pinOnTheRight: Bool {
        self == .rightToLeft
    }
}

public enum TextDirectionDetector {
    public static func direction(of text: String, systemIsArabic: Bool) -> TextDirection {
        for scalar in text.unicodeScalars {
            if let strong = strongDirection(of: scalar) {
                return strong
            }
        }
        return systemIsArabic ? .rightToLeft : .leftToRight
    }

    private static func strongDirection(of scalar: Unicode.Scalar) -> TextDirection? {
        guard scalar.properties.isAlphabetic else { return nil }
        return isRightToLeftScript(scalar) ? .rightToLeft : .leftToRight
    }

    private static func isRightToLeftScript(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
            return true
        default:
            return false
        }
    }
}
