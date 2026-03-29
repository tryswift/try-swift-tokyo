// swift-tools-version: 6.3

import PackageDescription

// NOTE: Skip dependencies are required here for Android transpilation via the skipstone
// plugin. SkipFoundation/SkipModel are lightweight on iOS/macOS (thin re-exports of
// Foundation/Observation). The skipstone plugin is a build tool that only runs during
// compilation and adds no runtime overhead on non-Android platforms.

let package = Package(
  name: "SharedModels",
  platforms: [.iOS(.v26), .macOS(.v15), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    .library(
      name: "SharedModels",
      targets: ["SharedModels"]
    )
  ],
  dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SharedModels",
      dependencies: [
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .testTarget(
      name: "SharedModelsTests",
      dependencies: ["SharedModels"],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ]
)
