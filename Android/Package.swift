// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "try-swift-tokyo-android",
  defaultLocalization: "en",
  platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .watchOS(.v26)],
  products: [
    .library(name: "AndroidApp", type: .dynamic, targets: ["AndroidApp"])
  ],
  dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
    .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
  ],
  targets: [
    .target(
      name: "AndroidApp",
      dependencies: [
        "ScheduleFeature",
        "SponsorFeature",
        "VenueFeature",
        "AboutFeature",
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "ScheduleFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "SponsorFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "VenueFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AboutFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
  ]
)
