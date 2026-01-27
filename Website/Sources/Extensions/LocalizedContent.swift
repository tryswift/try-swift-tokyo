import SharedModels

// Extensions to get localized content from models based on language

extension Speaker {
  func localizedBio(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return bioJa ?? bio
    case .en: return bio
    }
  }

  func localizedJobTitle(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return jobTitleJa ?? jobTitle
    case .en: return jobTitle
    }
  }
}

extension Organizer {
  func localizedBio(for language: SupportedLanguage) -> String {
    switch language {
    case .ja: return bioJa ?? bio
    case .en: return bio
    }
  }
}

extension Session {
  func localizedTitle(for language: SupportedLanguage) -> String {
    switch language {
    case .ja: return titleJa ?? title
    case .en: return title
    }
  }

  func localizedDescription(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return descriptionJa ?? description
    case .en: return description
    }
  }

  func localizedSummary(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return summaryJa ?? summary
    case .en: return summary
    }
  }

  func localizedPlace(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return placeJa ?? place
    case .en: return place
    }
  }

  func localizedRequirements(for language: SupportedLanguage) -> String? {
    switch language {
    case .ja: return requirementsJa ?? requirements
    case .en: return requirements
    }
  }
}
