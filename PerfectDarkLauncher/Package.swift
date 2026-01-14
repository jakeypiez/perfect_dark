// swift-tools-version:5.7
// This Package.swift is for VS Code/SourceKit indexing only.
// Use xcodebuild or build_dmg.sh to build the actual app.

import PackageDescription

let package = Package(
    name: "PerfectDarkLauncher",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "PerfectDarkLauncher", targets: ["PerfectDarkLauncher"])
    ],
    targets: [
        .executableTarget(
            name: "PerfectDarkLauncher",
            path: "PerfectDarkLauncher",
            exclude: [
                "Assets.xcassets",
                "Resources",
                "PerfectDarkLauncher.entitlements"
            ],
            sources: [
                "PerfectDarkLauncherApp.swift",
                "ContentView.swift",
                "GameSettings.swift",
                "GameLauncher.swift"
            ]
        )
    ]
)
