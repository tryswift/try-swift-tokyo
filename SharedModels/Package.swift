// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SharedModels",
  platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17), .visionOS(.v1)],
  products: [
    .library(
      name: "SharedModels",
      targets: ["SharedModels"]
    ),
  ],
  targets: [
    .target(
      name: "SharedModels",
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ]
)
