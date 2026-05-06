// swift-tools-version: 6.3

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
    .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.7.0"),
    .package(url: "https://github.com/vapor/jwt.git", from: "5.1.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
    .package(name: "DataClient", path: "../DataClient"),
    .package(name: "Web", path: "../Web"),
  ],
  targets: [
    .executableTarget(
      name: "Server",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "WebShared", package: "Web"),
        .product(name: "WebSponsor", package: "Web"),
        .product(name: "WebScholarship", package: "Web"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "JWT", package: "jwt"),
        .product(name: "Crypto", package: "swift-crypto"),
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
        .product(name: "VaporTesting", package: "vapor"),
        .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ]
)
