// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "CfPWeb",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "CfPWeb", targets: ["CfPWeb"])
  ],
  dependencies: [
    .package(url: "https://github.com/elementary-swift/elementary.git", from: "0.7.1"),
  ],
  targets: [
    .executableTarget(
      name: "CfPWeb",
      dependencies: [
        .product(name: "Elementary", package: "elementary"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
