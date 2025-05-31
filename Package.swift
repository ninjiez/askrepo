// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AskRepo",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AskRepo", targets: ["AskRepo"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AskRepo",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("../Resources")
            ]
        )
    ]
) 