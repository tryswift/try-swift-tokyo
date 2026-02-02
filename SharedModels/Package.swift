// swift-tools-version: 6.2

import PackageDescription

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
  ],
  targets: [
    .target(
      name: "SharedModels",
      dependencies: [
        .product(name: "SkipFoundation", package: "skip-foundation")
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
