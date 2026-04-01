import SharedModels

enum SessionTag: String, CaseIterable, Equatable, Hashable, Sendable {
  // UI Frameworks
  case swiftUI = "SwiftUI"
  case uiKit = "UIKit"

  // Language Features
  case concurrency = "Concurrency"
  case macros = "Macros"
  case generics = "Generics"
  case protocols = "Protocols"
  case resultBuilders = "Result Builders"
  case propertyWrappers = "Property Wrappers"
  case codable = "Codable"

  // Platforms
  case visionOS = "visionOS"
  case watchOS = "watchOS"
  case crossPlatform = "Cross Platform"

  // Domains
  case testing = "Testing"
  case performance = "Performance"
  case accessibility = "Accessibility"
  case animation = "Animation"
  case networking = "Networking"
  case security = "Security"
  case localization = "Localization"
  case architecture = "Architecture"
  case openSource = "Open Source"
  case serverSide = "Server-side Swift"
  case compiler = "Compiler"
  case debugging = "Debugging"
  case documentation = "Documentation"
  case designPatterns = "Design Patterns"

  // Data/Storage
  case swiftData = "SwiftData"
  case coreData = "Core Data"
  case database = "Database"

  // AI/ML
  case ai = "AI"
  case coreML = "Core ML"

  // Graphics
  case metal = "Metal"
  case graphics = "Graphics"

  // Frameworks
  case arKit = "ARKit"
  case appIntents = "App Intents"
  case widgetKit = "WidgetKit"
  case swiftPackageManager = "Swift Package Manager"
  case instruments = "Instruments"
  case combine = "Combine"

  // Swift language
  case swiftLanguage = "Swift Language"
  case typeSystem = "Type System"
  case memoryManagement = "Memory Management"

  var keywords: [String] {
    switch self {
    case .swiftUI: return ["swiftui"]
    case .uiKit: return ["uikit", "uicollectionview", "uitableview", "uiviewcontroller"]
    case .concurrency:
      return [
        "concurrency", "async/await", "async await", "actors", "sendable",
        "structured concurrency", "task group",
      ]
    case .macros: return ["macro", "macros", "@attached", "@freestanding"]
    case .generics: return ["generic", "generics"]
    case .protocols: return ["protocol-oriented", "protocol oriented"]
    case .resultBuilders: return ["result builder", "resultbuilder", "@resultbuilder"]
    case .propertyWrappers: return ["property wrapper", "propertywrapper", "@propertyWrapper"]
    case .codable: return ["codable", "encoding", "decoding", "json"]
    case .visionOS:
      return ["visionos", "vision pro", "spatial computing", "realitykit", "immersive"]
    case .watchOS: return ["watchos", "apple watch"]
    case .crossPlatform:
      return [
        "cross-platform", "cross platform", "multiplatform", "kotlin",
      ]
    case .testing:
      return [
        "testing", "xctest", "swift testing", "snapshot test", "unit test", "tdd",
        "test-driven",
      ]
    case .performance:
      return ["performance", "optimization", "optimizing", "profiling", "high-performance"]
    case .accessibility:
      return ["accessibility", "voiceover", "a11y", "assistive"]
    case .animation: return ["animation", "animations", "motion", "transition"]
    case .networking:
      return ["networking", "urlsession", "http", "grpc", "websocket", "rest api"]
    case .security:
      return ["security", "keychain", "encryption", "cryptokit", "auth"]
    case .localization:
      return ["localization", "internationalization", "i18n", "l10n", "string catalog"]
    case .architecture:
      return [
        "architecture", "composable architecture", "tca", "mvvm", "clean architecture",
        "redux", "unidirectional",
      ]
    case .openSource: return ["open source", "open-source", "oss"]
    case .serverSide:
      return [
        "server-side", "server side", "server swift", "vapor", "hummingbird", "backend",
      ]
    case .compiler: return ["compiler", "llvm", "swiftc", "compilation"]
    case .debugging: return ["debugging", "lldb", "debugger", "crash"]
    case .documentation: return ["documentation", "docc", "doc comment"]
    case .designPatterns:
      return [
        "design pattern", "dependency injection", "observer pattern", "singleton",
        "coordinator",
      ]
    case .swiftData: return ["swiftdata"]
    case .coreData: return ["core data", "coredata", "nsfetchedresultscontroller"]
    case .database: return ["database", "sqlite", "realm", "persistence"]
    case .ai:
      return [
        "ai", "machine learning", "artificial intelligence", "foundation model",
        "llm", "on-device intelligence", "ml model",
      ]
    case .coreML: return ["coreml", "core ml", "createml", "create ml"]
    case .metal: return ["metal", "shader", "gpu computing"]
    case .graphics: return ["graphics", "core graphics", "core image", "rendering"]
    case .arKit: return ["arkit", "augmented reality"]
    case .appIntents: return ["app intent", "appintent", "siri", "shortcut"]
    case .widgetKit: return ["widgetkit", "widget"]
    case .swiftPackageManager:
      return ["swift package manager", "package.swift"]
    case .instruments:
      return ["instruments", "time profiler", "allocation"]
    case .combine: return ["combine", "publisher", "subscriber"]
    case .swiftLanguage:
      return [
        "swift language", "swift evolution", "swift 5", "swift 6",
        "what's new in swift", "new in swift",
      ]
    case .typeSystem:
      return ["type system", "type safety", "type erasure", "opaque type", "existential"]
    case .memoryManagement:
      return ["memory management", "arc", "retain cycle", "memory leak", "weak reference"]
    }
  }
}

enum SessionTagging {
  static func generateTags(for session: Session) -> Set<SessionTag> {
    var corpus = session.title.lowercased()
    if let description = session.description {
      corpus += " " + description.lowercased()
    }
    if let summary = session.summary {
      corpus += " " + summary.lowercased()
    }

    var tags: Set<SessionTag> = []
    for tag in SessionTag.allCases {
      for keyword in tag.keywords {
        if corpus.contains(keyword) {
          tags.insert(tag)
          break
        }
      }
    }
    return tags
  }

  /// Normalize a speaker name into a set of lowercase word components for fuzzy matching.
  /// Handles variations like "Katsumi Kishikawa", "kishikawa katsumi", "giginet(Kohki Miki)".
  static func nameComponents(_ name: String) -> Set<String> {
    Set(
      name.lowercased()
        .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        .map(String.init)
        .filter { $0.count > 1 }
    )
  }

  /// Check if two speaker names likely refer to the same person.
  /// Compares normalized word components — the smaller set must be a subset of the larger.
  static func speakerNamesMatch(_ name1: String, _ name2: String) -> Bool {
    let words1 = nameComponents(name1)
    let words2 = nameComponents(name2)
    guard !words1.isEmpty, !words2.isEmpty else { return false }
    let smaller = words1.count <= words2.count ? words1 : words2
    let larger = words1.count > words2.count ? words1 : words2
    return smaller.isSubset(of: larger)
  }
}
