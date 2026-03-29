// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "iOS",
  defaultLocalization: "en",
  platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]),
    .library(
      name: "GuidanceFeature",
      targets: ["GuidanceFeature"]),
    .library(
      name: "ScheduleFeature",
      targets: ["ScheduleFeature"]),
    .library(
      name: "trySwiftFeature",
      targets: ["trySwiftFeature"]),
    .library(
      name: "VideoFeature",
      targets: ["VideoFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.0"),
    .package(url: "https://github.com/maiyama18/LicensesPlugin", from: "0.2.0"),
    .package(url: "https://github.com/flitto/rtt_sdk", from: "0.1.9"),
    .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit.git", from: "2.0.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
    .package(name: "DataClient", path: "../DataClient"),
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "GuidanceFeature",
        "LiveTranslationFeature",
        "ScheduleFeature",
        "SponsorFeature",
        "trySwiftFeature",
        "VideoFeature",
        .product(name: "SharedModels", package: "SharedModels"),
      ]
    ),
    .target(
      name: "BuildConfig",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "DependencyExtra",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "GuidanceFeature",
      dependencies: [
        "DependencyExtra",
        "MapKitClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "LiveTranslationFeature",
      dependencies: [
        "BuildConfig",
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "LiveTranslationSDK", package: "rtt_sdk"),
      ]
    ),
    .target(
      name: "MapKitClient",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SharedModels", package: "SharedModels"),
      ]
    ),
    .target(
      name: "ScheduleFeature",
      dependencies: [
        .product(name: "DataClient", package: "DataClient"),
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "VideoFeature",
      dependencies: [
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "YouTubePlayerKit", package: "YouTubePlayerKit"),
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SponsorFeature",
      dependencies: [
        .product(name: "DataClient", package: "DataClient"),
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "trySwiftFeature",
      dependencies: [
        .product(name: "DataClient", package: "DataClient"),
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
      plugins: [
        .plugin(name: "LicensesPlugin", package: "LicensesPlugin")
      ]
    ),
    .testTarget(
      name: "LiveTranslationFeatureTests",
      dependencies: [
        "LiveTranslationFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "ScheduleFeatureTests",
      dependencies: [
        "ScheduleFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "SponsorFeatureTests",
      dependencies: [
        "SponsorFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SharedModels", package: "SharedModels"),
      ]
    ),
    .testTarget(
      name: "trySwiftFeatureTests",
      dependencies: [
        "trySwiftFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SharedModels", package: "SharedModels"),
      ]
    ),
  ]
)
