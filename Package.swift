// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
    name: "human-rated-ai",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "HumanRatedAIApp", type: .dynamic, targets: ["HumanRatedAI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://source.skip.tools/skip.git", from: "1.0.10"),
        .package(url: "https://source.skip.tools/skip-firebase.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "HumanRatedAI",
                dependencies: [
                    .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                    .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
                    .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
                    .product(name: "SkipUI", package: "skip-ui"),
                ],
                resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "HumanRatedAITests",
                    dependencies: ["HumanRatedAI", .product(name: "SkipTest", package: "skip")],
                    resources: [.process("Resources")],
                    plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
