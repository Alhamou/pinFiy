import Foundation

public struct AppCommand: Equatable, Sendable {
    public let identifier: String
    public let keyEquivalent: String

    public init(identifier: String, keyEquivalent: String) {
        self.identifier = identifier
        self.keyEquivalent = keyEquivalent
    }
}

public enum AppCommands {
    public static let newNote = AppCommand(identifier: "new-note", keyEquivalent: "n")
    public static let closeNote = AppCommand(identifier: "close-note", keyEquivalent: "w")
    public static let togglePin = AppCommand(identifier: "toggle-pin", keyEquivalent: "p")
    public static let settings = AppCommand(identifier: "settings", keyEquivalent: ",")
    public static let quit = AppCommand(identifier: "quit", keyEquivalent: "q")

    public static let all = [newNote, closeNote, togglePin, settings, quit]
}
