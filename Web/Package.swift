// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "Web",
  defaultLocalization: "en",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "WebShared", targets: ["WebShared"]),
    .library(name: "WebSponsor", targets: ["WebSponsor"]),
    .executable(name: "WebCfP", targets: ["WebCfP"]),
    .executable(name: "WebScholarship", targets: ["WebScholarship"]),
    .executable(name: "WebConference", targets: ["WebConference"]),
  ],
  dependencies: [
    .package(url: "https://github.com/elementary-swift/elementary.git", from: "0.7.1"),
    .package(url: "https://github.com/twostraws/Ignite.git", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.2.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
    .package(name: "DataClient", path: "../DataClient"),
    .package(name: "LocalizationGenerated", path: "../LocalizationGenerated"),
  ],
  targets: [
    .target(
      name: "WebShared",
      dependencies: [
        .product(name: "Elementary", package: "elementary")
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .target(
      name: "WebSponsor",
      dependencies: [
        "WebShared",
        .product(name: "Elementary", package: "elementary"),
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "WebScholarship",
      dependencies: [
        "WebShared",
        .product(name: "Elementary", package: "elementary"),
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "WebCfP",
      dependencies: [
        "WebShared",
        .product(name: "Elementary", package: "elementary"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "WebConference",
      dependencies: [
        "WebShared",
        .product(name: "Ignite", package: "Ignite"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "LocalizationGenerated", package: "LocalizationGenerated"),
      ],
      resources: [
        .process("Resources")
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
