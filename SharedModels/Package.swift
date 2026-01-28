// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SharedModels",
  platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
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
    )
  ]
)
