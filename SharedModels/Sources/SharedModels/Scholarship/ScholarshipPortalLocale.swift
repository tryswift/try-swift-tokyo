import Foundation

/// Locale used when rendering student.tryswift.jp pages and dispatching emails.
public enum ScholarshipPortalLocale: String, Codable, Sendable, CaseIterable, Equatable {
  case ja
  case en

  public static let `default`: ScholarshipPortalLocale = .ja

  public var htmlLangCode: String {
    switch self {
    case .ja: return "ja"
    case .en: return "en"
    }
  }
}
