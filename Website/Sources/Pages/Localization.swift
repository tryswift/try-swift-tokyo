import LocalizationGenerated
import SharedModels

enum SupportedLanguage: String, CaseIterable {
  case ja
  case en
}

// Extension to convert LocalizedString → String based on language
extension LocalizedString {
  func localized(for language: SupportedLanguage) -> String {
    switch language {
    case .ja: return ja
    case .en: return en
    }
  }
}

// Extension for String literals used in UI
// Looks up from Website, then trySwiftFeature Localizable.xcstrings, falls back to literal if not found
extension String {
  init(_ literal: String, language: SupportedLanguage) {
    if let localized = WebsiteStrings[literal] {
      self = localized.localized(for: language)
    } else if let localized = TrySwiftStrings[literal] {
      self = localized.localized(for: language)
    } else {
      // Fallback to literal if not found in localizations
      self = literal
    }
  }
}

// Centralized lookup for dynamic localization keys
enum Localization {
  /// Lookup session titles, speaker bios, and other content from ScheduleFeature
  static func schedule(_ key: String, language: SupportedLanguage) -> String {
    ScheduleStrings[key]?.localized(for: language) ?? key
  }

  /// Lookup organizer names, bios, and other content from trySwiftFeature
  static func trySwift(_ key: String, language: SupportedLanguage) -> String {
    TrySwiftStrings[key]?.localized(for: language) ?? key
  }
}
