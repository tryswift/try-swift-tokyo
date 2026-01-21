// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "CfPWebsite",
  defaultLocalization: "en",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/twostraws/Ignite", from: "0.6.0"),
    .package(path: "../MyLibrary")
  ],
  targets: [
    .executableTarget(
      name: "CfPWebsite",
      dependencies: [
        "Ignite",
        .product(name: "SharedModels", package: "MyLibrary"),
      ]
    ),
  ]
)
