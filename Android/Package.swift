// swift-tools-version: 6.3
import PackageDescription

// Skip Fuse: Swift compiles natively for Android via the official Swift SDK
// for Android. Unlike Skip Lite, Foundation/Observation/Combine come from the
// real Swift toolchain (no Kotlin transpile), so Swift macros — including
// TCA's @Reducer / @ObservableState / @DependencyClient — work as-is. The
// Android wrapper just needs `skip-fuse-ui` for the SwiftUI → Compose bridge
// and the `skipstone` plugin for the build glue.
let package = Package(
  name: "try-swift-tokyo-android",
  defaultLocalization: "en",
  platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .watchOS(.v26)],
  products: [
    .library(name: "AndroidApp", type: .dynamic, targets: ["AndroidApp"])
  ],
  dependencies: [
    .package(url: "https://source.skip.tools/skip.git", from: "1.2.0"),
    .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
    .package(name: "DataClient", path: "../DataClient"),
    .package(name: "Conference", path: "../Conference"),
  ],
  targets: [
    .target(
      name: "AndroidApp",
      dependencies: [
        // Phase 4: SponsorFeature is the first feature shared via Conference.
        // The remaining tabs still use the Android-side legacy implementations
        // and will graduate to Conference one-by-one in Phase 5+.
        .product(name: "SponsorFeature", package: "Conference"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "SharedModels", package: "SharedModels"),
        "AndroidScheduleFeature",
        "VenueFeature",
        "AboutFeature",
        "AndroidLiveTranslationFeature",
        .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AndroidLiveTranslationFeature",
      dependencies: [
        .product(name: "SkipFuseUI", package: "skip-fuse-ui")
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AndroidScheduleFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "VenueFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
    .target(
      name: "AboutFeature",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
      ],
      plugins: [.plugin(name: "skipstone", package: "skip")]
    ),
  ]
)
