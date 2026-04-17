// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "CfPWeb",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "CfPWeb", targets: ["CfPWeb"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
    .package(url: "https://github.com/vapor-community/vapor-elementary.git", from: "0.2.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
  ],
  targets: [
    .executableTarget(
      name: "CfPWeb",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "VaporElementary", package: "vapor-elementary"),
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
