import Ignite

struct LanguageSelector: HTML, InlineElement {
  let path: (SupportedLanguage) -> String
  let currentLanguage: SupportedLanguage

  var body: some HTML {
    Section {
      ForEach(SupportedLanguage.allCases) { language in
        Link(language.name, target: path(language))
          .role(currentLanguage == language ? .light : .secondary)
          .fontWeight(currentLanguage == language ? .bold : .regular)
          .margin(.trailing, .px(16))
      }
    }
  }
}

private extension SupportedLanguage {
  var name: String {
    switch self {
    case .ja: return "日本語"
    case .en: return "English"
    }
  }
}
