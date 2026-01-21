// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MyLibrary",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17), .visionOS(.v1)],
  products: [
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]),
    .library(
      name: "CfPAPIClient",
      targets: ["CfPAPIClient"]),
    .library(
      name: "CfPFeature",
      targets: ["CfPFeature"]),
    .library(
      name: "GuidanceFeature",
      targets: ["GuidanceFeature"]),
    .library(
      name: "DataClient",
      targets: ["DataClient"]),
    .library(
      name: "SharedModels",
      targets: ["SharedModels"]),
    .library(
      name: "ScheduleFeature",
      targets: ["ScheduleFeature"]),
    .library(
      name: "trySwiftFeature",
      targets: ["trySwiftFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.18.0"),
    .package(url: "https://github.com/maiyama18/LicensesPlugin", from: "0.2.0"),
    .package(url: "https://github.com/flitto/rtt_sdk", branch: "0.1.5"),
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "CfPFeature",
        "GuidanceFeature",
        "LiveTranslationFeature",
        "ScheduleFeature",
        "SponsorFeature",
        "trySwiftFeature",
      ]
    ),
    .target(
      name: "CfPAPIClient",
      dependencies: [
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "CfPFeature",
      dependencies: [
        "CfPAPIClient",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "BuildConfig",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "DataClient",
      dependencies: [
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .target(
      name: "DependencyExtra",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .target(
      name: "GuidanceFeature",
      dependencies: [
        "DependencyExtra",
        "MapKitClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "LiveTranslationFeature",
      dependencies: [
        "BuildConfig",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "rtt-sdk", package: "rtt_sdk"),
      ]
    ),
    .target(
      name: "MapKitClient",
      dependencies: [
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ScheduleFeature",
      dependencies: [
        "DataClient",
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SharedModels",
      sources: [
        "CfP/ConferenceDTO.swift",
        "CfP/ProposalDTO.swift",
        "CfP/UserDTO.swift",
        "CfP/UserRole.swift",
        "CfPExports.swift",
        "Conference.swift",
        "ConferenceYear.swift",
        "Organizer.swift",
        "Speaker.swift",
        "Sponsors.swift",
      ]
    ),
    .target(
      name: "SponsorFeature",
      dependencies: [
        "DataClient",
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "trySwiftFeature",
      dependencies: [
        "DataClient",
        "DependencyExtra",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
      plugins: [
        .plugin(name: "LicensesPlugin", package: "LicensesPlugin")
      ]
    ),
    .testTarget(
      name: "ScheduleFeatureTests",
      dependencies: [
        "ScheduleFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "SponsorFeatureTests",
      dependencies: [
        "SponsorFeature",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "trySwiftFeatureTests",
      dependencies: [
        "trySwiftFeature",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)
