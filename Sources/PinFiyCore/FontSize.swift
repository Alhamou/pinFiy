import Foundation

public enum FontSize {
    public static let minimum = 12.0
    public static let maximum = 36.0
    public static let standard = 16.0

    public static func clamp(_ value: Double) -> Double {
        min(maximum, max(minimum, value))
    }
}
