// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ld-ios-encode-poc",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "poc", targets: ["poc"])
    ],
    dependencies: [
        // The released SDK version this PoC targets.
        .package(url: "https://github.com/launchdarkly/ios-client-sdk", exact: "11.7.0")
    ],
    targets: [
        .executableTarget(
            name: "poc",
            dependencies: [
                .product(name: "LaunchDarkly", package: "ios-client-sdk")
            ],
            path: "Sources/poc"
        )
    ]
)
