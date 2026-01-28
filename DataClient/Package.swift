// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "DataClient",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .watchOS(.v10),
    .tvOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "DataClient",
      targets: ["DataClient"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.2.0"),
    .package(path: "../SharedModels"),
  ],
  targets: [
    .target(
      name: "DataClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      resources: [
        .process("Resources")
      ]
    )
  ]
)
