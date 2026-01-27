/// Supported languages for CfP pages
public enum CfPLanguage: String, Sendable, CaseIterable {
  case en
  case ja

  public var displayName: String {
    switch self {
    case .en: return "English"
    case .ja: return "日本語"
    }
  }

  public var urlPrefix: String {
    return rawValue
  }

  public var otherLanguage: CfPLanguage {
    switch self {
    case .en: return .ja
    case .ja: return .en
    }
  }
}
