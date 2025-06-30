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
    dependencies: [
        .package(url: "https://github.com/aespinilla/Tiktoken.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "AskRepo",
            dependencies: [
                .product(name: "Tiktoken", package: "Tiktoken")
            ],
            path: "Sources",
            resources: [
                .copy("../Resources")
            ]
        )
    ]
) 