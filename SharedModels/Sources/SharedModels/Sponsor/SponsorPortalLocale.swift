import Foundation

public enum SponsorPortalLocale: String, Codable, Sendable, CaseIterable, Equatable {
  case ja
  case en

  public static let `default`: SponsorPortalLocale = .ja

  public var htmlLangCode: String {
    switch self {
    case .ja: return "ja"
    case .en: return "en"
    }
  }
}
