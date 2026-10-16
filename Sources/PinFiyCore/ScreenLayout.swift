import Foundation

public struct ScreenRect: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }

    public func intersects(_ other: ScreenRect) -> Bool {
        x < other.maxX && maxX > other.x && y < other.maxY && maxY > other.y
    }

    public func centeredFrame(width: Double, height: Double) -> ScreenRect {
        ScreenRect(
            x: x + (self.width - width) / 2,
            y: y + (self.height - height) / 2,
            width: width,
            height: height
        )
    }
}

public enum ScreenLayout {
    public static func visibleFrame(
        for frame: ScreenRect,
        screens: [ScreenRect],
        mainScreen: ScreenRect
    ) -> ScreenRect {
        if screens.contains(where: { frame.intersects($0) }) {
            return frame
        }
        return mainScreen.centeredFrame(width: frame.width, height: frame.height)
    }
}
