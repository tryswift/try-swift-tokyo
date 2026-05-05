// swift-tools-version: 6.3

import PackageDescription

// SharedModels: pure-data SwiftPM package consumed by iOS App, Server, and the
// Skip Fuse Android wrapper. With Skip Fuse, Swift compiles natively for
// Android via the official Swift SDK for Android, so SharedModels does not
// need any Skip-specific shims or plugins — the standard SwiftPM configuration
// works for both platforms.
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
      exclude: ["Skip"],
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
