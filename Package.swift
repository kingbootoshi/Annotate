// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Annotate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Annotate", targets: ["Annotate"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.4")
    ],
    targets: [
        .executableTarget(
            name: "Annotate",
            dependencies: ["KeyboardShortcuts"],
            path: "Annotate",
            exclude: [
                "Annotate.entitlements",
                "Info.plist"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content"),
            ]
        ),
        .testTarget(
            name: "AnnotateTests",
            dependencies: ["Annotate"],
            path: "AnnotateTests",
            swiftSettings: [
                .unsafeFlags(["-swift-version", "5"])
            ]
        ),
    ]
)
