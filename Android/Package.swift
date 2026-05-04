// swift-tools-version: 6.3
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
    .package(name: "DataClient", path: "../DataClient"),
    .package(name: "Conference", path: "../Conference"),
  ],
  targets: [
    .target(
      name: "AndroidApp",
      dependencies: [
        "AndroidScheduleFeature",
        "VenueFeature",
        "AboutFeature",
        "AndroidLiveTranslationFeature",
        .product(name: "SponsorFeature", package: "Conference"),
        .product(name: "DependencyExtra", package: "Conference"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AndroidLiveTranslationFeature",
      dependencies: [
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      path: "Sources/AndroidLiveTranslationFeature",
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AndroidScheduleFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipUI", package: "skip-ui"),
        .product(name: "SkipFoundation", package: "skip-foundation"),
        .product(name: "SkipModel", package: "skip-model"),
      ],
      path: "Sources/AndroidScheduleFeature",
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
