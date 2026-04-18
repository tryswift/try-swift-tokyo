// swift-tools-version: 6.3

import Foundation
import PackageDescription

// Skip dependencies are only needed for Android transpilation (skipstone plugin).
// Set INCLUDE_SKIP=1 environment variable to enable (e.g., `INCLUDE_SKIP=1 swift build`).
let includeSkipEnv = ProcessInfo.processInfo.environment["INCLUDE_SKIP"]?.lowercased()
let includeSkip = includeSkipEnv == "1" || includeSkipEnv == "true"

var packageDependencies: [Package.Dependency] = []
var targetDependencies: [Target.Dependency] = []
var targetPlugins: [Target.PluginUsage] = []
var targetExclude: [String] = []

if includeSkip {
  packageDependencies += [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0"),
  ]
  targetDependencies += [
    .product(name: "SkipFoundation", package: "skip-foundation"),
    .product(name: "SkipModel", package: "skip-model"),
  ]
  targetPlugins += [
    .plugin(name: "skipstone", package: "skip")
  ]
} else {
  targetExclude += ["Skip"]
}

let package = Package(
  name: "SharedModels",
  platforms: [.iOS(.v26), .macOS(.v15), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    .library(
      name: "SharedModels",
      targets: ["SharedModels"]
    )
  ],
  dependencies: packageDependencies,
  targets: [
    .target(
      name: "SharedModels",
      dependencies: targetDependencies,
      exclude: targetExclude,
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ],
      plugins: targetPlugins
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
