import Ignite

struct LanguageSelector: InlineElement {
  let path: (SupportedLanguage) -> String
  let currentLanguage: SupportedLanguage

  var body: some InlineElement {
    InlineForEach(SupportedLanguage.allCases) { language in
      Link(language.name, target: path(language))
        .role(currentLanguage == language ? .light : .secondary)
        .fontWeight(currentLanguage == language ? .bold : .regular)
        .margin(.trailing, .px(16))
    }
  }
}

extension SupportedLanguage {
  fileprivate var name: String {
    switch self {
    case .ja: return "日本語"
    case .en: return "English"
    }
  }
}
