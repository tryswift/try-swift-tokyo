// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Website",
  defaultLocalization: "en",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(url: "https://github.com/twostraws/Ignite", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.2.0"),
    .package(path: "../iOS"),
    .package(path: "../LocalizationGenerated")
  ],
  targets: [
    .executableTarget(
      name: "Website",
      dependencies: [
        "Ignite",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DataClient", package: "iOS"),
        .product(name: "LocalizationGenerated", package: "LocalizationGenerated"),
      ],
      resources: [
        .process("Resources")
      ]
    ),
  ]
)
