import Foundation

public struct PinWindowPolicy: Equatable, Sendable {
    public enum Level: String, Equatable, Sendable {
        case normal
        case floating
    }

    public var level: Level
    public var joinsAllSpaces: Bool
    public var fullScreenAuxiliary: Bool
    public var coversMenuBar: Bool

    public init(
        level: Level,
        joinsAllSpaces: Bool,
        fullScreenAuxiliary: Bool,
        coversMenuBar: Bool
    ) {
        self.level = level
        self.joinsAllSpaces = joinsAllSpaces
        self.fullScreenAuxiliary = fullScreenAuxiliary
        self.coversMenuBar = coversMenuBar
    }
}

public enum PinPolicy {
    public static func policy(pinned: Bool) -> PinWindowPolicy {
        if pinned {
            return PinWindowPolicy(
                level: .floating,
                joinsAllSpaces: false,
                fullScreenAuxiliary: false,
                coversMenuBar: false
            )
        }
        return PinWindowPolicy(
            level: .normal,
            joinsAllSpaces: false,
            fullScreenAuxiliary: false,
            coversMenuBar: false
        )
    }
}
