// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "CfPWebsite",
  defaultLocalization: "en",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/twostraws/Ignite", from: "0.6.0"),
    .package(path: "../SharedModels")
  ],
  targets: [
    .executableTarget(
      name: "CfPWebsite",
      dependencies: [
        "Ignite",
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .testTarget(
      name: "CfPWebsiteTests",
      dependencies: ["CfPWebsite"],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
