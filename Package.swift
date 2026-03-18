// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShellForge",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.8.0"),
        .package(url: "https://github.com/nicklama/Libssh2Prebuild.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ShellForge",
            dependencies: [
                "SwiftTerm",
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
                "Libssh2Prebuild",
            ],
            path: "Sources/ShellForge",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
