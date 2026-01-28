import Vapor

/// Supported languages for CfP pages
enum CfPLanguage: String, CaseIterable, Sendable {
  case en
  case ja

  /// Display name for the language
  var displayName: String {
    switch self {
    case .en: return "English"
    case .ja: return "日本語"
    }
  }

  /// Path prefix for URLs
  var pathPrefix: String {
    switch self {
    case .en: return ""  // English is default, no prefix
    case .ja: return "/ja"
    }
  }

  /// Creates path for a given route in this language
  func path(for route: String) -> String {
    if self == .en {
      return route
    } else {
      return "/ja\(route)"
    }
  }

  /// Parse language from request path
  static func from(request req: Request) -> CfPLanguage {
    let pathComponents = req.url.path.split(separator: "/")
    if pathComponents.contains("ja") {
      return .ja
    }
    return .en
  }
}
