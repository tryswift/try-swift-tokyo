// swift-tools-version: 6.3

import Foundation
import PackageDescription

// Skip dependencies are only needed for Android transpilation (skipstone plugin).
// Set INCLUDE_SKIP=1 environment variable to enable (e.g., `INCLUDE_SKIP=1 swift build`).
// Conference is consumed both by the iOS App (via App.xcodeproj) and by the Android
// SwiftPM package (`Android/Package.swift`, via `.package(path: "../Conference")`).
// Only the targets that have been migrated to SkipTCA carry the skipstone plugin;
// other targets remain iOS-only and are compiled by the host SwiftPM during INCLUDE_SKIP
// builds but never transpiled.
let includeSkipEnv = ProcessInfo.processInfo.environment["INCLUDE_SKIP"]?.lowercased()
let includeSkip = includeSkipEnv == "1" || includeSkipEnv == "true"

var packageDependencies: [Package.Dependency] = [
  .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
  .package(url: "https://github.com/maiyama18/LicensesPlugin", from: "0.2.0"),
  .package(url: "https://github.com/flitto/rtt_sdk", from: "0.2.0"),
  .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit.git", from: "2.0.5"),
  .package(url: "https://github.com/d-date/skip-tca", from: "0.2.0"),
  .package(name: "SharedModels", path: "../SharedModels"),
  .package(name: "DataClient", path: "../DataClient"),
]

// Skip-ready target plugin / deps (only when INCLUDE_SKIP=1).
var skipReadyTargetPlugins: [Target.PluginUsage] = []
var skipReadyExtraDeps: [Target.Dependency] = []
var skipReadyExclude: [String] = []

if includeSkip {
  packageDependencies += [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0"),
  ]
  skipReadyExtraDeps += [
    .product(name: "SkipUI", package: "skip-ui"),
    .product(name: "SkipFoundation", package: "skip-foundation"),
    .product(name: "SkipModel", package: "skip-model"),
  ]
  skipReadyTargetPlugins += [
    .plugin(name: "skipstone", package: "skip")
  ]
} else {
  skipReadyExclude += ["Skip"]
}

let package = Package(
  name: "Conference",
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
      name: "DependencyExtra",
      targets: ["DependencyExtra"]),
    .library(
      name: "SponsorFeature",
      targets: ["SponsorFeature"]),
    .library(
      name: "trySwiftFeature",
      targets: ["trySwiftFeature"]),
    .library(
      name: "VideoFeature",
      targets: ["VideoFeature"]),
  ],
  dependencies: packageDependencies,
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
        "DependencyExtra",
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SkipTCA", package: "skip-tca"),
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
      ] + skipReadyExtraDeps,
      exclude: skipReadyExclude,
      plugins: skipReadyTargetPlugins
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
        "VideoFeature",
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
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipTCA", package: "skip-tca"),
      ] + skipReadyExtraDeps,
      exclude: skipReadyExclude,
      resources: [
        .process("Media.xcassets"),
        .process("Localizable.xcstrings"),
      ],
      plugins: skipReadyTargetPlugins
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
        .product(name: "SkipTCATesting", package: "skip-tca"),
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
