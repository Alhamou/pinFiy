// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PinFiy",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PinFiyCore", targets: ["PinFiyCore"]),
        .executable(name: "PinFiyApp", targets: ["PinFiyApp"])
    ],
    targets: [
        .target(name: "PinFiyCore"),
        .executableTarget(
            name: "PinFiyApp",
            dependencies: ["PinFiyCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "PinFiyCoreTests",
            dependencies: ["PinFiyCore"]
        )
    ]
)
