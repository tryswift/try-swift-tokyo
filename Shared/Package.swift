// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Shared",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17)],
    products: [
        .library(name: "SharedViews", targets: ["SharedViews"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(
            name: "SharedViews",
            dependencies: [
                .product(name: "SharedModels", package: "SharedModels"),
            ]
        ),
    ]
)
