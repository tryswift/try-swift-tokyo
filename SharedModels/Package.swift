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
  targets: [
    .target(
      name: "SharedModels",
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
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
