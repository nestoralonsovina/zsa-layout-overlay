// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ZSALayoutOverlay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "zsa-layout-overlay", targets: ["ZSALayoutOverlay"]),
        .executable(name: "zsa-hid-probe", targets: ["ZSAHIDProbe"])
    ],
    targets: [
        .target(
            name: "ZSAHIDBridge",
            path: "HIDBridgeSources",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-I/opt/homebrew/Cellar/hidapi/0.15.0/include"])
            ],
            linkerSettings: [
                .unsafeFlags(["-L/opt/homebrew/lib", "-lhidapi"])
            ]
        ),
        .executableTarget(
            name: "ZSALayoutOverlay",
            dependencies: ["ZSAHIDBridge"],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "ZSAHIDProbe",
            path: "ProbeSources",
            cSettings: [
                .unsafeFlags(["-I/opt/homebrew/Cellar/hidapi/0.15.0/include"])
            ],
            linkerSettings: [
                .unsafeFlags(["-L/opt/homebrew/lib", "-lhidapi"])
            ]
        ),
        .testTarget(
            name: "ZSALayoutOverlayTests",
            dependencies: ["ZSALayoutOverlay"],
            path: "Tests"
        )
    ]
)
