// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShellForge",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "ShellForge",
            dependencies: [
                "SwiftTerm",
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
            ],
            path: "Sources/ShellForge",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
