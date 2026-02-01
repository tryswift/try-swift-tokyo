// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Server",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "Server", targets: ["Server"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
    .package(url: "https://github.com/vapor/jwt.git", from: "5.1.0"),
    .package(url: "https://github.com/vapor-community/vapor-elementary.git", from: "0.2.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
  ],
  targets: [
    .executableTarget(
      name: "Server",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "JWT", package: "jwt"),
        .product(name: "VaporElementary", package: "vapor-elementary"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "ServerTests",
      dependencies: [
        "Server",
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "XCTVapor", package: "vapor"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ]
)
