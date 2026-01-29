// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "LocalizationGenerated",
  platforms: [
    .macOS(.v15),
    .iOS(.v17),
  ],
  products: [
    .library(
      name: "LocalizationGenerated",
      targets: ["LocalizationGenerated"]
    )
  ],
  dependencies: [
    .package(path: "../SharedModels")
  ],
  targets: [
    .target(
      name: "LocalizationGenerated",
      dependencies: [
        .product(name: "SharedModels", package: "SharedModels")
      ],
      plugins: [
        "LocalizationCodegenPlugin"
      ]
    ),
    .plugin(
      name: "LocalizationCodegenPlugin",
      capability: .buildTool()
    ),
  ]
)
