// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Server",
  platforms: [.macOS(.v14), .linux],
  products: [
    .executable(name: "Server", targets: ["Server"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
    .package(url: "https://github.com/vapor/jwt.git", from: "5.1.0"),
  ],
  targets: [
    // SharedModels - embedded directly to avoid iOS-only dependencies in MyLibrary
    .target(
      name: "SharedModels",
      path: "../MyLibrary/Sources/SharedModels",
      sources: [
        "CfP/ConferenceDTO.swift",
        "CfP/ProposalDTO.swift",
        "CfP/UserDTO.swift",
        "CfP/UserRole.swift",
        "CfPExports.swift",
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .executableTarget(
      name: "Server",
      dependencies: [
        "SharedModels",
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "JWT", package: "jwt"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "ServerTests",
      dependencies: [
        "Server",
        .product(name: "XCTVapor", package: "vapor"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ]
)
