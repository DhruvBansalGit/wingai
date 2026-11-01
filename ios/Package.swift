// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WingAIiOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WingAICore",
            targets: ["WingAICore"]
        )
    ],
    targets: [
        .target(
            name: "WingAICore",
            path: ".",
            exclude: ["Tests", "Package.swift", "README.md"],
            sources: [
                "Shared/WingModels.swift",
                "Shared/WingAiApiClient.swift",
                "Shared/WingAiDesignSystem.swift",
                "WingAIKeyboard/WingAiKeyboardView.swift",
                "WingAIKeyboard/KeyboardViewController.swift",
                "WingAIApp/WingAIApp.swift",
                "WingAIBroadcast/SampleHandler.swift"
            ]
        ),
        .testTarget(
            name: "WingAITests",
            dependencies: ["WingAICore"],
            path: "Tests"
        )
    ]
)
