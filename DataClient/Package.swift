// swift-tools-version: 6.3

import Foundation
import PackageDescription

// Skip dependencies are only needed for Android transpilation (skipstone plugin).
// Set INCLUDE_SKIP=1 environment variable to enable (e.g., `INCLUDE_SKIP=1 swift build`).
let includeSkipEnv = ProcessInfo.processInfo.environment["INCLUDE_SKIP"]?.lowercased()
let includeSkip = includeSkipEnv == "1" || includeSkipEnv == "true"

var packageDependencies: [Package.Dependency] = [
  .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.12.0"),
  .package(path: "../SharedModels"),
]
var targetDependencies: [Target.Dependency] = [
  .product(name: "Dependencies", package: "swift-dependencies"),
  .product(name: "DependenciesMacros", package: "swift-dependencies"),
  .product(name: "SharedModels", package: "SharedModels"),
]
var targetPlugins: [Target.PluginUsage] = []
var targetExclude: [String] = []

if includeSkip {
  packageDependencies += [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
  ]
  targetDependencies += [
    .product(name: "SkipFoundation", package: "skip-foundation")
  ]
  targetPlugins += [
    .plugin(name: "skipstone", package: "skip")
  ]
} else {
  targetExclude += ["Skip"]
}

let package = Package(
  name: "DataClient",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v15),
    .iOS(.v26),
    .watchOS(.v26),
    .tvOS(.v26),
    .visionOS(.v26),
  ],
  products: [
    .library(
      name: "DataClient",
      targets: ["DataClient"]
    )
  ],
  dependencies: packageDependencies,
  targets: [
    .target(
      name: "DataClient",
      dependencies: targetDependencies,
      exclude: targetExclude,
      resources: [
        .process("Resources")
      ],
      plugins: targetPlugins
    ),
    .testTarget(
      name: "DataClientTests",
      dependencies: [
        "DataClient",
        .product(name: "SharedModels", package: "SharedModels"),
      ]
    ),
  ]
)
