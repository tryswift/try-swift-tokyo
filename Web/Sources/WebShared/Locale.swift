import Foundation

public enum WebLocale: String, Sendable, CaseIterable {
  case ja, en
  public var htmlLang: String { rawValue }
}
