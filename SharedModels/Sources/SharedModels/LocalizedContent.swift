import Foundation

// Locale-aware accessors for JSON-sourced content with Japanese variants.
// UI chrome strings (e.g. "Schedule", "Day 1") remain in Localizable.xcstrings.

private var isJapanese: Bool {
  Locale.current.language.languageCode?.identifier == "ja"
}

extension Session {
  public var localizedTitle: String {
    isJapanese ? (titleJa ?? title) : title
  }

  public var localizedSummary: String? {
    isJapanese ? (summaryJa ?? summary) : summary
  }

  public var localizedDescription: String? {
    isJapanese ? (descriptionJa ?? description) : description
  }

  public var localizedRequirements: String? {
    isJapanese ? (requirementsJa ?? requirements) : requirements
  }

  public var localizedPlace: String? {
    isJapanese ? (placeJa ?? place) : place
  }
}

extension Speaker {
  public var localizedBio: String? {
    isJapanese ? (bioJa ?? bio) : bio
  }

  public var localizedJobTitle: String? {
    isJapanese ? (jobTitleJa ?? jobTitle) : jobTitle
  }
}

extension Organizer {
  public var localizedBio: String {
    isJapanese ? (bioJa ?? bio) : bio
  }
}
